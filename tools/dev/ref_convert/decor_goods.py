"""Goods decor sets (decor batch 4), built locally (no AI): DecorArt's barrel, drawn clean.

  barrel_1  Decor.Kind.BARREL. TownMap_Component2's standalone barrel (row 5, by the sacks) cut with convert.py at the
            procedural barrel's size (10 px body) reads as noise (no hoops, no staves), so it is drawn clean on a fixed
            pixel map instead: a lid with a light rim, staves in a fixed light-to-dark pattern lit from the left, two
            iron hoops, a 1 px dark outline. Its tones are the sheet barrel's (wood lightness quintiles, the iron its
            darkest tenth), muted toward the town's timber like the drawn dock (bridges.DOCK_SAT, DOCK_VAL).
            12 x 15 px (the procedural barrel is 10 x 13), anchored at the middle of its base row.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_goods.py [all | barrel] [--out <scratch dir>]   (--out: write PNGs there, no manifest)
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
import decor_common  # noqa: E402

C2 = convert.ROOT / "concepts" / "TOWN REF" / "TownMap_Component2.png"
BARREL_BOX = (896, 520, 935, 578)    # the sheet barrel (no neighbours in the box)
WOOD_FROM = 35                       # wood tones: the sheet barrel's pixels lighter than this percentile
SAT, VAL = 0.72, 0.88                # as bridges.DOCK_SAT, DOCK_VAL: sheet wood toned toward the town's timber
OUTLINE = tuple(int(v) for v in convert.OUTLINE)

# The barrel, light from the left. 0..4 wood (darkest..lightest), i iron hoop, j hoop's lit left end, o outline.
BARREL = [
    "...oooooo...",
    ".oo444444oo.",
    "o4422222244o",
    "o4333333332o",
    "o4443333221o",
    "ojjjiiiiiiio",
    "o4432332110o",
    "o4432332110o",
    "o4432332110o",
    "o4432332110o",
    "o4432332110o",
    "ojjjiiiiiiio",
    "o4432332110o",
    ".o44323211o.",
    "..oooooooo..",
]
BARREL_ANCHOR = (6, 14)


def sheet_tones():
    """Five wood tones (darkest first) and the iron (dark, lit) from the sheet barrel's opaque pixels: the wood is its
    warm pixels above the lightness WOOD_FROM percentile (below are seams and outline), split in quintiles; the iron
    is its grey (low-saturation) dark pixels."""
    a = np.array(Image.open(C2).convert("RGBA").crop(BARREL_BOX)).astype(float)
    px = a[a[..., 3] > 200][:, :3]
    lum = px.sum(1)
    sat = (px.max(1) - px.min(1)) / np.maximum(px.max(1), 1)
    wood = px[(lum > np.percentile(lum, WOOD_FROM)) & (sat > 0.45)]
    wl = wood.sum(1)
    bins = np.digitize(wl, np.percentile(wl, [20, 40, 60, 80]))

    def tone(c):
        g = c.mean()
        return tuple(int(v) for v in np.round((g + (c - g) * SAT) * VAL))

    woods = [tone(wood[bins == k].mean(0)) for k in range(5)]
    grey = px[(sat < 0.45) & (lum > 60)]
    iron = tone(grey.mean(0))
    iron_lit = tuple(int(v) for v in np.minimum(np.array(iron) * 1.5 + 10, 255))
    return woods, iron, iron_lit


def from_map(rows, woods, iron, iron_lit):
    h, w = len(rows), len(rows[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pal = {str(k): woods[k] for k in range(5)}
    pal.update({"i": iron, "j": iron_lit, "o": OUTLINE})
    for y, row in enumerate(rows):
        assert len(row) == w, "ragged row %d" % y
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), pal[ch] + (255,))
    return img


def barrel():
    return from_map(BARREL, *sheet_tones()), BARREL_ANCHOR


SETS = {"barrel": [("barrel_1", barrel)]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("which", nargs="?", default="all", choices=["all"] + list(SETS))
    ap.add_argument("--out")
    a = ap.parse_args()
    for key, sets in SETS.items():
        if a.which not in ("all", key):
            continue
        for name, build in sets:
            img, anchor = build()
            if a.out:
                Path(a.out).mkdir(parents=True, exist_ok=True)
                img.save(Path(a.out) / (name + ".png"))
                print(name, img.size, anchor, "->", a.out)
            else:
                print(name, img.size, anchor, "->", decor_common.write_set(name, img, anchor))


if __name__ == "__main__":
    main()
