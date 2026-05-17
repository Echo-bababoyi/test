from PIL import Image
import numpy as np

files = [
    r'D:/Code/bs/docs/diagrams/screenshots/01_elder_home_agent.png',
    r'D:/Code/bs/docs/diagrams/screenshots/02_face_auth.png',
    r'D:/Code/bs/docs/diagrams/screenshots/03_pension_query.png',
    r'D:/Code/bs/docs/diagrams/screenshots/04_drafts.png',
]

def crop_black_frame(img):
    arr = np.array(img)
    mask = np.any(arr > 30, axis=2)
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    return img.crop((cols[0], rows[0], cols[-1] + 1, rows[-1] + 1))

imgs = [crop_black_frame(Image.open(f)) for f in files]
print('cropped sizes:', [i.size for i in imgs])

target_h = 900
scaled = []
for img in imgs:
    w, h = img.size
    new_w = int(w * target_h / h)
    scaled.append(img.resize((new_w, target_h), Image.LANCZOS))

gap = 24
bg_color = (245, 245, 245)
total_w = sum(i.width for i in scaled) + gap * (len(scaled) + 1)
total_h = target_h + gap * 2

canvas = Image.new('RGB', (total_w, total_h), bg_color)
x = gap
for img in scaled:
    canvas.paste(img, (x, gap))
    x += img.width + gap

out = r'D:/Code/bs/docs/diagrams/screenshots_combined.png'
canvas.save(out, dpi=(150, 150))
print(f'saved: {out}  size: {canvas.size}')
