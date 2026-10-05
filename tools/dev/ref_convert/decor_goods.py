"""Goods decor sets (decor batch 4), built locally (no AI): DecorArt's barrels, crates, benches, tables, log piles,
carts and signpost, drawn clean.

Cutting them from the sheets (TownMap_Component1..3: the crates and barrels by the sacks, the benches and tables of the
stall goods row, the carts row, Component3's signpost and logs) at the procedural sizes gives mottled brown noise:
the sheet's grain and shading survive the downscale as speckle, and the logs and signpost bring their grass along.
So every set is drawn on a fixed pattern instead, lit from the left, in the sheet barrel's wood tones (its lightness
quintiles, muted toward the town's timber like the drawn dock: bridges.DOCK_SAT, DOCK_VAL) with a 1 px dark outline.

  barrel_1  Decor.Kind.BARREL. A pixel map: a lid with a light rim, staves in a fixed light-to-dark pattern, two
            iron hoops. 12 x 15 px (the procedural barrel is 10 x 13), anchored at the middle of its base row.
  barrel_2  BARREL's other variant: a taller cask that bulges between three hoops. 12 x 16 px.
  crates_1  Decor.Kind.CRATES, one crate: a box 5/16 units a side, 7 px tall: board sides (light rail and corner
            posts, a dark seam halfway), a lid with one seam. Anchored at its front (bottom) corner, as DecorArt._crate stands `at` (the crate runs back
            from it).
  crates_2  CRATES' other variant, the procedural stack: the same crate with a smaller one (4/16, 6 px) on top,
            toward the back.
  bench_x   Decor.Kind.BENCH running along ground x (down-right on screen): a plank seat 11/16 units long on two
  bench_y   trestle legs; bench_y the same along ground y (down-left), its long side the shaded one. Anchored at the
            run's back end (the bench's `at`), segment 0.7 (TownDecor gives every bench 0.7 units: one tile each).
  table_1   Decor.Kind.TABLE: a table between two benches (as DecorArt._table), mugs and a jug on it;
  table_2   table_2 with a loaf and a bowl of apples. Anchored at the table's centre.
  logs_1    Decor.Kind.LOGS: three, two and one logs lying along ground x, their cut ends (rings) to the camera.
            Anchored under the middle of the front log, as DecorArt.log_pile.
  cart_1    Decor.Kind.CART: DecorArt._cart's handcart (plank bed between two spoked wheels, shafts forward along
  cart_2    ground x) loaded with sacks (cart_1) or pumpkins (cart_2). Anchored under the middle of the bed.
  signpost  Decor.Kind.SIGNPOST: DecorArt._signpost's layout (a post 28 px high, an arrow board pointing right and a
            lower one pointing left, both facing the camera), each board with a light top edge and a dark line of
            lettering. Anchored at the foot of the post.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_goods.py [all | barrel | crates | bench | table | logs | cart | signpost]
      [--out <scratch dir>]   (--out: write PNGs there, no manifest)
"""
import argparse
import math
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
U = 1.0 / 16.0                       # drawing grid (ground units): 2 px across, 1 px down on screen

# Goods colours (fixed, muted; none reaches check_sprite_glow's glow rule).
MUG = ((140, 108, 62), (176, 140, 84), (226, 216, 190))        # dark, body, foam
JUG = ((124, 66, 44), (160, 88, 56), (192, 118, 76))           # clay: dark, body, lit
APPLE = ((128, 40, 32), (170, 54, 42), (204, 86, 62))
LEAF = (82, 112, 46)
BREAD = ((150, 100, 50), (190, 140, 74), (220, 176, 108))
SACK = ((150, 134, 102), (196, 180, 144), (224, 212, 182))      # rim, body, highlight
PUMPKIN = ((150, 72, 30), (196, 102, 40), (224, 136, 64))

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
# The tall cask: narrower lid and foot, a bulge between three hoops.
CASK = [
    "..oooooooo..",
    ".o44444444o.",
    ".o42222232o.",
    ".o44333322o.",
    ".ojjiiiiiio.",
    "o4443323211o",
    "o4443323211o",
    "o4443323211o",
    "ojjjiiiiiiio",
    "o4443323211o",
    "o4443323211o",
    "o4443323211o",
    ".ojjiiiiiio.",
    ".o44323211o.",
    ".o44323211o.",
    "..oooooooo..",
]
CASK_ANCHOR = (6, 15)


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


