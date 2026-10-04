"""Corner towers get the town tower's roof: the two torches PixelLab painted on the corner bastion's back and front
merlons (they read as flames floating over a flat grey roof) come off, and the roof gets town_tower's lit floor and
fire basket, warm light falling off round it. Damaged: the burnt torch stubs come off and town_tower's dead basket
goes in. Ruins have no roof and are left alone.

The roof rows are the same in every corner set (town_tower_corner, _e, _s, _e_s), so the change is worked out once on
town_tower_corner and the changed pixels are written into each set's intact, damaged and idle frames (the idle strip only
sways the banners, below the roof).

Usage (from the project root; runs once, it refuses a set whose torches are already gone):
  python tools/dev/ref_convert/corner_roof.py
"""
from collections import deque
from pathlib import Path
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
SETS = ["town_tower_corner", "town_tower_corner_e", "town_tower_corner_s", "town_tower_corner_e_s"]
CX = 74          # the corner roof's centre column (back merlon, basket, front crenel)
FIRE = (74, 39)  # the floor's centre, where the basket stands
DX, DY = 14, 0   # town_tower's basket (60, 40) onto FIRE
FLOOR = np.array([166, 153, 144, 255])
TORCH = [(15, 10, 10), (32, 22, 24), (55, 33, 17), (127, 46, 8), (48, 48, 32)]
WARM_SOFT = [(178, 142, 115), (152, 120, 93), (191, 173, 155)]
WARM_HOT = [(85, 54, 46), (117, 75, 46), (152, 89, 54), (182, 119, 74), (207, 134, 71), (247, 170, 89)]


def load(p):
    return np.array(Image.open(p).convert("RGBA")).astype(int)


def lum(p):
    return p[..., 0] * 0.3 + p[..., 1] * 0.59 + p[..., 2] * 0.11


def merlon(o):
    """A plain back-corner merlon where the torch stood: a top diamond, a darker left face and a lighter right face
    (the back merlons' own shading), outlined like its neighbours."""
    out, top, top2, toph = [4, 4, 5, 255], [166, 153, 144, 255], [152, 141, 138, 255], [174, 162, 155, 255]
    lf, lf2, rf, rf2 = [108, 99, 104, 255], [116, 106, 111, 255], [132, 124, 127, 255], [152, 141, 138, 255]
    for x in range(60, 88):
        dxa = abs(x + 0.5 - CX)
        if dxa > 10.5:
            continue
        top_up, top_lo, bot = 4 + dxa * 0.5, 13 - dxa * 0.5, 26 - dxa * 0.5
        for y in range(0, 29):
            if y < top_up - 1:
                o[y, x] = [0, 0, 0, 0]
            elif y < top_up or (dxa > 9.5 and y < bot):
                o[y, x] = out
            elif y <= top_lo:
                o[y, x] = toph if (y <= top_up + 1 and x < CX) else (top if (x * 7 + y * 3) % 11 else top2)
            elif y <= bot:
                if x < CX:
                    o[y, x] = lf if (x * 5 + y * 3) % 9 else lf2
                else:
                    o[y, x] = rf if (x * 3 + y * 5) % 9 else rf2


def clean_intact(a, d):
    """The intact roof without its torches or their glow: glowing pixels take the damaged still's stone (it has the
    same roof, cold), the back merlon is redrawn, and the front torch's crenel is floor again."""
    r, b = a[..., 0], a[..., 2]
    box = np.zeros(a.shape[:2], bool)
    box[0:36, 58:92] = True
    box[36:68, 56:92] = True
    torch = np.zeros_like(box)
    for c in TORCH:
        torch |= np.abs(a[..., :3] - c).sum(2) < 3
    m = box & ((r - b > 35) | ((r > 200) & (a[..., 1] > 150)) | torch)
    o = a.copy()
    for y, x in zip(*np.nonzero(m)):
        o[y, x] = d[y, x] if lum(d[y, x]) >= 70 and d[y, x, 3] > 0 else FLOOR
    for y in range(40, 60):
        for x in range(67, 82):
            if lum(o[y, x]) < 115 or o[y, x, 0] - o[y, x, 2] > 25:
                o[y, x] = FLOOR
    merlon(o)
    # The damaged still's floor cracks that came across with its stone.
    for y in range(22, 52):
        for x in range(56, 94):
            dxa = abs(x + 0.5 - CX)
            if dxa <= 10.5 and y <= 26 - dxa * 0.5:
                continue
            p = o[y, x]
            if p[3] > 0 and (lum(p) < 115 or p[0] - p[2] > 25) and not (x < 62 or (x > 86 and y < 30)):
                o[y, x] = FLOOR
    return o


