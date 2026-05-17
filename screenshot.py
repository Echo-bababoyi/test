from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from PIL import Image
import time
import os

options = Options()
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-dev-shm-usage')
options.add_argument('--window-size=390,844')

driver = webdriver.Chrome(options=options)

base_url = "http://localhost:8080"
pages = [
    ("", "home"),
    ("/#/explore", "explore"),
    ("/#/bookshelf", "bookshelf"),
    ("/#/profile", "profile"),
]

screenshots = []
os.makedirs("D:/Code/bs/screenshots", exist_ok=True)

for path, name in pages:
    url = base_url + path
    driver.get(url)
    time.sleep(3)
    filepath = f"D:/Code/bs/screenshots/{name}.png"
    driver.save_screenshot(filepath)
    screenshots.append(filepath)
    print(f"截图完成: {name}")

driver.quit()

# 拼图
imgs = [Image.open(p) for p in screenshots]
w = imgs[0].width
h = imgs[0].height
combined = Image.new('RGB', (w * 2, h * 2))
combined.paste(imgs[0], (0, 0))
combined.paste(imgs[1], (w, 0))
combined.paste(imgs[2], (0, h))
combined.paste(imgs[3], (w, h))
combined.save("D:/Code/bs/screenshots/combined.png")
print("拼图完成: combined.png")
