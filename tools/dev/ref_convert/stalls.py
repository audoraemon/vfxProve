"""Market stalls from the reference sheet (concepts/TOWN REF/TownMap_Component2.png, rows 1-2): every stall design is
cut out, converted with convert.py at the stall plot (0.9 x 0.7), and finished with its states, all locally (no AI):

  stall_<n>                 intact, damaged, ruins, idle (4-frame awning ripple at 4 fps)
  stall_<n>_<red|blue|cream>   for the striped designs: the stripes recoloured (sprite_fix.py huemap) to the stall's
                            cloth (prop_art.gd CLOTH: c8342a/ece2c8, 2f5fb8/ece2c8, ece2c8/c0a070), same states

Usage (from anywhere):
  python tools/dev/ref_convert/stalls.py [all | cut | <n> ...] [--view <png>]
`cut` only writes the cut-out designs and a review sheet to the scratch dir; `all` (default) converts every design.
"""
import argparse
import json
import math
import random
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_fix  # noqa: E402

ROOT = convert.ROOT
B = convert.B
SHEET = ROOT / "concepts" / "TOWN REF" / "TownMap_Component2.png"
FP = (0.9, 0.7)
CLOTH = {"red": ((200, 52, 42), (236, 226, 200)), "blue": ((47, 95, 184), (236, 226, 200)),
         "cream": ((192, 160, 112), (236, 226, 200))}

# Design n: (scan box on the sheet, which piece when the box holds two stalls joined at a corner ("upper"/"lower" or
# None), stripe hue band (degrees) or None for fixed colours, extra convert options).
DESIGNS = {
    1: ((5, 40, 150, 290), "upper", (340, 20), {}),                       # red/white stripes, fruit crates
    2: ((150, 8, 290, 262), "upper", (195, 250), {}),                     # blue/white stripes, produce
    3: ((286, 16, 415, 146), None, (36, 58), {}),                         # yellow/cream stripes, bread
    4: ((392, 5, 590, 275), "upper", None, {}),                           # cream canopy, blue drape (12's awning
                                                                          # hides its front corner's foot: healed)
    5: ((615, 14, 792, 180), None, None, {}),                             # cream tent, open front
    6: ((848, 6, 1021, 174), None, None, {}),                             # cream pavilion, rug
    7: ((1182, 11, 1314, 174), None, None, {}),                           # red/cream round tent, flag
    8: ((1317, 6, 1442, 175), None, None, {}),                            # small cream tent, flag, banner
    9: ((5, 40, 150, 290), "lower", None, {}),                            # cream canopy, produce, barrel
    10: ((150, 8, 290, 262), "lower", None, {}),                          # cream canopy, cloth seller
    11: ((287, 143, 389, 271), None, (340, 20), {"measure": "bbox"}),     # small red/white stripes (its counter is
                                                                          # narrow: fit the whole stall to the plot)
    12: ((392, 5, 590, 275), "lower", None, {}),                          # long cream canopy, hanging goods
}
# Left out: the open cream tent with a loose side drape (sheet 1020,5..1173,174): its drape and stool spill a third of
# a plot past the stall; and the small banner stand (733,147..829,259), not a stall.


def _components(mask, min_px=1):
    h, w = mask.shape
    lab = np.zeros((h, w), int)
    comps = []
    for y0 in range(h):
        for x0 in range(w):
            if mask[y0, x0] and not lab[y0, x0]:
                q = deque([(y0, x0)]); lab[y0, x0] = len(comps) + 1; pts = []
                while q:
                    y, x = q.popleft(); pts.append((y, x))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            yy, xx = y + dy, x + dx
                            if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not lab[yy, xx]:
                                lab[yy, xx] = len(comps) + 1; q.append((yy, xx))
                comps.append(pts)
    return [c for c in comps if len(c) >= min_px]


def _erode(m):
    p = np.pad(m, 1)
    out = m.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            out &= p[1 + dy:1 + dy + m.shape[0], 1 + dx:1 + dx + m.shape[1]]
    return out


