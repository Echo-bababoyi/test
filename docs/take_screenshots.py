import asyncio
from playwright.async_api import async_playwright
import os

OUTPUT_DIR = "D:/Code/bs/docs/screenshots_ppt"
os.makedirs(OUTPUT_DIR, exist_ok=True)

BASE = "http://localhost:3080"

# (filename, route, mode)
PAGES = [
    ("01_elder_home.png",      "/elder",                   "elder"),
    ("01b_standard_home.png",  "/home",                    "standard"),
    ("04_face_auth.png",       "/login/face",              "elder"),
    ("04b_verify.png",         "/login/verify",            "elder"),
    ("05_yibao_jiaofei.png",   "/service/yibao-jiaofei",  "elder"),
    ("06_pension_query.png",   "/service/pension-query",   "elder"),
    ("07_shebao_query.png",    "/service/shebao-query",    "elder"),
    ("08_operation_logs.png",  "/elder/operation-logs",    "elder"),
    ("09_drafts.png",          "/elder/drafts",            "elder"),
    ("10_mine.png",            "/my",                      "elder"),
    ("11_search.png",          "/search",                  "elder"),
    ("12_agent_settings.png",  "/elder/agent-settings",   "elder"),
]

async def make_page(browser, mode):
    ctx = await browser.new_context(
        viewport={"width": 390, "height": 844},
        device_scale_factor=2,
    )
    await ctx.add_init_script(f"localStorage.setItem('app_mode', '{mode}');")
    page = await ctx.new_page()
    await page.goto(BASE, wait_until="networkidle")
    await page.wait_for_timeout(3000)
    return ctx, page

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=["--no-sandbox", "--disable-web-security"]
        )

        ctx_elder, page_elder = await make_page(browser, "elder")
        ctx_std,   page_std   = await make_page(browser, "standard")  # sequential: splash done before this starts

        pages_by_mode = {"elder": page_elder, "standard": page_std}

        for filename, route, mode in PAGES:
            page = pages_by_mode[mode]
            await page.goto(f"{BASE}/#{route}", wait_until="networkidle")
            await page.wait_for_timeout(3000)
            await page.screenshot(path=f"{OUTPUT_DIR}/{filename}", full_page=False)
            print(f"saved: {filename}")

        await ctx_elder.close()
        await ctx_std.close()
        await browser.close()
        print("All screenshots done!")

asyncio.run(main())
