"""
截图小浙 FAB 图标效果 - 截四个宣传册页面并拼合
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
import time

OUT_DIR = Path(r"D:\Code\bs\docs\diagrams\brochure_shots")
OUT_DIR.mkdir(parents=True, exist_ok=True)

VIEWPORT = {"width": 390, "height": 844}

PAGES = [
    ("/service/yibao-jiaofei", "01_yibao_jiaofei.png"),
    ("/service/pension-query", "02_pension_query.png"),
    ("/elder/drafts",          "03_drafts.png"),
    ("/login/face",            "04_face_auth.png"),
]

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--disable-web-security", "--lang=zh-CN"],
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

        print("Loading Flutter Web (DEMO_MODE)...")
        # 注意：需要 DEMO_MODE 构建，或者直接用当前 build
        page.goto("http://localhost:8080/", wait_until="domcontentloaded", timeout=60000)
        page.wait_for_selector("flutter-view", state="attached", timeout=90000)
        print("Flutter ready, waiting 5s...")
        time.sleep(5)

        shots = []
        for route, filename in PAGES:
            print(f"--> {filename}")
            page.evaluate(f"window.location.hash = '{route}'")
            time.sleep(3)
            out = OUT_DIR / filename
            page.screenshot(path=str(out), full_page=False)
            shots.append(str(out))
            print(f"    saved: {filename}")

        browser.close()

    # 拼图：2x2
    try:
        from PIL import Image
        imgs = [Image.open(p) for p in shots]
        w, h = imgs[0].size
        combined = Image.new("RGB", (w * 2, h * 2), (248, 248, 248))
        combined.paste(imgs[0], (0, 0))
        combined.paste(imgs[1], (w, 0))
        combined.paste(imgs[2], (0, h))
        combined.paste(imgs[3], (w, h))
        out_combined = OUT_DIR / "combined.png"
        combined.save(str(out_combined))
        print(f"拼图完成: {out_combined}")
    except Exception as e:
        print(f"拼图失败: {e}")

    print("DONE")

if __name__ == "__main__":
    main()