# Sheet pairs that overlap (not just touch): the lower stall's awning top edge, as points in the scan box (x, y);
# columns outside the points use the end values.
SPLIT_LINES = {(392, 5, 590, 275): [(0, 175), (18, 158), (123, 120), (183, 150), (198, 158)]}
# Columns (in the scan box) of an upper stall whose foot was hidden by the lower one: its bottom is re-drawn there.
HEAL = {4: (100, 135)}
# Fixed-colour designs whose red cloth counts as awning (the round tent's stripes are its own, never tinted).
RED_CLOTH = {7}


def _grow(core, allowed, steps):
    out = core.copy()
    for _ in range(steps):
        p = np.pad(out, 1)
        out = (out | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]) & allowed
    return out


def heal(a, x0, x1):
    """Re-draw the foot of columns x0..x1 that another stall hid: the bottom runs straight between the neighbouring
    columns' bottoms, and each healed column copies the nearer neighbour's lowest rows."""
    op = a[..., 3] > 128
    def bottom(x):
        ys = np.nonzero(op[:, x])[0]
        return int(ys.max()) if len(ys) else None
    bl, br = bottom(x0 - 1), bottom(x1 + 1)
    for x in range(x0, x1 + 1):
        t = (x - x0 + 1) / (x1 - x0 + 2)
        target = int(round(bl + (br - bl) * t))
        cur = bottom(x)
        if cur is None or cur >= target:
            continue
        ref = x0 - 1 if t < 0.5 else x1 + 1
        rb = bl if ref == x0 - 1 else br
        for y in range(cur + 1, target + 1):
            a[y, x] = a[rb - (target - y), ref]
    return a


def cut(n):
    """The design's pixels alone (RGBA crop of its scan box, everything else transparent)."""
    box, piece, _, _ = DESIGNS[n]
    a = np.array(Image.open(SHEET).convert("RGBA").crop(box))
    solid = a[..., 3] > 40
    main = max(_components(solid), key=len)
    m = np.zeros_like(solid)
    for y, x in main:
        m[y, x] = True
    if piece and box in SPLIT_LINES:
        # the lower stall's awning overlaps the upper one's foot: pixels above the awning's top edge are the upper's
        pts = SPLIT_LINES[box]
        yy, xx = np.mgrid[0:m.shape[0], 0:m.shape[1]]
        edge = np.interp(xx, [p[0] for p in pts], [p[1] for p in pts])
        upper = yy < edge
        m &= upper if piece == "upper" else ~upper
        main = max(_components(m & (a[..., 3] > 128)), key=len)
        keep = np.zeros_like(m)
        for y, x in main:
            keep[y, x] = True
        m = _grow(keep, m, 2)
    elif piece:
        # two stalls touching at a corner: erode until the shape splits into two big parts, then grow them back
        # inside the shape (breadth first, so each pixel joins the nearer part)
        core, big = m & (a[..., 3] > 200), []        # the soft drop shadow joins them too: split the solid core
        for _ in range(12):
            core = _erode(core)
            big = sorted(_components(core, int(m.sum() * 0.12)), key=len, reverse=True)
            if len(big) >= 2:
                break
        if len(big) < 2:
            sys.exit("stalls: design %d did not split" % n)
        big = sorted(big[:2], key=lambda c: np.mean([p[0] for p in c]))
        want = 0 if piece == "upper" else 1
        lab = np.zeros(m.shape, int)
        q = deque()
        for i, c in enumerate(big):
            for y, x in c:
                lab[y, x] = i + 1; q.append((y, x))
        while q:
            y, x = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < m.shape[0] and 0 <= xx < m.shape[1] and m[yy, xx] and not lab[yy, xx]:
                    lab[yy, xx] = lab[y, x]; q.append((yy, xx))
        m = lab == want + 1
    out = a.copy()
    out[~m, 3] = 0
    if n in HEAL:
        out = heal(out, *HEAL[n])
    return out


def review(images, dst, scale=3):
    w = sum(im.width for im in images) * scale + 8 * (len(images) + 1)
    h = max(im.height for im in images) * scale + 16
    sheet = Image.new("RGBA", (w, h), (90, 90, 90, 255))
    x = 8
    for im in images:
        big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        sheet.alpha_composite(big, (x, 8))
        x += big.width + 8
    sheet.save(dst)


