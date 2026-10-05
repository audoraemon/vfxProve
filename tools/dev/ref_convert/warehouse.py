"""The farm barns and the carpenter's workshop from the timber warehouse on TownMap_Component1 (row 3, 1st), without
its crane (the user chose "Adapt the warehouse": no barn is drawn on the four sheets). No AI calls.

  barn       HOUSE / farm / "",          footprint 1.3 x 1.5 (TownLayout.BARNS), height 20. The warehouse's gable end
             and a short stretch of its long side: the long side is cut down (the roof between where its dormer
             stood and its chimney comes out), the chimney goes (a barn never smokes), a big plank barn door on the
             gable.
  carpenter  HOUSE / house / carpenter, footprint 2.3 x 1.15 (TownLayout.CARPENTER), height 20. The whole warehouse,
             its long side lengthened by a 13 px slice of roof so it reaches 2.3 cells, its chimney kept (it smokes, as
             the procedural carpenter does), a stack of planks against the long wall. The crane is dropped too: it
             stands outside the gable and would hang over the yard past the plot.

What comes from the sheet: the roof (slates, ridge, rakes; the dormer painted out), the chimney and the gable's timber
triangle above its tie beam. The sheet's walls are hidden behind crates, barrels, a lean-to, a lantern and the crane,
and their stone door arch is not wanted, so the walls below are drawn clean in flat tones on the game's own iso
geometry: a stone plinth, a sill, timber posts, plaster panels, a wall plate, doors and windows. The sheet draws at
about 2.2:1; the roof is stretched to 2:1 (y x 1.11) as it is fitted, and the gable sets the scale (its run equals the
gable face's).

Light from the left: the sheet lights from the right (the chimney's right face and the gable are its lit sides), so
the barn (gable on its left face, the long side on its right) is the sheet mirrored. The carpenter's plot is wide (its
long side is its left face), which a mirror cannot give with the gable shaded, so it keeps the sheet's orientation and
is relit: roof up, gable triangle down, chimney mirrored in place, and its walls drawn lit on the long side.

States: intact, damaged (holes through the roof slates with charred rims, a scorch up the wall, the door hanging off
one hinge), ruins (the approved batch 2 ruins of the closest set, placed on this plot: townhouse_b's for the barn,
whose blue slate debris matches, scaled 0.9 and centred; the workshop's for the carpenter, the procedural carpenter's
own art, scaled 0.85). The collapse is the engine's sink. No idle strip.

Usage (from anywhere):
  python tools/dev/ref_convert/warehouse.py [all | barn | carpenter] [--out <scratch dir>] [--debug <dir>]
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bridges  # noqa: E402
import convert  # noqa: E402

ROOT = convert.ROOT
B = convert.B
C1 = ROOT / "concepts" / "TOWN REF" / "TownMap_Component1.png"
BOX = (86, 585, 316, 760)                 # the warehouse's roof and gable (sheet px)
# Sheet geometry (sheet px). The roof's bottom edge runs from EAVE_L to the front corner E; its slope is EAVE_K.
EAVE_L, EAVE_K = (100.0, 653.0), 0.44
RIDGE_L, RIDGE_K = (140.0, 596.0), 0.457
RAKE = (40.0, -57.0)                      # the roof's left rake, eave to ridge
E = (231.0, 716.0)                        # the front corner, under the eave: where the walls' front corner meets the slab
LONG, GAB = 131.0, 72.0                   # the long side's and the gable's run across (px)
AXIS_K = 0.45                             # the long side's slope, for sliding roof along it
STRETCH = 0.5 / AXIS_K                    # y stretch: the sheet's ~2.2:1 to the game's 2:1
# The slab: roof (found by its blue, per column), chimney and the gable's timber triangle above the tie beam.
ROOF_POLY = [(93, 660), (134, 590), (276, 650), (229, 717), (98, 657)]
GABLE_POLY = [(228, 717), (270, 653), (311, 690), (305, 695), (297, 696), (234, 721)]
CHIMNEY = (227, 610, 252, 647)
DORMER_U = 145.0                          # the barn's roof slice is cut from here (where the painted-out dormer stood)
# The sheet's dormer (a crescent of blue flashing that reads as a stain at sprite size): painted out with the slates
# DORMER_SHIFT along the roof (whole courses, no seam), before anything else.
DORMER = (141, 635, 169, 669)
DORMER_SHIFT = (40, 18)
CARP_SLICE_U = 168.0                      # the carpenter's added slice of roof is copied from here back
PAD = 6

# Flat tones (RGB), picked to match the sheet's gable (plaster, timber); the plinth a neutral grey near the town's
# stone (sprite_fix harmonize is not run: it reads the cream plaster as limestone and greys it).
PLASTER = np.array([222, 200, 160.0])
PLASTER_LO = np.array([200, 176, 138.0])
TIMBER = np.array([112, 72, 38.0])
TIMBER_DK = np.array([78, 48, 26.0])
TIMBER_LT = np.array([150, 104, 58.0])
DOOR = np.array([96, 60, 32.0])
DOOR_LT = np.array([128, 86, 46.0])
GLASS = np.array([62, 58, 70.0])
GLASS_LIT = np.array([214, 160, 72.0])
STONE = np.array([150, 144, 134.0])
STONE_DK = np.array([112, 106, 98.0])
PLANK = np.array([196, 152, 96.0])
PLANK_DK = np.array([150, 108, 62.0])
SHADE = 0.74                              # the shaded face against the lit one
CHAR = np.array([40, 30, 26.0])

SETS = {
    # name: footprint, height, seed, kind, role, tag, ruins source, ruins scale
    "barn": ([1.3, 1.5], 20, 70, "HOUSE", "farm", "", "townhouse_b", 0.9),
    "carpenter": ([2.3, 1.15], 20, 71, "HOUSE", "house", "carpenter", "workshop", 0.85),
}
WALL_H = {"barn": 23, "carpenter": 21}    # px from the ground to the eave, in the sprite


# --- the slab from the sheet ---------------------------------------------------------------------------------------
def _poly_mask(w, h, poly):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).polygon([(x - BOX[0], y - BOX[1]) for x, y in poly], fill=255)
    return np.array(m) > 0


def _u(px, py):
    """A roof pixel's place along the long side: where its line down the slope (along RAKE) meets the eave (sheet x)."""
    t = (EAVE_L[1] + EAVE_K * (px - EAVE_L[0]) - py) / (-RAKE[1] + EAVE_K * RAKE[0])
    return px - RAKE[0] * t


