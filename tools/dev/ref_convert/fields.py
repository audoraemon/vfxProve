"""The farm fields outside the walls, drawn clean (no AI) on the game's own iso geometry after the reference sheet's
fenced crop tiles (TownMap_Component3 row 5: the wheat field, 2nd, and the vegetable rows, 3rd):

  field_0, field_0_2  wheat (FARM_FIELD / farm, crop 0): straight rows of standing ears (a 3 px head on a stalk) on an
                      even lattice, in five gold tones from the sheet's wheat; field_0 rows run along ground x, field_0_2
                      along ground y. Idle: a sway, 4 frames at FPS: the ears' heads shift 1 px sideways in a wave that
                      travels across the rows (the stalks' feet, the soil and the fences stay still).
  field_1, field_1_2  cabbages (crop 1): rows of round heads (two drawn stamps, five greens from the sheet's vegetable
                      rows, light from the left) on raised ridges with dark furrows between; rows along x / along y.
                      A still: cabbages do not sway.

Each lies on its footprint (FOOT, a little between the plots' 5 x 3.5 and 5 x 3.4) as the procedural field does
(PropArt._field): a soil bed raised HEIGHT px inside a post-and-rail fence on all four sides (the sheet's round posts
with a cut top and two rails, in the approved dock's four wood tones), a strip of the town's grass between fence and
bed, and a gate gap in the middle of the near-left fence, where the farmers' field points are (TownLayout "field"
points: below each field's near-left edge). The fences are low (FENCE_H px, the procedural ones 12): a field is flat
(z -1, under the people who walk in it), so its near fence draws under a farmer crossing it, as the procedural one does.

States: intact; damaged (two trampled patches where the crop lies flat, one scorched patch of burnt stubs on charred
soil, a fence span broken with a rail fallen across it, a far post snapped); ruins (charred soil, the rows burnt to
short stubble or charred stumps, the fences down to stumps with a few rails lying along their lines; clean, no rubble).

The sheet draws at about 2.5:1; a 5 x 3.5 field is ~270 px wide at 2:1. Cutting it whole does not fit, and its
textures read as noise at this size (the dock review), so everything is drawn: only the tones come from the sheet, muted
toward the town's (SAT, VAL; the greens pulled toward the town's leaf greens).

Usage (from anywhere):
  python tools/dev/ref_convert/fields.py [all | <name> ...] [--out DIR] [--debug DIR]
"""
import argparse
import functools
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bridges  # noqa: E402
import convert  # noqa: E402
import warehouse  # noqa: E402

ROOT = convert.ROOT
B = convert.B
C3 = bridges.C3
Canvas = bridges.Canvas

FOOT = (5.0, 3.45)            # ground units: the plots are 5 x 3.5 (north, east) and 5 x 3.4 (south)
HEIGHT = 3.0                  # the bed's top above the ground (px): Structure height 3, as PropArt._field's soil box
FENCE_IN = 0.07               # the fence line in from the footprint's edge (units)
BED_IN = 0.2                  # the bed's edge in from the footprint's edge (units)
FENCE_H = 10                  # post height (px)
RAILS = (3, 7)                # each rail's lower edge above the ground (px); rails are 2 px
POST_STEP = 0.5               # about this far apart (units)
GATE = (2.2, 2.8)             # the gap in the near-left fence (gy = D), along x (units)
FRAMES, FPS = 4, 3
WAVE = (0, 1, 0, -1)          # a head's sideways shift (px) at phase (frame - row) mod 4
PAD = 4
LEAN = 0.08                   # the crop lattice's shift toward the front corner (units)

