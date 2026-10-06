"""Water decor sets (decor batch 4), built locally (no AI): DecorArt's moored ship and its rowing boats, drawn clean
in the style of decor_goods.py (its Canvas and wood tones: fixed tone patterns, light from the left, 1 px dark outline).

Cutting them from the sheets does not work. The only ship is the Scale sheet's (Town Visual and Scale Upgrade.png,
about (150, 630)-(290, 750)): a single-masted cog about 55 x 70 px, a third of the procedural ship's size, painted
onto the river with the dock and a person over its hull, so there is no clean edge and it would have to be scaled up.
Component3's dock tile has the one rowing boat (about (1295, 295)-(1372, 355)), also painted onto water: keyed out and
fitted to the procedural boat's size it is mottled brown speckle with a blue fish of water reflection in it and a dock
post along. So both are drawn on the procedural geometry instead, which keeps where they sit on the water and how much
of the dock behind them they hide.

  ship    Decor.Kind.SHIP: DecorArt._ship's hull (the same sheer and lifts, 3.3 units stern to stem, deck 20 px above the
          water), drawn as clinker strakes under a light rail and a dark wale on its near (+y, lit) side, darker below
          the bend; a planked deck (lit along its far edge, no bulwark there: the dock side) with a hatch, a raised
          stern castle with a railing, the bowsprit, two masts (64 and 48 px) with gaff sails in panels (lit aft,
          shaded by the mast), a blue pennant, and the procedural ship's rigging as clean 1 px rope lines (no
          outline), the same in every frame: each mast's forestay to the bowsprit's end (over the sails) and a
          shroud to either rail (the far one behind the sails), the main mast's backstay to the stern behind its
          sail (the fore mast's would run level across both sails, so it has none). Anchored at the hull's
          waterline centre (ground (0, 0) at the water), as the procedural ship stands on SHIP_AT.
  boat_1  Decor.Kind.BOAT along ground x: DecorArt._boat's hull (1.5 units long, gunwale 12 px, its ends 3 px higher),
  boat_2  clinker strakes on the near side, the dark inside with ribs and two thwarts, a short mast (30 px) near the
          bow with its loading spar; boat_2 the same along ground y (its near side is then the shaded right face). The
          procedural boat picks its axis from the seed; a sprite boat lies along the river holding it
          (DecorSprites.name_for: boat_2 on TownLayout.RIVER_WEST, else boat_1). Anchored at the hull's waterline
          centre. Both draw at the procedural boat's ArtTuning scale (boat 1.12), like it. Their wood is lifted
          (BOAT_LIFT) toward the procedural boat's brightness; the ship keeps the sheet barrel's tones.

Usage (from anywhere):
  python tools/dev/ref_convert/decor_water.py [all | ship | boat] [--out <scratch dir>]   (--out: PNGs only)
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
import decor_goods  # noqa: E402

OUTLINE = tuple(int(v) for v in convert.OUTLINE)

# Fixed colours (none reaches check_sprite_glow's glow rule).
CLOTH = ((166, 152, 124), (198, 186, 160), (226, 216, 192), (240, 233, 214))     # seam, shade, body, lit
PENNANT = ((31, 69, 166), (53, 99, 200))                                         # ArtKit.BANNER[0], [1]
# The ship is a 4-frame strip at 5 fps (Group C): only the pennant moves. A wave runs out along it (period
# PENNANT_WAVE columns, a quarter a frame), each column lifted or dropped by round(amp * (wave now - wave at frame
# 0)), the amp growing from 0 at the mast to PENNANT_AMP at the tip; its tip reaches out and draws back a px.
SHIP_FPS = 5.0
PENNANT_LEN = 11
PENNANT_WAVE = 8.0
PENNANT_AMP = 1.0
PENNANT_REACH = (0, -1, 0, 1)
ROPE = (58, 44, 32)
SHROUD_DROP = 6.0                    # a shroud leaves its mast this many px under the masthead
SHROUD_AFT = 0.12                    # and comes down to the rail this far aft of the mast (units)
WAKE = (190, 226, 246)
# The rowing boats' wood: the sheet barrel's tones lifted this far toward the stalls' timber (decor_goods.sheet_tones),
# so at the river's zoom (0.5) they read about as light as the procedural boat (ArtKit.WOOD); the ship keeps lift 0.
BOAT_LIFT = 0.5


class WaterCanvas(decor_goods.Canvas):
    """decor_goods.Canvas plus screen-space polygons, bare pixels (no outline ring: ropes, the wake) and per-pixel
    alpha (the wake is see-through)."""

    def __init__(self, w=220, h=200, ox=100, oy=150, lift=0.0):
        super().__init__(w, h, ox, oy, lift=lift, soft=False)
        self.bare = np.zeros_like(self.a)
        self.alpha = np.ones(self.a.shape)
        self.under = []                      # (mask, rgb, alpha): painted after the outline, on clear pixels only

    def poly(self, pts, col):
        """Fill the screen polygon `pts` (px from the ground point), even-odd at pixel centres. `col` is an RGB, or
        fn(cx, cy) giving wood tone indices."""
        x, y = self.cx, self.cy
        inside = np.zeros_like(self.a)
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if y0 == y1:
                continue
            cross = ((y0 <= y) & (y < y1)) | ((y1 <= y) & (y < y0))
            xi = x0 + (y - y0) * (x1 - x0) / (y1 - y0)
            inside ^= cross & (x < xi)
        if callable(col):
            self.put(inside, self.tones(np.asarray(col(x, y), int) * np.ones_like(x, int)))
        else:
            self.put(inside, col)
        self.bare &= ~inside
        return inside

    def bare_line(self, p0, p1, col, alpha=1.0):
        """A 1 px line that gets no outline ring."""
        before = self.a.copy()
        keep = self.rgb.copy()
        self.line(p0, p1, col)
        new = self.a & ~before
        self.bare |= new
        self.alpha[new] = alpha
        self.rgb[before] = keep[before]      # never paint over what is there

    def rope_line(self, p0, p1, col, alpha=1.0, keep=None):
        """A 1 px rope drawn over what is there (rigging seen across the sails, as the procedural ship draws it): on
        clear pixels a bare line (no outline ring) at `alpha`; over the drawing, `col` blended in by `alpha` (the
        pixel stays opaque). Pixels in `keep` (a mask: the pennant) are left alone."""
        before = self.a.copy()
        old = self.rgb.copy()
        self.a = np.zeros_like(before)
        self.line(p0, p1, col)
        line = self.a if keep is None else self.a & ~keep
        self.a, self.rgb = before | line, old
        new = line & ~before
        over = line & before
        self.rgb[new] = col
        self.bare |= new
        self.alpha[new] = alpha
        self.rgb[over] = old[over] * (1.0 - alpha) + np.array(col, float) * alpha

    def under_line(self, p0, p1, col, alpha):
        """A 1 px see-through line (the wake) painted after the outline ring, only where nothing else is."""
        keep_rgb, keep_a = self.rgb.copy(), self.a.copy()
        self.line(p0, p1, col)
        self.under.append((self.a & ~keep_a, np.array(col, float), alpha))
        self.rgb, self.a = keep_rgb, keep_a

    def finish(self):
        a = self.a
        solid = a & ~self.bare
        p = np.pad(solid, 1)
        ring = ~a & (p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:])
        rgb = self.rgb.copy()
        rgb[ring] = OUTLINE
        alpha = np.where(ring, 1.0, np.where(a, self.alpha, 0.0))
        for m, col, al in self.under:
            m = m & (alpha == 0)
            rgb[m] = col
            alpha[m] = al
        ys, xs = np.nonzero(alpha > 0)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        out = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        out[..., :3] = np.round(rgb[y0:y1, x0:x1]).astype(np.uint8)
        out[..., 3] = np.round(alpha[y0:y1, x0:x1] * 255).astype(np.uint8)
        return Image.fromarray(out, "RGBA"), (self.o[0] - x0, self.o[1] - y0)


def _lerp_y(cx, a, b):
    """The screen y of segment a->b at screen x `cx` (clamped to its ends)."""
    if b[0] == a[0]:
        return np.full_like(cx, min(a[1], b[1]))
    t = np.clip((cx - a[0]) / (b[0] - a[0]), 0.0, 1.0)
    return a[1] + t * (b[1] - a[1])


def strakes(top, bend, lit, rail=True, wale=4, step=4):
    """Tone fn for a hull side under the edge top=(a, b) (screen points), its bend (where it turns under) bend=(a, b):
    a light rail row, a dark wale `wale` px down, clinker strakes `step` px deep (a lit lap row on top, a seam row
    at the foot),
    darker below the bend. lit: the near side faces left (light) or right (shade)."""
    hi, mid, lo, seam = (4, 3, 2, 1) if lit else (3, 2, 1, 0)

    def fn(cx, cy):
        d = np.floor(cy - _lerp_y(cx, *top))
        below = cy >= _lerp_y(cx, *bend)
        k = np.mod(d - (wale + 1), step)
        out = np.where(k == step - 1, seam, np.where(k == 0, mid, lo))
        out = np.where(d < wale, mid, out)
        out = np.where(d == wale, seam - 1, out)
        if rail:
            out = np.where(d < 1, hi + 1, np.where(d < 2, hi, out))
        out = np.where(below, np.where(np.mod(d, step) == step - 1, seam - 1, seam), out)
        return out
    return fn


# ---- the ship (DecorArt._ship's geometry) ----
HL, HW, DECK = 1.55, 0.5, 20.0
SIDE = [(-HL, HW * 0.8), (-HL * 0.5, HW), (HL * 0.4, HW), (HL * 0.8, HW * 0.55), (HL + 0.25, 0.0)]
LIFT = [6.0, 0.0, 0.0, 2.0, 8.0]
MASTS = [(-0.3, 64.0, 1.3), (0.65, 48.0, 0.9)]       # x, height above the deck, sail span (units toward the stern)


def pennant_dy(i, frame):
    """Column i's (1 at the mast) lift in frame `frame`: 0 in frame 0, so frame 0 is the still and frame 4 frame 0."""
    a = PENNANT_AMP * i / PENNANT_LEN
    ph = 2 * math.pi * i / PENNANT_WAVE
    return int(round(a * (math.sin(ph - math.pi / 2 * frame) - math.sin(ph))))


