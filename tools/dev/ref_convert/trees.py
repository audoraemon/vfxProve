"""The town's trees from the reference sheets, converted locally (no AI) with convert.py and finished with their states
and a crown-sway idle:

  tree_1..tree_5  forest and meadow trees (TREE / decor / "", plot TownLayout.TREE_SIZE 0.7 x 0.7), from
                  TownMap_Component3 rows 3-4: a broad leafy tree, a pine, a slender leafy tree, a smaller leafy tree
                  and a pair of pines. The sheet lights them from the right: they are mirrored (light from the left).
  oak_1..oak_3    the town's garden oaks (TREE / decor / oak, plot TOWN_TREE 0.45 x 0.45): the two round trees of
                  TownMap_Component2 row 2 (lit from the left, kept) and a leafy tree of Component3 row 4 (mirrored).

Cut: Component3's trees stand on grass tiles with undergrowth, rocks and flowers. Each is cut as its crown (everything
above the crown's middle row, and below it what lies inside an ellipse round the crown's lower half) plus its trunk
(the brown pixels of a column box down to the trunk's foot): the tile, the undergrowth and the rocks are left behind.

Scale: SCALE sprite px per sheet px, the sheet's own proportions (a sheet person is ~50 px, a game person ~17: 0.33,
as for the street posts). It makes the forest trees 46-58 px tall and 34-43 px wide, the procedural tree's size
(tall = 1.8 x 26..32 = 47-58 px). Component2's round trees are drawn smaller on their sheet: they take OAK_SCALE so
they stand as tall as the procedural town oak (1.8 x 25..29 = 45-52 px).

Greens: the sheet's yellow-lime highlights and teal shadows are pulled toward the town's leaf greens (GREEN_PULL) and a little muted, as the town's olive greens.
Then (art polish 2) every finished still and the idle strip go through shade_greens(): the leaves darker and less
yellow, as the decor forest's, so every tree in the town matches in hue. The states are made from the fitted greens
first (the char, bites and ruins come out as before); only green pixels change (the crown, the ruins' tuft), never the
trunk, stump, log or char.

Anchor: the trunk's foot stands at the plot's centre, which is 16 x size px above the footprint's front corner.

States (trees have no cracks): damaged, a scorched and thinned crown (ragged charred patches, bites out of its edge);
ruins, a stump with its cut face up and the trunk lying on the ground beside it, a tuft of its crown at the far end,
clean. Idle: a crown sway, 4 frames at FPS: the crown's upper rows shift 1 px sideways (more of them the higher), out
and back; the trunk and the lower crown stay still.

Usage (from anywhere):
  python tools/dev/ref_convert/trees.py [all | <name> ...] [--preview DIR]   (--preview: the cuts at 3x, nothing written)
"""
import argparse
import math
import sys
import tempfile
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402

ROOT = convert.ROOT
B = convert.B
REF = ROOT / "concepts" / "TOWN REF"
OUTLINE = np.array([34, 26, 24])
SCALE = 0.33
OAK_SCALE = 0.38
FRAMES = 4
FPS = 3
FOREST = (0.7, 0.7)
TOWN = (0.45, 0.45)
GREEN_PULL = 0.4
LOBES = 7

# name: (sheet, box, mirror, scale, footprint, tag, height, seed,
#        crown ellipse (cx, cy, rx, ry) or None, trunk (x0, x1, foot y), all in sheet px)
SETS = {
    "tree_1": (3, (890, 432, 1030, 600), True, SCALE, FOREST, "", 29, 1, (955, 492, 64, 57), (938, 966, 590)),
    "tree_2": (3, (1025, 422, 1145, 602), True, SCALE, FOREST, "", 32, 2, (1081, 528, 62, 40), (1072, 1094, 596)),
    "tree_3": (3, (1320, 432, 1440, 602), True, SCALE, FOREST, "", 29, 3, (1375, 497, 52, 54), (1366, 1388, 592)),
    "tree_4": (3, (118, 625, 225, 760), True, SCALE, FOREST, "", 26, 4, (172, 680, 44, 39), (164, 184, 753)),
    "tree_5": (3, (430, 622, 549, 750), True, SCALE, FOREST, "", 32, 5, (494, 700, 52, 30), (468, 486, 738)),
    "oak_1": (2, (1175, 165, 1262, 292), False, OAK_SCALE, TOWN, "oak", 27, 1, None, (1206, 1228, 289)),
    "oak_2": (2, (1265, 160, 1363, 282), False, OAK_SCALE, TOWN, "oak", 27, 2, None, (1302, 1325, 279)),
    "oak_3": (3, (24, 640, 130, 762), True, SCALE, TOWN, "oak", 25, 3, (78, 692, 50, 41), (64, 86, 759)),
}


