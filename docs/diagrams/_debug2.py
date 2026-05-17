from playwright.sync_api import sync_playwright
import time

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    ctx = browser.new_context(viewport={'width': 480, 'height': 920}, device_scale_factor=2)
    page = ctx.new_page()
    page.goto('http://localhost:8765/', wait_until='load', timeout=60000)
    print('Loaded, waiting 15s for full render...')
    time.sleep(15)

    info = page.evaluate("""() => ({
        url: location.href,
        bodyHTML: document.body.innerHTML.length,
        flutterView: !!document.querySelector('flutter-view'),
        bodyText: document.body.innerText.substring(0, 200),
    })""")
    print('Status:', info)

    page.screenshot(path='D:/Code/bs/docs/diagrams/screenshots/_debug.png')
    print('Screenshot saved')

    # 切换到 home
    page.evaluate("window.location.hash = '#/home'")
    time.sleep(3)
    page.screenshot(path='D:/Code/bs/docs/diagrams/screenshots/_debug_home.png')
    print('Home screenshot saved')

    browser.close()
print('done')
