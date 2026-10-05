"""Nature decor sets (decor batch 4): bushes, rocks, flowers and reeds, drawn clean (no AI) as pixel maps in the style
of the pasture animals (decor_animals) and the garden plants (decor_farm.PLANTS): flat tones in a fixed pattern, light
from the left, a 1 px outline (the reeds' blades excepted, see below). TownMap_Component3's bushes, boulders and reed tufts were tried as cuts first: at decor
size (a quarter of the sheet's) they come out soft and speckled, sampled texture with no outline, so these are drawn
from the procedural pieces at their size.

Greens are muted toward the batch 3 trees' (oak_1..3: lime highlights to deep green shade), between those and the
procedural ArtKit.OAK; vegetation takes a deep green outline (as the trees' and the garden plants'), the rocks the
shared convert.OUTLINE.

  bush_1     Decor.Kind.BUSH: DecorArt._bush(o, seed, 1.2) (PropArt.leafy, r 8.4 x 6.6 about 6.6 px up: ~20 x 15): a
  bush_2     mound of round leaf lobes, back to front, each shaded about its own centre and the whole mound lit from the
  bush_3     upper left; a front lobe throws a dark rim on the lobes behind it. bush_1 the full round mound; bush_2 a
             wider, lower one with a few cream blossoms (as the sheet's flowering bushes); bush_3 a smaller round one
             (~3/4: the floor's meadow shrubs, TownFloor._shrubs, r 4..7 x 3..5, draw these sets too). Laid out a
             little large and drawn at BUSH_SCALE (0.9).
  rock_1     Decor.Kind.ROCK: DecorArt._rock's blocky boulders (TownDecor footprint 28 x 18): each a block with a pale
  rock_2     top, a mid left face and a dark right face (TownFloor.PEBBLE spread to five steps), its own outline, a lit
  rock_3     front-left top edge, a crack, moss on some tops. rock_1 a big boulder and a small one in front; rock_2
             three; rock_3 one tall boulder and a pebble.
  flowers_1  Decor.Kind.FLOWERS: DecorArt._flowers (six 2 px blooms on 1 px stems over ~12 x 6): a low tuft of leaves
  flowers_2  with six or seven blooms, one colour a clump as the floor's procedural flowers (yellow, pink, cream with
  flowers_3  blue), each bloom lit on its top left. Colours are TownFloor.FLOWERS, muted under check_sprite_glow's rule.
  reeds_1    Decor.Kind.REEDS: DecorArt._reeds (twelve blades over 14 px, 12..26 px tall, a cattail on every third):
             blades 14..28 px here (they read shorter than the procedural's polygons once the town is zoomed out);
  reeds_2    a low base of short leaves, tall blades (2 px at the foot, then 1 px; each one tone, the tones taking turns
             blade by blade, back ones a step darker) and three cattails (brown, lit left column). Only the cattails take
             the outline: as the procedural reeds, the leaves have none (ringed, the blades read as black strokes and
             the tuft's foot as a dark line down the bank).

Each is anchored at the ground point (the procedural `o`): x 0 of the drawing, the outline row under its foot.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_nature.py [all | bush | rock | flowers | reeds] [--out <scratch dir>]
      (--out: write PNGs there, no manifest)
"""
import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
import decor_common  # noqa: E402

INK = tuple(int(v) for v in convert.OUTLINE)
# Leaves: highlight .. dark, muted toward the batch 3 oaks (68a613 / 51910f / 3e7b0f / 2f620c / 21560a) from ArtKit.OAK
# (6a9434 / 44702e / 2c4a27), and the deep green outline.
LEAF = ((106, 150, 40), (80, 126, 32), (58, 100, 28), (40, 74, 22), (26, 52, 18))
LEAF_INK = (14, 32, 12)
# Reeds: the same greens a little yellower (ArtKit.LEAF's reed blades), and the cattail browns.
REED = ((156, 176, 68), (122, 152, 50), (90, 122, 40), (64, 94, 32))
CATTAIL = ((132, 88, 50), (100, 64, 36), (74, 46, 28))
# Rock: TownFloor.PEBBLE (a8a49c / 8e8a82 / 76726c) spread to five steps: lit edge, top, left face, right face, crack.
STONE = ((196, 192, 182), (168, 164, 156), (142, 138, 130), (114, 110, 104), (86, 82, 78))
MOSS = ((132, 150, 58), (104, 124, 48), (80, 98, 40))
# Blooms (TownFloor.FLOWERS, muted under check_sprite_glow's rule): [lit, shade] per colour.
BLOOM = {
    "yellow": ((226, 196, 80), (196, 160, 58)),
    "pink": ((222, 128, 160), (184, 96, 126)),
    "cream": ((238, 232, 214), (204, 196, 176)),
    "blue": ((176, 206, 236), (132, 164, 204)),
}
LIGHT = (-0.55, -0.83)    # up and to the left


