"""The fountain and the well from the reference sheet (concepts/TOWN REF/TownMap_Component2.png, row 3), converted with
convert.py at their plots and finished with their states, all locally (no AI):

  fountain   the round two-tier fountain (1.2 x 1.2): intact, damaged (cracked rim, dry spout), ruins (a broken low
             basin ring, clean), idle (4-frame water shimmer at 6 fps: ripple highlights move, the jet tip alternates)
  well       the roofed stone well (0.5 x 0.5): intact, damaged, ruins

The sheet's grass ring round each base is dropped (the fountain stands on the market's paving).

Usage (from anywhere):
  python tools/dev/ref_convert/fountains.py [all | fountain | well] [--out <scratch dir>]
"""
import argparse
import math
import random
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_fix  # noqa: E402

ROOT = convert.ROOT
B = convert.B
SHEET = ROOT / "concepts" / "TOWN REF" / "TownMap_Component2.png"
OUTLINE = (34, 26, 24)
FRAMES, FPS = 4, 6
ROUND = 1.1        # the basin circle's diameter, in plot sides

# name: (scan box on the sheet, footprint, tag, height, seed, extra convert options)
SETS = {
    "fountain": ((272, 272, 372, 410), (1.2, 1.2), "", 24, 1, {}),
    "well": ((478, 262, 568, 392), (0.5, 0.5), "well", 12, 2, {}),
}


def hls(a):
    return sprite_fix._hls(a)


def grassy(a):
    """The grass ring's pixels: green over red and blue, or the dark olive at its edge."""
    rgb = a[..., :3].astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (g > r + 4) & (g > b + 12)


def cut(name):
    box = SETS[name][0]
    a = np.array(Image.open(SHEET).convert("RGBA").crop(box))
    a[grassy(a), 3] = 0
    return convert.keep_shapes(a)


def outline(a, only=None):
    """convert.py's 1 px dark outline on the opaque shape's edge (within `only` when given)."""
    al = a[..., 3] > 0
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    dark = a[..., :3].astype(int).sum(axis=2) < 200
    m = e & ~dark
    if only is not None:
        m &= only
    a[m, :3] = (a[m, :3] * 0.45 + np.array(OUTLINE) * 0.55).astype(np.uint8)
    return a


def basin(a):
    """(cx, cy, rx, ry) of the round base's footprint ellipse: the lower half's width, its bottom row."""
    al = a[..., 3] > 0
    ys = np.nonzero(al.any(1))[0]
    lo = (ys.min() + ys.max()) // 2
    xs = np.nonzero(al[lo:].any(0))[0]
    rx = (xs.max() - xs.min() + 1) / 2
    cx = (xs.min() + xs.max()) / 2
    bottom = max(int(np.nonzero(al[:, x])[0].max()) for x in range(int(cx) - 1, int(cx) + 2))
    ry = rx / 2
    return cx, bottom - ry + 0.5, rx, ry


def clean_base(a):
    """The base's bottom edge as a clean ellipse arc: the soft ground shadow and grass edge left under it cut away,
    gaps up to the arc filled from the pixel above, and the edge outlined again."""
    a = a.copy()
    h, w = a.shape[:2]
    cx, cy, rx, ry = basin(a)
    al = a[..., 3] > 0
    for x in range(w):
        t = (x + 0.5 - cx) / rx
        if abs(t) >= 1:
            continue
        yb = int(math.floor(cy + ry * math.sqrt(1 - t * t)))
        a[yb + 1:, x] = 0
        ys = np.nonzero(al[:yb + 1, x])[0]
        if not len(ys):
            continue
        # fill up to the arc from the lowest opaque pixel at or above it (inside the base's wall)
        last = int(ys.max())
        if last < yb and last > yb - 6:
            for y in range(last + 1, yb + 1):
                a[y, x] = a[last - 1 if last > 0 else last, x]
        a[yb, x, :3] = (a[yb, x, :3] * 0.45 + np.array(OUTLINE) * 0.55).astype(np.uint8)
    return a