SAT, VAL = 0.78, 0.9          # the sheet's tones toward the town's (soil, wood)
WHEAT_VAL = 0.95              # the wheat a little brighter: the town's procedural wheat is a bright gold
GREEN_PULL = 0.45             # cabbage greens toward the town's leaf greens (ArtKit.LEAF / OAK)
SOIL_PULL = 0.55              # bed soil toward the town's soil (ArtKit.SOIL)
TOWN_LEAF = [(23, 38, 22), (44, 74, 46), (61, 94, 34), (95, 138, 42), (143, 176, 58)]
TOWN_SOIL = [(76, 56, 38), (90, 67, 44), (110, 82, 54), (128, 98, 64)]
GRASS = [(122, 157, 67), (108, 143, 60), (94, 128, 54)]          # TownFloor.GRASS[1..3]
CHAR = [(46, 37, 31), (62, 50, 40), (78, 63, 49)]       # burnt soil, darkest first
DRY = [(104, 100, 58), (90, 86, 50)]                       # the grass strip, scorched dry
STUBBLE = [(92, 74, 46), (126, 102, 62), (150, 124, 78)]

# Wheat: ears every EAR along a row, rows ROW apart (units): pixel steps (2, 1) and (-6, 3): rows
# 6 px apart on screen, so each shows its heads over a dark line of the row behind's stalk feet.
EAR, ROW = 0.0625, 0.1875
STALK = 3                     # stalk rows under the head (px)
HEAD_SHADE = (0, 1, 0, -1, 0, 1, -1, 0, 0, -1, 1, 0)   # a head's tone step along its row: a fixed pattern, no noise
# Cabbages: heads every CAB along a row, rows CROW apart.
CAB, CROW = 0.25, 0.4375
CAB_SEQ = (0, 1, 0, 0, 1, 0, 1, 1, 0)                     # which stamp, along a row
CAB_TONE = (0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0)         # 1: a yellower head

# Damaged: (cx, cy, rx, ry) in units of the footprint, in the field's own (row-along, row-across) frame.
TRAMPLED = ((1.3, 1.1, 0.55, 0.38), (3.6, 2.35, 0.45, 0.35))
SCORCHED = ((3.2, 0.9, 0.6, 0.42),)
BROKEN_SPAN = 2               # the span (post k to k + 1) past the gate on the near-left fence that is broken
SNAPPED_POST = 3              # the far fence (gy = 0) post that is snapped


def _mute(c, sat=SAT, val=VAL):
    c = np.array(c, float)
    g = c.mean()
    return np.clip((g + (c - g) * sat) * val, 0, 255)


def _tones(box, mask_fn, k):
    """k tones of the sheet pixels in box passing mask_fn, darkest first: the means of their lightness bands."""
    a = bridges.load(C3)
    x0, y0, x1, y1 = box
    reg = a[y0:y1, x0:x1]
    m = (reg[..., 3] > 200) & mask_fn(reg[..., 0], reg[..., 1], reg[..., 2])
    px = reg[m][:, :3]
    lum = px @ np.array([0.3, 0.59, 0.11])
    bins = np.digitize(lum, np.percentile(lum, np.linspace(0, 100, k + 1)[1:-1]))
    return [px[bins == i].mean(0) for i in range(k)]


@functools.lru_cache(None)
def palette():
    """The sheet's tones: wheat (5), cabbage greens (5), soil (4) and the dock's wood (4), darkest first."""
    wheat = [_mute(c, SAT, WHEAT_VAL) for c in _tones((240, 800, 400, 930), lambda r, g, b: (r > 120) & (r > b + 60) & (g > 70), 5)]
    veg = (440, 800, 610, 930)
    greens = _tones(veg, lambda r, g, b: (g > r) & (g > b + 10) & (g < 140) & (r < 90), 5)
    greens = [_mute(np.array(c) * (1 - GREEN_PULL) + np.array(t) * GREEN_PULL, 0.85, 1.0)
              for c, t in zip(greens, TOWN_LEAF)]
    soil = _tones(veg, lambda r, g, b: (r > g + 15) & (g > b + 10) & (r < 200) & (r > 90), 4)
    soil = [_mute(np.array(c) * (1 - SOIL_PULL) + np.array(t) * SOIL_PULL, 0.7, 0.92) for c, t in zip(soil, TOWN_SOIL)]
    wood = [np.array(c, float) for c in bridges.dock_tones()]
    return {"wheat": wheat, "green": greens, "soil": soil, "wood": wood}