def ship(frame=0):
    cv = WaterCanvas()
    P = cv.iso

    # The deck: planks along the hull (a seam every 2/16 unit across), a dark hatch.
    deck = [P(x, y * 0.85, DECK - 1) for x, y in SIDE] + [P(x, -y * 0.85, DECK - 1) for x, y in reversed(SIDE)]

    def planks(cx, cy):
        """Planks along the hull, 3/32 unit wide (3 px rows on screen): a seam row, then two rows, every other plank
        a tone darker."""
        s, q = cx / 32.0, (cy + DECK - 1) / 16.0
        r = np.floor((q - s) / 2.0 * 32.0)
        return np.where(np.mod(r, 3) == 0, 2, np.where(np.mod(np.floor(r / 3), 2) == 0, 4, 3))
    cv.poly(deck, planks)
    # Its far edge: a lit row (no far bulwark above the deck: the dock and the people on it are behind this side,
    # and the procedural ship has none either).
    for i in range(len(SIDE) - 1):
        (ax, ay), (bx, by) = SIDE[i], SIDE[i + 1]
        cv.line(P(ax, -ay * 0.85, DECK - 1), P(bx, -by * 0.85, DECK - 1), cv.tones(np.array([[5]]))[0, 0])
    cv.poly([P(0.3, -0.15, DECK), P(0.7, -0.15, DECK), P(0.7, 0.15, DECK), P(0.3, 0.15, DECK)],
            lambda x, y: np.where(np.mod(np.floor(x), 3) == 0, 0, -1))

    # The stern castle: its front bulkhead (shaded), its near wall (lit), its sloping top, a railing.
    c0, c1 = -HL, -HL + 0.7
    cw0, cw1 = HW * 0.8, HW * 0.9
    cv.poly([P(c1, -cw1, DECK + 10), P(c1, cw1, DECK + 10), P(c1, cw1, DECK), P(c1, -cw1, DECK)],
            lambda x, y: np.where(np.mod(np.floor(y), 3) == 2, 0, 1))
    cv.poly([P(c0, -cw0, DECK + 12), P(c1, -cw1, DECK + 10), P(c1, cw1, DECK + 10), P(c0, cw0, DECK + 12)],
            lambda x, y: np.full_like(x, 4, dtype=int))
    top = (P(c0, cw0, DECK + 12), P(c1, cw1, DECK + 10))
    cv.poly([top[0], top[1], P(c1, cw1, DECK + 2), P(c0, cw0, DECK + 6)],
            lambda x, y: np.where(y - _lerp_y(x, *top) < 1, 4, np.where(np.mod(np.floor(y - _lerp_y(x, *top)), 3) == 2, 2, 3)))
    rail = (P(c0, cw0, DECK + 15), P(c1, cw1, DECK + 13))
    m = cv.poly([rail[0], rail[1], top[1], top[0]], (0, 0, 0))
    edge = (cv.cy - _lerp_y(cv.cx, *rail)) < 1
    post = np.mod(np.floor(cv.cx), 3) == 0
    cv.rgb[m & edge] = cv.tones(np.array([[4]]))[0, 0]
    cv.rgb[m & ~edge & post] = cv.tones(np.array([[2]]))[0, 0]
    cv.a &= ~(m & ~edge & ~post)                 # clear between the railing's posts

    # Masts and their gaff sails, aft mast first (the fore sail lies over it).
    for x, tall, span in MASTS:
        foot, head_pt = P(x, 0, DECK), P(x, 0, DECK + tall)
        head, foot_h = DECK + tall - 8.0, DECK + 12.0
        s0, s1, s2, s3 = P(x - span, 0, head + 6), P(x, 0, head), P(x, 0, foot_h), P(x - span, 0, foot_h + 4)

        def cloth(cx, cy, s0=s0, s1=s1, s2=s2, s3=s3):
            u = (cx - s0[0]) / (s1[0] - s0[0])
            ty, by = _lerp_y(cx, s0, s1), _lerp_y(cx, s3, s2)
            k = np.where(u < 0.4, 3, np.where(u < 0.62, 2, 1))
            panel = np.mod(np.floor(cx - s0[0]), 7) == 6
            return np.where(panel, np.maximum(k - 2, 0), k)
        m = cv.poly([s0, s1, s2, s3], (0, 0, 0))
        idx = cloth(cv.cx, cv.cy)
        cv.rgb[m] = np.array(CLOTH, float)[idx[m]]
        # The gaff along the head, the boom along the foot (wood, 1 px).
        cv.line(s0, s1, cv.wood[0])
        cv.line(s3, s2, cv.wood[1])
        # The mast: 3 px at the foot, 2 at the head, lit left.
        mx = foot[0]
        for dx, k in ((-1, 3), (0, 2), (1, 1)):
            h = tall if dx < 1 else tall * 0.6
            cv.put((np.floor(cv.cx) == math.floor(mx) + dx) & (cv.cy < foot[1]) & (cv.cy >= foot[1] - h),
                   cv.tones(np.full(cv.a.shape, k)))
        cv.put((np.floor(cv.cx) == math.floor(mx)) & (cv.cy < head_pt[1] + 2) & (cv.cy >= head_pt[1]), cv.tones(np.full(cv.a.shape, 4)))

    # The stem's far face (toward +x, shaded), seen past the bow.
    (ax, ay), (bx, by) = SIDE[-2], SIDE[-1]
    fa, fb = P(ax, -ay * 0.85, DECK - 1), P(bx, by, DECK + LIFT[-1])   # its far end at the deck's edge
    cv.poly([fb, fa, P(ax * 0.97, -ay * 0.55, -1), P(bx * 0.97, 0, -1)],
            strakes((fa, fb), (P(ax, -ay * 0.8, 5), P(bx, 0, 5)), False))
    # The near side, segment by segment: rail, wale, clinker strakes, the dark turn under the bend to the water.
    for i in range(len(SIDE) - 1):
        (ax, ay), (bx, by) = SIDE[i], SIDE[i + 1]
        ta, tb = P(ax, ay, DECK + LIFT[i]), P(bx, by, DECK + LIFT[i + 1])
        ma, mb = P(ax, ay * 0.8, 5), P(bx, by * 0.8, 5)
        wa, wb = P(ax * 0.97, ay * 0.55, -1), P(bx * 0.97, by * 0.55, -1)
        cv.poly([ta, tb, mb, wb, wa, ma], strakes((ta, tb), (ma, mb), True))
    # The stern's transom edge: a dark post down the stern.
    cv.line(P(-HL, HW * 0.8, DECK + 6), P(-HL * 0.97, HW * 0.44, 0), cv.tones(np.array([[0]]))[0, 0])

    # The bowsprit (2 px: lit top, dark under).
    sprit = P(HL + 0.8, 0, DECK + 18)
    cv.line(P(HL, 0, DECK + 7), sprit, cv.wood[3])
    cv.line(P(HL, 0, DECK + 6), (sprit[0], sprit[1] + 1), cv.wood[0])
    # The pennant at the main masthead.
    f = P(-0.3, 0, DECK + 64)
    fx, fy = math.floor(f[0]), math.floor(f[1])
    pennant = np.zeros_like(cv.a)
    for j in range(5):
        w = round((PENNANT_LEN + PENNANT_REACH[frame]) * (1 - abs(j - 2) / 3.0))
        for i in range(1, w + 1):
            m = (np.floor(cv.cx) == fx + i) & (np.floor(cv.cy) == fy + j + pennant_dy(i, frame))
            cv.put(m, PENNANT[1] if j < 2 else PENNANT[0])
            pennant |= m
    # The rigging, 1 px ropes as the procedural ship's, the same in every frame (only the pennant moves, and it stays
    # over them). Behind the sails (bare, the sails' pixels win): each mast's shroud to the far rail, and the main
    # mast's backstay down to the stern (it lies in the sails' plane). The fore mast has no stay to the stern: from
    # its masthead that stay ran level across both sails (the stern is as high on screen as the fore top), so its
    # shrouds hold it aft. Then over everything: each shroud to the near rail and each forestay to the bowsprit's end
    # (both diagonal).
    for x, tall, _span in MASTS:
        cv.bare_line(P(x, 0, DECK + tall - SHROUD_DROP), P(x - SHROUD_AFT, -HW * 0.85, DECK - 1), ROPE, 0.8)
    main_x, main_tall, _span = MASTS[0]
    cv.bare_line(P(main_x, 0, DECK + main_tall), P(-HL, 0, DECK + 12), ROPE, 0.8)
    for x, tall, _span in MASTS:
        top_pt = P(x, 0, DECK + tall)
        cv.rope_line(P(x, 0, DECK + tall - SHROUD_DROP), P(x - SHROUD_AFT, HW * 0.97, DECK + 1), ROPE, 0.9,
                     keep=pennant)
        cv.rope_line(top_pt, sprit, ROPE, 1.0, keep=pennant)
    # The wake along the near waterline, see-through.
    cv.under_line(P(-HL + 0.1, HW * 0.75, 0), P(HL, HW * 0.3, 0), WAKE, 0.7)
    cv.under_line(P(HL + 0.1, 0.1, 0), P(HL + 0.35, 0.25, 0), WAKE, 0.6)
    return cv.finish()