def convert_set(name, tmp, harmonize=False):
    """Cut, fit and place: the round basin is a ground circle of diameter ROUND x the plot's side (convert.py's own fit
    would make it the plot diamond's width, a circle round the plot's corners), centred on the plot. Writes intact.png
    and the manifest entry; returns (intact, anchor)."""
    box, fp, tag, height, seed, opts = SETS[name]
    src = Path(tmp) / ("cut_%s.png" % name)
    im = Image.fromarray(cut(name), "RGBA")
    x0, y0, x1, y1 = im.getchannel("A").getbbox()
    im.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(src)
    w, h = Image.open(src).size
    W, D = fp
    # convert.py scales the body to 32 (W + D) px; a ground circle of diameter d is 32 * sqrt(2) * d px wide
    k = math.sqrt(2) * ROUND / 2
    c, _, info = convert.convert(str(src), (0, 0, w, h), (W * k, D * k), colors=opts.get("colors", 40))
    c = clean_base(c)
    al = c[..., 3] > 0
    # the basin's centre column: the middle of the lower half's opaque columns; its bottom on that column
    ys = np.nonzero(al.any(1))[0]
    lower = al[(ys.min() + ys.max()) // 2:]
    xs = np.nonzero(lower.any(0))[0]
    cx = int(round((xs.min() + xs.max()) / 2))
    bottom = int(np.nonzero(al[:, cx])[0].max())
    # the plot's front corner lies 16 W px below its centre, the circle's bottom 16 sqrt(2) r px
    drop = int(round(16 * W - 16 * math.sqrt(2) * ROUND * W / 2))
    anchor = (cx, bottom + drop)
    need = anchor[1] + 3 - c.shape[0]
    if need > 0:
        c = np.concatenate([c, np.zeros((need, c.shape[1], 4), np.uint8)], 0)
    d = B / name
    d.mkdir(parents=True, exist_ok=True)
    Image.fromarray(c, "RGBA").save(d / "intact.png")
    if harmonize:
        import subprocess
        subprocess.run([sys.executable, str(ROOT / "tools" / "dev" / "sprite_fix.py"), "harmonize",
                        str(convert.HARMONIZE_TARGET[0]), convert.HARMONIZE_TARGET[1], str(d / "intact.png")],
                       cwd=ROOT, check=True)
        c = np.array(Image.open(d / "intact.png").convert("RGBA"))
    print("%s: scale %.3f size %s anchor %s" % (name, info["scale"], [c.shape[1], c.shape[0]], list(anchor)))
    convert.write_manifest(B / "manifest.json", name, {
        "size": [c.shape[1], c.shape[0]], "footprint": [W, D], "anchor": list(anchor), "height": height,
        "seed": seed, "kind": "FOUNTAIN", "role": "decor", "tag": tag})
    return c, anchor


# ---- finish: idle, damaged, ruins ----------------------------------------------------------------------------------
def masks(a):
    """(water, stone) masks: water the saturated blue, stone the low-saturation greys and beiges."""
    h, l, s = hls(a)
    op = a[..., 3] > 0
    water = op & (h >= 175) & (h <= 240) & (s >= 0.25) & (l >= 0.12)
    stone = op & ~water & (s < 0.32) & (l >= 0.18) & (a[..., 2].astype(int) <= a[..., 0].astype(int) + 6)
    return water, stone


def geom(a):
    """(cx, cy, rx, ry, wall): the base ellipse and the height of its vertical wall (the rows its outermost columns
    span above the ellipse's middle row)."""
    cx, cy, rx, ry = basin(a)
    _, stone = masks(a)
    x = int(round(cx))
    y = int(np.nonzero(a[:, x, 3] > 0)[0].max())
    run = 0
    while y - run - 1 >= 0 and stone[y - run - 1, x]:
        run += 1
    # the run is the front wall and the rim's cap (2 rows deep at the front)
    return cx, cy, rx, ry, run - 1


def despeckle(a, stone):
    """Lone reddish or near-black specks inside the stone (left from the sheet's soft shading) take their
    neighbours' median colour."""
    h, l, s = hls(a)
    op = a[..., 3] > 0
    odd = op & ((((h < 18) | (h > 340)) & (s > 0.3)) | (l < 0.16))
    out = a.copy()
    H, W = op.shape
    for y, x in zip(*np.nonzero(odd)):
        nb = [(y + dy, x + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dy or dx)]
        nb = [(yy, xx) for yy, xx in nb if 0 <= yy < H and 0 <= xx < W and stone[yy, xx] and not odd[yy, xx]]
        if len(nb) >= 6:
            px = np.array([a[yy, xx, :3] for yy, xx in nb])
            out[y, x, :3] = px[np.argsort(px.astype(int).sum(1))[len(px) // 2]]
    return out


def _pick(px, q):
    order = np.argsort(px.astype(int).sum(1))
    return tuple(int(v) for v in px[order[int(q * (len(order) - 1))]])


def stone_colours(a, stone):
    px = a[stone][:, :3]
    c = {k: _pick(px, q) for k, q in (("light", 0.95), ("lit", 0.85), ("mid", 0.62), ("shade", 0.4), ("dark", 0.12))}
    c["floor"] = tuple(int(round(v * 0.5 + w * 0.5)) for v, w in zip(c["mid"], c["shade"]))
    return c


def water_colours(a, water):
    px = a[water][:, :3]
    return {"deep": _pick(px, 0.15), "mid": _pick(px, 0.5), "hi": _pick(px, 0.9)}


def pool_mask(a, water):
    """The basin's pool: water inside the rim's inner ellipse (the base ellipse raised by the wall, less the rim)."""
    cx, cy, rx, ry, wall = geom(a)
    H, W = water.shape
    yy, xx = np.mgrid[0:H, 0:W]
    px, py = cx, cy - wall
    inner = ((xx + 0.5 - px) / (rx - 3)) ** 2 + ((yy + 0.5 - py) / (ry - 1.5)) ** 2 <= 1
    return water & inner, (px, py, rx - 3, ry - 1.5)


def spire_top(a):
    al = a[..., 3] > 0
    y = int(np.nonzero(al.any(1))[0].min())
    xs = np.nonzero(al[y])[0]
    return int(round((xs.min() + xs.max()) / 2)), y


def shimmer(a, f, water, pool, ell, jet=True):
    """Frame f of the water shimmer: two rings of light ripple pixels widening across the pool (dotted, the dots
    stepping each frame), a few glints, a light streak running down each stream, and the jet over the spire tall and
    short in turn."""
    out = a.copy()
    wc = water_colours(a, water)
    hi = np.array(wc["hi"])
    white = np.array((222, 244, 255))
    px, py, prx, pry = ell
    H, W = water.shape
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt(((xx + 0.5 - px) / prx) ** 2 + ((yy + 0.5 - py) / pry) ** 2)
    for k in range(2):
        r = 0.32 + 0.6 * (((f / FRAMES) + k * 0.5) % 1.0)
        ring = pool & (np.abs(d - r) < 0.8 / pry) & ((xx + yy + f) % 2 == 0)
        out[ring, :3] = (out[ring, :3] * 0.35 + hi * 0.65).astype(np.uint8)
    rng = random.Random(7)
    pts = list(zip(*np.nonzero(pool)))
    for i, (y, x) in enumerate(rng.sample(pts, min(8, len(pts)))):
        if (i + f) % FRAMES == 0:
            out[y, x, :3] = white
    stream = water & ~pool
    st = stream & ((yy - f) % 4 == 0)
    out[st, :3] = (out[st, :3] * 0.4 + hi * 0.6).astype(np.uint8)
    if jet:
        x, y = spire_top(a)
        tall = 3 if f % 2 == 0 else 2
        for k in range(1, tall + 1):
            out[y - k, x, :3] = hi if k < tall else white
            out[y - k, x, 3] = 255
        sx = x - 1 if f % 2 == 0 else x + 1
        out[y - tall + 1, sx, :3] = hi
        out[y - tall + 1, sx, 3] = 255
    return out


def dry(a, water, pool, wc):
    """No water running: the streams gone (the stone behind them filled from the row's nearest stone, or nothing
    where they hung free), the pool still and dull."""
    out = a.copy()
    rgb = a[..., :3].astype(int)
    bluish = (a[..., 3] > 0) & (rgb[..., 2] > rgb[..., 0] + 12)
    stream = (water | bluish) & ~pool
    H, W = water.shape
    # with the streams' dark outlines and the shadow lines between them
    ps = np.pad(stream, 1)
    by = np.any([ps[1 + dy:1 + dy + H, 1 + dx:1 + dx + W] for dy in (-1, 0, 1) for dx in (-1, 0, 1)], 0)
    stream |= by & (rgb.sum(-1) < 170) & (a[..., 3] > 0) & ~pool
    for y, x in zip(*np.nonzero(stream)):
        left = next((x - k for k in range(1, 7) if x - k >= 0 and a[y, x - k, 3] > 0 and not water[y, x - k]), None)
        right = next((x + k for k in range(1, 7) if x + k < W and a[y, x + k, 3] > 0 and not water[y, x + k]), None)
        if left is None or right is None:
            out[y, x] = 0
        else:
            out[y, x] = a[y, left if x - left <= right - x else right]
    # the streams' outline pixels left hanging free: dark pixels near a removed stream with few opaque neighbours
    near = np.pad(stream, 2)
    near = np.any([near[2 + dy:2 + dy + H, 2 + dx:2 + dx + W] for dy in range(-2, 3) for dx in range(-2, 3)], 0)
    for _ in range(3):
        op = out[..., 3] > 0
        p = np.pad(op, 1)
        cnt = sum(p[1 + dy:1 + dy + H, 1 + dx:1 + dx + W].astype(int) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                  if dy or dx)
        dark = out[..., :3].astype(int).sum(-1) < 260
        out[op & near & dark & (cnt <= 3), 3] = 0
        out[out[..., 3] == 0] = 0
    # loose bits (under 8 px) left off the main shape
    keep = convert.keep_shapes(np.where((out[..., 3] > 0)[..., None], out, 0).astype(np.uint8))
    out[(keep[..., 3] == 0)] = 0
    lum = a[..., :3].astype(int).sum(-1)
    deep, mid = np.array(wc["deep"]), np.array(wc["mid"])
    dull = deep * 0.6 + np.array((70, 80, 70)) * 0.4
    lit = (lum > np.median(lum[pool]))[pool][:, None]
    out[pool, :3] = np.where(lit, mid * 0.55 + dull * 0.45, dull).astype(np.uint8)
    return out


def crack(out, pts, col):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            x = int(round(x0 + (x1 - x0) * i / n)); y = int(round(y0 + (y1 - y0) * i / n))
            if out[y, x, 3] > 0:
                out[y, x, :3] = col


def damaged(a, name, water, pool, wc, sc):
    """Cracked basin rim: two dark cracks down the front wall, a notch chipped out of the rim's front right with its
    block lying at the foot; the fountain's spout dry, the well's roof missing two shingles."""
    out = dry(a, water, pool, wc) if name == "fountain" else a.copy()
    cx, cy, rx, ry, wall = geom(a)
    s = rx / 30.0

    def P(t, z):
        """A point on the front wall: t from -1 (left side) through 0 (front) to 1 (right side), z px up."""
        ang = t * math.pi / 2
        return cx + rx * math.sin(ang), cy + ry * math.cos(ang) - z
    for t, wob in ((0.42, (1, -1, 1, 0)), (-0.3, (-1, 1, 0, -1))):
        x, y = P(t, wall - 1)
        pts = [(x, y)]
        for w in wob:
            x += w * max(1, round(s)); y += max(2, round(wall * 0.17))
            pts.append((x, y))
        crack(out, [(int(round(px)), int(round(py))) for px, py in pts], OUTLINE)
    # the chipped rim: a notch out of the front cap's top edge, the basin's inside (its water, or the well's dark)
    # showing through, the broken stone's top in light
    tc = 0.55 if name == "fountain" else 0.3
    bx, _ = P(tc, wall)
    nw = max(2, int(round(3 * s))); nd = max(2, int(round(3 * s)))
    for x in range(int(round(bx)) - nw, int(round(bx)) + nw + 1):
        t = (x + 0.5 - cx) / rx
        ytop = int(round(cy - wall + ry * math.sqrt(max(0.0, 1 - t * t))))   # the cap's outer top edge
        depth = nd - abs(x - int(round(bx))) * nd // (nw + 1)
        if depth <= 0:
            continue
        inside = out[ytop - 2, x].copy()
        for y in range(ytop - 1, ytop + depth):
            out[y, x] = inside
        out[ytop + depth, x, :3] = sc["light"]
    if name == "well":
        roof_gap(out)
        return outline(out)
    fx, fy = P(0.3, 0)
    fx, fy = int(round(fx)) + 2, int(round(fy)) + 1
    H, W = out.shape[:2]
    for x in range(fx, fx + nw + 1):
        for y in range(fy - 1, fy + 1):
            if 0 <= x < W and 0 <= y < H:
                out[y, x, :3] = sc["lit"] if y == fy - 1 else sc["shade"]
                out[y, x, 3] = 255
    return outline(out)


def roof_gap(out):
    """Two shingles gone from the roof's slope: the dark under the roof shows through."""
    h, l, s = hls(out)
    roof = (out[..., 3] > 0) & (h >= 200) & (h <= 240) & (s >= 0.3)
    ys, xs = np.nonzero(roof)
    cy, cx = int(np.median(ys)), int(np.median(xs))
    for dx, dy in ((-3, 0), (2, -2)):
        for y in range(cy + dy - 1, cy + dy + 1):
            for x in range(cx + dx - 1, cx + dx + 2):
                if roof[y, x]:
                    out[y, x, :3] = (40, 30, 26)


def iso_block(d, x, y, w, h, z, sc):
    """A small stone block, (x, y) its front bottom corner, w along the right face, h along the left, z tall: left face
    lit (light from the left), right face in shade, top lightest."""
    ink = sc["dark"]
    d.polygon([(x - h, y - h // 2), (x, y), (x, y - z), (x - h, y - z - h // 2)], fill=sc["lit"], outline=ink)
    d.polygon([(x, y), (x + w, y - w // 2), (x + w, y - z - w // 2), (x, y - z)], fill=sc["shade"], outline=ink)
    d.polygon([(x, y - z), (x + w, y - z - w // 2), (x + w - h, y - z - w // 2 - h // 2), (x - h, y - z - h // 2)],
              fill=sc["light"], outline=ink)


def ruins(a, name, sc):
    """A broken low basin ring, clean: the wall cut down to about a third (its lower courses kept as they are), a
    rim cap on top, the ring broken at the front right and the back left, the basin floor dark inside with a few
    fallen blocks (the fountain) or the roof's beam lying across it (the well)."""
    cx, cy, rx, ry, wall = geom(a)
    H, W = a.shape[:2]
    hr = max(3, int(round(wall * 0.45)))
    yy, xx = np.mgrid[0:H, 0:W]

    def ell(z, shrink=0.0):
        return ((xx + 0.5 - cx) / (rx - shrink)) ** 2 + ((yy + 0.5 - (cy - z)) / (ry - shrink / 2)) ** 2 <= 1
    out = np.zeros_like(a)
    rim = 5.5 if name == "fountain" else 3.0            # the cap's width at the sides (half that front and back)
    cap = ell(hr)
    hole = ell(hr, rim)                                 # the opening inside the cap
    low = ell(1, rim)                                   # the basin's floor, just over the ground
    ring = cap & ~hole
    # 1. the cap, lit from the left (its right half a shade darker), its outer edge a line darker still
    out[ring, :3] = sc["light"]
    out[ring & (xx > cx + 1), :3] = sc["lit"]
    out[cap & ~ell(hr, 1.0), :3] = sc["mid"]
    # 2. inside: the back wall's inner face (lit on the right, where it faces the light) over the floor
    face = hole & ~low
    out[face, :3] = sc["dark"]
    out[face & (xx > cx), :3] = sc["shade"]
    out[hole & low, :3] = sc["floor"]
    out[cap, 3] = 255
    # 3. the front wall, hr rows: the intact wall's courses just under its cap, moved down (their light kept), on
    #    the intact's bottom edge
    yb = {}
    for x in range(W):
        t = (x + 0.5 - cx) / rx
        if abs(t) >= 1:
            continue
        yb[x] = int(math.floor(cy + ry * math.sqrt(1 - t * t)))
        src = yb[x] - wall + 2
        out[yb[x] - hr + 1:yb[x], x] = a[src:src + hr - 1, x]
        out[yb[x], x] = a[yb[x], x]
    # 4. a gap at the front right: the wall down to a 2-row stub, the floor seen over it, the broken ends' tops lit
    #    (left end) and in shade (right end)
    span = max(2, int(round(rx * 0.17)))
    bx = int(round(cx + rx * math.sin(0.42 * math.pi / 2)))
    for x in range(bx - span, bx + span + 1):
        stub = 2 if abs(x - bx) < span else max(3, hr - 2)
        top = yb[x] - stub + 1
        for y in range(0, top):
            if not out[y, x, 3] or y < cy - hr:
                continue
            out[y, x, :3] = sc["floor"]                # the floor, seen through the gap down to the stub
        out[top, x, :3] = sc["light"] if x < bx else sc["mid"]
        if abs(x - bx) == span:                         # the broken ends: the right one faces the light
            for y in range(top - (hr - 3), top):
                if out[y, x, 3] and y > cy - hr + ry * 0.3:
                    out[y, x, :3] = sc["lit"] if x > bx else sc["shade"]
    # 5. a gap at the back left: the cap broken off there, its stump's top the floor's colour
    gx = int(round(cx - rx * math.sin(0.55 * math.pi / 2)))
    for x in range(gx - span, gx + span + 1):
        for y in np.nonzero(ring[:, x])[0]:
            if y < cy - hr and abs(x - gx) < span:
                out[y, x, :3] = sc["shade"]
    im = Image.fromarray(out, "RGBA")
    d = ImageDraw.Draw(im)
    s = rx / 30.0
    if name == "fountain":
        # the spire's broken stub in the middle and fallen blocks round it, all inside the floor
        for u, v, w, h, z in ((-0.08, -0.05, 4, 4, 6), (-0.5, 0.0, 5, 4, 3), (0.42, -0.1, 4, 5, 3),
                              (0.15, 0.35, 6, 3, 2), (-0.3, 0.4, 3, 3, 2)):
            x = int(round(cx + u * rx)); y = int(round(cy - hr * 0.5 + v * ry))
            iso_block(d, x, y, max(2, int(round(w * s))), max(2, int(round(h * s))), max(2, int(round(z * s))), sc)
    else:
        # the roof's beam lying across the ring, and a post stub
        wood = ((150, 96, 52), (112, 70, 38), (78, 48, 28))
        x0, y0 = int(round(cx - rx * 0.85)), int(round(cy - hr))
        x1, y1 = int(round(cx + rx * 0.55)), int(round(cy - hr - ry * 0.8))
        d.line([(x0, y0), (x1, y1)], fill=wood[1], width=2)
        d.line([(x0, y0 - 1), (x1, y1 - 1)], fill=wood[0], width=1)
    return outline(np.array(im))


def finish(name, intact):
    d = B / name
    water, stone = masks(intact)
    a = despeckle(intact, stone)
    water, stone = masks(a)
    sc, wc = stone_colours(a, stone), water_colours(a, water)
    pool, ell = pool_mask(a, water)
    if name == "fountain":
        frames = [shimmer(a, f, water, pool, ell) for f in range(FRAMES)]
        Image.fromarray(frames[0], "RGBA").save(d / "intact.png")
        Image.fromarray(np.concatenate(frames, axis=1), "RGBA").save(d / "idle.png")
        convert.write_manifest(B / "manifest.json", name, {"frames": FRAMES, "fps": FPS})
    else:
        Image.fromarray(a, "RGBA").save(d / "intact.png")
    Image.fromarray(damaged(a, name, water, pool, wc, sc), "RGBA").save(d / "damaged.png")
    Image.fromarray(ruins(a, name, sc), "RGBA").save(d / "ruins.png")
    print("%s: water px %d (pool %d), stone px %d, wall %d" % (name, int(water.sum()), int(pool.sum()),
                                                                int(stone.sum()), geom(a)[4]))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", default=str(Path(tempfile.gettempdir()) / "fountains"))
    a = p.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for n in (list(SETS) if a.what == ["all"] else a.what):
        c, _ = convert_set(n, out, harmonize=True)
        finish(n, c)