# --- geometry ---------------------------------------------------------------------------------------------------------
class Field:
    """One field's canvas: footprint W x D, the bed HEIGHT px up. `along_x`: its rows run along ground x."""

    def __init__(self, along_x):
        self.W, self.D = FOOT
        self.along_x = along_x
        W, D = FOOT
        A = (int(np.ceil(32 * W)) + PAD + 2, int(np.ceil(16 * (W + D))) + FENCE_H + 16 + PAD)
        self.cv = Canvas(int(A[0] + np.ceil(32 * D)) + PAD + 2, A[1] + 12 + PAD, A, W, D)
        self.A = A

    def g(self, u, v):
        """Ground point at u along the rows and v across them (units from the footprint's back corner)."""
        return (u, v) if self.along_x else (v, u)

    @property
    def span(self):
        """(length along the rows, width across them)."""
        return (self.W, self.D) if self.along_x else (self.D, self.W)

    def px(self, gx, gy, z):
        x, y = self.cv.pt(gx, gy, z)
        return int(np.floor(x)), int(np.floor(y))

    def put(self, i, j, rgb):
        h, w = self.cv.a.shape[:2]
        if 0 <= i < w and 0 <= j < h:
            self.cv.put(i, j, np.asarray(rgb, float))


def lattice(f, step_u, step_v):
    """The crop's points (u, v, row, k) on the bed, back to front (painter's order)."""
    L, Wd = f.span
    lo = BED_IN + 0.04 + LEAN / 2
    nu = int((L - 2 * lo) / step_u)
    nv = int((Wd - 2 * lo) / step_v)
    # centred, then LEAN toward the front: the crop stands up, so it would read set back from the near fence
    u0 = lo + (L - 2 * lo - nu * step_u) / 2 + step_u / 2 + LEAN
    v0 = lo + (Wd - 2 * lo - nv * step_v) / 2 + step_v / 2 + LEAN
    pts = [(u0 + k * step_u, v0 + r * step_v, r, k) for r in range(nv) for k in range(nu)]
    pts.sort(key=lambda p: (sum(f.g(p[0], p[1])), f.g(p[0], p[1])[0]))
    return pts


def in_patch(f, u, v, patches):
    for cx, cy, rx, ry in patches:
        L, Wd = f.span
        # patches are given on a 5 x 3.45 field along x; scale to this field's frame
        px, py = cx / 5.0 * L, cy / 3.45 * Wd
        if ((u - px) / rx) ** 2 + ((v - py) / ry) ** 2 <= 1.0:
            return True
    return False


# --- the bed, grass and fences ----------------------------------------------------------------------------------------
def bed(f, pal, state, furrows=False, bed_only=True):
    """The grass strip inside the fence, then the soil bed raised HEIGHT px (lit left face, shaded right face)."""
    W, D = f.W, f.D
    s = pal["soil"]
    cv = f.cv

    def grass(gx, gy):
        x, y = f.px(gx, gy, 0)
        if state == "ruins":
            return np.array(DRY[1] if (x + 2 * y) % 5 else DRY[0], float)
        return np.array(GRASS[0] if (x + 2 * y) % 7 == 0 else GRASS[1] if (x * 3 + y) % 5 == 0 else GRASS[2], float)

    if not bed_only:
        cv.top(0.0, 0.0, W, D, 0.0, grass)
        return
    b0x, b0y, b1x, b1y = BED_IN, BED_IN, W - BED_IN, D - BED_IN

    def top(gx, gy):
        u, v = (gx, gy) if f.along_x else (gy, gx)
        scorched = state == "damaged" and in_patch(f, u, v, SCORCHED)
        if state == "ruins" or scorched:
            base = CHAR
            fr = ((v - BED_IN - 0.04 - LEAN / 2) / (CROW if furrows else ROW)) % 1.0
            if furrows:
                return np.array(base[2] if 0.3 < fr < 0.7 else base[0], float)
            return np.array(base[2] if 0.35 < fr < 0.65 else base[1], float)
        if furrows:
            fr = ((v - BED_IN - 0.04) / CROW) % 1.0
            if fr < 0.12 or fr > 0.88:
                return s[0]
            if 0.3 < fr < 0.7:
                return s[3] if 0.42 < fr < 0.58 else s[2]
            return s[1]
        return s[1]

    cv.top(b0x, b0y, b1x, b1y, HEIGHT, top)
    side = s if state != "ruins" else [np.array(c, float) for c in CHAR + [CHAR[2]]]
    cv.face_y(b1y, b0x, b1x, 0.0, HEIGHT, lambda g, z, i: side[2] if z >= HEIGHT - 1 else side[1])
    cv.face_x(b1x, b0y, b1y, 0.0, HEIGHT, lambda g, z, i: side[1] if z >= HEIGHT - 1 else side[0])