def cask():
    return from_map(CASK, *sheet_tones()), CASK_ANCHOR


class Canvas:
    """A drawing surface in screen px, the piece's ground point at pixel corner (OX, OY). Fills test pixel centres, so
    2:1 edges through whole-pixel corners (ground points on the U grid) step cleanly. finish() rings the silhouette
    with the outline and crops it."""

    def __init__(self, w=120, h=100, ox=60, oy=80):
        self.rgb = np.zeros((h, w, 3))
        self.a = np.zeros((h, w), bool)
        self.o = (ox, oy)
        ys, xs = np.mgrid[0:h, 0:w]
        self.cx = xs + 0.5 - ox
        self.cy = ys + 0.5 - oy
        self.wood = sheet_tones()[0]

    @staticmethod
    def iso(gx, gy, z=0.0):
        return (gx - gy) * 32.0, (gx + gy) * 16.0 - z

    def put(self, mask, col):
        """Paint `mask` with `col`: one RGB, or a per-pixel (h, w, 3) array."""
        col = np.asarray(col, float)
        self.rgb[mask] = col[mask] if col.ndim == 3 else col
        self.a |= mask

    def tones(self, idx):
        """Wood tone indices (h, w ints: -1 darker than tone 0, 5 lighter than tone 4) to an RGB array."""
        lit = np.minimum(np.array(self.wood[4], float) * 1.18 + 6, 255)
        pal = np.array([np.array(self.wood[0]) * 0.8] + [list(c) for c in self.wood] + [lit], float)
        return pal[np.clip(idx, -1, 5) + 1]

    def face(self, A, B, z0, z1, fn):
        """A vertical face over the ground segment A->B (A the screen-left end) from height z0 to z1 (px). fn(u, z)
        gives wood tone indices: u px from A along the screen x, z px above the ground."""
        ax, ay = self.iso(*A)
        bx, by = self.iso(*B)
        t = (self.cx - ax) / (bx - ax)
        z = ay + t * (by - ay) - self.cy
        m = (t >= 0) & (t < 1) & (z >= z0) & (z < z1)
        self.put(m, self.tones(np.asarray(fn(self.cx - ax, z), int) * np.ones_like(t, int)))

    def top(self, x0, y0, x1, y1, z, fn):
        """A level face at height z over ground x0..x1, y0..y1; fn(gx, gy) gives wood tone indices."""
        s = self.cx / 32.0
        q = (self.cy + z) / 16.0
        gx, gy = (q + s) / 2.0, (q - s) / 2.0
        m = (gx >= x0) & (gx < x1) & (gy >= y0) & (gy < y1)
        self.put(m, self.tones(np.asarray(fn(gx, gy), int) * np.ones_like(gx, int)))

    def box(self, x0, y0, x1, y1, z0, z1, top=3, left=2, right=1):
        """A box's three visible faces: the y = y1 face (screen left, lit), the x = x1 face (screen right, shaded),
        the top. Each tone is an index or an fn as face()/top() take."""
        f = lambda v: v if callable(v) else (lambda *_: v)
        self.face((x0, y1), (x1, y1), z0, z1, f(left))
        self.face((x1, y1), (x1, y0), z0, z1, f(right))
        self.top(x0, y0, x1, y1, z1, f(top))

    def ellipse(self, c, rx, ry, col):
        m = ((self.cx - c[0]) / rx) ** 2 + ((self.cy - c[1]) / ry) ** 2 <= 1.0
        self.put(m, col)

    def pixels(self, at, rows, pal):
        """Stamp a small pixel map (rows of keys into pal; '.' clear) with its top-left at screen px `at`."""
        ox, oy = self.o
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch != ".":
                    y, x = oy + int(at[1]) + j, ox + int(at[0]) + i
                    self.rgb[y, x] = pal[ch]
                    self.a[y, x] = True

    def line(self, p0, p1, col):
        """A 1 px line between two screen px (Bresenham)."""
        ox, oy = self.o
        x0, y0, x1, y1 = (int(math.floor(v)) for v in (p0[0], p0[1], p1[0], p1[1]))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x1 > x0 else -1), (1 if y1 > y0 else -1)
        err = dx + dy
        while True:
            self.rgb[oy + y0, ox + x0] = col
            self.a[oy + y0, ox + x0] = True
            if (x0, y0) == (x1, y1):
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def finish(self):
        """Ring the silhouette with the outline (4-neighbours), crop, and return (image, anchor)."""
        a = self.a
        p = np.pad(a, 1)
        ring = ~a & (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:])
        rgb = self.rgb.copy()
        rgb[ring] = OUTLINE
        alpha = a | ring
        ys, xs = np.nonzero(alpha)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        out = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        out[..., :3] = np.round(rgb[y0:y1, x0:x1]).astype(np.uint8)
        out[..., 3] = np.where(alpha[y0:y1, x0:x1], 255, 0)
        return Image.fromarray(out, "RGBA"), (self.o[0] - x0, self.o[1] - y0)


