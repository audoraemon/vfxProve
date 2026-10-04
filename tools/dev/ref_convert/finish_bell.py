"""Finish the bell tower: arch frames round the window and door (intact), then the damaged and ruins states drawn
from it, all on the same canvas and anchor."""
import random
from collections import deque
import numpy as np
from PIL import Image

S = "C:/Users/dorae/AppData/Local/Temp/claude/C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab/64321455-71f5-4ef9-84ed-ba260def80dc/scratchpad/conv/"
D = "C:/BURIN_NITRO/Godot/GIT/vfxProve-gpt/assets/pixellab/buildings/bell_tower/"
AX, AY, HALF, Z_TOP = 73, 200, 35.2, 80
L_BRICK, L_MORT = (160, 150, 137), (92, 79, 74)
R_BRICK, R_MORT = (101, 90, 101), (48, 40, 47)
ARCH_L, ARCH_R = (196, 186, 170), (128, 116, 124)
SOOT = (40, 32, 30)
SLATE_C, BEAM_C = (52, 72, 132), (128, 84, 40)
HOLE = (24, 20, 22)

a = np.array(Image.open(S + "bell_retex.png").convert("RGBA"))
h, w = a.shape[:2]
op = a[..., 3] > 0
rgb = a[..., :3].astype(int)


def base_y(x):
    return AY - abs(AX - x) * 0.5


def on_wall(x, y):
    return op[y, x] and abs(x - AX) < HALF - 1 and base_y(x) - Z_TOP <= y <= base_y(x) - 2


def blobs(mask, min_px):
    seen = np.zeros_like(mask); out = []
    for y0 in range(h):
        for x0 in range(w):
            if mask[y0, x0] and not seen[y0, x0]:
                q = deque([(y0, x0)]); seen[y0, x0] = True; pts = []
                while q:
                    y, x = q.popleft(); pts.append((y, x))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not seen[yy, xx]:
                            seen[yy, xx] = True; q.append((yy, xx))
                if len(pts) >= min_px:
                    out.append(pts)
    return out


# ---- 1. arch frames: a 1 px light stone ring round the window and the door, a dark line outside it ----------------
blue = (rgb[..., 2] > rgb[..., 0] + 30) & (rgb[..., 2] > rgb[..., 1] + 15)
doorish = (rgb.sum(axis=2) < 260) | ((rgb[..., 0] > rgb[..., 1] + 40) & (rgb.max(axis=2) < 170))
openings = []
for pts in blobs(op & blue, 12):                        # the window is the blue blob on the LEFT face
    if np.mean([x for _, x in pts]) < AX - 4:
        openings.append(pts)
for pts in blobs(op & doorish, 30):                     # the door: a dark/wood blob low on the left face
    ys = [y for y, _ in pts]; xs = [x for _, x in pts]
    if np.mean(xs) < AX and max(ys) > AY - 40 and min(ys) > AY - Z_TOP:
        openings.append(pts)
out = a.copy()
for pts in []:   # no arch frames (user review): the openings stay as in the reference
    m = np.zeros((h, w), bool)
    for y, x in pts:
        m[y, x] = True
    ring1 = np.zeros_like(m); ring2 = np.zeros_like(m)
    p = np.pad(m, 1)
    ring1 = (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]) & ~m
    p2 = np.pad(m | ring1, 1)
    ring2 = (p2[:-2, 1:-1] | p2[2:, 1:-1] | p2[1:-1, :-2] | p2[1:-1, 2:]) & ~(m | ring1)
    for y, x in zip(*np.nonzero(ring1)):
        if on_wall(x, y) and y < max(py for py, _ in pts):          # no frame under the sill / threshold line
            out[y, x, :3] = ARCH_L if x < AX else ARCH_R
    for y, x in zip(*np.nonzero(ring2)):
        if on_wall(x, y) and y < max(py for py, _ in pts):
            out[y, x, :3] = L_MORT if x < AX else R_MORT
Image.fromarray(out, "RGBA").save(D + "intact.png")
intact = out.copy()

# ---- 2. damaged: cracks, knocked-out bricks, scorch, a torn banner, broken belfry rails --------------------------
rng = random.Random(52)
dmg = intact.copy()


def crack(x, y, steps, dirx):
    for _ in range(steps):
        if 0 <= x < w and 0 <= y < h and on_wall(x, y):
            dmg[y, x, :3] = SOOT
        y += 1
        x += rng.choice((dirx, dirx, 0, -dirx))


for sx, sy, n, d in ((AX - 22, AY - 70, 26, -1), (AX + 14, AY - 64, 22, 1), (AX - 8, AY - 40, 14, 1),
                     (AX + 26, AY - 36, 12, -1)):
    crack(sx, int(sy - abs(AX - sx) * 0.5 + 0), n, d)
# knocked-out bricks: dark holes with a lighter broken rim
for cx, cz in ((AX - 26, 52), (AX + 20, 60), (AX + 8, 24), (AX - 14, 70)):
    cy = int(base_y(cx) - cz)
    for dy in range(-2, 3):
        for dx in range(-3, 4):
            x, y = cx + dx, cy + dy + (dx * (1 if cx < AX else -1)) // 2
            if 0 <= y < h and on_wall(x, y) and abs(dx) + abs(dy) <= 4:
                dmg[y, x, :3] = HOLE if abs(dx) + abs(dy) <= 2 else (ARCH_L if cx < AX else ARCH_R)