def posts_along(n0, n1):
    """Post positions from n0 to n1 (units), about POST_STEP apart."""
    k = max(int(round((n1 - n0) / POST_STEP)), 1)
    return [n0 + (n1 - n0) * i / k for i in range(k + 1)]


def post(f, gx, gy, top, wood, cut=False, lean=0):
    """A round post standing at ground point (gx, gy), `top` px tall: a 3 px shaft lit from the left (light, mid, dark)
    under a pale cut top; the outline comes from finish()."""
    x, y = f.px(gx, gy, 0)
    for j in range(top):
        dx = int(round(lean * j / max(top, 1)))
        f.put(x - 1 + dx, y - j, wood[3] if j < top - 1 else wood[3] * 1.12)
        f.put(x + dx, y - j, wood[2])
        f.put(x + 1 + dx, y - j, wood[1])
    dx = int(round(lean))
    cap = np.minimum(np.array(wood[3]) * (1.35 if cut else 1.22), 255)
    for i in (-1, 0, 1):
        f.put(x + i + dx, y - top, cap)


def rail_y(f, Y, x0, x1, z, wood, lit=True):
    """A 2 px rail on the plane gy = Y from gx x0 to x1, its lower edge z px up."""
    hi, lo = (wood[3], wood[2]) if lit else (wood[2], wood[1])
    f.cv.face_y(Y, x0, x1, z, z + 2, lambda g, zz, i: hi if zz >= z + 1 else lo)


def rail_x(f, X, y0, y1, z, wood, lit=False):
    hi, lo = (wood[3], wood[2]) if lit else (wood[2], wood[1])
    f.cv.face_x(X, y0, y1, z, z + 2, lambda g, zz, i: hi if zz >= z + 1 else lo)


def lying_rail(f, gx0, gy0, gx1, gy1, wood):
    """A rail lying on the ground along a fence line: a 2 px strip (lit top, shaded edge)."""
    p0 = np.array(f.cv.pt(gx0, gy0, 0)); p1 = np.array(f.cv.pt(gx1, gy1, 0))
    n = int(np.ceil(np.abs(p1 - p0).max())) + 1
    for t in np.linspace(0, 1, n):
        x, y = p0 + (p1 - p0) * t
        f.put(int(np.floor(x)), int(np.floor(y)) - 1, wood[3])
        f.put(int(np.floor(x)), int(np.floor(y)), wood[1])


def fallen_rail(f, a, b, wood):
    """A rail from screen point a down to b (px), 2 px thick."""
    a = np.array(a, float); b = np.array(b, float)
    n = int(np.ceil(np.abs(b - a).max())) + 1
    for t in np.linspace(0, 1, n):
        x, y = a + (b - a) * t
        f.put(int(np.floor(x)), int(np.floor(y)), wood[3])
        f.put(int(np.floor(x)), int(np.floor(y)) + 1, wood[1])


