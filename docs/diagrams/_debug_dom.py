"""调试：查看 Flutter Web 的 DOM 结构和渲染状态"""
from playwright.sync_api import sync_playwright
import time

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    ctx = browser.new_context(viewport={'width': 480, 'height': 920}, device_scale_factor=1)
    page = ctx.new_page()
    page.goto('http://localhost:8765/', wait_until='load', timeout=60000)

    for t in [2, 5, 10, 15]:
        time.sleep(t - (sum([2, 5, 10, 15][:[2, 5, 10, 15].index(t)])))
        info = page.evaluate("""() => ({
            url: location.href,
            bodyChildren: Array.from(document.body.children).map(e => e.tagName + (e.id ? '#' + e.id : '') + (e.className ? '.' + e.className : '')),
            canvases: document.querySelectorAll('canvas').length,
            flutterView: !!document.querySelector('flutter-view'),
            glass: !!document.querySelector('flt-glass-pane'),
            scene: !!document.querySelector('flt-scene-host'),
            sceneCanvases: document.querySelector('flt-scene-host') ? document.querySelector('flt-scene-host').querySelectorAll('canvas').length : -1,
            allTags: Array.from(new Set(Array.from(document.querySelectorAll('*')).map(e => e.tagName.toLowerCase()))).filter(t => t.startsWith('flt') || t.startsWith('flutter')),
        })""")
        print(f'T+{t}s:', info)

    page.screenshot(path='D:/Code/bs/docs/diagrams/screenshots/_debug.png')
    browser.close()
print('done')
