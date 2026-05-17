"""
低保真线框图截图脚本
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
import time

OUT_DIR = Path(r"D:\Code\bs\docs\diagrams\wireframes")
OUT_DIR.mkdir(parents=True, exist_ok=True)

VIEWPORT = {"width": 480, "height": 920}

PAGES = [
    ("wf0", "#/wireframe/0", "01_elder_home.png"),
    ("wf1", "#/wireframe/1", "02_face_auth.png"),
    ("wf2", "#/wireframe/2", "03_yibao_jiaofei.png"),
    ("wf3", "#/wireframe/3", "04_agent_panel.png"),
    ("wf4", "#/wireframe/4", "05_auth_card.png"),
    ("wf5", "#/wireframe/5", "06_operation_log.png"),
]

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--disable-web-security", "--lang=zh-CN", "--font-render-hinting=none"],
            proxy={"server": "http://127.0.0.1:7897", "bypass": "localhost,127.0.0.1"},
        )
        ctx = browser.new_context(
            viewport=VIEWPORT,
            device_scale_factor=2,
            locale="zh-CN",
            bypass_csp=True,
        )
        page = ctx.new_page()
        page.on("pageerror", lambda exc: print(f"  [ERR] {exc}"))

        print("Loading Flutter Web...")
        page.goto("http://localhost:8765/", wait_until="domcontentloaded", timeout=60000)
        page.wait_for_selector("flutter-view", state="attached", timeout=90000)
        print("Flutter ready, waiting 5s...")
        time.sleep(5)

        for name, route, filename in PAGES:
            print(f"--> {name}")
            page.evaluate(f"window.location.hash = '{route}'")
            time.sleep(3)
            page.screenshot(path=str(OUT_DIR / filename), full_page=False)
            print(f"    saved: {filename}")

        browser.close()
    print("DONE")

if __name__ == "__main__":
    main()