def fence(f, pal, state, near):
    """The far fences (near False: gy = FENCE_IN along x, gx = FENCE_IN along y) or the near ones (gy = D - FENCE_IN,
    the gate side, and gx = W - FENCE_IN)."""
    wood = pal["wood"]
    W, D, e = f.W, f.D, FENCE_IN
    if state == "ruins":
        for side in (("x", e), ("y", e)) if not near else (("x", D - e), ("y", W - e)):
            run = posts_along(e, W - e) if side[0] == "x" else posts_along(e, D - e)
            for k, p in enumerate(run):
                gx, gy = (p, side[1]) if side[0] == "x" else (side[1], p)
                if side[0] == "x" and near and GATE[0] - 0.05 < p < GATE[1] + 0.05:
                    continue
                post(f, gx, gy, 3 if k % 3 else 2, wood, cut=True)
            # a few rails lying along the line, clean
            for k in range(0, len(run) - 1, 3):
                a, b = run[k] + 0.04, run[k + 1] - 0.04
                if side[0] == "x":
                    lying_rail(f, a, side[1] + 0.06, b, side[1] + 0.06, wood)
                else:
                    lying_rail(f, side[1] + 0.06, a, side[1] + 0.06, b, wood)
        return
    if not near:
        # the far fence along x (gy = e) and along y (gx = e): rails behind, posts over them
        run = posts_along(e, W - e)
        for z in RAILS:
            for k in range(len(run) - 1):
                rail_y(f, e, run[k], run[k + 1], z, wood)
        for k, p in enumerate(run):
            snapped = state == "damaged" and k == SNAPPED_POST
            post(f, p, e, 4 if snapped else FENCE_H, wood, cut=snapped)
        run = posts_along(e, D - e)
        for z in RAILS:
            for k in range(len(run) - 1):
                rail_x(f, e, run[k], run[k + 1], z, wood)
        for p in run:
            post(f, e, p, FENCE_H, wood)
        return
    # near fences: along y at gx = W - e (shaded, right face), then along x at gy = D - e (lit, the gate side)
    run = posts_along(e, D - e)
    for p in run:
        post(f, W - e, p, FENCE_H, wood)
    for z in RAILS:
        for k in range(len(run) - 1):
            rail_x(f, W - e, run[k], run[k + 1], z, wood)
    # the gate side: two runs of posts, either side of the gate's gap, its posts a little taller
    for n, (a0, a1) in enumerate(((e, GATE[0]), (GATE[1], W - e))):
        run = posts_along(a0, a1)
        for p in run:
            post(f, p, D - e, FENCE_H + 2 if p in GATE else FENCE_H, wood)
        for k in range(len(run) - 1):
            a, b = run[k], run[k + 1]
            if state == "damaged" and n == 1 and k == BROKEN_SPAN:
                # rails gone; one hangs from the left post's upper rail down to the ground by the right post
                pa = f.cv.pt(a, D - e, RAILS[1] + 1)
                pb = f.cv.pt(b - 0.1, D - e, 0)
                fallen_rail(f, (pa[0] + 1, pa[1]), (pb[0], pb[1] - 1), wood)
                continue
            for z in RAILS:
                rail_y(f, D - e, a, b, z, wood)


