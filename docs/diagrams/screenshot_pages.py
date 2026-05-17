"""
宣传册四页面自动截图（v4）
- 长辈版首页：demo 模式自动打开助手面板
- 刷脸页：点击"开始认证"触发弹窗
- 养老金页：点击"查询"按钮展示结果
- 草稿箱：注入 mock 数据后截图
"""
from playwright.sync_api import sync_playwright
from pathlib import Path
import time, json

OUT_DIR = Path(r"D:\Code\bs\docs\diagrams\screenshots")
OUT_DIR.mkdir(parents=True, exist_ok=True)

VIEWPORT = {"width": 480, "height": 920}


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

        # ── 1. 长辈版首页 + 助手面板（demo 模式自动打开）──
        print("--> 01 elder home + agent panel")
        page.evaluate("window.location.hash = '#/elder'")
        time.sleep(4)
        page.screenshot(path=str(OUT_DIR / "01_elder_home_agent.png"), full_page=False)
        print("    saved")

        # ── 2. 刷脸页（默认状态 + 助手面板引导）──
        print("--> 02 face auth + agent panel")
        page.evaluate("window.location.hash = '#/login/face'")
        time.sleep(4)
        page.screenshot(path=str(OUT_DIR / "02_face_auth.png"), full_page=False)
        print("    saved")

        # ── 3. 养老金查询 + 助手面板 ──
        print("--> 03 pension query + agent panel")
        page.evaluate("window.location.hash = '#/service/pension-query'")
        time.sleep(4)
        page.screenshot(path=str(OUT_DIR / "03_pension_query.png"), full_page=False)
        print("    saved")

        # ── 4. 草稿箱（注入 mock 数据到 IndexedDB）──
        print("--> 04 drafts with data")
        mock_drafts = [
            {
                "draft_id": "demo_1",
                "page_id": "yibao_jiaofei",
                "page_title": "医保缴费",
                "fields": {"缴费对象": "本人", "年度": "2026", "金额": "4800元"},
                "updated_at": "2026-05-14T14:30:00",
            },
            {
                "draft_id": "demo_2",
                "page_id": "pension_query",
                "page_title": "养老金查询",
                "fields": {"查询月份": "2026年5月"},
                "updated_at": "2026-05-13T09:15:00",
            },
        ]
        inject_js = """
        async () => {
            const dbReq = indexedDB.open('xiaozhe_draft', 1);
            await new Promise((resolve, reject) => {
                dbReq.onupgradeneeded = (e) => {
                    const db = e.target.result;
                    if (!db.objectStoreNames.contains('drafts')) {
                        db.createObjectStore('drafts', {keyPath: 'draft_id'});
                    }
                };
                dbReq.onsuccess = resolve;
                dbReq.onerror = reject;
            });
            const db = dbReq.result;
            const tx = db.transaction('drafts', 'readwrite');
            const store = tx.objectStore('drafts');
            const drafts = """ + json.dumps(mock_drafts) + """;
            for (const d of drafts) { store.put(d); }
            await new Promise(r => { tx.oncomplete = r; });
            db.close();
        }
        """
        page.evaluate(inject_js)
        time.sleep(1)
        # 先去别的页面，再回来（强制 DraftsPage 重新 initState）
        page.evaluate("window.location.hash = '#/elder'")
        time.sleep(1.5)
        page.evaluate("window.location.hash = '#/elder/drafts'")
        time.sleep(3)
        page.screenshot(path=str(OUT_DIR / "04_drafts.png"), full_page=False)
        print("    saved")

        browser.close()
    print("DONE")

if __name__ == "__main__":
    main()
