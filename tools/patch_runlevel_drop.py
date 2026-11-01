"""Story-stage reward pop-up ("So lucky !", dlg_ui/RunLevelDrop.ccbi): the button picture says "Fold" (a bad translation) and the game
draws its own "Proceed" title on top of it at font size 12, so both showed. This paints "Proceed" into the button picture
(dropbox_04 in ccbResources/runlevel_drop.pvr.ccz) in the same white-with-brown-outline style and makes the tiny title size 1.

python tools/patch_runlevel_drop.py   (needs re/obb from tools/setup_re.py and Pillow; writes into cdn/src)
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(__file__))
import ccbi, pvrccz

SRC, OUT = 're/obb', 'cdn/src'
X0, Y0, W, H = 314, 503, 194, 67  # dropbox_04 in the sheet (runlevel_drop.plist)

pvr, head = pvrccz.read(f'{SRC}/ccbResources/runlevel_drop.pvr.ccz')
w, h, rgba = pvrccz.to_rgba(pvr)
sheet = Image.frombytes('RGBA', (w, h), rgba)
btn = sheet.crop((X0, Y0, X0 + W, Y0 + H))
px = btn.load()
# erase "Fold": each row blends between two clean columns left and right of the word
L, R = 46, 144
for y in range(12, 55):
    a, b = px[L, y], px[R, y]
    for x in range(L + 1, R):
        t = (x - L) / (R - L)
        px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(4))
# draw "Proceed" centred where "Fold" was (white, dark brown outline like the original lettering)
d = ImageDraw.Draw(btn)
font = ImageFont.truetype('C:/Windows/Fonts/seguibl.ttf', 26)
box = d.textbbox((0, 0), 'Proceed', font=font, stroke_width=3)
x = (W - (box[2] - box[0])) // 2 - box[0] - 4
y = 33 - (box[3] + box[1]) // 2
d.text((x, y), 'Proceed', font=font, fill=(255, 255, 255, 255), stroke_width=3, stroke_fill=(68, 17, 0, 255))
sheet.paste(btn, (X0, Y0))
os.makedirs(f'{OUT}/ccbResources', exist_ok=True)
pvrccz.write(f'{OUT}/ccbResources/runlevel_drop.pvr.ccz', pvrccz.from_rgba(pvr, sheet.tobytes()), head)
btn.save('re/proceed_button.png')

data = open(f'{SRC}/dlg_ui/RunLevelDrop.ccbi', 'rb').read()
os.makedirs(f'{OUT}/dlg_ui', exist_ok=True)
open(f'{OUT}/dlg_ui/RunLevelDrop.ccbi', 'wb').write(ccbi.patch(data, {'CCControlButton': {'titleTTFSize|1': (1.0, 0)}}))
print('ok')