# --- crops ------------------------------------------------------------------------------------------------------------
def wheat(f, pal, state, frame):
    """Rows of standing ears packed side by side (one every EAR, 2 px): each a 2 px head (lit left, shaded right) on a
    body of stalks; a row hides the one behind it but for its heads and a dark line of stalk feet."""
    t = pal["wheat"]
    pts = lattice(f, EAR, ROW)
    for u, v, r, k in pts:
        gx, gy = f.g(u, v)
        x, y = f.px(gx, gy, HEIGHT)
        sh = HEAD_SHADE[(k + 5 * r) % len(HEAD_SHADE)]
        tone = lambda i: t[int(np.clip(i + sh, 0, 4))]
        if state == "ruins":
            # burnt stubble: short stalks on the charred bed, every other ear, in rows
            if k % 2 == 0:
                f.put(x, y - 1, STUBBLE[1] if k % 4 else STUBBLE[2])
                f.put(x, y - 2, STUBBLE[0])
            continue
        if state == "damaged" and in_patch(f, u, v, SCORCHED):
            if k % 2 == 0:
                f.put(x, y - 1, CHAR[2])
                f.put(x, y - 2, CHAR[1] if k % 4 else CHAR[2])
            continue
        if state == "damaged" and in_patch(f, u, v, TRAMPLED):
            # flattened: the ears lie along the ground, heads one way (a fixed pattern)
            # flattened: a mat of straw lying along the row, filling the row's pitch (6 px), streaked
            for i in (0, 1):
                for j, c in enumerate((tone(2), tone(3), tone(2), t[1], tone(2), t[1])):
                    f.put(x + i, y - 3 + j, c)
            continue
        dx = WAVE[(frame - r) % 4] if state == "intact" else 0
        for j in range(STALK):             # the body: stalk feet in shadow
            sx = x + (dx if j == STALK - 1 else 0)
            f.put(sx, y - 1 - j, t[0] if j == 0 else t[1])
            f.put(sx + 1, y - 1 - j, t[0])
        hy = y - 1 - STALK                 # the head's lowest row
        hx = x + dx
        f.put(hx, hy, tone(2)); f.put(hx + 1, hy, tone(1))
        f.put(hx, hy - 1, tone(3)); f.put(hx + 1, hy - 1, tone(2))
        f.put(hx, hy - 2, tone(4)); f.put(hx + 1, hy - 2, tone(2))
        f.put(hx + (k % 2), hy - 3, tone(3))


# Cabbage stamps (light from the left): o outline, D dark, M mid, L light, H highlight. Anchored at the bottom middle.
CABBAGES = [
    ["..ooooo..",
     ".oLLLMMo.",
     "oLHHLMMDo",
     "oLHLLMDDo",
     "oLLMMMDDo",
     "oMMMMDDDo",
     ".oDDDDDo.",
     "..ooooo.."],
    ["..ooo..",
     ".oLLMo.",
     "oLHLMDo",
     "oLLMMDo",
     "oMMMDDo",
     ".oDDDo.",
     "..ooo.."],
]


