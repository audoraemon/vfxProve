"""Repaint the bell tower's stone walls with the town tower's own brick pattern (flat lit/shaded faces, mortar every
5 px along each face's 2:1 slope, staggered joints); keep the banner, window, door, their arch stones and the bushes."""
import numpy as np
from PIL import Image

S = "C:/Users/dorae/AppData/Local/Temp/claude/C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab/64321455-71f5-4ef9-84ed-ba260def80dc/scratchpad/conv/"
im = Image.open(S + "bell_blend3.png").convert("RGBA")   # mirrored (lit from the left), stone toned
a = np.array(im)
h, w = a.shape[:2]
AX, AY, HALF = 151 - 78, 200, 35.2                       # front corner after mirroring; half the diamond width

# town tower colours (assets/pixellab/buildings/town_tower/intact.png)
L_BRICK, L_BRICK2, L_MORT = (160, 150, 137), (150, 140, 128), (92, 79, 74)
R_BRICK, R_BRICK2, R_MORT = (101, 90, 101), (94, 84, 94), (48, 40, 47)
ROW, BRICK = 5, 8

rgb = a[..., :3].astype(int)
op = a[..., 3] > 0
mx, mn = rgb.max(axis=2), rgb.min(axis=2)
sat = mx - mn
blue = (rgb[..., 2] > rgb[..., 0] + 30) & (rgb[..., 2] > rgb[..., 1] + 15)
green = (rgb[..., 1] > rgb[..., 0] + 12) & (rgb[..., 1] > rgb[..., 2] + 12)
wood = (rgb[..., 0] > rgb[..., 1] + 40) & (rgb[..., 0] > rgb[..., 2] + 70)
dark = rgb.sum(axis=2) < 150
raw = op & (blue | green | (wood & (mx < 170)) | dark)
# only large connected shapes are features (banner, window, door, bushes); stone speckle is not
from collections import deque
feature = np.zeros_like(raw)
seen = np.zeros_like(raw)
for y0 in range(h):
    for x0 in range(w):
        if raw[y0, x0] and not seen[y0, x0]:
            q = deque([(y0, x0)]); seen[y0, x0] = True; pts = []
            while q:
                y, x = q.popleft(); pts.append((y, x))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and raw[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True; q.append((yy, xx))
            if len(pts) >= 25:
                for y, x in pts:
                    feature[y, x] = True
# keep a 1 px ring round each feature (window and door arch stones, the banner's rod)
ring = feature.copy()
for _ in range(1):
    p = np.pad(ring, 1)
    ring = ring | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]

# per column, the wall starts below the belfry: the lowest timber (wood) pixel in the upper half, plus the corbels
wall_top = np.full(w, h, int)
zs = []
for x in range(int(AX + 4), int(AX + HALF - 2)):          # the shaded right face: belfry timber is clearly wood there
    ys = np.nonzero(wood[: h // 2, x])[0]
    if len(ys):
        zs.append((AY - (x - AX) * 0.5) - (ys.max() + 4))
Z_TOP = float(np.median(zs))                             # the wall's height below the belfry, the same all round
for x in range(w):
    wall_top[x] = int(round((AY - abs(AX - x) * 0.5) - Z_TOP))
print("wall height under the belfry", Z_TOP)

out = a.copy()
for y in range(h):
    for x in range(int(AX - HALF) + 1, int(AX + HALF)):
        if not op[y, x] or ring[y, x] or y < wall_top[x]:
            continue
        left = x < AX
        base = AY - abs(AX - x) * 0.5
        z = base - y                                      # height above the face's ground line
        if z < 2:
            continue                                      # leave the footing / step as drawn
        u = abs(AX - x)
        row = int(z // ROW)
        if int(z) % ROW == 0:
            col = L_MORT if left else R_MORT
        elif int(u + (BRICK // 2 if row % 2 else 0)) % BRICK == 0:
            col = L_MORT if left else R_MORT
        else:
            alt = ((row * 7 + int((u + (BRICK // 2 if row % 2 else 0)) // BRICK) * 3) % 5) == 0
            col = (L_BRICK2 if alt else L_BRICK) if left else (R_BRICK2 if alt else R_BRICK)
        # a step darker in the belfry's shadow
        if y < wall_top[x] + 4:
            col = tuple(int(c * 0.82) for c in col)
        out[y, x, :3] = col

# the front corner edge: one light column, as on the town tower
for y in range(h):
    if op[y, AX] and not ring[y, AX] and y >= wall_top[AX] and AY - y > 2:
        out[y, AX, :3] = (176, 166, 152)

Image.fromarray(out, "RGBA").save(S + "bell_retex.png")
B = "C:/BURIN_NITRO/Godot/GIT/vfxProve-gpt/assets/pixellab/buildings/"
ims = [Image.open(S + "bell_blend3.png"), Image.fromarray(out, "RGBA"), Image.open(B + "town_tower/intact.png"),
       Image.open(B + "townhouse_a/intact.png")]
ims = [i.convert("RGBA") for i in ims]
H = max(i.height for i in ims); W = sum(i.width + 8 for i in ims)
s = Image.new("RGBA", (W, H), (96, 92, 82, 255)); xx = 0
for i in ims:
    s.alpha_composite(i, (xx, H - i.height)); xx += i.width + 8
s.resize((W * 3, H * 3), Image.NEAREST).save(S + "retex_cmp.png")