def _seam(v, at):
    """True on the one pixel row a 2:1 seam at ground coordinate `at` covers (v: gx or gy at pixel centres, which
    step 1/32 unit a row)."""
    return (v >= at) & (v < at + 1.0 / 32.0)


def _crate(cv, fx, fy, s, h, lift):
    """A crate whose front (bottom) corner stands at ground (fx, fy), `s` units a side, `h` px tall, from height
    `lift`: board sides (a light top rail and corner posts, a dark seam halfway, a dark foot row; the lit side light,
    the shaded side dark), a light lid with one seam across its middle."""
    L = s * 32.0

    def side(body, frame):
        def fn(u, z):
            r = np.floor(z - lift)
            out = np.where((u < 1) | (u >= L - 1) | (r == h - 1), frame, body)
            out = np.where(r == h // 2, body - 1, out)
            return np.where(r == 0, 0, out)
        return fn

    lid = lambda gx, gy: np.where(_seam(gy, fy - s / 2.0), 4, 5)
    cv.box(fx - s, fy - s, fx, fy, lift, lift + h, top=lid, left=side(3, 4), right=side(1, 2))


CRATE_H = 7


def crates(stacked):
    cv = Canvas()
    _crate(cv, 0.0, 0.0, 5 * U, CRATE_H, 0)
    if stacked:
        _crate(cv, -U, -U, 4 * U, CRATE_H - 2, CRATE_H)
    return cv.finish()


BENCH_L = 11 * U                     # seat length (units); TownDecor's benches run 0.7
BENCH_SEG = 0.7


def _bench(cv, along_x, cx=0.0, cy=0.0, length=BENCH_L, half=U, seat=(3, 5), legs_in=U):
    """A plank bench from ground (cx, cy) along x (or y) `length` units: a seat `half` units either side of its line,
    `seat` (z0, z1) px, a light top with a seam down its middle, two trestle legs `legs_in` from its ends."""
    z0, z1 = seat
    for t in (legs_in, length - legs_in - U):
        if along_x:
            cv.box(cx + t, cy - half, cx + t + U, cy + half, 0, z0, top=2, left=2, right=0)
        else:
            cv.box(cx - half, cy + t, cx + half, cy + t + U, 0, z0, top=2, left=2, right=0)

    def seat_top(gx, gy):
        across = (gy - cy) if along_x else (gx - cx)
        return np.where(_seam(across, 0.0), 4, 5)

    lit_edge = lambda u, z: np.where(z >= z1 - 1, 3, 2)
    dark_edge = lambda u, z: np.where(z >= z1 - 1, 2, 1)
    if along_x:
        cv.box(cx, cy - half, cx + length, cy + half, z0, z1, top=seat_top, left=lit_edge, right=dark_edge)
    else:
        cv.box(cx - half, cy, cx + half, cy + length, z0, z1, top=seat_top, left=lit_edge, right=dark_edge)


def bench(along_x):
    cv = Canvas()
    _bench(cv, along_x)
    return cv.finish()


MUG_MAP = ["ff", "mM", "mM"]
JUG_MAP = [".c.", "cCd", "cCd", ".d."]
LOAF_MAP = [".lll.", "lLLLl", "bbbbb"]
BOWL_MAP = [".rar.", "rRrRa", "wwwww", ".WWW."]


def table(goods):
    """DecorArt._table: a table (top 8/16 x 4/16 units, 8 px high) between two benches 4/16 either side of it."""
    cv = Canvas()
    w = cv.wood
    for side in (-1, 1):
        if side > 0:
            for x in (-4 * U + U * 0.5, 4 * U - U * 1.5):
                for y in (-2 * U + U * 0.5, 2 * U - U * 1.5):
                    cv.box(x, y, x + U, y + U, 0, 6, top=2, left=2, right=0)
            grain = lambda gx, gy: np.where(_seam(gy, 0.0), 4, 5)
            cv.box(-4 * U, -2 * U, 4 * U, 2 * U, 6, 8, top=grain, left=lambda u, z: np.where(z >= 7, 3, 2),
                   right=lambda u, z: np.where(z >= 7, 2, 1))
            pal = {"f": MUG[2], "m": MUG[1], "M": MUG[0], "c": JUG[1], "C": JUG[2], "d": JUG[0],
                   "l": BREAD[1], "L": BREAD[2], "b": BREAD[0], "r": APPLE[1], "R": APPLE[2], "a": LEAF,
                   "w": w[3], "W": w[1]}
            # Screen px on the top (its centre is at (0, -8)); each map's top-left.
            if goods == "mugs":
                for at, m in (((-9, -12), MUG_MAP), ((-2, -13), JUG_MAP), ((4, -11), MUG_MAP)):
                    cv.pixels(at, m, pal)
            else:
                for at, m in (((-9, -12), LOAF_MAP), ((2, -12), BOWL_MAP)):
                    cv.pixels(at, m, pal)
        _bench(cv, True, -3 * U, side * 4 * U, length=6 * U, seat=(3, 5), legs_in=0.0)
    return cv.finish()


LOG_END = ((150, 112, 66), (196, 160, 108), (218, 186, 136))     # cut face: ring, face, lit
LOG_CAP = [".rrr.", "rLffr", "rfpfr", "rfffr", ".rrr."]


def _log(cv, c, length=4, thick=5):
    """One log lying along ground x, its middle at screen px `c` (the ground line under it), running `length` px
    either way on screen x: a bark body (a light top row, a dark bottom row) and a cut end (ring, face, lit corner,
    pith) to the camera."""
    w = cv.wood
    a = (c[0] - length, c[1] - length // 2)
    b = (c[0] + length, c[1] + length // 2)
    t = (cv.cx - a[0]) / (b[0] - a[0])
    up = a[1] + t * (b[1] - a[1]) - cv.cy
    m = (t >= 0) & (t < 1) & (up >= 0) & (up < thick)
    k = np.where(up >= thick - 1, 2, np.where(up < 1, -1, 1))
    cv.put(m, cv.tones(k))
    pal = {"r": np.array(w[0], float) * 0.9, "f": LOG_END[1], "L": LOG_END[2], "p": LOG_END[0]}
    cv.pixels((b[0] - 2, b[1] - thick), LOG_CAP, pal)


def logs():
    """DecorArt.log_pile(o, 3), drawn clean: three logs side by side along ground y, two in their dips, one on top;
    back ones first. Whole-pixel places, so every log's edges step alike."""
    cv = Canvas()
    for row in (((10, -6), (5, -3), (0, 0)), ((8, -8), (3, -5)), ((5, -11),)):
        for c in row:
            _log(cv, c)
    return cv.finish()


def _wheel(cv, c, R, dark):
    """A cart wheel in the x-z plane (its axle along ground y), centre `c` screen px: an ellipse leaning with the
    ground x axis; a dark rim, six spokes and a hub, a lit arc at its upper left."""
    w = cv.wood
    ux, uy = 2.0 / math.sqrt(5.0), 1.0 / math.sqrt(5.0)
    px, py = cv.cx - c[0], cv.cy - c[1]
    a = px / ux
    b = a * uy - py
    r = np.hypot(a, b)
    ang = np.arctan2(b, a)
    spoke = np.zeros_like(r, bool)
    for k in range(3):
        phi = k * math.pi / 3.0 + 0.3
        spoke |= np.abs(a * math.sin(phi) - b * math.cos(phi)) < 0.75
    shade = 0.75 if dark else 1.0
    rim = (r <= R) & (r > R - 2.0)
    lit = rim & (ang > 1.6) & (ang < 3.0)
    inner = r <= R - 2.0
    cv.put(rim, np.array(w[1], float) * shade)
    cv.put(lit, np.array(w[3], float) * shade)
    cv.put(inner & ~spoke, np.array(w[0], float) * 0.7 * shade)
    cv.put(inner & spoke, np.array(w[3], float) * shade)
    cv.put(r <= 1.8, np.array(w[4], float) * shade)


def cart(load):
    """DecorArt._cart: a plank bed (x +-7/16, y +-4/16 units, sides 10..21 px) on two wheels (radius 9 px at
    y +-5/16), shafts forward along +x to the ground; its load inside."""
    cv = Canvas(160, 110, 70, 90)
    w = cv.wood
    bl, bw, z0, z1 = 7 * U, 4 * U, 10, 21
    P = lambda x, y, z: cv.iso(x, y, z)
    # Shafts: forward along +x from the bed down to the ground (a dark underside, a lit top).
    for y in (-bw * 0.75, bw * 0.75):
        cv.line(P(bl, y, z0 + 2), P(bl + 0.6, y, 1), np.array(w[0], float) * 0.85)
        cv.line(P(bl, y, z0 + 3), P(bl + 0.6, y, 2), w[2])
    _wheel(cv, P(0.0, -bw - U, 9), 9.0, True)
    # Inside: the far long wall's and the back wall's inner faces, the floor.
    cv.face((-bl, -bw), (bl, -bw), z0, z1, lambda u, z: np.where((np.floor(z - z0) % 4) == 3, 1, 2))
    cv.face((-bl, bw), (-bl, -bw), z0, z1, lambda u, z: 1)
    cv.top(-bl, -bw, bl, bw, z0 + 1, lambda gx, gy: np.where((np.floor(gy / U) % 2) == 0, 0, 1))
    if load == "sacks":
        for x, y, zz in ((-3 * U, -2 * U, 4), (2 * U, -2 * U, 4), (-1 * U, 1 * U, 3), (4 * U, 1 * U, 3)):
            c = P(x, y, z1 + zz)
            cv.ellipse(c, 6.0, 5.0, SACK[0])
            cv.ellipse((c[0] - 0.5, c[1] + 0.2), 5.0, 4.0, SACK[1])
            cv.ellipse((c[0] - 2.0, c[1] - 1.5), 2.2, 1.6, SACK[2])
            cv.line((c[0] - 1, c[1] - 5), (c[0] + 1, c[1] - 5), SACK[0])
    else:
        for x, y in ((-4 * U, -2 * U), (0, -2 * U), (4 * U, -2 * U), (-2 * U, 1 * U), (2 * U, 1 * U), (6 * U, 1 * U)):
            c = P(x, y, z1 + 3)
            cv.ellipse(c, 4.6, 3.8, PUMPKIN[0])
            cv.ellipse((c[0] - 0.3, c[1] + 0.2), 3.6, 2.9, PUMPKIN[1])
            cv.ellipse((c[0] - 1.6, c[1] - 1.0), 1.4, 1.0, PUMPKIN[2])
            cv.pixels((c[0], c[1] - 5), ["a", "a"], {"a": LEAF})
    # The near walls (outer faces): planks with two seams, corner posts, a light top rail; then the near wheel.
    third = (z1 - z0) / 3.0

    def near(lit):
        def fn(u, z):
            k = z - z0
            seam = (np.abs(k - third) < 0.5) | (np.abs(k - 2 * third) < 0.5)
            rail = k >= (z1 - z0) - 1
            post = (u < 2) | (np.abs(u - 14) < 1) | (u >= 28 - 2) if lit else (u < 2) | (u >= 16 - 1)
            body, light = (3, 4) if lit else (1, 2)
            return np.where(rail, light, np.where(post, body - 1, np.where(seam, body - 2, body)))
        return fn

    cv.face((-bl, bw), (bl, bw), z0, z1, near(True))
    cv.face((bl, bw), (bl, -bw), z0, z1, near(False))
    _wheel(cv, P(0.0, bw + U, 9), 9.0, False)
    return cv.finish()


def signpost():
    """DecorArt._signpost, drawn clean: a post 4 px wide and 28 high (lit left), a foot board, two arrow boards facing
    the camera (one pointing right, high; one pointing left, lower), each with a light top edge, a dark lower edge and
    a dark line of lettering. Screen px as the procedural one, so it reads the same at a glance."""
    cv = Canvas()
    w = cv.wood
    pal = lambda k: (np.array(w[0], float) * 0.8) if k < 0 else np.array(cv.tones(np.array([[k]]))[0, 0])

    def rect(x0, y0, x1, y1, col):
        cv.put((cv.cx >= x0) & (cv.cx < x1) & (cv.cy >= y0) & (cv.cy < y1), pal(col))

    rect(-4, -2, 4, 0, 2)
    rect(-4, -2, 4, -1, 3)
    for x, k in ((-2, 3), (-1, 3), (0, 2), (1, 1)):
        rect(x, -28, x + 1, -2, k)
    rect(-2, -28, 2, -27, 4)

    def board(x0, x1, y0, d):
        """A board over screen x0..x1, rows y0..y0+6, its arrow point beyond x1 (d > 0) or x0 (d < 0)."""
        rect(x0, y0, x1, y0 + 6, 4)
        rect(x0, y0, x1, y0 + 1, 5)
        rect(x0, y0 + 5, x1, y0 + 6, 2)
        rect(x0 + 2, y0 + 3, x1 - 2, y0 + 4, 1)
        end = x1 if d > 0 else x0 - 1
        for k in range(3):
            x = end + d * k
            rect(x, y0 + k + 1, x + 1, y0 + 5 - k, 4)

    board(-2, 12, -26, 1)
    board(-12, 2, -18, -1)
    return cv.finish()


SETS = {
    "barrel": [("barrel_1", barrel), ("barrel_2", cask)],
    "crates": [("crates_1", lambda: crates(False)), ("crates_2", lambda: crates(True))],
    "bench": [("bench_x", lambda: bench(True)), ("bench_y", lambda: bench(False))],
    "table": [("table_1", lambda: table("mugs")), ("table_2", lambda: table("bread"))],
    "logs": [("logs_1", logs)],
    "cart": [("cart_1", lambda: cart("sacks")), ("cart_2", lambda: cart("produce"))],
    "signpost": [("signpost", signpost)],
}
SEGMENT = {"bench_x": BENCH_SEG, "bench_y": BENCH_SEG}


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
                print(name, img.size, anchor, "->", decor_common.write_set(name, img, anchor, SEGMENT.get(name)))


if __name__ == "__main__":
    main()