def cabbages(f, pal, state):
    gr = pal["green"]
    pts = lattice(f, CAB, CROW)
    for u, v, r, k in pts:
        gx, gy = f.g(u, v)
        x, y = f.px(gx, gy, HEIGHT)
        if state == "ruins" or (state == "damaged" and in_patch(f, u, v, SCORCHED)):
            # a charred stump in the row
            for i in (-1, 0, 1):
                f.put(x + i, y - 1, CHAR[0] if i else CHAR[1])
            f.put(x, y - 2, CHAR[1] if state == "ruins" else CHAR[0])
            continue
        if state == "damaged" and in_patch(f, u, v, TRAMPLED):
            # crushed flat: a low smear of leaf
            for i in range(-3, 4):
                f.put(x + i, y - 1, gr[1] if abs(i) < 3 else gr[0])
            for i in (-1, 0, 1):
                f.put(x + i, y - 2, gr[2])
            continue
        st = CABBAGES[CAB_SEQ[(k + 4 * r) % len(CAB_SEQ)]]
        yellow = CAB_TONE[(k * 3 + r * 5) % len(CAB_TONE)]
        cmap = {"o": gr[0], "D": gr[1], "M": gr[2], "L": gr[3], "H": gr[4]}
        if yellow:
            cmap = {c: np.minimum(np.array(v) * np.array([1.18, 1.05, 0.8]), 255) for c, v in cmap.items()}
        h, w = len(st), len(st[0])
        for j, row in enumerate(st):
            for i, ch in enumerate(row):
                if ch != ".":
                    f.put(x - w // 2 + i, y - h + j, cmap[ch])


# --- a set --------------------------------------------------------------------------------------------------------------
def draw(crop, along_x, state, frame=0):
    pal = palette()
    f = Field(along_x)
    bed(f, pal, state, bed_only=False)
    fence(f, pal, state, near=False)
    bed(f, pal, state, furrows=crop == 1)
    if crop == 0:
        wheat(f, pal, state, frame)
    else:
        cabbages(f, pal, state)
    fence(f, pal, state, near=True)
    return f.cv.a, f.A


SETS = {
    # name: crop, rows along x, seed
    "field_0": (0, True, 71),
    "field_0_2": (0, False, 72),
    "field_1": (1, True, 73),
    "field_1_2": (1, False, 74),
}


def make(name, out_dir, debug=None):
    crop, along_x, seed = SETS[name]
    frames = FRAMES if crop == 0 else 1
    views = []
    A = None
    for fr in range(frames):
        img, A = draw(crop, along_x, "intact", fr)
        views.append(img)
    damaged, _ = draw(crop, along_x, "damaged")
    rn, _ = draw(crop, along_x, "ruins")
    al = np.zeros(views[0].shape[:2], bool)
    for v in views + [damaged, rn]:
        al |= v[..., 3] > 0
    ys, xs = np.nonzero(al)
    y0, x0, x1 = ys.min() - PAD, xs.min() - PAD, xs.max() + 1 + PAD
    y1 = max(ys.max() + 1 + PAD, A[1] + 11)
    cut = lambda v: v[y0:y1, x0:x1]
    A = (int(A[0] - x0), int(A[1] - y0))
    done = bridges.finish([cut(v) for v in views] + [cut(damaged), cut(rn)], None)
    stills = {"intact": done[0], "damaged": done[frames], "ruins": done[frames + 1]}
    d = out_dir / name
    d.mkdir(parents=True, exist_ok=True)
    for st, img in stills.items():
        Image.fromarray(img, "RGBA").save(d / (st + ".png"))
    idle = None
    if frames > 1:
        idle = np.concatenate(done[:frames], 1)
        Image.fromarray(idle, "RGBA").save(d / "idle.png")
    elif (d / "idle.png").exists():
        (d / "idle.png").unlink()
    h, w = done[0].shape[:2]
    corners = warehouse.corner_errors(done[0].astype(float), A, FOOT)
    moved = [int(np.any(done[i] != done[0], axis=2).sum()) for i in range(frames)]
    print(name, "size", [w, h], "anchor", list(A), "frames", frames, "idle", None if idle is None else list(idle.shape[1::-1]),
          "px moved per frame", moved, "base corners off by", corners)
    if debug:
        debug.mkdir(parents=True, exist_ok=True)
        sheet = np.zeros((h, w * 3 + 20, 4))
        for i, st in enumerate(("intact", "damaged", "ruins")):
            sheet[:, i * (w + 10):i * (w + 10) + w] = stills[st]
        warehouse._dbg(sheet, debug / (name + "_states.png"), 2)
        warehouse._dbg(done[0].astype(float), debug / (name + "_intact_3x.png"), 3)
        if idle is not None:
            warehouse._dbg(idle.astype(float), debug / (name + "_idle.png"), 2)
    entry = {"size": [w, h], "footprint": list(FOOT), "anchor": list(A), "height": int(HEIGHT), "seed": seed,
             "kind": "FARM_FIELD", "role": "farm", "tag": ""}
    if frames > 1:
        entry.update({"frames": frames, "fps": FPS})
    return entry


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", help="write the sets here instead of assets/pixellab/buildings (no manifest change)")
    p.add_argument("--debug", help="write stage pictures here")
    args = p.parse_args()
    dbg = Path(args.debug) if args.debug else None
    for n in (list(SETS) if args.what == ["all"] else args.what):
        entry = make(n, Path(args.out) if args.out else B, dbg)
        if not args.out:
            convert.write_manifest(B / "manifest.json", n, entry)
            print("manifest updated:", n)
