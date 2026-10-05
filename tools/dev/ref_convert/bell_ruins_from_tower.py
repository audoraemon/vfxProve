"""The bell tower's ruins: the approved town_tower ruins (PixelLab, footprint 1.6) scaled to the bell tower's 1.1 plot
with a premultiplied Lanczos downscale, snapped back to the source's 32-colour palette, outlined, and placed so the
two anchors meet. Run after finish_bell.py (which writes intact and damaged; its own ruins were rejected as too rough).
Usage (from the project root): python tools/dev/ref_convert/bell_ruins_from_tower.py
"""
import numpy as np
from PIL import Image

D = "assets/pixellab/buildings/"
src = Image.open(D + "town_tower/ruins.png").convert("RGBA")
k = 1.1 / 1.6
nw, nh = round(src.width * k), round(src.height * k)
sm = src.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
al = np.array(sm.getchannel("A")) >= 120
pal = src.convert("RGB").quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
q = sm.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
a = np.zeros((nh, nw, 4), np.uint8)
a[..., :3] = np.array(q)
a[..., 3] = np.where(al, 255, 0)
p = np.pad(al, 1)
edge = al & ~(p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:])
a[edge, :3] = (a[edge, :3] * 0.4 + np.array([34, 26, 24]) * 0.6).astype(np.uint8)
# town_tower's anchor (60, 172), scaled, lands on the bell tower's anchor (73, 200) on its 152 x 220 canvas
canvas = np.zeros((220, 152, 4), np.uint8)
ox, oy = round(73 - 60 * k), round(200 - 172 * k)
canvas[oy:oy + nh, ox:ox + nw] = a
Image.fromarray(canvas, "RGBA").save(D + "bell_tower/ruins.png")
print("ruins placed at", ox, oy, "size", nw, nh)
