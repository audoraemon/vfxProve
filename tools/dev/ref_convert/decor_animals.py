"""Pasture animal decor sets (decor batch 4), drawn clean (no AI) as pixel maps in the style of the scarecrow
(decor_farm.scarecrow): flat tones in a fixed pattern, light from the left, ringed with the 1 px outline
(convert.OUTLINE). The reference sheets' only animals (TownMap_Component3's pasture cows, ~25 px, sampled texture) come
out as speckle at this size, so these are drawn from DecorArt._sheep / DecorArt._cow at their size; cow_2 takes the
reference's pied coat.

Each faces right (its head at +x), lit from the left; DecorSprites.MIRRORED draws half the seeds flipped, anchored at
the mirrored ground point (so those are lit from the right, as the procedural animals, which do not shade by facing).

  sheep_1   Decor.Kind.SHEEP standing, head up (DecorArt._sheep: a wool cloud on four thin legs, a pale face under a
            wool cap, its ear back).
  sheep_2   Decor.Kind.SHEEP grazing, its head down at the grass.
  cow_1     Decor.Kind.COW: DecorArt._cow (a deep brown barrel with a white belly and flank patch on four legs, the head
            raised at the front, horns, a pale muzzle), tail hanging at the rump.
  cow_2     Decor.Kind.COW pied, as the reference's cows: white with dark brown patches, its head held level.

Anchored at the ground point (the procedural `o`): x 0 of the drawing, the row under the hooves.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_animals.py [all | sheep | cow] [--out <scratch dir>]
      (--out: write PNGs there, no manifest)
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
import decor_common  # noqa: E402

OUTLINE = tuple(int(v) for v in convert.OUTLINE)

# Sheep: wool lit to dark (DecorArt._sheep's wool ece6da / shade c9bfb0 spread to five steps), its face and legs
# (skin dcc0b4), hooves (3a3230), eye (2a2220).
WOOL = ((248, 245, 236), (234, 229, 216), (214, 207, 191), (188, 179, 162), (156, 146, 132))
SKIN = ((232, 208, 196), (214, 186, 172), (182, 152, 140), (150, 122, 112))
HOOF = (58, 50, 48)
EYE = (42, 34, 32)

# Cow: DecorArt._cow's hide (7a4a2c) lit to dark, the patch (f0ead8) and its shade, muzzle (d8a898), horns (e8e0c8).
HIDE = ((150, 96, 62), (122, 74, 44), (98, 58, 34), (72, 42, 26))
# cow_2's patches: the reference's dark brown, lit to dark.
PIED = ((96, 64, 50), (74, 48, 38), (56, 36, 30))
WHITE = ((244, 240, 228), (226, 220, 204), (200, 192, 176), (168, 160, 146))
MUZZLE = ((226, 184, 168), (200, 156, 142))
HORN = ((236, 228, 206), (196, 186, 160))
COW_HOOF = (42, 34, 28)


class Pix:
    """A pixel map in the procedural animal's coordinates: x right of the ground point, y up from it (negative); later
    puts cover earlier ones."""

    def __init__(self):
        self.px = {}

    def put(self, x, y, c):
        self.px[(int(x), int(y))] = tuple(int(v) for v in c)

    def rect(self, x0, y0, w, h, fn):
        for j in range(h):
            for i in range(w):
                self.put(x0 + i, y0 + j, fn(i, j) if callable(fn) else fn)

    def stamp(self, x0, y0, rows, cmap):
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != ".":
                    self.put(x0 + i, y0 + j, cmap[ch])

    def image(self):
        """Ring it with the outline (4-neighbours), crop; returns (image, anchor)."""
        xs = [p[0] for p in self.px]
        ys = [p[1] for p in self.px]
        x0, y0 = min(xs) - 1, min(ys) - 1
        w, h = max(xs) - x0 + 2, max(ys) - y0 + 2
        rgb = np.zeros((h, w, 3))
        al = np.zeros((h, w), bool)
        for (x, y), c in self.px.items():
            rgb[y - y0, x - x0] = c
            al[y - y0, x - x0] = True
        p = np.pad(al, 1)
        ring = ~al & (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:])
        rgb[ring] = OUTLINE
        out = np.zeros((h, w, 4), np.uint8)
        out[..., :3] = np.round(rgb).astype(np.uint8)
        out[..., 3] = np.where(al | ring, 255, 0)
        # the ground point: x 0's left edge, the row under the hooves (y 0)
        return Image.fromarray(out, "RGBA"), (-x0, -y0)


def lit(x, y, cx, cy, rx, ry):
    """How much a point of an ellipse faces the light (up and to the left): -1 .. 1."""
    nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    n = max((nx * nx + ny * ny) ** 0.5, 1e-6)
    return (-0.55 * nx - 0.83 * ny) / max(n, 0.35) * min(n, 1.0) ** 0.5


def tone(v, steps):
    """A light value to a tone index (0 lit .. len(steps)): `steps` are the thresholds, high to low."""
    for k, s in enumerate(steps):
        if v > s:
            return k
    return len(steps)


# --- sheep --------------------------------------------------------------------------------------------------------------
# Wool: a body ellipse with curly bumps along its back and rump; each bump shaded about its own centre, so the back
# reads as tufts.
SHEEP_BODY = (-1.0, -14.5, 10.5, 5.5)
SHEEP_BUMPS = ((-9.0, -18.0, 3.4), (-5.0, -20.5, 3.6), (-0.5, -21.0, 3.6), (4.0, -20.0, 3.5), (7.5, -17.0, 3.2),
               (-11.0, -13.5, 3.0), (-6.5, -10.5, 3.0), (5.0, -10.5, 3.0))
CURLS = ((-6, -17), (-2, -18), (2, -17), (-4, -14), (0, -14), (4, -14), (-8, -13), (6, -17))

HEAD_UP = [   # facing right; w wool cap, F/f/g face lit/mid/shade, e eye, n nostril, E ear
    "...hWw...",
    "..hWWws..",
    "EEwWwsFF.",
    ".EfFFFFFF",
    "..fFFeFFF",
    "..fFFFFFF",
    "..gfFFFnF",
    "...gfFFF.",
    "....ggf..",
]
HEAD_DOWN = [  # grazing: the head hangs forward from the shoulder, its muzzle at the grass
    ".hWw....",
    "hWWws...",
    "wWwsEE..",
    "fFFFFE..",
    "fFFeFFF.",
    "gfFFFFF.",
    ".gfFFFF.",
    "..gfFnF.",
    "...gff..",
]


def sheep_cmap():
    return {"h": WOOL[0], "W": WOOL[1], "w": WOOL[2], "s": WOOL[3], "F": SKIN[0], "f": SKIN[1], "g": SKIN[2],
            "E": SKIN[2], "e": EYE, "n": SKIN[3]}


def sheep(grazing):
    p = Pix()
    # legs: far pair (shaded) behind, near pair (lit left column) in front; 2 px, hooves the bottom two rows
    legs = ((-4, False), (6, False), (-8, True), (3, True))
    for x, near in legs:
        if grazing and x > 0:
            x += 1                       # the forelegs step out under the lowered head
        for y in range(-10, 0):
            if y >= -2:
                p.put(x, y, HOOF)
                p.put(x + 1, y, HOOF)
            elif near:
                p.put(x, y, SKIN[1])
                p.put(x + 1, y, SKIN[2])
            else:
                p.put(x, y, SKIN[2])
                p.put(x + 1, y, SKIN[3])
    cx, cy, rx, ry = SHEEP_BODY
    for y in range(-30, 0):
        for x in range(-16, 16):
            parts = []
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                parts.append(lit(x, y, cx, cy, rx, ry))
            for bx, by, r in SHEEP_BUMPS:
                if (x + 0.5 - bx) ** 2 + (y + 0.5 - by) ** 2 <= r * r:
                    # a tuft is shaded about its own centre (its lit top-left, its shaded rim), dimmed by where it
                    # sits on the body
                    parts.append(0.6 * lit(x, y, bx, by, r, r) + 0.4 * lit(x, y, cx, cy, rx, ry))
            if not parts:
                continue
            k = tone(max(parts), (0.55, 0.15, -0.3, -0.65))
            if (x, y) in CURLS and k < 3:
                k += 1
            p.put(x, y, WOOL[min(k, 4)])
    cm = sheep_cmap()
    if grazing:
        p.stamp(9, -14, HEAD_DOWN, cm)
    else:
        p.stamp(7, -27, HEAD_UP, cm)
    return p.image()


# --- cows ---------------------------------------------------------------------------------------------------------------
# Body box (DecorArt._cow: x -15..13, rows -33..-14), its corners rounded.
COW_X0, COW_X1, COW_Y0, COW_Y1 = -15, 13, -33, -14


def cow_body_tone(x, y):
    """0 lit .. 3 dark: the top and the rump (left end) lit, the belly and the chest (right end) shaded."""
    if y <= COW_Y0 + 1:
        return 0
    if x <= COW_X0 + 1:
        return 0 if y < COW_Y1 - 4 else 1
    if y >= COW_Y1 - 2 or x >= COW_X1 - 1:
        return 2
    return 1


def in_cow_body(x, y):
    """The body box with its four corners cut (two px along each edge)."""
    if not (COW_X0 <= x <= COW_X1 and COW_Y0 <= y <= COW_Y1):
        return False
    edge_x = x <= COW_X0 or x >= COW_X1
    edge_y = y <= COW_Y0 or y >= COW_Y1
    near_x = x <= COW_X0 + 1 or x >= COW_X1 - 1
    near_y = y <= COW_Y0 + 1 or y >= COW_Y1 - 1
    return not ((edge_x and near_y) or (edge_y and near_x))


# Heads in profile, facing right and sloping down to the muzzle: H/h horn, E ear, a/b/c face lit/mid/dark, e eye,
# M/m muzzle, n nostril.
COW_HEAD = [
    ".Hh.......",
    "..Hh......",
    "EEaaab....",
    "EEaaaab...",
    ".baeaaab..",
    ".baaaaaab.",
    "..baaaaaab",
    "...baaaMMM",
    "....bbMMnM",
    ".....bMmmm",
    "......mmm.",
]


def cow(pied):
    p = Pix()
    coat = WHITE if pied else HIDE
    spot = PIED if pied else WHITE
    # legs: 3 px; far pair (darker) behind, near pair in front; hooves the bottom two rows
    for x, near in ((-12, False), (7, False), (-8, True), (11, True)):
        for y in range(-16, 0):
            for i in range(3):
                if y >= -2:
                    c = COW_HOOF
                elif pied:
                    c = (WHITE[1] if i == 0 else WHITE[2]) if near else (WHITE[2] if i == 0 else WHITE[3])
                else:
                    c = (HIDE[1] if i == 0 else HIDE[2]) if near else (HIDE[2] if i == 0 else HIDE[3])
                p.put(x - 1 + i, y, c)
    # the body
    for y in range(COW_Y0, COW_Y1 + 1):
        for x in range(COW_X0, COW_X1 + 1):
            if in_cow_body(x, y):
                p.put(x, y, coat[cow_body_tone(x, y)])
    # patches: fixed shapes, each lit on its top-left
    if pied:
        patches = [
            [(-14, -32), "..XXXX....", ".XXXXXXX..", "XXXXXXXX..", "XXXXXXX...", "XXXXXX....", ".XXXX....."],
            [(-2, -33), "...XXXXXX", ".XXXXXXXX", "XXXXXXXX.", "XXXXXX...", ".XXXX...."],
            [(-7, -24), "..XXXX.", ".XXXXXX", "XXXXXXX", "XXXXXX.", ".XXX..."],
            [(6, -26), ".XXXX", "XXXXX", "XXXXX", ".XXX."],
        ]
    else:
        patches = [
            [(-7, -31), "..XXXXX.", ".XXXXXXX", "XXXXXXX.", "XXXXXX..", ".XXXXX..", "..XXXX..", "...XX..."],
            [(-10, -18), "...XXXXXXXXXXXX....", ".XXXXXXXXXXXXXXXXX.", "XXXXXXXXXXXXXXXXXX."],
        ]
    for (px0, py0), *rows in patches:
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                x, y = px0 + i, py0 + j
                if ch == "X" and in_cow_body(x, y):
                    top = j == 0 or rows[j - 1][i] != "X" or i == 0 or row[i - 1] != "X"
                    under = y >= COW_Y1 - 1 or x >= COW_X1 - 1
                    p.put(x, y, spot[2] if under else spot[0] if top else spot[1])
    # the tail: down the rump from its top, a dark tuft at the end
    for y in range(-31, -18):
        p.put(COW_X0 - 1, y, coat[2] if pied else HIDE[2])
    for y in range(-19, -16):
        p.put(COW_X0 - 1, y, PIED[2] if pied else HIDE[3])
        p.put(COW_X0 - 2, y, PIED[1] if pied else HIDE[3])
    # neck and head
    cm = {"a": coat[1], "b": coat[2], "c": coat[3], "E": coat[2], "H": HORN[0], "h": HORN[1], "M": MUZZLE[0],
          "m": MUZZLE[1], "e": EYE, "n": (150, 104, 96)}
    if pied:
        cm.update({"a": WHITE[1], "b": PIED[1], "c": PIED[2], "E": PIED[1]})
    if pied:
        # level: a thick neck forward from the shoulder, the head held at the body's top
        for y in range(-33, -24):
            for x in range(10 + (y + 33) // 3, 18):
                p.put(x, y, coat[0] if x == 10 + (y + 33) // 3 else coat[2] if y >= -26 else coat[1])
        p.stamp(14, -38, COW_HEAD, cm)
    else:
        # raised: a thick neck climbing from the shoulder to the head
        for y in range(-38, -29):
            t = (y + 38) / 8.0
            xl = int(round(14 - 6 * t))
            xr = int(round(18 - 4 * t))
            for x in range(xl, xr + 1):
                p.put(x, y, HIDE[0] if x == xl else HIDE[2] if x >= xr - 1 else HIDE[1])
        p.stamp(13, -44, COW_HEAD, cm)
    return p.image()


SETS = {
    "sheep": lambda: [("sheep_1",) + sheep(False), ("sheep_2",) + sheep(True)],
    "cow": lambda: [("cow_1",) + cow(False), ("cow_2",) + cow(True)],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("which", nargs="?", default="all", choices=["all"] + list(SETS))
    ap.add_argument("--out")
    args = ap.parse_args()
    for key in SETS if args.which == "all" else [args.which]:
        for name, img, anchor in SETS[key]():
            if args.out:
                Path(args.out).mkdir(parents=True, exist_ok=True)
                path = Path(args.out) / (name + ".png")
                img.save(path)
            else:
                path = decor_common.write_set(name, img, anchor)
            print("%-8s %dx%d anchor %s -> %s" % (name, img.width, img.height, anchor, path))


if __name__ == "__main__":
    main()
