"""Decor tree sets (decor batch 4, Task 14): the forest's and the town's decor oaks and pines (Decor.Kind.OAK / PINE,
DecorSprites.tree_set), converted locally (no AI) from the same sheet cuts as the batch 3 trees (trees.py: cut, mirror
to light from the left, green muting, outline), each fitted to the procedural tree's size (PropArt.tree, measured as
the bounding box of its polygons) and kept at native scale.

  forest_oak_1..3   the forest's oaks (decor with no size: PropArt.tree tall 46..64, FOREST_CLUSTERS; 40..54 px wide):
                    trees.py's tree_1 (broad leafy), oak_3 (leafy) and oak_2 (round) at 56, 50 and 60 px tall
  forest_pine_1..2  the forest's pines (tall 46..64; 35..43 px wide): tree_2 (a pine) at 60 px and the taller pine of
                    tree_5's pair (cut alone, see PINE_CONE) at 52 px
  town_oak_1..3     the town's decor trees behind the houses (TownDecor._houses: their height in size.x, 24..32; the
  town_pine_1..2    procedural tree 20..27 px wide): the same cuts at 26, 29, 32 (oaks) and 28, 32 px (pines)

Greens: after the fit every set's leaves go through trees.shade_greens() (darker and less yellow, toward the
procedural forest; the same shift the batch 3 building trees take, so all trees match in hue). The stump is cut
before it, from the fitted greens (its bark samples unchanged).

Anchor: the trunk's foot (convert's anchor: the lowest body row's middle), the tree's ground point, as the procedural
tree's base. The canvas is cropped round the tree (1 px margin) and ends 2 px under the foot.

Stump (stump.png, same canvas, drawn at the intact's anchor when the tree is knocked down): a short trunk of the tree's
own bark (trees.bark_colours), lit on the left, its cut face up, a root flare at its foot; clean, nothing round it.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_trees.py [all | <name> ...] [--preview DIR]   (--preview: intact | stump at 3x)
"""
import argparse
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
import decor_common  # noqa: E402
import trees  # noqa: E402

# The taller pine of tree_5's pair (TownMap_Component3, sheet px), cut alone: a cone from its tip down to its widest
# branch row, plus its trunk's brown pixels; the smaller pine beside it and the undergrowth are left behind.
PINE_CONE = {"sheet": 3, "box": (436, 618, 512, 742), "tip": (474, 622), "base_y": 724, "half": 33,
             "trunk": (466, 484, 738)}

# name: (cut: a trees.SETS name or "pine_cone", opaque height px, foot to tip)
SETS = {
    "forest_oak_1": ("tree_1", 56),
    "forest_oak_2": ("oak_3", 50),
    "forest_oak_3": ("oak_2", 60),
    "forest_pine_1": ("tree_2", 60),
    "forest_pine_2": ("pine_cone", 52),
    "town_oak_1": ("tree_1", 29),
    "town_oak_2": ("oak_3", 26),
    "town_oak_3": ("oak_2", 32),
    "town_pine_1": ("tree_2", 32),
    "town_pine_2": ("pine_cone", 28),
}


def cut_cone():
    """The PINE_CONE pine alone: an RGBA array of its box."""
    p = PINE_CONE
    box = p["box"]
    a = np.array(Image.open(trees.REF / ("TownMap_Component%d.png" % p["sheet"])).convert("RGBA").crop(box))
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    X, Y = xx + box[0], yy + box[1]
    tx, ty = p["tip"]
    t = np.clip((Y - ty) / float(p["base_y"] - ty), 0, None)
    # the cone's rim bulges a little in branch rows (every ~9 sheet px), so the cut reads as drooping branches
    rim = p["half"] * t * (0.92 + 0.1 * np.abs(np.sin((Y - ty) * np.pi / 9.0)))
    keep = (np.abs(X - tx) <= rim + 1) & (Y <= p["base_y"])
    x0, x1, foot = p["trunk"]
    keep |= (X >= x0) & (X <= x1) & trees.brown(a) & (Y > p["base_y"] - 20)
    keep &= Y <= foot
    a[~keep, 3] = 0
    a[a[..., 3] < 128, 3] = 0
    return trees.largest(convert.keep_shapes(a))


def source(cut_name):
    """(cut RGBA array, mirror): the sheet lights its Component3 trees from the right, so those are mirrored."""
    if cut_name == "pine_cone":
        return cut_cone(), True
    return trees.cut(cut_name), trees.SETS[cut_name][2]