class Pix:
    """A pixel map in the procedural piece's coordinates: x right of the ground point, y up from it (negative); later
    puts cover earlier ones. Pixels put as ink stay ink (a part's own outline)."""

    def __init__(self, ink):
        self.px = {}
        self.ink = ink
        self.bare = set()   # pixels that take no outline of their own (a reed blade: ringed, it reads as a black stroke)

    def put(self, x, y, c, bare=False):
        k = (int(x), int(y))
        self.px[k] = tuple(int(v) for v in c)
        if bare:
            self.bare.add(k)
        else:
            self.bare.discard(k)

    def has(self, x, y):
        return (int(x), int(y)) in self.px

    def drop(self):
        """Shift it so its lowest pixel sits on y -1 (its outline on the ground row, y 0)."""
        dy = -1 - max(y for _, y in self.px)
        self.px = {(x, y + dy): c for (x, y), c in self.px.items()}
        self.bare = {(x, y + dy) for x, y in self.bare}
        return self

    def image(self):
        """Ring it with the outline (4-neighbours), crop; returns (image, anchor)."""
        xs = [p[0] for p in self.px]
        ys = [p[1] for p in self.px]
        x0, y0 = min(xs) - 1, min(ys) - 1
        w, h = max(xs) - x0 + 2, max(ys) - y0 + 2
        rgb = np.zeros((h, w, 3))
        al = np.zeros((h, w), bool)
        ringed = np.zeros((h, w), bool)
        for (x, y), c in self.px.items():
            rgb[y - y0, x - x0] = c
            al[y - y0, x - x0] = True
            ringed[y - y0, x - x0] = (x, y) not in self.bare
        p = np.pad(ringed, 1)
        ring = ~al & (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:])
        rgb[ring] = self.ink
        out = np.zeros((h, w, 4), np.uint8)
        out[..., :3] = np.round(rgb).astype(np.uint8)
        out[..., 3] = np.where(al | ring, 255, 0)
        return Image.fromarray(out, "RGBA"), (-x0, -y0)


def lit(x, y, cx, cy, rx, ry):
    """How much a point of an ellipse faces the light: -1 .. 1 (its rim most, its centre 0)."""
    nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
    n = math.hypot(nx, ny)
    if n < 1e-6:
        return 0.0
    return (LIGHT[0] * nx + LIGHT[1] * ny) / n * min(n, 1.0) ** 0.6


def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


def tone(v, steps):
    for k, s in enumerate(steps):
        if v > s:
            return k
    return len(steps)


# --- bushes -------------------------------------------------------------------------------------------------------------
# Lobes (cx, cy, rx, ry), back to front. The mound's own centre and radii shade it as a whole.
BUSHES = {
    "bush_1": dict(
        lobes=((-2.5, -12.0, 3.6, 3.0), (3.5, -11.5, 3.6, 3.0), (-6.5, -8.5, 3.4, 3.0), (0.5, -9.0, 3.8, 3.2),
               (7.0, -8.0, 3.2, 3.0), (-4.0, -5.0, 3.8, 3.2), (3.5, -5.0, 3.8, 3.2), (-0.5, -3.0, 3.6, 2.6)),
        mound=(0.0, -7.5, 10.0, 7.0), blossoms=()),
    "bush_2": dict(
        lobes=((-4.0, -9.5, 3.8, 3.0), (3.0, -10.0, 3.8, 3.0), (-8.5, -6.0, 3.2, 2.8), (9.0, -6.0, 3.2, 2.8),
               (-1.0, -7.0, 3.8, 3.0), (-5.0, -3.5, 3.8, 2.8), (4.5, -3.5, 3.8, 2.8)),
        mound=(0.0, -6.0, 12.0, 6.0),
        blossoms=((-5, -11), (2, -12), (-8, -7), (-2, -8), (5, -8), (-5, -4))),
    "bush_3": dict(
        lobes=((-2.5, -8.5, 3.2, 2.6), (3.0, -8.0, 3.2, 2.6), (-4.0, -4.5, 3.2, 2.8), (3.5, -4.5, 3.2, 2.8),
               (0.0, -3.0, 3.4, 2.4)),
        mound=(0.0, -5.5, 7.5, 5.5), blossoms=()),
}