def light(o, stone):
    """Warm firelight over the roof (the floor and the merlons round it), strongest by the basket, snapped to the
    sprite's stone palette and town_tower's warm one."""
    zone = np.zeros(o.shape[:2], bool)
    q = deque([(FIRE[1], FIRE[0])])
    zone[FIRE[1], FIRE[0]] = True
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            yy, xx = y + dy, x + dx
            if 0 <= yy < 62 and 0 <= xx < o.shape[1] and not zone[yy, xx] and o[yy, xx, 3] > 0 \
                    and lum(o[yy, xx]) >= 60:
                zone[yy, xx] = True
                q.append((yy, xx))
    w = o.copy()
    for y, x in zip(*np.nonzero(zone)):
        dist = ((x - FIRE[0]) ** 2 + ((y - FIRE[1]) * 2) ** 2) ** 0.5
        s = max(0.0, min(1.0, 1.4 - dist / 44.0))
        if s <= 0:
            continue
        p = o[y, x, :3].astype(float)
        L = lum(o[y, x])
        c = p * (1 - s) + np.array([L * 1.12 + 8, L * 0.86, L * 0.62]) * s
        in_merlon = abs(x + 0.5 - CX) <= 10.5 and y <= 26 - abs(x + 0.5 - CX) * 0.5
        pal = stone + WARM_SOFT + (WARM_HOT if s >= 0.6 and not in_merlon else [])
        w[y, x, :3] = min(pal, key=lambda k: ((np.array(k) - c) ** 2).sum())
    return w


def paste_basket(o, t, dead):
    """town_tower's basket (and, lit, its glowing floor diamond) onto the corner roof's centre."""
    for y in range(16, 52):
        for x in range(36, 86):
            p = t[y, x]
            if p[3] == 0:
                continue
            if dead:
                hit = 52 <= x <= 68 and 26 <= y <= 43 and lum(p) < 60
            else:
                # Above the bowl (y < 28) only the flame: the orange beside it there is town_tower's merlon faces.
                hit = (52 <= x <= 67 and 19 <= y <= 43 and (lum(p) < 80 or p[0] - p[2] > 100)
                       and (y >= 28 or p[0] > 220)) \
                    or (abs(x - 60) / 21 + abs(y - 40) / 10.5 <= 1 and p[0] - p[2] > 120)
            if hit:
                o[y + DY, x + DX] = p


def clean_damaged(d):
    """The damaged roof without its burnt torch stubs: each row's stone from either side, the front crenel floor."""
    o = d.copy()
    for y in range(0, 4):
        for x in range(70, 79):
            o[y, x] = [0, 0, 0, 0]
    for (x0, x1, y0, y1) in [(70, 79, 4, 28)]:
        for y in range(y0, y1):
            for x in range(x0, x1):
                p = o[y, x]
                if lum(p) < 85 or p[0] - p[2] > 35:
                    o[y, x] = o[y, x0 - 1] if x < CX else o[y, x1]
    floor = d[45, 60].copy()
    for y in range(48, 60):
        for x in range(68, 81):
            p = o[y, x]
            if lum(p) < 85 or p[0] - p[2] > 35:
                o[y, x] = floor
    return o


def main():
    base = B / SETS[0]
    a, d = load(base / "intact.png"), load(base / "damaged.png")
    flame = (a[..., 0] > 240) & (a[..., 1] > 160) & (a[..., 2] < 120)
    if flame[:66].sum() < 10:
        sys.exit("town_tower_corner has no roof torches: already converted")
    stone = [tuple(int(v) for v in c) for c in np.unique(a[a[..., 3] > 0][:, :3], axis=0)]
    tw = B / "town_tower"
    lit = light(clean_intact(a, d), stone)
    paste_basket(lit, load(tw / "intact.png"), False)
    cold = clean_damaged(d)
    paste_basket(cold, load(tw / "damaged.png"), True)
    for name, old, new in [("intact", a, lit), ("damaged", d, cold)]:
        changed = np.any(old != new, axis=2)
        for s in SETS:
            im = load(B / s / f"{name}.png")
            assert np.array_equal(im[changed], old[changed]), f"{s}/{name}: roof differs from {SETS[0]}"
            im[changed] = new[changed]
            Image.fromarray(im.astype(np.uint8)).save(B / s / f"{name}.png")
            if name == "intact" and (B / s / "idle.png").exists():
                strip = load(B / s / "idle.png")
                w = im.shape[1]
                for k in range(strip.shape[1] // w):
                    f = strip[:, k * w:(k + 1) * w]
                    assert np.array_equal(f[changed], old[changed]), f"{s}/idle frame {k}: roof differs"
                    f[changed] = new[changed]
                Image.fromarray(strip.astype(np.uint8)).save(B / s / "idle.png")
        print(name, "pixels changed:", int(changed.sum()))


if __name__ == "__main__":
    main()