def fit(name, tmp):
    """Tone, fit to the set's height, mirror; crop round the tree. Returns (canvas, anchor)."""
    cut_name, height = SETS[name]
    a, mirror = source(cut_name)
    a = trees.tone(a)
    im = Image.fromarray(a, "RGBA")
    x0, y0, x1, y1 = im.getchannel("A").getbbox()
    src = Path(tmp) / ("cut_%s.png" % name)
    im.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(src)
    w, h = Image.open(src).size
    # convert.py scales the bbox width to 32 (W + D) px: pick the footprint that makes the opaque height `height`
    scale = height / float(y1 - y0)
    k = scale * (x1 - x0) / 64.0
    c, foot, _ = convert.convert(str(src), (0, 0, w, h), (k, k), mirror=mirror, colors=40, keep_green=True,
                                 measure="bbox", canvas_pad=4)
    al = c[..., 3] > 0
    ys = np.nonzero(al.any(1))[0]
    xs = np.nonzero(al.any(0))[0]
    top, left, right = int(ys.min()) - 1, int(xs.min()) - 1, int(xs.max()) + 2
    bottom = foot[1] + 3
    if bottom > c.shape[0]:
        c = np.concatenate([c, np.zeros((bottom - c.shape[0], c.shape[1], 4), np.uint8)], 0)
    c = c[top:bottom, left:right].copy()
    return c, (foot[0] - left, foot[1] - top)


def stump(c, anchor):
    """A short trunk on the intact's canvas, foot at the anchor (see the module doc)."""
    fx, fy = anchor
    al = c[..., 3] > 0
    # the trunk's width just above its foot (its own pixels), 3..6 px
    row = np.nonzero(al[max(fy - 2, 0)])[0]
    near = row[np.abs(row - fx) <= 4] if len(row) else row
    tw = int(np.clip(near.max() - near.min() + 1 if len(near) else 4, 3, 6))
    big = c.shape[0] > 40
    th = 6 if big else 4
    info = {"foot": (fx, fy), "crown_bot": max(fy - 12, 0)}
    bc = trees.bark_colours(c, info)
    out = np.zeros_like(c)
    sx0 = fx - tw // 2

    def put(x, y, col):
        if 0 <= y < out.shape[0] and 0 <= x < out.shape[1]:
            out[y, x, :3] = col
            out[y, x, 3] = 255

    for y in range(fy - th + 1, fy + 1):
        for x in range(sx0, sx0 + tw):
            t = (x - sx0) / max(tw - 1, 1)
            put(x, y, bc["lit"] if t < 0.34 else (bc["mid"] if t < 0.7 else bc["dark"]))
    # root flare: a pixel out either side on the foot row (the shaded side darker)
    put(sx0 - 1, fy, bc["mid"])
    put(sx0 + tw, fy, bc["dark"])
    # cut face: the top row a light wood oval inside a bark rim
    face = np.array([214, 178, 126])
    ty = fy - th
    for x in range(sx0, sx0 + tw):
        put(x, ty, face if 0 < x - sx0 < tw - 1 else bc["mid"])
    put(sx0 + tw // 2, ty, face - 40)
    return trees.outline(out)


def build(name, tmp):
    c, anchor = fit(name, tmp)
    st = stump(c, anchor)                # from the fitted greens: the stump's bark samples stay as they were
    c = trees.shade_greens(c)
    path = decor_common.write_set(name, Image.fromarray(c, "RGBA"), anchor)
    Image.fromarray(st, "RGBA").save(path.parent / "stump.png")
    al = c[..., 3] > 0
    xs = np.nonzero(al.any(0))[0]
    ys = np.nonzero(al.any(1))[0]
    print("%s: size %s anchor %s opaque %dx%d" % (name, [c.shape[1], c.shape[0]], list(anchor),
                                                 xs.max() - xs.min() + 1, ys.max() - ys.min() + 1))
    return c, st


def preview(names, out):
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for n in names:
            c, anchor = fit(n, tmp)
            st = stump(c, anchor)
            c = trees.shade_greens(c)
            both = np.concatenate([c, np.zeros((c.shape[0], 4, 4), np.uint8), st], 1)
            im = Image.fromarray(both, "RGBA")
            bg = Image.new("RGBA", im.size, (96, 120, 64, 255))
            bg.alpha_composite(im)
            bg.resize((im.size[0] * 3, im.size[1] * 3), Image.NEAREST).convert("RGB").save(out / ("%s.png" % n))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--preview")
    args = p.parse_args()
    names = list(SETS) if args.what == ["all"] else args.what
    if args.preview:
        preview(names, Path(args.preview))
        sys.exit(0)
    with tempfile.TemporaryDirectory() as tmp:
        for n in names:
            build(n, tmp)