# scorch: darken a patch round the lower right and the belfry's foot
for y in range(h):
    for x in range(w):
        if not op[y, x]:
            continue
        d1 = ((x - (AX + 18)) / 16) ** 2 + ((y - (AY - 30)) / 22) ** 2
        d2 = ((x - (AX - 10)) / 20) ** 2 + ((y - (AY - 82)) / 8) ** 2
        k = max(0.0, 1 - min(d1, d2))
        if k > 0 and rng.random() < 0.85:
            dmg[y, x, :3] = (dmg[y, x, :3] * (1 - 0.55 * k)).astype(np.uint8)
# torn banner: its bottom quarter gone, ragged
bl = blobs(op & blue, 40)
for pts in bl:
    if np.mean([x for _, x in pts]) > AX and min(y for y, _ in pts) > AY - Z_TOP - 4:   # the banner: on the right WALL, not the roof
        ys = [y for y, _ in pts]; cut = int(min(ys) + (max(ys) - min(ys)) * 0.7)
        for y, x in pts:
            if y > cut + (x % 3):
                dmg[y, x, :3] = intact[min(y, h - 1), x, :3]
                dmg[y, x, :3] = R_BRICK if (y - cut) % 5 else R_MORT
# broken belfry rails: punch a few dark gaps in the timber band
timber = (rgb[..., 0] > rgb[..., 1] + 30) & (rgb[..., 0] > rgb[..., 2] + 50) & (np.arange(h)[:, None] < AY - Z_TOP)
ty, tx = np.nonzero(timber)
for _ in range(5):
    i = rng.randrange(len(ty))
    for dy in range(-2, 3):
        for dx in range(-1, 2):
            y, x = ty[i] + dy, tx[i] + dx
            if 0 <= y < h and 0 <= x < w and timber[y, x]:
                dmg[y, x, :3] = HOLE
Image.fromarray(dmg, "RGBA").save(D + "damaged.png")

# ---- 3. ruins: a stump broken along whole brick courses, in a smooth mound of whole bricks ------------------------
ROW, BRICK = 5, 8
STUMP = 30
ru = np.zeros_like(intact)
for x in range(w):
    if abs(x - AX) >= HALF:
        continue
    u = abs(x - AX)
    course = int(u // BRICK)
    step = (3 - (course * 5 + (1 if x < AX else 2)) % 4) * ROW      # 0..15 px, in whole courses
    top = int(base_y(x) - STUMP - step)
    for y in range(max(top, 0), h):
        if intact[y, x, 3] > 0 and y <= base_y(x) + 6:
            ru[y, x] = dmg[y, x]
# no banner scraps on the stump: blue pixels become the wall's brick colour
rr = ru[..., :3].astype(int)
bl = (ru[..., 3] > 0) & (rr[..., 2] > rr[..., 0] + 30) & (rr[..., 2] > rr[..., 1] + 15)
for y, x in zip(*np.nonzero(bl)):
    ru[y, x, :3] = L_BRICK if x < AX else R_BRICK
# the heap: small iso stone blocks (lit top, lit left side, shaded right side, dark outline), stacked into a
# rounded pile against the stump's foot, drawn back to front
TOPC, LEFTC, RIGHTC = (176, 168, 156), (150, 140, 128), (98, 88, 98)
OUTC = (40, 32, 34)
blocks = []
for _ in range(90):
    gx = rng.uniform(-0.95, 0.95)
    x = AX + gx * (HALF - 4)
    hgt = 16 * (1 - gx * gx) ** 0.8
    lift = rng.uniform(0, hgt)
    y = base_y(x) + 4 - lift
    blocks.append((y, x, rng.choice((2, 3, 3, 4))))
blocks.sort()
for y, x, s_ in blocks:
    x, y = int(x), int(y)
    # top face: a small diamond; sides below it
    for dy in range(-s_ // 2, s_ // 2 + 1):
        half = s_ - abs(dy) * 2
        for dx in range(-half, half + 1):
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < w:
                ru[yy, xx, :3] = TOPC; ru[yy, xx, 3] = 255
    for dz in range(1, s_ + 1):
        for dx in range(-s_, s_ + 1):
            yy = y + s_ // 2 + dz - (abs(dx) // 2)
            xx = x + dx
            if 0 <= yy < h and 0 <= xx < w:
                ru[yy, xx, :3] = LEFTC if dx < 0 else RIGHTC; ru[yy, xx, 3] = 255
    # outline this block against what is behind it
    for dy in range(-s_ // 2 - 1, s_ + s_ // 2 + 2):
        for dx in (-s_ - 1, s_ + 1):
            yy, xx = y + dy - (abs(dx) // 2 if dy > s_ // 2 else 0), x + dx
            if 0 <= yy < h and 0 <= xx < w and ru[yy, xx, 3] > 0:
                ru[yy, xx, :3] = OUTC
# dark outline round the ruins' silhouette, like every sprite
al = ru[..., 3] > 0
p = np.pad(al, 1)
edge = al & ~(p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:])
ru[edge, :3] = (ru[edge, :3] * 0.4 + np.array([34, 26, 24]) * 0.6).astype(np.uint8)
Image.fromarray(ru, "RGBA").save(D + "ruins.png")

sheet = [Image.open(D + n + ".png") for n in ("intact", "damaged", "ruins")]
s = Image.new("RGBA", (w * 3 + 16, h), (96, 92, 82, 255))
for i, im in enumerate(sheet):
    s.alpha_composite(im, (i * (w + 8), 0))
s.resize((s.width * 3, s.height * 3), Image.NEAREST).save(S + "bell_states.png")
print("openings framed", len(openings))
