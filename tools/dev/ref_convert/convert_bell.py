"""Convert the reference sheet's bell tower (TownMap_Component4) into a game sprite for the 1.1 x 1.1 plot."""
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

S = "C:/Users/dorae/AppData/Local/Temp/claude/C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab/64321455-71f5-4ef9-84ed-ba260def80dc/scratchpad/conv/"
src = Image.open(S + "bell_crop.png").convert("RGBA")
a = np.array(src)
h, w = a.shape[:2]

# 1. keep the largest solid shape (drops the neighbouring trees at the crop's edges)
solid = a[..., 3] > 128
lab = -np.ones((h, w), int)
sizes = []
for y0 in range(h):
    for x0 in range(w):
        if solid[y0, x0] and lab[y0, x0] < 0:
            q = deque([(y0, x0)]); lab[y0, x0] = len(sizes); n = 0
            while q:
                y, x = q.popleft(); n += 1
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and solid[yy, xx] and lab[yy, xx] < 0:
                            lab[yy, xx] = len(sizes); q.append((yy, xx))
            sizes.append(n)
main = int(np.argmax(sizes))
a[lab != main, 3] = 0
a[(lab == main) & ~solid, 3] = 0

# 2. the tower body's width: non-green opaque extent over the lower-middle rows (walls are vertical in iso,
#    so the body's width equals its footprint diamond's width)
rgb = a[..., :3].astype(int)
green = (rgb[..., 1] > rgb[..., 0] + 15) & (rgb[..., 1] > rgb[..., 2] + 15)
body = (a[..., 3] > 0) & ~green
ys = np.nonzero(body.any(axis=1))[0]
top, bot = ys.min(), ys.max()
rows = range(int(top + (bot - top) * 0.62), int(top + (bot - top) * 0.78))
widths = [np.ptp(np.nonzero(body[y])[0]) + 1 for y in rows if body[y].any()]
body_w = float(np.median(widths))
TARGET = 32 * (1.1 + 1.1)            # 70.4 px
scale = TARGET / body_w
print("body width", body_w, "scale", round(scale, 3))

# 3. downscale with proper alpha (premultiplied), then sharpen a touch
img = Image.fromarray(a, "RGBA")
nw, nh = round(w * scale), round(h * scale)
small = img.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
alpha = small.getchannel("A")
rgbimg = small.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))

# 4. hard alpha and a limited palette
al = np.array(alpha) >= 110
q = rgbimg.quantize(colors=48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
out = np.zeros((nh, nw, 4), np.uint8)
out[..., :3] = np.array(q)
out[..., 3] = np.where(al, 255, 0)

# 5. dark 1 px outline where the silhouette meets the background (the reference has a soft dark edge)
OUT = np.array([34, 26, 24])
edge = np.zeros_like(al)
pad = np.pad(al, 1)
for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
    edge |= al & ~pad[1 + dy:1 + dy + nh, 1 + dx:1 + dx + nw]
dark = out[..., :3].astype(int).sum(axis=2) < 200
out[edge & ~dark, :3] = (out[edge & ~dark, :3] * 0.45 + OUT * 0.55).astype(np.uint8)

# 6. canvas with room, and the anchor: the front (lowest) point of the body's base
canvas_w, canvas_h = nw + 8, nh + 8
c = np.zeros((canvas_h, canvas_w, 4), np.uint8)
c[4:4 + nh, 4:4 + nw] = out
cb = (c[..., 3] > 0)
gb = cb & ~((c[..., 1].astype(int) > c[..., 0] + 15) & (c[..., 1].astype(int) > c[..., 2] + 15))
yb = np.nonzero(gb.any(axis=1))[0].max()
xs = np.nonzero(gb[yb])[0]
print("canvas", (canvas_w, canvas_h), "lowest body row", yb, "x", xs.min(), xs.max())
Image.fromarray(c, "RGBA").save(S + "bell_intact.png")
Image.fromarray(c, "RGBA").resize((canvas_w * 4, canvas_h * 4), Image.NEAREST).save(S + "bell_intact_x4.png")