# ---- convert -----------------------------------------------------------------------------------------------------
def convert_design(n, out_dir, tmp):
    """Cut design n, convert it with convert.py into <out_dir>/intact.png (+ manifest when out_dir is the set's)."""
    _, _, _, opts = DESIGNS[n]
    src = Path(tmp) / ("cut_%d.png" % n)
    im = Image.fromarray(cut(n), "RGBA")
    x0, y0, x1, y1 = im.getchannel("A").getbbox()
    im.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(src)
    w, h = Image.open(src).size
    argv = ["stall_%d" % n, "--sheet", str(src), "--box", "0,0,%d,%d" % (w, h), "--footprint", "%g,%g" % FP,
            "--kind", "MARKET_STALL", "--role", "market", "--tag", "", "--height", "10", "--seed", str(n)]
    for k, v in opts.items():
        argv += ["--" + k] if v is True else ["--" + k, str(v)]
    a = convert.parser().parse_args(argv)
    return convert.run(a, out_dir, manifest=(out_dir == B / a.set))


# ---- finish: awning, damaged, ruins, idle, tints -----------------------------------------------------------------
OUTLINE = (34, 26, 24)
HOLE = (46, 34, 28)       # the dark inside of a stall, seen through a tear
GAP = 2              # rows of non-cloth bridged inside an awning column
WAVE = 11.0          # px: the awning ripple's wavelength along the edge
FRAMES, FPS = 4, 4


def hls(a):
    return sprite_fix._hls(a)


def stripe_px(a, n):
    """Coloured stripe pixels of a striped design (its hue band, saturated, darker than the cream stripes)."""
    band = DESIGNS[n][2]
    if band is None:
        return np.zeros(a.shape[:2], bool)
    h, l, s = hls(a)
    h0, h1 = band
    inb = ((h >= h0) & (h <= h1)) if h0 <= h1 else ((h >= h0) | (h <= h1))
    return (a[..., 3] > 0) & inb & (s >= 0.35) & (l >= 0.12) & (l < 0.78)


def awning(a, n):
    """Per column, the topmost run of cloth (cream, or the stripe colour; the round tent's red too): the awning or
    canopy. Returns (mask, {x: bottom row of the run, its outline included})."""
    h, l, s = hls(a)
    op = a[..., 3] > 0
    cream = op & (h >= 15) & (h <= 70) & (l >= 0.56)
    red = (op & ((h >= 340) | (h <= 20)) & (s >= 0.35) & (l >= 0.2)) if n in RED_CLOTH else np.zeros_like(op)
    cloth = cream | stripe_px(a, n) | red
    m = np.zeros_like(op)
    edge = {}
    H = a.shape[0]
    for x in range(a.shape[1]):
        ys = np.nonzero(cloth[:, x])[0]
        if not len(ys):
            continue
        # down the column while it is cloth; a break of up to GAP rows (the dark seams between stripes, shading)
        # is bridged when cloth follows
        y = int(ys[0]); last = y
        while y + 1 < H:
            nxt = next((k for k in range(1, GAP + 2) if y + k < H and cloth[y + k, x]), None)
            if nxt is None or not op[y + 1:y + nxt + 1, x].all():
                break
            y += nxt; last = y
        m[int(ys[0]):last + 1, x] = op[int(ys[0]):last + 1, x]
        if last - int(ys[0]) >= 2:
            edge[x] = last
        else:
            m[:, x] = False
    # a column running on into goods of the stripe's colour (red fruit under a red awning) is cut back to its
    # neighbours' edge
    xs = sorted(edge)
    for x in xs:
        near = [edge[k] for k in range(x - 3, x + 4) if k in edge and k != x]
        if near:
            med = int(np.median(near))
            if edge[x] > med + 2:
                m[med + 1:, x] = False
                edge[x] = med
    # the outline just under the run belongs to the awning's edge (it moves with it)
    for x, b in list(edge.items()):
        if b + 1 < H and op[b + 1, x] and int(a[b + 1, x, :3].astype(int).sum()) < 260:
            m[b + 1, x] = True
            edge[x] = b + 1
    return m, edge


def outline(a):
    """convert.py's 1 px dark outline on the opaque shape's edge."""
    al = a[..., 3] > 0
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    dark = a[..., :3].astype(int).sum(axis=2) < 200
    m = e & ~dark
    a[m, :3] = (a[m, :3] * 0.45 + np.array(OUTLINE) * 0.55).astype(np.uint8)
    return a