# The lobes above are laid out a little over DecorArt._bush's size; drawn at 0.9 (bush_1 ~ 20 x 15 inside its outline).
BUSH_SCALE = 0.9


def bush(name):
    spec = BUSHES[name]
    p = Pix(LEAF_INK)
    k = BUSH_SCALE
    mcx, mcy, mrx, mry = (v * k for v in spec["mound"])
    for i, (cx, cy, rx, ry) in enumerate(tuple(v * k for v in lobe) for lobe in spec["lobes"]):
        x0, x1 = int(math.floor(cx - rx - 1)), int(math.ceil(cx + rx + 1))
        y0, y1 = int(math.floor(cy - ry - 1)), int(math.ceil(cy + ry + 1))
        if i:
            # the lobe's shadow on the lobes behind it: its rim, a pixel down and right, in the darkest leaf
            for y in range(y0, y1 + 2):
                for x in range(x0, x1 + 2):
                    if p.has(x, y) and in_ellipse(x, y, cx + 0.8, cy + 1.0, rx + 0.6, ry + 0.6) \
                            and not in_ellipse(x, y, cx, cy, rx, ry):
                        p.put(x, y, LEAF[4])
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if not in_ellipse(x, y, cx, cy, rx, ry):
                    continue
                v = 0.8 * lit(x, y, cx, cy, rx, ry) + 0.6 * lit(x, y, mcx, mcy, mrx, mry)
                p.put(x, y, LEAF[tone(v, (0.8, 0.35, -0.1, -0.6))])
        # a leaf tick: two highlight pixels on the lobe's lit shoulder, a dark notch under its lower right
        hx, hy = int(round(cx - rx * 0.45)), int(round(cy - ry * 0.5))
        if lit(hx, hy, mcx, mcy, mrx, mry) > -0.3:
            p.put(hx, hy, LEAF[0])
            p.put(hx + 1, hy, LEAF[1])
        nx, ny = int(round(cx + rx * 0.4)), int(round(cy + ry * 0.45))
        p.put(nx, ny, LEAF[4])
    for bx, by in ((int(round(x * k)), int(round(y * k))) for x, y in spec["blossoms"]):
        lit_side = lit(bx, by, mcx, mcy, mrx, mry) > -0.15
        c = BLOOM["cream"]
        p.put(bx, by, c[0] if lit_side else c[1])
        p.put(bx + 1, by, c[1])
    return p.drop().image()


# --- rocks --------------------------------------------------------------------------------------------------------------
# A boulder (DecorArt._rock's block): its ground centre (x, y), half width a, height h, the top's jitter (left, back,
# right, front corners, y), moss (True / False). Back boulders first.
ROCKS = {
    "rock_1": (((-1, -1, 8, 10, (0, -1, 1, 0)), True), ((7, 2, 5, 6, (1, 0, -1, 0)), False)),
    "rock_2": (((-6, -2, 6, 8, (1, 0, 0, 1)), False), ((5, -3, 6, 9, (0, -1, 1, 0)), True),
               ((0, 2, 5, 6, (0, 0, 1, 0)), False)),
    "rock_3": (((0, -1, 7, 13, (1, -1, 0, 0)), True), ((-9, 2, 3, 3, (0, 0, 0, 0)), False)),
}


def _poly_mask(pts, w, h, off):
    im = Image.new("L", (w, h), 0)
    ImageDraw.Draw(im).polygon([(x + off, y + off) for x, y in pts], fill=1)
    return np.array(im, bool)


def _chamfer(pts, cuts):
    """The polygon with each corner cut `cuts[k]` px back along both its edges."""
    out = []
    n = len(pts)
    for k, (x, y) in enumerate(pts):
        c = cuts[k]
        for q in (pts[k - 1], pts[(k + 1) % n]):
            dx, dy = q[0] - x, q[1] - y
            d = math.hypot(dx, dy)
            f = min(c / d, 0.45) if d else 0.0
            out.append((x + dx * f, y + dy * f))
    # each corner gave (toward prev, toward next): in order around the polygon
    return out


