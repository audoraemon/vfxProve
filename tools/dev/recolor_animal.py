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
        "eyes": "e0a048",
    }),
    # Cats by hue (the template cat has too many shades for keys): its orange coat and its cream each take a new ramp,
    # dark to light by the pixel's own brightness; the near-black outline and eyes stay.
    "black_cat": ("tabby", {"hue": True, "warm": ("1e1b22", "4a4652"), "pale": ("2a2630", "5a5664"),
                            "eyes": "e8d040"}),
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


## A source sheet whose eyes alone change (its own coat stays): the hound's dark eye on its dark brown head goes amber.
EYES_ONLY = {"hound": "e0a048"}


## Eye pixels a cell at most, by source sheet: a dog in profile shows one, a cat turned to us two.
MAX_EYES = {"hound": 1, "tabby": 2}


def _dark(c):
    return colorsys.rgb_to_hls(*(v / 255.0 for v in c[:3]))[1] < 0.16


def _eye_colours():
    out = {_hex(v) for v in EYES_ONLY.values()}
    out |= {_hex(t["eyes"]) for _, t in BREEDS.values() if "eyes" in t}
    return out


## Every cell's eye pixels: a dark pixel (or one already painted an eye colour, so a re-run finds it again) inside the
## silhouette (all four neighbours filled, three of them coat, so not the outline) in the head: the top 40% of the figure and
## its front 40% (the sprites face right). Found on the source sheet, before a recolour darkens the coat round them.
def eye_mask(im, src, cell=24):
    px = im.load()
    painted = _eye_colours()
    found = []
    for cy in range(0, im.height, cell):
        for cx in range(0, im.width, cell):
            box = im.crop((cx, cy, cx + cell, cy + cell)).getchannel("A").getbbox()
            if not box:
                continue
            x0, y0, x1, y1 = box
            cands = []
            for y in range(cy + y0 + 1, cy + y0 + int((y1 - y0) * 0.4) + 1):
                for x in range(cx + x0 + int((x1 - x0) * 0.6), cx + x1 - 1):
                    c = px[x, y]
                    if c[3] == 0 or not (_dark(c) or c[:3] in painted):
                        continue
                    bright = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                                 if px[x + dx, y + dy][3] > 0 and not _dark(px[x + dx, y + dy]))
                    filled = all(px[x + dx, y + dy][3] > 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    if filled and bright >= 3:
                        cands.append((-bright, y - x, x, y))
            # At most MAX_EYES a cell: the most surrounded by coat, then the highest and most forward.
            found += [(x, y) for _, _, x, y in sorted(cands)[:MAX_EYES.get(src, 1)]]
    return found


def paint_eyes(im, mask, colour):
    px = im.load()
    eye = _hex(colour)
    for x, y in mask:
        px[x, y] = eye + (px[x, y][3],)
    return len(mask)


def recolor(breed):
    if breed in EYES_ONLY:
        path = os.path.join(DIR, breed + ".png")
        im = Image.open(path).convert("RGBA")
        print(breed, "eyes", paint_eyes(im, eye_mask(im, breed), EYES_ONLY[breed]))
        im.save(path)
        return
    src, table = BREEDS[breed]
    table = dict(table)
    eyes = table.pop("eyes", None)
    keys = [] if table.get("hue") else [(_hex(k), _hex(v)) for k, v in table.items()]
    im = Image.open(os.path.join(DIR, src + ".png")).convert("RGBA")
    mask = eye_mask(im, src) if eyes else []
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
    if eyes:
        print(breed, "eyes", paint_eyes(im, mask, eyes))
    out = os.path.join(DIR, breed + ".png")
    im.save(out)
    shutil.copyfile(os.path.join(DIR, src + ".png.json"), out + ".json")
    print("recoloured", src, "->", out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--breed", choices=sorted(BREEDS) + sorted(EYES_ONLY))
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()
    # The eyes-only sheets first: the recolours are made from them.
    for b in (sorted(EYES_ONLY) + sorted(BREEDS) if args.all else [args.breed]):
        recolor(b)


if __name__ == "__main__":
    main()