def _hls(a):
    rgb = a[..., :3].astype(float) / 255
    mx, mn = rgb.max(-1), rgb.min(-1)
    l = (mx + mn) / 2
    d = mx - mn
    s = np.where(d == 0, 0, d / np.maximum(1 - np.abs(2 * l - 1), 1e-6))
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / np.maximum(d, 1e-6)) % 6, np.where(mx == g, (b - r) / np.maximum(d, 1e-6) + 2,
                                                                      (r - g) / np.maximum(d, 1e-6) + 4)) * 60
    return np.where(d == 0, 0, h), l, s


def brown(a):
    """Bark: warm (red above green, green above blue) and not bright."""
    rgb = a[..., :3].astype(int)
    return (rgb[..., 0] >= rgb[..., 1] - 4) & (rgb[..., 1] >= rgb[..., 2] - 6) & (rgb.sum(-1) < 520)


def cut(name):
    """The tree alone (see the module doc): an RGBA array of its box."""
    sheet, box, _, _, _, _, _, _, ell, trunk = SETS[name]
    a = np.array(Image.open(REF / ("TownMap_Component%d.png" % sheet)).convert("RGBA").crop(box))
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    X, Y = xx + box[0], yy + box[1]
    tx0, tx1, foot = trunk
    if ell is None:
        keep = np.ones((h, w), bool)
    else:
        cx, cy, rx, ry = ell
        # a scalloped ellipse: its rim bulges in leaf clumps (LOBES round it), so the cut reads as the crown's own edge
        ang = np.arctan2((Y - cy) / ry, (X - cx) / rx)
        rim = 0.9 + 0.12 * np.abs(np.sin(ang * LOBES))
        keep = (Y < cy) | (np.hypot((X - cx) / rx, (Y - cy) / ry) <= rim)
    keep |= (X >= tx0) & (X <= tx1) & brown(a) & (Y > (ell[1] if ell else 0))
    keep &= Y <= foot
    a[~keep, 3] = 0
    a[a[..., 3] < 128, 3] = 0
    a = convert.keep_shapes(a)
    return largest(a)


def largest(a):
    """Only the largest 8-connected shape (keep_shapes also keeps small pieces low down: here they are undergrowth)."""
    solid = a[..., 3] > 0
    h, w = solid.shape
    lab = -np.ones((h, w), int)
    sizes = []
    for y0, x0 in zip(*np.nonzero(solid)):
        if lab[y0, x0] >= 0:
            continue
        k = len(sizes); lab[y0, x0] = k; q = deque([(y0, x0)]); n = 0
        while q:
            y, x = q.popleft(); n += 1
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and solid[yy, xx] and lab[yy, xx] < 0:
                        lab[yy, xx] = k; q.append((yy, xx))
        sizes.append(n)
    a = a.copy()
    if len(sizes) > 1:
        a[lab != int(np.argmax(sizes)), 3] = 0
    return a