def slab(chimney=True, relit=False):
    """The sheet's roof, chimney (or not) and gable triangle; everything else cleared. relit: lit from the left in the
    sheet's orientation (the roof's front slope up, the gable down, the chimney mirrored in place)."""
    a = np.array(Image.open(C1).convert("RGBA").crop(BOX)).astype(float)
    x0, y0, x1, y1 = DORMER[0] - BOX[0], DORMER[1] - BOX[1], DORMER[2] - BOX[0], DORMER[3] - BOX[1]
    sx, sy = DORMER_SHIFT
    a[y0:y1, x0:x1] = a[y0 + sy:y1 + sy, x0 + sx:x1 + sx]
    h, w = a.shape[:2]
    rgb = a[..., :3]
    blue = (a[..., 3] > 0) & (rgb[..., 2] > rgb[..., 0] + 12) & (rgb[..., 2] > 55)
    roof = _poly_mask(w, h, ROOF_POLY)
    # per column: the roof down to its lowest blue pixel (+1 px of its dark edge)
    low = np.full(w, -1)
    for x in range(w):
        ys = np.nonzero(blue[:, x] & roof[:, x])[0]
        if len(ys):
            low[x] = ys.max() + 1
    yy = np.arange(h)[:, None]
    roof &= yy <= low[None, :]
    gable = _poly_mask(w, h, GABLE_POLY) & ~roof
    keep = roof | gable
    cx0, cy0, cx1, cy1 = (CHIMNEY[0] - BOX[0], CHIMNEY[1] - BOX[1], CHIMNEY[2] - BOX[0], CHIMNEY[3] - BOX[1])
    ridge = RIDGE_L[1] + RIDGE_K * (np.arange(w) + BOX[0] - RIDGE_L[0]) - BOX[1]
    chim = np.zeros((h, w), bool)
    chim[cy0:cy1, cx0:cx1] = True
    chim &= ~(blue & (yy >= ridge[None, :] - 1)) & (a[..., 3] > 0)
    if chimney:
        keep |= chim
    else:
        keep &= ~(chim & (yy < ridge[None, :] - 1))
    a[~keep] = 0
    if relit:
        a[roof & blue, :3] *= 1.16
        a[gable, :3] *= 0.8
        if chimney:
            box = a[cy0:cy1, cx0:cx1].copy()
            m = chim[cy0:cy1, cx0:cx1]
            fb, fm = box[:, ::-1], m[:, ::-1]
            box[m & ~fm] = 0
            box[fm] = fb[fm]
            a[cy0:cy1, cx0:cx1] = box
        a[..., :3] = np.clip(a[..., :3], 0, 255)
    return a