# ---- the rowing boat (DecorArt._boat's geometry) ----
BHL, BHW, GUN = 0.75, 0.32, 12.0


def boat(along_x):
    cv = WaterCanvas(140, 120, 70, 90, lift=BOAT_LIFT)

    def P(u, v, z):
        return cv.iso(u, v, z) if along_x else cv.iso(v, u, z)

    rim = []
    for i in range(9):
        u = -BHL + 2 * BHL * i / 8.0
        rim.append((u, BHW * math.sqrt(max(0.0, 1.0 - (u / BHL) ** 4))))
    rise = lambda u: 3.0 if abs(u) > BHL * 0.9 else 0.0
    # The inside: the gunwale outline, dark, its floorboards across; the far gunwale's lit rail.
    gun = [P(u, v, GUN + rise(u)) for u, v in rim] + [P(u, -v, GUN + rise(u)) for u, v in reversed(rim)]
    def floor_boards(cx, cy):
        """Boards along the hull (a darker seam every 3 px across it)."""
        s, q = cx / 32.0, (cy + GUN) / 16.0
        v = (q - s) / 2.0 if along_x else (q + s) / 2.0
        return np.where(np.mod(np.floor(v * 32.0), 3) == 0, -1, 0)
    cv.poly(gun, floor_boards)
    for i in range(8):
        (ua, va), (ub, vb) = rim[i], rim[i + 1]
        cv.line(P(ua, -va, GUN + rise(ua)), P(ub, -vb, GUN + rise(ub)), cv.wood[3])
    # Ribs, then two thwarts (seats, a lit top row).
    for k in (-0.45, -0.1, 0.25, 0.55):
        cv.line(P(k, -BHW * 0.85, GUN - 1), P(k, BHW * 0.85, GUN - 1), cv.wood[1])
    for k in (-0.28, 0.4):
        cv.poly([P(k - 0.05, -BHW * 0.8, GUN - 1), P(k + 0.05, -BHW * 0.8, GUN - 1), P(k + 0.05, BHW * 0.8, GUN - 1),
                 P(k - 0.05, BHW * 0.8, GUN - 1)], lambda x, y: np.full_like(x, 3, dtype=int))
    # The short mast near the bow (2 px, lit left), its foot inside the hull.
    foot, top_pt = P(-BHL * 0.55, 0, GUN), P(-BHL * 0.55, 0, GUN + 30)
    mx = math.floor(foot[0])
    for dx, k in ((0, 3), (1, 1)):
        cv.put((np.floor(cv.cx) == mx + dx) & (cv.cy < foot[1]) & (cv.cy >= top_pt[1]), cv.tones(np.full(cv.a.shape, k)))
    # The near side: strakes down to the water.
    for i in range(8):
        (ua, va), (ub, vb) = rim[i], rim[i + 1]
        ta, tb = P(ua, va, GUN + rise(ua)), P(ub, vb, GUN + rise(ub))
        wa, wb = P(ua, va * 0.7, 0), P(ub, vb * 0.7, 0)
        if ta[0] > tb[0]:
            ta, tb, wa, wb = tb, ta, wb, wa
        bend = ((wa[0], wa[1] - 3), (wb[0], wb[1] - 3))
        cv.poly([ta, tb, wb, wa], strakes((ta, tb), bend, along_x, wale=4, step=3))
    # The loading spar slanting back from the masthead, its rope down (bare).
    spar_end = P(BHL * 0.2, 0, GUN + 22)
    cv.line((top_pt[0], top_pt[1] + 2), spar_end, cv.wood[0])
    cv.line((top_pt[0], top_pt[1] + 3), (spar_end[0], spar_end[1] + 1), cv.wood[2])
    cv.bare_line((spar_end[0], spar_end[1] + 2), P(BHL * 0.2, 0, GUN + 4), ROPE, 0.6)
    cv.under_line(P(-BHL * 0.7, BHW * 0.75, -2), P(BHL * 0.7, BHW * 0.75, -2), WAKE, 0.6)
    return cv.finish()


SETS = {
    "ship": [("ship", lambda: decor_common.strip([ship(k) for k in range(4)]))],
    "boat": [("boat_1", lambda: boat(True)), ("boat_2", lambda: boat(False))],
}


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
                anim = {"frames": 4, "fps": SHIP_FPS} if name == "ship" else {}
                print(name, img.size, anchor, "->", decor_common.write_set(name, img, anchor, **anim))


if __name__ == "__main__":
    main()
