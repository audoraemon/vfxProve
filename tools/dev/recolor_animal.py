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
    # A white cat with pale blue eyes, and a brown tabby (its stripes a dark brown, its belly cream).
    "white_cat": ("tabby", {"hue": True, "warm": ("b4b0aa", "f4f2ec"), "pale": ("d8d6d0", "ffffff"),
                            "eyes": "68a8d8"}),
    "brown_cat": ("tabby", {"hue": True, "warm": ("3a2818", "9a7450"), "pale": ("b8a080", "f0e4cc")}),
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


## A source sheet whose eyes alone change (its own coat stays): the hound's dark eye on its dark brown head goes amber;
## the terrier's (dark, but missing in some PixelLab frames and blue in its back walk) is set the same in every frame.
EYES_ONLY = {"hound": "e0a048", "terrier": "140a06", "wolfhound": "e0a048", "spaniel": "e0a048"}


def _dark(c):
    return colorsys.rgb_to_hls(*(v / 255.0 for v in c[:3]))[1] < 0.16


## The eyes, placed by hand on the still poses of the raw PixelLab sheet (cell-local pixels): the south-east still
## (sheet cell 0,0) and the north-east one (cell 1,0). Every clip is tracked from them (eye_mask).
EYES_AT = {
    "hound": {"se": [(13, 9)], "ne": [(15, 7)]},
    "terrier": {"se": [(16, 9)], "ne": [(16, 8)]},
    "wolfhound": {"se": [(14, 8)], "ne": [(14, 6)]},
    "spaniel": {"se": [(14, 9)], "ne": [(16, 8)]},
    "tabby": {"se": [(13, 10), (15, 10)], "ne": []},  # turned away: no eyes show
}
## Sheet rows (make_animal_sheet.ROWS) drawn from the north-east view: the back walk.
NE_ROWS = (2,)
## By source sheet: from which frame of a clip (sheet row) the eyes are shut, so it gets none: the dog asleep in its lie
## clip (row 9), the cat yawning and stretching in its bark row (row 6).
SHUT_FROM = {"hound": {9: 3}, "terrier": {9: 3}, "wolfhound": {9: 3}, "spaniel": {9: 3}, "tabby": {6: 2}}
## Frames where the track is a pixel off what PixelLab drew, set by hand: (sheet row, frame) -> cell-local eye pixels.
## The terrier's walk away: its own (blue) eye sits at 16,7.
OVERRIDES = {"terrier": {(2, 0): [(16, 7)], (2, 1): [(16, 7)], (2, 2): [(16, 7)], (2, 3): [(16, 7)]}}
## How far the head may move between two frames, and the patch round the eyes that is matched.
STEP = 3
PATCH = (4, 3, 4, 3)  # left, up, right, down of the eyes' box

_masks = {}


def _px(px, w, h, x, y):
    return px[x, y] if 0 <= x < w and 0 <= y < h else (0, 0, 0, 0)


## How unlike the patch round `eyes` in cell `a` is the same patch moved by (dx, dy) in cell `b` (all sheet pixels).
def _cost(px, w, h, a, b, eyes, dx, dy):
    xs = [x for x, _ in eyes]
    ys = [y for _, y in eyes]
    total = 0
    for y in range(min(ys) - PATCH[1], max(ys) + PATCH[3] + 1):
        for x in range(min(xs) - PATCH[0], max(xs) + PATCH[2] + 1):
            p = _px(px, w, h, a[0] + x, a[1] + y)
            q = _px(px, w, h, b[0] + x + dx, b[1] + y + dy)
            if p[3] == 0 and q[3] == 0:
                continue
            if (p[3] == 0) != (q[3] == 0):
                total += 400
            else:
                total += abs(p[0] - q[0]) + abs(p[1] - q[1]) + abs(p[2] - q[2])
    return total


## The shift of the head from cell a to cell b: the best match of the patch round the eyes, the smaller move on a tie.
def _track(px, w, h, a, b, eyes):
    best = None
    for dy in range(-STEP, STEP + 1):
        for dx in range(-STEP, STEP + 1):
            c = (_cost(px, w, h, a, b, eyes, dx, dy), abs(dx) + abs(dy), dx, dy)
            if best is None or c < best:
                best = c
    return best[2], best[3]


## The eye pixels of every frame (sheet pixels), on the source sheet before any recolour: each clip starts from the
## still pose of its view (EYES_AT) and follows the head frame to frame (_track), so the eyes stay on the face as it
## walks, bites, sniffs or lies down. An eye that lands on the outline or off the figure steps to the nearest coat pixel;
## frames with the eyes shut (SHUT_FROM) get none. Worked out once per source, so its recolours share it.
def eye_mask(im, src, cell=24):
    if src in _masks:
        return _masks[src]
    px = im.load()
    w, h = im.size
    at = EYES_AT[src]
    shut = SHUT_FROM.get(src, {})
    found = []

    def opaque(cx, cy):
        return im.crop((cx, cy, cx + cell, cy + cell)).getchannel("A").getbbox() is not None

    def settle(cx, cy, eyes):
        out = []
        for x, y in eyes:
            for ox, oy in ((0, 0), (-1, 0), (0, 1), (0, -1), (1, 0), (-1, 1), (-1, -1), (1, 1), (1, -1)):
                gx, gy = cx + x + ox, cy + y + oy
                # Inside the figure: it and its four neighbours filled, so not on the outline's edge.
                if all(_px(px, w, h, gx + a, gy + b)[3] > 0 for a, b in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1))):
                    out.append((x + ox, y + oy))
                    break
            else:
                out.append((x, y))  # nowhere better: keep it, so the track goes on
        return out

    for row in range(h // cell):
        cy = row * cell
        if row == 0:
            found += [(x, y) for x, y in at["se"]] + [(cell + x, y) for x, y in at["ne"]]
            continue
        view = "ne" if row in NE_ROWS else "se"
        ref = (cell if view == "ne" else 0, 0)
        eyes = list(at[view])
        if not eyes:
            continue  # a view that shows none
        prev = ref
        for col in range(w // cell):
            cx = col * cell
            if not opaque(cx, cy):
                break
            dx, dy = _track(px, w, h, prev, (cx, cy), eyes)
            eyes = settle(cx, cy, [(x + dx, y + dy) for x, y in eyes])
            prev = (cx, cy)
            fixed = OVERRIDES.get(src, {}).get((row, col))
            if fixed:
                eyes = list(fixed)
            if col < shut.get(row, 999):
                found += [(cx + x, cy + y) for x, y in eyes]
    _masks[src] = found
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