def splice(a, cut_u, delta):
    """The roof lengthened (delta > 0) or shortened (delta < 0) along the long side at cut_u (sheet x on the eave):
    everything past the cut slides delta px along the side; a lengthened roof repeats the delta px before the cut."""
    h, w = a.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    u = _u(xs + BOX[0], ys + BOX[1])
    dx, dy = int(round(delta)), int(round(delta * AXIS_K))
    src = u >= cut_u - delta
    out = np.zeros((h + abs(dy), w + abs(dx), 4))
    oy = abs(dy) if dy < 0 else 0
    left = a.copy()
    left[u >= cut_u] = 0
    out[oy:oy + h, :w] = left
    moved = np.where(src[..., None], a, 0)
    ty, tx = oy + dy, dx
    region = out[max(ty, 0):ty + h, max(tx, 0):tx + w]
    piece = moved[max(-ty, 0):, max(-tx, 0):][:region.shape[0], :region.shape[1]]
    region[piece[..., 3] > 0] = piece[piece[..., 3] > 0]
    # the front corner (E) moves with the part past the cut
    return out, (dx, dy + oy), oy


def fit(a, s):
    """Premultiplied Lanczos to scale s across and s * STRETCH down; hard alpha. Float RGBA."""
    h, w = a.shape[:2]
    nw, nh = round(w * s), round(h * s * STRETCH)
    pm = a.copy()
    pm[..., :3] *= a[..., 3:] / 255.0
    im = Image.fromarray(np.clip(pm, 0, 255).astype(np.uint8), "RGBa").resize((nw, nh), Image.LANCZOS)
    out = np.array(im.convert("RGBA")).astype(float)
    out[..., 3] = np.where(out[..., 3] >= 110, 255, 0)
    out[out[..., 3] == 0] = 0
    return out, (nw / w, nh / h)


