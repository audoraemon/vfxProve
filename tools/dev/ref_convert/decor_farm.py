"""Farm decor sets (decor batch 4), drawn clean (no AI) in the style of the batch 3 farm fields (fields.py): the same
round posts (a 3 px shaft lit from the left under a pale cut top), 2 px rails, the approved dock's four wood tones
(bridges.dock_tones) and the same 1 px outline (bridges.outline), so a pasture fence and a field fence side by side
read as one fence.

  fence_x    Decor.Kind.FENCE along ground x (down-right on screen): one post and its two rails to the next post,
  fence_y    POST_STEP (0.5) units: the batch 3 field fence's post spacing; segment 0.5. 14 px posts as the
             procedural fence (DecorArt._fence(.., 14.0)), rails 2 px with their lower edges 4 and 9 px up (the
             procedural rails sit at 0.35 and 0.72 of the post). fence_x shows the rails' lit face; fence_y (along
             ground y, down-left) their shaded face, as the field's near fences do. Each tile is the middle span of a
             three-span strip drawn and outlined whole, so tiles meet without seams. Anchored at the post's foot: the
             post is a tile's first column (fence_x) or its last (fence_y). "end_post" is that post's rect: the run's
             closing post, drawn at its far end.
  garden_1   Decor.Kind.GARDEN: a house garden, one still per plot size (TownLayout.gardens: 1 x 0.45, 0.95 x 0.45,
  ..         0.45 x 1, 0.45 x 0.95 units; "footprint" in the manifest, DecorSprites picks the nearest): a soil bed
  garden_4   raised 2 px (the field's soil tones, lit left face, shaded right face, a furrow between its rows), two
             rows of plants along its long side (5 a row, as DecorArt._garden's 0.18 grid: round cabbages and leafy
             sprigs, some flowering, in a fixed order, in the field's cabbage greens), inside a low fence on all four
             sides (8 px, a px under the procedural garden's 9, rails 1 and 5 px up, so the plants stand over the near
             one). Anchored at the plot's back corner (the decor's `at`).
  scarecrow  Decor.Kind.SCARECROW: DecorArt._scarecrow's figure (a post, a patched shirt with straw hands on a cross
             bar, trousers, a straw head with button eyes, a wide-brimmed hat) as a pixel map, light from the left,
             ringed with the outline. Anchored at the post's foot. A 4-frame strip at 4 fps (Group C): the shirt's
             hem and the sleeves' hanging edges flutter, each column's bottom row a px longer or shorter in a ripple
             that runs left to right with the wind (frame 0 the still: no ripple).

Usage (from anywhere):
  python tools/dev/ref_convert/decor_farm.py [all | fence | garden | scarecrow] [--out <scratch dir>]
      (--out: write PNGs there, no manifest)
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bridges  # noqa: E402
import convert  # noqa: E402
import decor_common  # noqa: E402
import fields  # noqa: E402

OUTLINE = tuple(int(v) for v in convert.OUTLINE)

# Fence: the field fence's post spacing, the procedural pasture fence's height.
SEG = fields.POST_STEP            # 0.5 units: a tile is one post and its span
FENCE_H = 14                      # DecorArt._fence(.., 14.0)
FENCE_RAILS = (4, 9)              # rail lower edges (px); 2 px rails
SPAN_PX = int(32 * SEG)           # a span's screen width (16 px)

# Garden: the procedural garden's low fence and plant grid.
GARDEN_SIZES = ((1.0, 0.45), (0.95, 0.45), (0.45, 1.0), (0.45, 0.95))
GARDEN_H = 8                      # a little under DecorArt._garden's 9 px fences, so the plants show over the near one
GARDEN_RAILS = (1, 5)
GARDEN_IN = 0.03                  # the fence line in from the plot's edge (units)
BED_IN = 0.07                     # the bed's edge in from the plot's edge (units)
BED_H = 2                         # the bed's raise (px)
PLANT_STEP = 0.18                 # DecorArt._garden's grid step: plants along a row
ROWS = 2
# Plant stamps (light from the left): o outline (dark green), D dark, M mid, L light, H highlight, F flower. Bottom
# row on the bed; they stand 7 px, over the near fence's top rail.
PLANTS = [
    ["..o..",
     ".oLo.",
     "oLHMo",
     "oHLMo",
     "oLMDo",
     "oMDDo",
     ".ooo."],
    [".F.F.",
     "oFoFo",
     "oLoMo",
     "oLoDo",
     "oLLMo",
     "oMMDo",
     ".ooo."],
]
PLANT_SEQ = (0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1)   # which stamp, along the rows (a fixed pattern)
FLOWER_SEQ = (0, 1, 2, 1, 0, 2, 2)               # which flower colour, per sprig
# TownFloor.FLOWERS (cream, yellow, pink), muted under check_sprite_glow's glow rule.
FLOWERS = ((236, 230, 210), (222, 192, 78), (214, 118, 150))

# Scarecrow colours: DecorArt.CLOTH (shirt), its patch, the trousers, DecorArt.STRAW and the eyes.
CLOTH = ((166, 92, 72), (138, 74, 58), (104, 56, 44))
PATCH = ((206, 160, 96), (192, 144, 80))
TROUSERS = ((84, 100, 134), (74, 90, 120), (62, 76, 104))
STRAW = ((232, 206, 124), (216, 184, 96), (176, 146, 70))
EYE = (42, 28, 20)
SCARECROW_FPS = 4.0


def ripple(i, f):
    """A cloth column's hem change in frame f (rows: +1 longer, -1 shorter, 0 none): a wave of period 4 columns
    running right a column a frame, less its frame 0 shape, so frame 0 is the still and frame 4 frame 0."""
    w = (0, 1, 0, -1)
    return max(-1, min(1, w[(i - f) % 4] - w[i % 4]))


class Strip:
    """A canvas fields.post / rail_x / rail_y draw on (they take a Field: .cv, .px, .put)."""

    def __init__(self, w, h, A, W=0.0, D=0.0):
        self.cv = bridges.Canvas(w, h, A, W, D)

    def px(self, gx, gy, z):
        x, y = self.cv.pt(gx, gy, z)
        return int(np.floor(x)), int(np.floor(y))

    def put(self, i, j, rgb):
        h, w = self.cv.a.shape[:2]
        if 0 <= i < w and 0 <= j < h:
            self.cv.put(i, j, np.asarray(rgb, float))


def wood():
    return fields.palette()["wood"]


# --- fences -------------------------------------------------------------------------------------------------------------
def fence(along_x):
    """One tile: the middle span of a three-span strip (posts at 0, 0.5, 1, 1.5 units), drawn and outlined whole."""
    wd = wood()
    A = (10, 30) if along_x else (60, 30)
    f = Strip(70, 50, A)
    posts = [SEG * k for k in range(4)]
    for z in FENCE_RAILS:
        for k in range(3):
            if along_x:
                fields.rail_y(f, 0.0, posts[k], posts[k + 1], z, wd, lit=True)
            else:
                fields.rail_x(f, 0.0, posts[k], posts[k + 1], z, wd, lit=False)
    for p in posts:
        fields.post(f, p, 0.0, FENCE_H, wd) if along_x else fields.post(f, 0.0, p, FENCE_H, wd)
    a = bridges.outline(f.cv.a.copy())
    px, py = f.px(SEG, 0.0, 0) if along_x else f.px(0.0, SEG, 0)
    x0 = px - 1 if along_x else px - (SPAN_PX - 2)
    tile = a[:, x0:x0 + SPAN_PX]
    ys = np.nonzero(tile[..., 3].any(axis=1))[0]
    y0, y1 = ys.min(), ys.max() + 1
    tile = tile[y0:y1]
    anchor = (px - x0, py - y0)
    top = py - FENCE_H - y0                      # the cap's row
    end_post = (anchor[0] - 1, top, 3, anchor[1] - top + 1)
    img = Image.fromarray(np.clip(tile, 0, 255).astype(np.uint8), "RGBA")
    return img, anchor, end_post


# --- gardens ------------------------------------------------------------------------------------------------------------
def garden(W, D):
    """A plot W x D units: its far fences, the raised bed, its plants back to front, its near fences."""
    wd = wood()
    pal = fields.palette()
    soil, gr = pal["soil"], pal["green"]
    A = (int(np.ceil(32 * W)) + 6, int(np.ceil(16 * (W + D))) + GARDEN_H + 8)
    f = Strip(int(A[0] + np.ceil(32 * D)) + 8, A[1] + 6, A, W, D)
    cv = f.cv
    e = GARDEN_IN
    along_x = W >= D
    L, Wd = (W, D) if along_x else (D, W)

    def g(u, v):
        return (u, v) if along_x else (v, u)

    # far fences: along x at gy = e, along y at gx = e; rails behind, posts over them
    run = fields.posts_along(e, W - e)
    for z in GARDEN_RAILS:
        for k in range(len(run) - 1):
            fields.rail_y(f, e, run[k], run[k + 1], z, wd)
    for p in run:
        fields.post(f, p, e, GARDEN_H, wd)
    run = fields.posts_along(e, D - e)
    for z in GARDEN_RAILS:
        for k in range(len(run) - 1):
            fields.rail_x(f, e, run[k], run[k + 1], z, wd)
    for p in run:
        fields.post(f, e, p, GARDEN_H, wd)

    # the bed: a flat top with one dark furrow between the two rows, a lit left face, a shaded right face
    b0, b1x, b1y = BED_IN, W - BED_IN, D - BED_IN

    def top(gx, gy):
        u, v = (gx, gy) if along_x else (gy, gx)
        return soil[0] if abs(v - Wd / 2) < 0.02 else soil[1]

    cv.top(b0, b0, b1x, b1y, BED_H, top)
    cv.face_y(b1y, b0, b1x, 0.0, BED_H, lambda gx, z, i: soil[2] if z >= BED_H - 1 else soil[1])
    cv.face_x(b1x, b0, b1y, 0.0, BED_H, lambda gy, z, i: soil[1] if z >= BED_H - 1 else soil[0])

    # plants: ROWS rows along the long side, as many a row as DecorArt._garden's grid holds
    n = max(int(L / PLANT_STEP), 1)
    pts = []
    for r in range(ROWS):
        for k in range(n):
            u = (k + 0.5) * L / n
            v = BED_IN + (r + 0.5) * (Wd - 2 * BED_IN) / ROWS
            pts.append((g(u, v), r * n + k))
    pts.sort(key=lambda p: (p[0][0] + p[0][1], p[0][0]))
    sprig = 0
    for (gx, gy), i in pts:
        st = PLANTS[PLANT_SEQ[i % len(PLANT_SEQ)]]
        cmap = {"o": gr[1], "D": gr[2], "M": gr[3], "L": gr[4], "H": np.minimum(np.array(gr[4]) * 1.22 + 8, 255)}
        if "F" in "".join(st):
            cmap["F"] = FLOWERS[FLOWER_SEQ[sprig % len(FLOWER_SEQ)]]
            sprig += 1
        x, y = f.px(gx, gy, BED_H)
        h, w = len(st), len(st[0])
        for j, row in enumerate(st):
            for c, ch in enumerate(row):
                if ch != ".":
                    f.put(x - w // 2 + c, y - h + j + 1, cmap[ch])

    # near fences: along y at gx = W - e (shaded), then along x at gy = D - e (lit), as the field's
    run = fields.posts_along(e, D - e)
    for p in run:
        fields.post(f, W - e, p, GARDEN_H, wd)
    for z in GARDEN_RAILS:
        for k in range(len(run) - 1):
            fields.rail_x(f, W - e, run[k], run[k + 1], z, wd)
    run = fields.posts_along(e, W - e)
    for p in run:
        fields.post(f, p, D - e, GARDEN_H, wd)
    for z in GARDEN_RAILS:
        for k in range(len(run) - 1):
            fields.rail_y(f, D - e, run[k], run[k + 1], z, wd)

    a = bridges.outline(cv.a.copy())
    ys, xs = np.nonzero(a[..., 3] > 0)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    back = f.px(0.0, 0.0, 0)
    img = Image.fromarray(np.clip(a[y0:y1, x0:x1], 0, 255).astype(np.uint8), "RGBA")
    return img, (back[0] - x0, back[1] - y0)


# --- scarecrow ----------------------------------------------------------------------------------------------------------
def scarecrow(frame=0):
    """DecorArt._scarecrow in its own coordinates (x right of the ground point, y up from it, negative), light from
    the left, ringed with the outline; `frame` 0..3 of its flutter."""
    wd = [tuple(int(v) for v in c) for c in wood()]
    W, H, cx, gy = 27, 36, 13, 35
    rgb = np.zeros((H + 2, W + 2, 3))
    al = np.zeros((H + 2, W + 2), bool)

    def px(x, y, c):
        """Procedural coordinates: x right of the post, y up from the ground (negative)."""
        i, j = cx + x + 1, gy + y + 1
        rgb[j, i] = c
        al[j, i] = True

    def rect(x0, y0, w, h, fn):
        for yy in range(y0, y0 + h):
            for xx in range(x0, x0 + w):
                px(xx, yy, fn(xx - x0, yy - y0))

    # the post (2 px, lit left), up through the figure to the hat
    rect(-1, -30, 2, 30, lambda i, j: wd[3] if i == 0 else wd[1])
    # the cross bar's ends, past the hands
    rect(-13, -22, 1, 2, lambda i, j: wd[3] if j == 0 else wd[1])
    rect(12, -22, 1, 2, lambda i, j: wd[2] if j == 0 else wd[0])
    # the shirt: lit left columns, shaded right, a hem row; a patch on its right side. Each column runs down to its
    # hem, which the flutter moves a row (a shorter column leaves the post or the belt showing under it).
    def cloth(x0, y0, w, h, fn, ripple_at):
        for i in range(w):
            r = ripple(ripple_at + i, frame)
            for j in range(h + min(r, 0)):
                px(x0 + i, y0 + j, fn(i, j, j == h - 1 + min(r, 0)))

    def hem_drops(x0, y0, w, h, fn, ripple_at):
        """The rows a longer column hangs below its hem (after what it hangs over)."""
        for i in range(w):
            if ripple(ripple_at + i, frame) > 0:
                px(x0 + i, y0 + h, fn(i, h, True))

    def shirt(i, j, hem):
        return CLOTH[2] if hem else CLOTH[0] if i < 2 else CLOTH[2] if i > 8 else CLOTH[1]

    def sleeve_l(i, j, hem):
        return CLOTH[0] if j == 0 else CLOTH[1] if j == 1 and not hem else CLOTH[2]

    def sleeve_r(i, j, hem):
        return CLOTH[1] if j == 0 else CLOTH[2]
    cloth(-5, -23, 11, 10, shirt, 4)
    rect(1, -20, 3, 3, lambda i, j: PATCH[0] if (i, j) == (0, 0) else PATCH[1])
    px(-1, -21, CLOTH[2]); px(-1, -18, CLOTH[2]); px(-1, -15, CLOTH[2])      # buttons down the post's line
    # sleeves: 4 px each side, rows -23..-21
    cloth(-9, -23, 4, 3, sleeve_l, 0)
    cloth(6, -23, 4, 3, sleeve_r, 15)
    # straw hands, frayed below
    rect(-12, -23, 3, 3, lambda i, j: STRAW[0] if j == 0 else STRAW[1])
    rect(10, -23, 3, 3, lambda i, j: STRAW[1] if j == 0 else STRAW[2])
    px(-12, -20, STRAW[1]); px(-10, -20, STRAW[2]); px(10, -20, STRAW[2]); px(12, -20, STRAW[2])
    # a straw belt, then the trousers: two legs either side of the post, lit left
    rect(-5, -13, 11, 1, lambda i, j: STRAW[1] if i < 6 else STRAW[2])
    hem_drops(-5, -23, 11, 10, shirt, 4)
    hem_drops(-9, -23, 4, 3, sleeve_l, 0)
    hem_drops(6, -23, 4, 3, sleeve_r, 15)
    rect(-4, -12, 3, 6, lambda i, j: TROUSERS[0] if i == 0 else TROUSERS[1])
    rect(2, -12, 3, 6, lambda i, j: TROUSERS[1] if i == 0 else TROUSERS[2])
    # straw poking from the cuffs
    rect(-4, -6, 3, 1, lambda i, j: STRAW[1]); px(-3, -5, STRAW[2])
    rect(2, -6, 3, 1, lambda i, j: STRAW[2]); px(3, -5, STRAW[2])
    # the head: a straw ball, lit left, two button eyes and a stitched mouth
    for yy in range(-30, -23):
        for xx in range(-3, 4):
            if (xx * 2 / 7.0) ** 2 + ((yy + 26.5) * 2 / 7.0) ** 2 <= 1.05:
                px(xx, yy, STRAW[0] if xx < -1 else STRAW[2] if xx > 1 else STRAW[1])
    px(-1, -28, EYE); px(1, -28, EYE)
    px(-1, -25, STRAW[2]); px(0, -25, STRAW[2]); px(1, -25, STRAW[2])
    # the hat: a wide brim (lit top, dark underside) and a crown, a cloth band
    rect(-7, -31, 15, 1, lambda i, j: wd[2] if i < 9 else wd[1])
    rect(-6, -30, 13, 1, lambda i, j: wd[1] if i < 9 else wd[0])
    rect(-4, -35, 9, 4, lambda i, j: (wd[3] if i < 2 else wd[1] if i > 6 else wd[2]) if j < 3 else CLOTH[1])
    rect(-3, -36, 7, 1, lambda i, j: wd[3])
    # the outline ring (4-neighbours)
    p = np.pad(al, 1)
    ring = ~al & (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:])
    rgb[ring] = OUTLINE
    alpha = al | ring
    ys, xs = np.nonzero(alpha)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    out = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
    out[..., :3] = np.round(rgb[y0:y1, x0:x1]).astype(np.uint8)
    out[..., 3] = np.where(alpha[y0:y1, x0:x1], 255, 0)
    # anchor: the ground point between the post's two columns (x 0 is its dark column), the post's foot row
    return Image.fromarray(out, "RGBA"), (cx + 1 - x0, gy + 1 - y0)


def _fence_sets():
    out = []
    for name, ax in (("fence_x", True), ("fence_y", False)):
        img, anchor, post = fence(ax)
        out.append((name, img, anchor, {"segment": SEG, "end_post": post}))
    return out


def _garden_sets():
    out = []
    for n, (W, D) in enumerate(GARDEN_SIZES, 1):
        img, anchor = garden(W, D)
        out.append(("garden_%d" % n, img, anchor, {"footprint": (W, D)}))
    return out


SETS = {
    "fence": _fence_sets,
    "garden": _garden_sets,
    "scarecrow": lambda: [("scarecrow",) + decor_common.strip([scarecrow(k) for k in range(4)])
                          + ({"frames": 4, "fps": SCARECROW_FPS},)],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("which", nargs="?", default="all", choices=["all"] + list(SETS))
    ap.add_argument("--out")
    args = ap.parse_args()
    for key in SETS if args.which == "all" else [args.which]:
        for name, img, anchor, extra in SETS[key]():
            if args.out:
                Path(args.out).mkdir(parents=True, exist_ok=True)
                path = Path(args.out) / (name + ".png")
                img.save(path)
            else:
                path = decor_common.write_set(name, img, anchor, **extra)
            print("%-10s %dx%d anchor %s %s -> %s" % (name, img.width, img.height, anchor, extra, path))


if __name__ == "__main__":
    main()