def ripple(a, mask, edge, phase):
    """The awning's front edge (the run's lowest 2 rows and its outline) shifted +-1 px vertically: a wave along x."""
    out, om = a.copy(), mask.copy()
    H = a.shape[0]
    for x, b in edge.items():
        v = math.sin(phase - 2 * math.pi * x / WAVE)
        dy = 1 if v > 0.35 else (-1 if v < -0.35 else 0)
        if dy == 1 and b + 1 < H:
            for y in (b + 1, b, b - 1):
                out[y, x] = a[y - 1, x]; om[y, x] = mask[y - 1, x]
        elif dy == -1 and b + 1 < H:
            for y in (b - 2, b - 1):
                out[y, x] = a[y + 1, x]; om[y, x] = mask[y + 1, x]
            out[b, x] = a[b + 1, x]
            om[b, x] = False
    return out, om


def _pick(px, q):
    order = np.argsort(px.astype(int).sum(1))
    return tuple(int(v) for v in px[order[int(q * (len(order) - 1))]])


def wood_colours(a, mask):
    h, l, s = hls(a)
    w = (a[..., 3] > 0) & ~mask & (h >= 18) & (h <= 45) & (s >= 0.35) & (l >= 0.2) & (l <= 0.62)
    px = a[w][:, :3]
    return _pick(px, 0.85), _pick(px, 0.55), _pick(px, 0.25)          # lit, mid, shade


def goods_colours(a, mask):
    h, l, s = hls(a)
    g = (a[..., 3] > 0) & ~mask & (s >= 0.45) & (l >= 0.3) & (l <= 0.7) & ((h < 18) | (h > 50))
    px = a[g][:, :3]
    if len(px) < 6:
        return [(200, 60, 40), (90, 150, 50), (220, 170, 60), (200, 60, 40), (90, 150, 50)]
    rng = np.random.default_rng(len(px))
    return [tuple(int(v) for v in px[i]) for i in rng.choice(len(px), 6, replace=False)]


def cloth_colours(a, n, mask):
    """(stripe colour or None, light cloth colour, cloth shade) from the intact awning."""
    st = stripe_px(a, n) & mask
    if n in RED_CLOTH:
        h, l, s = hls(a)
        st = mask & ((h >= 340) | (h <= 20)) & (s >= 0.35)
    lp = a[mask & ~st][:, :3]
    c_light, c_shade = _pick(lp, 0.7), _pick(lp, 0.2)
    if st.any():
        return _pick(a[st][:, :3], 0.6), c_light, c_shade
    return None, c_light, c_shade


def iso(anchor, u, v, z):
    ax, ay = anchor
    return (ax + 32 * u - 32 * v, ay - 16 * u - 16 * v - z)


def _box(d, anchor, u, v, su, sv, hz, z0, wood):
    lit, mid, shade = wood
    P = lambda uu, vv, zz: iso(anchor, uu, vv, zz)
    d.polygon([P(u, v, z0), P(u, v + sv, z0), P(u, v + sv, z0 + hz), P(u, v, z0 + hz)], fill=lit)       # left face
    d.polygon([P(u, v, z0), P(u + su, v, z0), P(u + su, v, z0 + hz), P(u, v, z0 + hz)], fill=shade)     # right face
    d.polygon([P(u, v, z0 + hz), P(u + su, v, z0 + hz), P(u + su, v + sv, z0 + hz), P(u, v + sv, z0 + hz)], fill=mid)