# --- the drawn walls --------------------------------------------------------------------------------------------------
class Walls:
    """The walls on the sprite canvas c (float RGBA) in the sheet's orientation: the long side is the left face (run
    `long` px across from the front corner A), the gable the right face (`gab` px). Painted under the slab: each column
    up to the slab's lowest pixel."""

    def __init__(self, c, A, long, gab, wall_h, lit_long):
        self.c, self.A, self.long, self.gab, self.wall_h = c, A, long, gab, wall_h
        self.lit_long = lit_long
        self.slab_low = {}
        al = c[..., 3] > 0
        for x in range(c.shape[1]):
            ys = np.nonzero(al[:, x])[0]
            self.slab_low[x] = ys.max() if len(ys) else None
        self.layer = np.zeros_like(c)

    def base(self, x):
        return self.A[1] - abs(x - self.A[0]) * 0.5

    def face(self, x):
        return "long" if x < self.A[0] else "gab"

    def tone(self, x, rgb):
        lit = (self.face(x) == "long") == self.lit_long
        return rgb if lit else rgb * SHADE

    def columns(self, which):
        A = self.A[0]
        if which == "long":
            return range(int(round(A - self.long)), A)
        return range(A, int(round(A + self.gab)) + 1)

    def top(self, x):
        """The wall's top row in column x: under the slab, or the eave height if the slab misses it."""
        eave = int(round(self.base(x) - self.wall_h))
        low = self.slab_low.get(x)
        return min(eave, low) if low is not None else eave

    def put(self, x, y, rgb):
        if 0 <= y < self.c.shape[0] and 0 <= x < self.c.shape[1]:
            self.layer[y, x, :3] = self.tone(x, rgb)
            self.layer[y, x, 3] = 255

    def d(self, x):
        return abs(x - self.A[0])

    def v(self, x, y):
        return int(round(self.base(x))) - y

    def paint(self, posts, rail):
        """Plaster between timber; posts: {face: [d...]} (px from the front corner) besides the corners; a rail
        (timber) `rail` px above the ground."""
        for which in ("long", "gab"):
            run = self.long if which == "long" else self.gab
            for x in self.columns(which):
                d = self.d(x)
                b = int(round(self.base(x)))
                post = d <= 1 or d >= run - 1.5 or any(abs(d - p) <= 0.5 for p in posts.get(which, []))
                for y in range(self.top(x), b + 1):
                    v = b - y
                    if v <= 1:
                        rgb = STONE_DK if v == 0 else STONE
                    elif v == 2:
                        rgb = TIMBER_DK
                    elif y <= self.top(x) + 1:
                        rgb = TIMBER if y == self.top(x) + 1 else TIMBER_DK
                    elif post:
                        rgb = TIMBER if d > 0 else TIMBER_LT
                    elif v == rail:
                        rgb = TIMBER
                    else:
                        rgb = PLASTER if v > 6 else PLASTER_LO
                    self.put(x, y, rgb)

    def opening(self, which, d0, d1, v0, v1, fill, frame=TIMBER_DK, planks=False, brace=False, lit=None):
        """A door or window on a face: d (px from the front corner) d0..d1, v (px above the ground) v0..v1."""
        for x in self.columns(which):
            d = self.d(x)
            if d < d0 - 1 or d > d1 + 1:
                continue
            b = int(round(self.base(x)))
            for v in range(v0 - 1, v1 + 2):
                y = b - v
                edge = d < d0 or d > d1 or v < v0 or v > v1
                if edge:
                    rgb = frame
                elif lit is not None and (d == (d0 + d1) // 2 or v == (v0 + v1 + 1) // 2):
                    rgb = TIMBER_DK
                elif lit is not None:
                    rgb = GLASS_LIT if lit else GLASS
                elif brace and (abs((d - d0) / max(d1 - d0, 1) - (v - v0) / max(v1 - v0, 1)) < 0.09
                                or abs((d - d0) / max(d1 - d0, 1) - (v1 - v) / max(v1 - v0, 1)) < 0.09):
                    rgb = DOOR_LT
                elif planks and (d - d0) % 3 == 2:
                    rgb = TIMBER_DK
                elif brace and abs(d - (d0 + d1) / 2) < 0.6:
                    rgb = TIMBER_DK
                else:
                    rgb = fill
                self.put(x, y, rgb)

    def gp(self, gx, gy, z):
        """Screen px of ground point (gx, gy) (units from the front corner, the building at gx, gy <= 0; x along the
        long side) z px up."""
        return (self.A[0] + (gx - gy) * 32.0, self.A[1] + (gx + gy) * 16.0 - z)

    def box(self, gx0, gx1, gy0, gy1, z1, top, side, end, seams=None):
        """A box on the ground in front of the walls, drawn over them: its side (facing +y, a left face), end (+x,
        a right face) and top; seams: z of dark lines along the side (stacked planks)."""
        im = Image.new("RGBA", (self.c.shape[1], self.c.shape[0]), (0, 0, 0, 0))
        dr = ImageDraw.Draw(im)
        P = self.gp
        dr.polygon([P(gx0, gy1, 0), P(gx1, gy1, 0), P(gx1, gy1, z1), P(gx0, gy1, z1)], fill=tuple(int(v) for v in side))
        dr.polygon([P(gx1, gy0, 0), P(gx1, gy1, 0), P(gx1, gy1, z1), P(gx1, gy0, z1)], fill=tuple(int(v) for v in end))
        dr.polygon([P(gx0, gy0, z1), P(gx1, gy0, z1), P(gx1, gy1, z1), P(gx0, gy1, z1)], fill=tuple(int(v) for v in top))
        for z in seams or []:
            dr.line([P(gx0, gy1, z), P(gx1, gy1, z)], fill=tuple(int(v) for v in PLANK_DK * 0.8))
            dr.line([P(gx1, gy0, z), P(gx1, gy1, z)], fill=tuple(int(v) for v in end * 0.75))
        a = np.array(im).astype(float)
        m = a[..., 3] > 0
        self.layer[m] = a[m]
        return self

    def compose(self, over=None):
        """The walls under the slab (the planks' layer `over` on top of everything)."""
        out = self.layer.copy()
        al = self.c[..., 3] > 0
        out[al] = self.c[al]
        if over is not None:
            m = over[..., 3] > 0
            out[m] = over[m]
        return out


# --- the sets ---------------------------------------------------------------------------------------------------------
def build(name, debug=None):
    fp, *_ = SETS[name]
    W, D = fp
    if name == "barn":
        gab_units, long_units = W, D             # mirrored at the end: the gable becomes the left face
    else:
        gab_units, long_units = D, W
    s = 32.0 * gab_units / GAB
    long_sheet = 32.0 * long_units / s
    a = slab(chimney=(name == "carpenter"), relit=(name == "carpenter"))
    e = (E[0] - BOX[0], E[1] - BOX[1])
    if name == "barn":
        a, (dx, dy), oy = splice(a, DORMER_U, long_sheet - LONG)
    else:
        a, (dx, dy), oy = splice(a, CARP_SLICE_U, long_sheet - LONG)
    e = (e[0] + dx, e[1] + dy)
    if debug:
        _dbg(a, debug / (name + "_slab.png"), 3)
    small, (kx, ky) = fit(a, s)
    h, w = small.shape[:2]
    wall_h = WALL_H[name]
    long_px, gab_px = 32.0 * long_units, 32.0 * gab_units
    # canvas: the slab's front corner sits wall_h above the anchor
    ex, ey = e[0] * kx, e[1] * ky
    cw = int(np.ceil(max(w, ex + gab_px + 2) + 2 * PAD))
    ch = int(np.ceil(h + 2 * PAD + max(0.0, (ey + wall_h) - h) + 8))
    c = np.zeros((ch, cw, 4))
    ox, oy2 = PAD, PAD
    c[oy2:oy2 + h, ox:ox + w] = small
    A = (int(round(ox + ex)), int(round(oy2 + ey + wall_h)))
    return c, A, long_px, gab_px, wall_h


def _dbg(a, path, k):
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    bg = Image.new("RGBA", im.size, (90, 90, 110, 255))
    bg.alpha_composite(im)
    bg.resize((im.width * k, im.height * k), Image.NEAREST).save(path)


def _hash(*v):
    h = 2166136261
    for k in v:
        h = ((h ^ (int(k) & 0xFFFFFFFF)) * 16777619) & 0xFFFFFFFF
    return h / 4294967295.0


def roof_holes(c, holes):
    """Holes through the slates (state damaged): each (x, y, rx, ry) an ellipse along the eave; a dark loft inside
    with rafters across it, a charred rim, and the slates round it sooted."""
    out = c.copy()
    h, w = c.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    rgb = c[..., :3]
    roof = (c[..., 3] > 0) & (rgb[..., 2] > rgb[..., 0] + 8)
    for (hx, hy, rx, ry) in holes:
        u = xs - hx
        v = (ys - hy) - (xs - hx) * 0.5 * (1 if hx < 0 else 1)
        r = (u / rx) ** 2 + (v / ry) ** 2
        noise = np.array([[_hash(x, y, int(hx)) for x in range(w)] for y in range(h)]) * 0.3
        inside = roof & (r + noise < 1.0)
        rim = roof & ~inside & (r + noise < 1.6)
        soot = roof & ~inside & ~rim & (r < 2.8)
        out[soot, :3] = out[soot, :3] * 0.7 + CHAR * 0.3
        out[rim, :3] = CHAR * 0.85 + out[rim, :3] * 0.15
        out[inside, :3] = CHAR * 0.5
        raf = inside & ((((xs - hx) + 2 * (ys - hy)) % 6) < 1.2)
        out[raf, :3] = TIMBER_DK * 0.75
    return out


def scorch(img, x0, x1, y_top, y_bot):
    """Soot up a wall over a burnt opening: darkest low in the middle, fading up and out in three clean steps."""
    out = img.copy()
    mid, half = (x0 + x1) / 2.0, (x1 - x0) / 2.0
    for y in range(int(round(y_top)), int(round(y_bot)) + 1):
        t = (y_bot - y) / max(y_bot - y_top, 1)          # 0 at the bottom, 1 at the top
        width = half * (1.0 - 0.5 * t)
        for x in range(int(x0), int(x1) + 1):
            if out[y, x, 3] == 0 or abs(x - mid) > width:
                continue
            k = abs(x - mid) / max(width, 1)
            f = round((0.2 + 0.8 * min(1.0, 0.7 * t + 0.5 * k)) * 3) / 3
            out[y, x, :3] = out[y, x, :3] * f + CHAR * (1 - f)
    return out


def door(wl, which, d0, d1, v0, v1, state, double=False):
    """A plank door (double: a barn's two braced leaves). Damaged: the far leaf hangs off its top hinge, its free
    corner dropped a few px, the dark doorway showing above it."""
    wl.opening(which, d0, d1, v0, v1, DOOR, planks=not double, brace=double)
    if state != "damaged":
        return
    a0 = (d0 + d1) // 2 + 1 if double else d0
    sag = 3
    for x in wl.columns(which):
        d = wl.d(x)
        if not (a0 <= d <= d1):
            continue
        b = int(round(wl.base(x)))
        drop = int(round(sag * (d - a0) / max(d1 - a0, 1)))
        for v in range(v0, v1 + 1):
            wl.put(x, b - v, CHAR * 0.6)
        for v in range(v0 - 1, v1 + 1):
            vv = v - drop
            if vv < 1:
                continue
            edge = d in (a0, d1) or v in (v0 - 1, v1)
            wl.put(x, b - vv, TIMBER_DK if edge else (DOOR_LT if (d - a0) % 3 == 1 else DOOR))


# (x, y, rx, ry) per hole on the canvas in the sheet's orientation, from the front corner A, the long side's run L
# and the wall height H: a point f of the way along the long side, k px up the slope from the eave.
def _on_roof(A, L, H, f, k):
    return A[0] - L * f, A[1] - H - L * f * 0.5 - k


HOLES = {
    "barn": lambda A, L, G, H: [(*_on_roof(A, L, H, 0.55, 14), 5.5, 3.2)],
    "carpenter": lambda A, L, G, H: [(*_on_roof(A, L, H, 0.62, 13), 5.0, 3.0), (*_on_roof(A, L, H, 0.2, 8), 3.6, 2.2)],
}


def clean_roof(c):
    """The sheet's brown specks of moss and dirt on the slates painted out with the slates round them."""
    out = c.copy()
    rgb = c[..., :3]
    al = c[..., 3] > 0
    blue = al & (rgb[..., 2] > rgb[..., 0] + 8)
    h, w = blue.shape
    for y in range(h):
        for x in range(w):
            if not al[y, x] or blue[y, x]:
                continue
            win = blue[max(0, y - 2):y + 3, max(0, x - 2):x + 3]
            if win.sum() >= 15:                       # inside the roof, not its edge or the chimney
                out[y, x, :3] = rgb[max(0, y - 2):y + 3, max(0, x - 2):x + 3][win].mean(0)
    return out


def draw(name, state):
    """intact or damaged, in the final orientation, on a roomy canvas; returns (img, anchor)."""
    c, A, long_px, gab_px, wall_h = build(name)
    c = clean_roof(c)
    if state == "damaged":
        c = roof_holes(c, HOLES[name](A, long_px, gab_px, wall_h))
    wl = Walls(c, A, long_px, gab_px, wall_h, lit_long=(name == "carpenter"))
    over = None
    if name == "barn":
        wl.paint({"long": [round(long_px * 0.5)], "gab": []}, 18)
        mid = round(gab_px * 0.5)
        door(wl, "gab", mid - 8, mid + 8, 3, 16, state, double=True)
        wl.opening("long", 31, 36, 13, 16, TIMBER_DK * 0.8)          # the hay loft's hatch, shut
        wl.opening("long", 8, 12, 9, 13, GLASS, lit=True)
    else:
        wl.paint({"long": [round(long_px * f) for f in (0.25, 0.5, 0.75)], "gab": [round(gab_px * 0.5)]}, 15)
        door(wl, "long", 23, 29, 3, 12, state)
        wl.opening("long", 7, 11, 9, 13, GLASS, lit=True)
        wl.opening("long", 42, 46, 9, 13, GLASS, lit=True)
        wl.opening("gab", 8, 12, 9, 13, GLASS, lit=True)
        wl.opening("gab", 24, 28, 9, 13, GLASS, lit=False)
        # planks stacked against the long wall in its far bay, clear of the corner
        stack = Walls(c, A, long_px, gab_px, wall_h, lit_long=True)
        stack.box(-2.12, -1.8, 0.0, 0.16, 6, PLANK, PLANK * 0.92, PLANK_DK, seams=[2, 4])
        over = stack.layer
    img = wl.compose(over)
    if state == "damaged":
        if name == "barn":
            x = A[0] + round(gab_px * 0.5)
            yb = A[1] - gab_px * 0.25
            img = scorch(img, x - 9, x + 9, yb - wall_h + 1, yb - 14)
        else:
            x = A[0] - 26
            yb = A[1] - 13
            img = scorch(img, x - 7, x + 7, yb - wall_h + 1, yb - 12)
    if name == "barn":
        img = img[:, ::-1].copy()
        A = (img.shape[1] - 1 - A[0], A[1])
    return img, A


def ruins(name, shape, A):
    """The source set's approved ruins on this plot (final orientation): scaled k, the two footprints' centres met."""
    fp, _, _, _, _, _, src_name, k = SETS[name]
    sm = convert.json.load(open(B / "manifest.json", encoding="utf-8"))[src_name]
    src = Image.open(B / src_name / "ruins.png").convert("RGBA")
    Ws, Ds = sm["footprint"]
    As = sm["anchor"]
    if k != 1.0:
        nw, nh = round(src.width * k), round(src.height * k)
        small = src.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
        al = np.array(small.getchannel("A")) >= 120
        pal = src.convert("RGB").quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        q = small.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
        a = np.zeros((nh, nw, 4))
        a[..., :3] = np.array(q)
        a[..., 3] = np.where(al, 255, 0)
        a = bridges.outline(a)
    else:
        a = np.array(src).astype(float)
    W, D = fp
    cx = A[0] + 16 * (D - W) - k * 16 * (Ds - Ws)
    cy = A[1] - 8 * (W + D) + k * 8 * (Ws + Ds)
    ox, oy = int(round(cx - As[0] * k)), int(round(cy - As[1] * k))
    out = np.zeros(shape)
    h, w = a.shape[:2]
    out[oy:oy + h, ox:ox + w] = a
    return out


def corner_errors(img, A, fp):
    """(dx, dy) from each footprint base corner (left = A - (32 W, 16 W), right = A + (32 D, -16 D)) to the nearest
    column-bottom pixel."""
    W, D = fp
    al = img[..., 3] > 0
    base = [(x, int(np.nonzero(al[:, x])[0].max())) for x in range(al.shape[1]) if al[:, x].any()]
    out = {}
    for nm, (cx, cy) in (("left", (A[0] - 32 * W, A[1] - 16 * W)), ("right", (A[0] + 32 * D, A[1] - 16 * D))):
        bx, by = min(base, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
        out[nm] = (round(bx - cx, 1), round(by - cy, 1))
    return out


def make(name, out_dir, debug=None, colors=48):
    fp, height, seed, kind, role, tag, _, _ = SETS[name]
    st = {}
    for state in ("intact", "damaged"):
        img, A = draw(name, state)
        st[state] = np.pad(img, ((40, 40), (40, 40), (0, 0)))
    A = (A[0] + 40, A[1] + 40)
    st["ruins"] = ruins(name, st["intact"].shape, A)
    # one canvas for the three: the union of their pixels, PAD round it, FOOT_ROOM under the front corner
    al = np.zeros(st["intact"].shape[:2], bool)
    for v in st.values():
        al |= v[..., 3] > 0
    ys, xs = np.nonzero(al)
    y0, x0, x1 = ys.min() - PAD, xs.min() - PAD, xs.max() + 1 + PAD
    y1 = max(ys.max() + 1 + PAD, A[1] + 11)
    crop = {k2: v[y0:y1, x0:x1] for k2, v in st.items()}
    A = (int(A[0] - x0), int(A[1] - y0))
    done = bridges.finish([crop["intact"], crop["damaged"]], colors)
    done.append(np.clip(crop["ruins"], 0, 255).astype(np.uint8))
    d = out_dir / name
    d.mkdir(parents=True, exist_ok=True)
    for state, img in zip(("intact", "damaged", "ruins"), done):
        Image.fromarray(img, "RGBA").save(d / (state + ".png"))
    h, w = done[0].shape[:2]
    print(name, "size", [w, h], "anchor", list(A), "base corners off by", corner_errors(done[0], A, fp))
    if debug:
        sheet = np.zeros((h, w * 3 + 20, 4))
        for i, img in enumerate(done):
            sheet[:, i * (w + 10):i * (w + 10) + w] = img
        _dbg(sheet, debug / (name + "_states.png"), 3)
    entry = {"size": [w, h], "footprint": fp, "anchor": list(A), "height": height, "seed": seed, "kind": kind,
             "role": role, "tag": tag}
    if name == "carpenter":
        entry["chimney"] = chimney_top(done[0])
        print(name, "chimney", entry["chimney"])
    return entry


def chimney_top(img):
    """The chimney's top middle (sprite px), for ChimneySmoke: the columns whose highest pixel is not slate, past the
    roof's middle."""
    al = img[..., 3] > 0
    cols = []
    for x in range(img.shape[1] // 2, img.shape[1]):
        ys = np.nonzero(al[:, x])[0]
        if len(ys):
            r, g, b = img[ys[0], x, :3].astype(int)
            if not b > r + 8:
                cols.append((x, ys[0]))
    top = min(y for _, y in cols)
    xs = [x for x, y in cols if y <= top + 3]
    return [int(round((min(xs) + max(xs)) / 2)), int(top)]


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", help="write the sets here instead of assets/pixellab/buildings (no manifest change)")
    p.add_argument("--debug", help="write stage pictures here")
    args = p.parse_args()
    dbg = Path(args.debug) if args.debug else None
    for n in (list(SETS) if args.what == ["all"] else args.what):
        entry = make(n, Path(args.out) if args.out else B, dbg)
        if not args.out:
            convert.write_manifest(B / "manifest.json", n, entry)
            print("manifest updated:", n)