def tone(a):
    """Pull the leaf greens toward the town's (ArtKit.OAK, the procedural crowns): lime highlights a little less yellow,
    teal shadows a little less blue, by the hue's distance from leaf green (100 deg)."""
    h, l, s = _hls(a)
    leaf = (a[..., 3] > 0) & (h >= 55) & (h <= 175) & (s > 0.15)
    if not leaf.any():
        return a
    rgb = a[..., :3].astype(float)
    # hue rotation toward 95 deg, done in RGB by mixing with a green of the same lightness
    target_h = np.where(h < 95, h + (95 - h) * GREEN_PULL, h - (h - 95) * GREEN_PULL)
    out = _from_hls(target_h, l, s * 0.82)
    rgb[leaf] = out[leaf]
    a = a.copy()
    a[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    return a


SHADE_HUE, SHADE_HUE_PULL = 112.0, 0.45
SHADE_SAT, SHADE_VAL = 0.78, 0.9


def shade_greens(c):
    """Leaves (green pixels: hue 55..175, saturation over 0.15) darker and less yellow, toward the procedural forest
    (ArtKit.OAK / PINE: hue ~100..120, saturation ~0.5): the hue pulled SHADE_HUE_PULL of the way to SHADE_HUE,
    saturation times SHADE_SAT, value times SHADE_VAL. Bark, char, the cut face and the outline (not green) are
    untouched. A colour-to-colour map, so a fitted palette stays clean. Shared by every tree set (trees.py's tree_n /
    oak_n states and idle, decor_trees.py's forest and town sets) so all trees match in hue. c: an RGBA uint8 array,
    returned changed (a copy)."""
    rgb = c[..., :3].astype(float) / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    d = mx - mn
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    safe = np.where(d > 0, d, 1.0)
    h = np.where(mx == r, ((g - b) / safe) % 6, np.where(mx == g, (b - r) / safe + 2, (r - g) / safe + 4)) * 60.0
    s = np.where(mx > 0, d / np.where(mx > 0, mx, 1.0), 0.0)
    leaf = (c[..., 3] > 0) & (d > 0) & (h >= 55) & (h <= 175) & (s > 0.15)
    h2 = h + (SHADE_HUE - h) * SHADE_HUE_PULL
    s2 = s * SHADE_SAT
    v2 = mx * SHADE_VAL
    # HSV back to RGB
    hp = (h2 % 360) / 60.0
    cc = v2 * s2
    x = cc * (1 - np.abs(hp % 2 - 1))
    z = np.zeros_like(cc)
    conds = [hp < 1, hp < 2, hp < 3, hp < 4, hp < 5, hp >= 5]
    out = np.stack([np.select(conds, q) for q in ([cc, x, z, z, x, cc], [x, cc, cc, x, z, z], [z, z, x, cc, cc, x])], -1)
    out += (v2 - cc)[..., None]
    c = c.copy()
    c[leaf, :3] = np.clip(np.round(out[leaf] * 255.0), 0, 255).astype(np.uint8)
    return c


def _from_hls(h, l, s):
    c = (1 - np.abs(2 * l - 1)) * s
    hp = (h % 360) / 60
    x = c * (1 - np.abs(hp % 2 - 1))
    z = np.zeros_like(c)
    conds = [hp < 1, hp < 2, hp < 3, hp < 4, hp < 5, hp >= 5]
    rs = [c, x, z, z, x, c]
    gs = [x, c, c, x, z, z]
    bs = [z, z, x, c, c, x]
    r = np.select(conds, rs); g = np.select(conds, gs); b = np.select(conds, bs)
    m = l - c / 2
    return np.stack([r + m, g + m, b + m], -1) * 255


def outline(a):
    """convert.py's 1 px dark outline on the opaque shape's edge (pixels already dark are left)."""
    al = a[..., 3] > 0
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    dark = a[..., :3].astype(int).sum(axis=2) < 200
    m = e & ~dark
    a[m, :3] = (a[m, :3] * 0.45 + OUTLINE * 0.55).astype(np.uint8)
    return a


def convert_set(name, tmp):
    """Cut, tone, fit at the set's scale (mirrored when lit from the right), place with the trunk's foot at the plot's
    centre. Returns (intact, anchor, info) with info: trunk foot (x, y), crown bottom row."""
    sheet, box, mirror, scale, fp, tag, height, seed, ell, trunk = SETS[name]
    a = tone(cut(name))
    im = Image.fromarray(a, "RGBA")
    x0, y0, x1, y1 = im.getchannel("A").getbbox()
    src = Path(tmp) / ("cut_%s.png" % name)
    im.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(src)
    w, h = Image.open(src).size
    body_w = float(x1 - x0)
    # convert.py scales the bbox width to 32 (W + D) px: pick the footprint that gives `scale`
    k = scale * body_w / 64.0
    c, foot, info = convert.convert(str(src), (0, 0, w, h), (k, k), mirror=mirror, colors=40, keep_green=True,
                                    measure="bbox", canvas_pad=4)
    # the foot: the trunk's lowest row, its middle (convert's anchor, with greens counted)
    drop = int(round(16 * fp[0]))
    room_right = 24
    c = np.concatenate([c, np.zeros((drop + 4, c.shape[1], 4), np.uint8)], 0)
    c = np.concatenate([c, np.zeros((c.shape[0], room_right, 4), np.uint8)], 1)
    anchor = (foot[0], foot[1] + drop)
    # the crown's bottom: the lowest row whose opaque run is wider than the trunk by half the crown
    al = c[..., 3] > 0
    widths = [np.ptp(np.nonzero(al[y])[0]) + 1 if al[y].any() else 0 for y in range(c.shape[0])]
    full = max(widths)
    crown_bot = max(y for y in range(c.shape[0]) if widths[y] >= full * 0.4)
    top = int(np.nonzero(al.any(1))[0].min())
    return c, anchor, {"foot": foot, "crown_bot": crown_bot, "top": top, "scale": info["scale"]}


# ---- states -----------------------------------------------------------------------------------------------------
BARK = np.array([[52, 36, 26], [78, 54, 34], [104, 72, 44], [136, 98, 60]])   # dark .. light (ArtKit.BARK's range)
CHAR = [np.array(v) for v in ((38, 30, 27), (62, 48, 38), (92, 70, 48))]


def _pick(px, q):
    order = np.argsort(px.astype(int).sum(1))
    return np.array(px[order[int(q * (len(order) - 1))]], int)


def bark_colours(a, info):
    fx, fy = info["foot"]
    reg = a[info["crown_bot"]:fy + 1, max(fx - 5, 0):fx + 6]
    m = (reg[..., 3] > 0) & brown(reg)
    px = reg[m][:, :3] if m.sum() > 6 else BARK
    out = {k: _pick(px, q) for k, q in (("light", 0.95), ("lit", 0.75), ("mid", 0.5), ("dark", 0.15))}
    # a trunk mostly in shade (the pines) samples too dark to read as wood: lift it halfway to the town's bark
    for k, ref in zip(("light", "lit", "mid", "dark"), BARK[::-1]):
        if out[k].sum() < ref.sum():
            out[k] = (out[k] + ref) // 2
    return out


def damaged(a, info, seed):
    """A scorched, thinned crown: charred patches (the leaves' light kept as char's light) and bites out of the crown's
    edge; the trunk and the lower crown's middle untouched."""
    rng = np.random.default_rng(1000 + seed)
    out = a.copy()
    al = a[..., 3] > 0
    h, w = al.shape
    yy, xx = np.mgrid[0:h, 0:w]
    top, bot = info["top"], info["crown_bot"]
    crown = al & (yy <= bot)
    ys, xs = np.nonzero(crown)
    lum = a[..., :3].astype(int).sum(-1)
    # charred patches: 4-5 ragged ones on the crown, denser at their middle and thinning out to scattered charred
    # leaves at their rim; each charred pixel keeps 18% of its leaf (the clumps still read through the char)
    for _ in range(int(rng.integers(4, 6))):
        i = int(rng.integers(len(ys)))
        r = float(rng.uniform(3.6, 5.0))
        d = np.sqrt((yy - ys[i]) ** 2 + (xx - xs[i]) ** 2)
        m = crown & (d <= r) & (rng.random((h, w)) < 0.45 + 0.55 * (1 - d / r))
        for j, (lo, hi) in enumerate(((0, 170), (170, 300), (300, 999))):
            sel = m & (lum >= lo) & (lum < hi)
            out[sel, :3] = (CHAR[j] * 0.82 + a[sel, :3] * 0.18).astype(np.uint8)
    # bites: 3 round gaps on the crown's edge (its upper half, and one side low), the leaves there gone
    edge_pts = []
    for y in range(top + (bot - top) // 3, bot - 2):
        row = np.nonzero(crown[y])[0]
        if len(row):
            edge_pts += [(y, row.min()), (y, row.max())]
    for _ in range(4):
        y, x = edge_pts[int(rng.integers(len(edge_pts)))]
        r = float(rng.uniform(2.6, 3.6))
        out[(yy - y) ** 2 + (xx - x) ** 2 <= r * r] = 0
    out[out[..., 3] == 0] = 0
    out = convert.keep_shapes(out)
    return outline(out)


def ruins(a, info, anchor):
    """A stump with its cut face up where the trunk stood, the trunk lying on the ground to its right (going down the
    ground's x axis, 2 px across for 1 down), its cut end facing the stump, and a tuft of the crown at its far end."""
    bc = bark_colours(a, info)
    out = np.zeros_like(a)
    fx, fy = info["foot"]
    tw = 7
    sx0 = fx - tw // 2
    # stump: 4 rows of bark, lit on the left
    for y in range(fy - 5, fy + 1):
        for x in range(sx0, sx0 + tw):
            t = (x - sx0) / (tw - 1)
            col = bc["lit"] if t < 0.34 else (bc["mid"] if t < 0.7 else bc["dark"])
            out[y, x, :3] = col; out[y, x, 3] = 255
    # cut face: a light oval on top (two rows), a bark rim round it
    face = np.array([214, 178, 126])
    for x in range(sx0 + 1, sx0 + tw - 1):
        out[fy - 8, x, :3] = bc["mid"]; out[fy - 8, x, 3] = 255
    for y, f in ((fy - 7, face), (fy - 6, face - 26)):
        for x in range(sx0, sx0 + tw):
            out[y, x, :3] = f if 0 < x - sx0 < tw - 1 else bc["mid"]; out[y, x, 3] = 255
    out[fy - 7, sx0 + 3, :3] = face - 50
    # the log: lying from beside the stump toward the lower right, 4 px thick
    L = 16
    lx0, ly0 = sx0 + tw + 2, fy - 5
    tones = ("light", "lit", "lit", "mid", "dark")
    for i in range(L):
        x, y = lx0 + i, ly0 + i // 2
        for k in range(5):
            out[y + k, x, :3] = bc[tones[k]]; out[y + k, x, 3] = 255
    # its broken near end: the light wood showing
    for k in range(1, 5):
        out[ly0 + k, lx0, :3] = face
    # a tuft of the crown at the far end: a disc cut from the crown's lower middle
    tx, ty = lx0 + L - 1, ly0 + (L - 1) // 2
    cy = info["crown_bot"] - 6
    r = 4
    for dy in range(-r, r + 1):
        for dx in range(-r - 1, r + 2):
            if (dx / (r + 1)) ** 2 + (dy / r) ** 2 <= 1:
                sy, sxx = cy + dy, fx + dx
                y, x = ty + dy - 1, tx + dx + 2
                if a[sy, sxx, 3] and 0 <= y < out.shape[0] and 0 <= x < out.shape[1]:
                    out[y, x] = a[sy, sxx]
    return outline(out)


def sway(a, info):
    """The idle strip: frame f shifts the crown's rows above its bottom by round(1.5 t sin(2 pi f / 4)) px, clamped
    to 1 (t: 0 at the crown's bottom row, 1 at its top), so the upper two thirds lean out and back; the rest stays."""
    h, w = a.shape[:2]
    top, bot = info["top"], info["crown_bot"]
    frames = []
    for f in range(FRAMES):
        s = math.sin(2 * math.pi * f / FRAMES)
        fr = a.copy()
        for y in range(top, bot + 1):
            t = (bot - y) / max(bot - top, 1)
            dx = int(max(-1, min(1, round(1.5 * t * s))))
            if dx:
                fr[y] = np.roll(a[y], dx, axis=0)
        frames.append(fr)
    return np.concatenate(frames, 1)


def build(name, tmp):
    sheet, box, mirror, scale, fp, tag, height, seed, ell, trunk = SETS[name]
    c, anchor, info = convert_set(name, tmp)
    d = B / name
    d.mkdir(parents=True, exist_ok=True)
    rn = ruins(c, info, anchor)
    # trim the room on the right the ruins do not use (all stills share one canvas)
    used = max(int(np.nonzero((c[..., 3] > 0).any(0))[0].max()), int(np.nonzero((rn[..., 3] > 0).any(0))[0].max()))
    W = used + 3
    c, rn = c[:, :W], rn[:, :W]
    Image.fromarray(shade_greens(c), "RGBA").save(d / "intact.png")
    Image.fromarray(shade_greens(damaged(c, info, seed)), "RGBA").save(d / "damaged.png")
    Image.fromarray(shade_greens(rn), "RGBA").save(d / "ruins.png")
    Image.fromarray(shade_greens(sway(c, info)), "RGBA").save(d / "idle.png")
    H = c.shape[0]
    print("%s: scale %.3f size %s anchor %s foot %s crown rows %d-%d" % (name, info["scale"], [W, H], list(anchor),
                                                                       info["foot"], info["top"], info["crown_bot"]))
    convert.write_manifest(B / "manifest.json", name, {
        "size": [W, H], "footprint": list(fp), "anchor": list(anchor), "height": height, "seed": seed,
        "kind": "TREE", "role": "decor", "tag": tag, "frames": FRAMES, "fps": FPS})


def preview(names, out):
    out.mkdir(parents=True, exist_ok=True)
    for n in names:
        a = cut(n)
        im = Image.fromarray(a, "RGBA")
        bg = Image.new("RGBA", im.size, (255, 0, 255, 255)); bg.alpha_composite(im)
        bg.resize((im.size[0] * 3, im.size[1] * 3), Image.NEAREST).convert("RGB").save(out / ("cut_%s.png" % n))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--preview")
    a = p.parse_args()
    names = list(SETS) if a.what == ["all"] else a.what
    if a.preview:
        preview(names, Path(a.preview))
        sys.exit(0)
    with tempfile.TemporaryDirectory() as tmp:
        for n in names:
            build(n, tmp)