def ruins(a, n, mask, anchor):
    """The awning fallen flat over a low heap of planks and crates, inside the plot. Clean shapes, no speckle.
    Returns (ruins, cloth mask, stripe mask)."""
    from PIL import ImageDraw
    h, w = a.shape[:2]
    wood = wood_colours(a, mask)
    stripe, light, shade = cloth_colours(a, n, mask)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # heap: planks, a crate left standing at the front, the snapped post lying along the right
    _box(d, anchor, 0.04, 0.44, 0.50, 0.07, 1.5, 0, wood)
    _box(d, anchor, 0.34, 0.02, 0.50, 0.07, 1.5, 0, wood)
    _box(d, anchor, 0.82, 0.08, 0.07, 0.52, 2, 0, wood)
    _box(d, anchor, 0.04, 0.10, 0.20, 0.20, 6, 0, wood)
    # the fallen awning: a sheet over the rest of the heap, higher at the back where it lies over a crate, its front
    # edges scalloped
    cm = Image.new("L", (w, h), 0)
    dm = ImageDraw.Draw(cm)
    sheet = [(0.26, 0.12, 3), (0.80, 0.14, 4), (0.78, 0.62, 8), (0.24, 0.58, 7)]
    dm.polygon([iso(anchor, u, v, z) for u, v, z in sheet], fill=255)
    for k in range(6):
        t = (k + 0.5) / 6
        x, y = iso(anchor, 0.26 + 0.54 * t, 0.12 + 0.02 * t, 3 + t)
        dm.ellipse([x - 1.6, y - 1, x + 1.6, y + 2], fill=255)
    for k in range(4):
        t = (k + 0.5) / 4
        x, y = iso(anchor, 0.26 - 0.02 * t, 0.12 + 0.46 * t, 3 + 4 * t)
        dm.ellipse([x - 1.6, y - 1, x + 1.6, y + 2], fill=255)
    sm = np.array(cm) > 0
    arr = np.array(im)
    yy, xx = np.mgrid[0:h, 0:w]
    ax, ay = anchor
    # stripes as on the standing awning: bands across the sheet, along the screen's down-right slope
    t = (xx - ax) + 2 * (yy - ay)
    band = np.floor(t / 7.0).astype(int) % 2 == 0
    col = np.zeros((h, w, 3), np.uint8)
    col[:] = light
    stripe_m = np.zeros((h, w), bool)
    if stripe is not None:
        stripe_m = sm & band
        col[stripe_m] = stripe
    # light from the left: the sheet's right half (past its back corner) in a half shade, fold lines and the
    # hanging scallops in the cloth's shade
    bx = iso(anchor, 0.78, 0.62, 8)[0]
    right = sm & (xx > bx) & ~stripe_m
    col[right] = (np.array(light) * 0.6 + np.array(shade) * 0.4).astype(np.uint8)
    fold = sm & ((xx - ax) % 7 == 3) & ~stripe_m
    col[fold] = shade
    fm = Image.new("L", (w, h), 0)
    ImageDraw.Draw(fm).polygon([iso(anchor, u, v, z) for u, v, z in sheet], fill=255)
    hem = sm & ~(np.array(fm) > 0) & ~stripe_m
    col[hem] = shade
    arr[sm, :3] = col[sm]; arr[sm, 3] = 255
    out = outline(arr)
    return out, sm, stripe_m