def rock(name):
    p = Pix(INK)
    W = H = 96
    OFF = 48
    for (cx, cy, a, hgt, jit), moss in ROCKS[name]:
        top_y = cy - hgt
        tl = (cx - a, top_y + jit[0])
        tb = (cx, top_y - a // 2 + jit[1])
        tr = (cx + a, top_y + jit[2])
        tf = (cx, top_y + a // 2 + jit[3])
        bl = (tl[0], cy)
        br = (tr[0], cy)
        bf = (cx, cy + a // 2)
        # the silhouette, its outer corners cut (a boulder, not a box); each face is the silhouette's share of it
        sil = _poly_mask(_chamfer((tl, tb, tr, br, bf, bl), (2, 2, 2, 2, 1, 2)), W, H, OFF)
        faces = {
            "left": _poly_mask((tl, tf, bf, bl), W, H, OFF) & sil,
            "right": _poly_mask((tf, tr, br, bf), W, H, OFF) & sil,
            "top": _poly_mask((tl, tb, tr, tf), W, H, OFF) & sil,
        }
        body = faces["left"] | faces["right"] | faces["top"]
        pad = np.pad(body, 1)
        ring = ~body & (pad[:-2, 1:-1] | pad[2:, 1:-1] | pad[1:-1, :-2] | pad[1:-1, 2:])
        for j, i in zip(*np.nonzero(ring)):
            p.put(i - OFF, j - OFF, INK)
        for key, col in (("left", STONE[2]), ("right", STONE[3]), ("top", STONE[1])):
            for j, i in zip(*np.nonzero(faces[key])):
                p.put(i - OFF, j - OFF, col)
        # the lit edge: the top's front-left edge (tl to tf), a pixel inside the top
        top = faces["top"]
        for j, i in zip(*np.nonzero(top)):
            x, y = i - OFF, j - OFF
            if not top[j + 1, i] or not top[j, i - 1]:
                if x <= cx:
                    p.put(x, y, STONE[0])
        # the face edge: the left and right faces meet at a darker seam under the front corner
        for y in range(int(tf[1]) + 2, int(bf[1])):
            p.put(cx, y, STONE[3])
        # a crack down the left face, a short one on the right
        lx = cx - max(2, a // 2)
        for k in range(min(4, hgt - 2)):
            p.put(lx + (k // 2), int(tl[1]) + 3 + k, STONE[4])
        if a >= 5:
            for k in range(min(3, hgt - 3)):
                p.put(cx + a // 2 + 1, int(tf[1]) + 3 + k + (k // 2), STONE[4])
        if moss:
            mx, my = cx - 1, (tb[1] + tf[1]) / 2.0
            for y in range(int(my) - 2, int(my) + 3):
                for x in range(int(mx - a * 0.5) - 1, int(mx + a * 0.5) + 2):
                    if top[y + OFF, x + OFF] and in_ellipse(x, y, mx, my, a * 0.5, 2.0):
                        v = lit(x, y, mx, my, a * 0.5, 2.0)
                        p.put(x, y, MOSS[0] if v > 0.3 else MOSS[1] if v > -0.3 else MOSS[2])
    return p.image()


# --- flowers ------------------------------------------------------------------------------------------------------------
# Leaf tufts (x, height), then blooms (x, y of the bloom's top-left, colour), all in a fixed layout.
FLOWERS = {
    "flowers_1": dict(tufts=((-5, 3), (-3, 4), (-1, 3), (1, 4), (3, 3), (5, 4), (0, 2)),
                      blooms=((-6, -6, "yellow"), (-2, -7, "yellow"), (2, -6, "yellow"), (5, -7, "yellow"),
                              (-4, -4, "yellow"), (3, -4, "cream"))),
    "flowers_2": dict(tufts=((-6, 3), (-4, 4), (-2, 3), (0, 4), (2, 3), (4, 4), (6, 3)),
                      blooms=((-5, -7, "pink"), (-1, -8, "pink"), (3, -7, "pink"), (6, -5, "pink"),
                              (-7, -4, "pink"), (1, -5, "pink"), (-3, -4, "cream"))),
    "flowers_3": dict(tufts=((-5, 3), (-3, 4), (-1, 3), (1, 4), (3, 3), (5, 3)),
                      blooms=((-5, -6, "cream"), (-1, -7, "blue"), (3, -6, "cream"), (5, -4, "blue"),
                              (-3, -4, "blue"), (1, -4, "cream"))),
}


def flowers(name):
    spec = FLOWERS[name]
    p = Pix(LEAF_INK)
    # the tuft: a low mound of leaves (lit left), then leaf blades up from it
    for y in range(-3, 0):
        for x in range(-7, 8):
            if in_ellipse(x, y, 0.5, 0.0, 6.6, 2.6):
                v = lit(x, y, 0.5, -0.5, 6.6, 2.6)
                c = LEAF[1] if v > 0.3 else LEAF[2] if v > -0.3 else LEAF[3]
                if (x - y) % 3 == 0 and v > -0.3:      # leaf tips: a fixed hatch
                    c = LEAF[0] if v > 0.3 else LEAF[1]
                p.put(x, y, c)
    for x, h in spec["tufts"]:
        for k in range(h):
            p.put(x + (1 if k == h - 1 and x > 0 else -1 if k == h - 1 and x < 0 else 0), -2 - k,
                  LEAF[1] if x < 0 else LEAF[2])
    for bx, by, col in spec["blooms"]:
        c = BLOOM[col]
        # its stem down to the tuft
        for y in range(by + 2, -2):
            if not p.has(bx, y):
                p.put(bx, y, LEAF[2])
        p.put(bx, by, c[0])
        p.put(bx + 1, by, c[0])
        p.put(bx, by + 1, c[0])
        p.put(bx + 1, by + 1, c[1])
    return p.drop().image()


# --- reeds --------------------------------------------------------------------------------------------------------------
# Blades (foot x, height, lean, back: drawn darker), back first; cattails (blade index); the base mound's half width.
REEDS = {
    "reeds_1": dict(blades=((-5, 22, -2, True), (2, 26, 1, True), (6, 20, 2, True), (-2, 28, 0, False),
                            (-7, 18, -3, False), (4, 24, 2, False), (0, 21, -1, False), (-4, 15, -2, False),
                            (7, 14, 3, False)),
                    cattails=(1, 3, 5)),
    "reeds_2": dict(blades=((-3, 25, -1, True), (5, 22, 2, True), (-7, 18, -2, True), (1, 28, 1, False),
                            (-5, 21, -2, False), (6, 16, 3, False), (-1, 17, 0, False), (3, 20, 1, False)),
                    cattails=(0, 3, 4)),
}


# The reed base's leaf heights, left to right (a fixed pattern).
BASE_H = (2, 3, 2, 4, 2, 3, 4, 3, 4, 2, 3, 2, 4, 2, 3)


def reeds(name):
    spec = REEDS[name]
    p = Pix(LEAF_INK)
    tips = []
    for i, (fx, h, lean, back) in enumerate(spec["blades"]):
        tip = (fx + lean, -h)
        tips.append(tip)
        for k in range(h):
            t = k / max(h - 1, 1)
            x = int(round(fx + lean * t * t))
            y = -1 - k
            # blades are bare (no outline): ringed, a 1 px blade reads as a black stroke along the bank. Each blade
            # one tone, the tones taking turns blade by blade (as DecorArt._reeds' ArtKit.LEAF[i % 3]), so the stalks
            # stay apart when the town is drawn zoomed out; back blades a step darker.
            c = REED[min(i % 3 + (1 if back else 0), 3)]
            p.put(x, y, c, bare=True)
            if t < 0.4:    # 2 px at the foot
                p.put(x + 1, y, c, bare=True)
    for i in spec["cattails"]:
        tx, ty = tips[i]
        for k in range(5):
            y = ty + 2 + k
            p.put(tx, y, CATTAIL[0])
            p.put(tx + 1, y, CATTAIL[1] if k < 4 else CATTAIL[2])
    # the base: a tuft of short leaves fanning out over the blades' feet (fixed heights, outer ones leaning out),
    # lit on the left
    for x in range(-7, 8):
        h = BASE_H[(x + 7) % len(BASE_H)]
        for k in range(h):
            t = k / max(h - 1, 1)
            xx = x + int(round((x / 7.0) * 2.0 * t))
            c = REED[3] if k == 0 else (REED[1] if x < 0 else REED[2]) if t < 0.8 else (REED[0] if x < 0 else REED[1])
            if not (k > 1 and p.has(xx, -1 - k) and p.px[(xx, -1 - k)] in CATTAIL):
                p.put(xx, -1 - k, c, bare=True)
    return p.drop().image()


SETS = {
    "bush": lambda: [(n, *bush(n)) for n in BUSHES],
    "rock": lambda: [(n, *rock(n)) for n in ROCKS],
    "flowers": lambda: [(n, *flowers(n)) for n in FLOWERS],
    "reeds": lambda: [(n, *reeds(n)) for n in REEDS],
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
            print("%-10s %dx%d anchor %s -> %s" % (name, img.width, img.height, anchor, path))


if __name__ == "__main__":
    main()
