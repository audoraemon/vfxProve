"""Makes a breed's sheet from another's by swapping its coat colours (0 PixelLab generations).

Usage (from the project root):
  python tools/dev/recolor_animal.py --breed shepherd
  python tools/dev/recolor_animal.py --all

Each breed below names its source sheet and a map of source colour -> new colour. Every opaque pixel takes the new
colour of the nearest source colour in the map, shifted by the pixel's own difference from it, so the PixelLab
shading in between keeps its steps. Pixels far from every key (the outline, a tongue, eyes) stay as they are. Writes
assets/pixellab/animals/<breed>.png and copies the source's .json (same cells, feet and frame counts).
"""
import argparse
import colorsys
import os
import shutil

from PIL import Image

DIR = "assets/pixellab/animals"
## Farther than this (RGB distance) from every key, a pixel keeps its colour.
KEEP_BEYOND = 38

BREEDS = {
    # A black shepherd with a tan muzzle and chest: every brown goes charcoal by its own light, the cream goes tan.
    "shepherd": ("hound", {
        "a26c4d": "5c5254",
        "935c3b": "4e4446",
        "874f33": "3e3638",
        "835c4c": "56484a",
        "734230": "322b2d",
        "714739": "362e30",
        "5d372f": "282224",
        "553531": "2a2426",
        "e4dccf": "e8c890",
        "cdbca7": "d4a868",
        "c3bab1": "c8a060",
        "b79b86": "b48a50",
    }),
    # Cats by hue (the template cat has too many shades for keys): its orange coat and its cream each take a new ramp,
    # dark to light by the pixel's own brightness; the near-black outline and eyes stay.
    "black_cat": ("tabby", {"hue": True, "warm": ("1e1b22", "4a4652"), "pale": ("2a2630", "5a5664")}),
    "grey_cat": ("tabby", {"hue": True, "warm": ("4a4a54", "a8a8b2"), "pale": ("9a9aa4", "eeeef4")}),
}


def _hex(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def _ramp(lo, hi, t):
    a, b = _hex(lo), _hex(hi)
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


## A cat pixel's new colour by hue: warm (orange) or pale (cream, white), placed on that ramp by its brightness.
def _by_hue(c, table):
    h, l, sat = colorsys.rgb_to_hls(*(v / 255.0 for v in c))
    if l < 0.16:
        return c  # the outline and the eyes
    pale = sat < 0.45 or l > 0.82
    lo, hi = table["pale"] if pale else table["warm"]
    t = (l - 0.16) / 0.84
    return _ramp(lo, hi, max(0.0, min(1.0, t)))


def recolor(breed):
    src, table = BREEDS[breed]
    keys = [] if table.get("hue") else [(_hex(k), _hex(v)) for k, v in table.items()]
    im = Image.open(os.path.join(DIR, src + ".png")).convert("RGBA")
    px = im.load()
    cache = {}
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            c = (r, g, b)
            if c not in cache and not keys:
                cache[c] = _by_hue(c, table)
            if c not in cache:
                k, v = min(keys, key=lambda kv: _dist(c, kv[0]))
                if _dist(c, k) > KEEP_BEYOND:
                    cache[c] = c
                else:
                    cache[c] = tuple(max(0, min(255, v[i] + c[i] - k[i])) for i in range(3))
            px[x, y] = cache[c] + (a,)
    out = os.path.join(DIR, breed + ".png")
    im.save(out)
    shutil.copyfile(os.path.join(DIR, src + ".png.json"), out + ".json")
    print("recoloured", src, "->", out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--breed", choices=sorted(BREEDS))
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    for b in (sorted(BREEDS) if args.all else [args.breed]):
        recolor(b)


if __name__ == "__main__":
    main()