def damaged(a, n, mask, edge, anchor, seed):
    """Torn awning (bites out of its front edge), the right corner post snapped (the awning's corner sagging onto
    it), a few goods spilled at the foot. Clean shapes."""
    rng = random.Random(seed)
    out, om = a.copy(), mask.copy()
    h, w = a.shape[:2]
    xs = sorted(edge)
    if not xs:
        return out, om
    hh, _, _ = hls(a)
    # 1. the snapped post: the awning's right end sags 1..3 px toward the corner, the post top under it is gone
    #    (not on tents, whose cloth runs down to the ground)
    x_r = xs[-1]
    span = max(6, (xs[-1] - xs[0]) // 4)
    tent = edge[x_r] > anchor[1] - 18
    src, srcm = out.copy(), om.copy()
    for x in ([] if tent else range(x_r - span + 1, min(w, x_r + 4))):
        # everything in the column down to the awning's edge (its outline, its end) drops k px
        k = min(3, int(round(3 * (x - (x_r - span)) / span)))
        b = edge.get(x, edge[x_r])
        if k <= 0:
            continue
        out[:b + 1, x] = 0; om[:b + 1, x] = False
        for y in range(b, -1, -1):
            if y + k < h and src[y, x, 3] > 0:
                out[y + k, x] = src[y, x]; om[y + k, x] = srcm[y, x]
        if x in edge:
            edge[x] = b + k
    for x in ([] if tent else range(x_r - 1, x_r + 1)):    # the post's top, under the corner, broken off
        if x not in edge:
            continue
        for y in range(edge[x] + 1, min(h, edge[x] + 5)):
            if out[y, x, 3] > 0 and (18 <= hh[y, x] <= 45 or out[y, x, :3].astype(int).sum() < 200):
                out[y, x] = 0
    # 2. torn awning: bites out of the front edge; through a bite the stall's dark inside shows (or the ground, past
    #    the stall)
    cand = xs[span // 2:-span]
    for _ in range(3 if len(cand) > 14 else 2):
        if not cand:
            break
        x = rng.choice(cand)
        cand = [c for c in cand if abs(c - x) > 7]
        b = edge[x]
        r = rng.choice((2.6, 3.2))
        for yy in range(int(b - r - 1), b + 2):
            for xx in range(int(x - r - 1), int(x + r + 2)):
                if 0 <= yy < h and 0 <= xx < w and om[yy, xx] and (xx - x) ** 2 + ((yy - b - 0.5) * 1.2) ** 2 <= r * r:
                    below = a[min(h - 1, edge.get(xx, yy) + 2), xx, 3] > 0
                    out[yy, xx] = (*HOLE, 255) if below else (0, 0, 0, 0)
                    om[yy, xx] = False
    out = outline(out)
    # 3. spilled goods at the foot: a tipped basket with its goods rolled out in front of the left face, two more in
    #    front of the right face
    goods = goods_colours(a, mask)
    lit, mid, shade = wood_colours(a, mask)
    bx, by = (int(round(v)) for v in iso(anchor, -0.08, 0.30, 0))
    for px, py, c in [(bx + i, by - j, mid if j < 2 else lit) for i in range(4) for j in range(3)] +             [(bx + 4, by - 1, shade), (bx + 4, by, shade)]:
        if 0 <= px < w and 0 <= py < h:
            out[py, px, :3] = c; out[py, px, 3] = 255
    fruit = [(bx + 5, by + 1), (bx + 7, by + 1), (bx + 6, by - 1)]
    fx, fy = (int(round(v)) for v in iso(anchor, 0.42, -0.10, 0))
    fruit += [(fx, fy), (fx + 3, fy - 1)]
    for (x, y), c in zip(fruit, goods):
        for px, py in ((x - 1, y), (x - 1, y - 1), (x + 2, y), (x + 2, y - 1), (x, y + 1), (x + 1, y + 1)):
            if 0 <= px < w and 0 <= py < h and out[py, px, 3] == 0:
                out[py, px, :3] = OUTLINE; out[py, px, 3] = 255
        for px, py in ((x, y), (x + 1, y), (x, y - 1), (x + 1, y - 1)):
            if 0 <= px < w and 0 <= py < h:
                out[py, px, :3] = c; out[py, px, 3] = 255
        if 0 <= y - 1 < h and 0 <= x < w:
            out[y - 1, x, :3] = tuple(min(255, v + 45) for v in c)
    # outline round the basket
    out = outline(out)
    return out, om


def idle(a, mask, edge):
    frames, masks = [], []
    for f in range(FRAMES):
        fr, fm = ripple(a, mask, edge, 2 * math.pi * f / FRAMES)
        frames.append(fr); masks.append(fm)
    return np.concatenate(frames, axis=1), np.concatenate(masks, axis=1)


def palette_png(rgb, path):
    """A lightness ramp of one cloth colour (huemap's palette box): dark shade .. light."""
    import colorsys
    hh, ll, ss = colorsys.rgb_to_hls(*(v / 255 for v in rgb))
    row = []
    for t in np.linspace(-0.2, 0.1, 8):
        c = colorsys.hls_to_rgb(hh, min(0.86, max(0.12, ll + t)), ss)
        row.append(tuple(int(round(v * 255)) for v in c) + (255,))
    im = Image.new("RGBA", (8, 1))
    im.putdata(row)
    im.save(path)
    return "0,0,8,1"


def finish(n, tmp):
    """States, idle and (striped designs) tints of stall_<n>, from its converted intact."""
    d = B / ("stall_%d" % n)
    man = json.load(open(B / "manifest.json", encoding="utf-8"))
    e = man["stall_%d" % n]
    anchor = tuple(e["anchor"])
    a = np.array(Image.open(d / "intact.png").convert("RGBA"))
    mask, edge = awning(a, n)
    dmg, dmask = damaged(a, n, mask, dict(edge), anchor, 100 + n)
    rui, rmask, rstripe = ruins(a, n, mask, anchor)
    strip, smask = idle(a, mask, edge)
    Image.fromarray(dmg, "RGBA").save(d / "damaged.png")
    Image.fromarray(rui, "RGBA").save(d / "ruins.png")
    Image.fromarray(strip, "RGBA").save(d / "idle.png")
    convert.write_manifest(B / "manifest.json", "stall_%d" % n, {"frames": FRAMES, "fps": FPS})
    print("stall_%d: awning px %d, edge cols %d" % (n, int(mask.sum()), len(edge)))
    if DESIGNS[n][2] is None:
        return
    # tints: only the stripes (the stripe colour inside the awning) are recoloured, in every state and frame
    masks = {"intact.png": stripe_px(a, n) & mask, "damaged.png": stripe_px(dmg, n) & dmask,
             "ruins.png": rstripe & (rui[..., 3] > 0), "idle.png": stripe_px(strip, n) & smask}
    for tint, (stripe_rgb, _) in CLOTH.items():
        name = "stall_%d_%s" % (n, tint)
        td = B / name
        td.mkdir(exist_ok=True)
        pal = Path(tmp) / ("pal_%s.png" % tint)
        box = palette_png(stripe_rgb, pal)
        for f, m in masks.items():
            mp = Path(tmp) / ("mask_%d_%s" % (n, f))
            Image.fromarray(np.where(m, 255, 0).astype(np.uint8), "L").save(mp)
            subprocess.run([sys.executable, str(ROOT / "tools" / "dev" / "sprite_fix.py"), "huemap", str(d / f),
                            str(td / f), "0,360", str(pal), box, "minsat=0", "minl=0", "mask=" + str(mp)],
                           cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
        entry = dict(e)
        entry.update({"frames": FRAMES, "fps": FPS})
        convert.write_manifest(B / "manifest.json", name, entry)
    print("stall_%d: tints red, blue, cream" % n)


def deglow(path):
    """The sprite shader lets bright saturated orange-yellow glow (check_sprite_glow.py's rule: red the top channel,
    over 0.93, saturated, green over 0.45): the yellow awning and sunlit fruit and wood are toned down just under it."""
    a = np.array(Image.open(path).convert("RGBA")).astype(np.float64)
    rgb = a[..., :3] / 255
    mx, mn = rgb.max(-1), rgb.min(-1)
    hot = (a[..., 3] > 0) & (rgb[..., 0] >= mx) & (mx > 0.925) & ((mx - mn) / np.maximum(mx, 1e-6) > 0.55) &         (rgb[..., 1] > 0.45)
    if hot.any():
        a[..., :3][hot] = rgb[hot] * (0.92 / mx[hot])[:, None] * 255
        Image.fromarray(a.round().astype(np.uint8), "RGBA").save(path)
    return int(hot.sum())


def build(n, tmp):
    convert_design(n, B / ("stall_%d" % n), tmp)
    deglow(B / ("stall_%d" % n) / "intact.png")
    finish(n, tmp)
    for d in [B / ("stall_%d" % n)] + [B / ("stall_%d_%s" % (n, t)) for t in CLOTH]:
        for f in ("intact.png", "damaged.png", "ruins.png", "idle.png"):
            if (d / f).exists():
                deglow(d / f)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", default=str(Path(tempfile.gettempdir()) / "stalls"))
    a = p.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    if a.what == ["cut"]:
        ims = []
        for n in DESIGNS:
            c = Image.fromarray(cut(n), "RGBA")
            c = c.crop(c.getchannel("A").getbbox())
            c.save(out / ("cut_%d.png" % n)); ims.append(c)
        review(ims[:6], out / "cut_a.png", 2); review(ims[6:], out / "cut_b.png", 2)
        print("cut ->", out)
        sys.exit(0)
    todo = list(DESIGNS) if a.what == ["all"] else [int(v) for v in a.what]
    for n in todo:
        build(n, out)
