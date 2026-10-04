"""The windmill and the watermill, after the combined mill of TownMap_Component1 (row 3, 3rd: a round plastered tower
under a wooden cap with four lattice sails, a red-tiled timber cottage on its left and an undershot wheel in a race on
its right). No AI calls.

  windmill   HOUSE / farm / windmill,  footprint 0.9 x 0.9 (TownLayout.WINDMILL), height 60. The sheet's tower: round,
             tapering, cream plaster on a stone foot, a plank door, small timber-framed windows, a wooden cap; its four
             lattice sails turn in front of it, high on its left face (where the procedural mill's turn).
  watermill  HOUSE / farm / watermill, footprint 2.4 x 1.9 (TownLayout.WATERMILL), height 34. The sheet's cottage
             (red tile roof, plaster and timber walls, lit windows) with the sheet's wheel (eight spokes, boxed paddles)
             against its long left wall, standing in a stone-lined race, where the procedural wheel stands.

Why drawn, not cut: on the sheet the four sails cross the tower, the cap and the cottage; the wheel and two bushes hide
the rest of the tower's foot; the cottage's gable is behind a sail. Cutting the sails and wheel out would leave most
of each body to repaint, and the user rejects sampled, patched texture ("a mess and rough"). So each body is drawn
clean, in flat tones picked from the sheet's own mill, on the game's 2:1 geometry (as warehouse.py draws its walls):
the round tower in five tone bands across its width (lit from the left; the sheet lights its tower from the right), the
cap in shaded facets with shingle courses, the cottage's walls, gable and tile courses face by face. No stone arch
frames: openings have timber frames.

The turning parts are drawn geometrically each frame, as polygons rotated in their own plane and rasterised 4x
supersampled, each pixel taking the weighted majority colour of its 16 samples (bars and stocks weigh more, so they
never break up), then the 1 px outline. Never a bitmap rotation.
  sails  in the plane of the tower's left face (u = (1, 0.5), v = (0, -1) px, as the procedural sails and wheel),
         four stocks with a lattice of two columns by five rows of cloth on their trailing side; 8 frames over 90 deg
         (the four sails are symmetric, so that is a whole turn's loop), 8 fps.
  wheel  in the plane of the cottage's left wall, 0.06..0.28 cells out from it: back rim and dark inside, 16 boxed
         paddles, 8 spokes, front rim, iron hub; clipped at the race's water line plane by plane; 8 frames over 45 deg
         (one spoke spacing, two paddle spacings), 8 fps, with foam at its foot and ripples in the race stepping on the
         same 8-frame loop.
Loop check: frame 8 (the one after the last) is drawn from its own angle, without wrapping it, and must equal frame 0.

States: intact (frame 0 of the idle strip), damaged (still: the windmill's sails broken -- one snapped, one a stub, one
with its cloth burnt out -- a hole through the cap and soot up the tower over the door; the watermill's wheel cracked,
three paddles gone, a spoke snapped, a hole through the roof and soot over the door), ruins (the approved ruins of the
closest set placed on the plot: town_tower's for the round tower, scaled 0.9 / 1.6 and snapped to its palette as the
bell tower's; the tavern's for the red-tiled cottage, its footprint as wide, unscaled, centred). Collapse: the engine's.

Usage (from anywhere):
  python tools/dev/ref_convert/mills.py [all | windmill | watermill] [--out <scratch dir>] [--debug <dir>]
"""
import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bridges  # noqa: E402
import convert  # noqa: E402
import warehouse  # noqa: E402

ROOT = convert.ROOT
B = convert.B
SHEET = ROOT / "concepts" / "TOWN REF" / "TownMap_Component1.png"
SHEET_BOX = (800, 570, 1090, 850)        # the combined mill (row 3, 3rd); its tones are picked from it
SS = 4                                   # supersampling of the turning parts
FRAMES = 8
FPS = 8
PAD = 6
CW, CH = 320, 300                        # the roomy drawing canvas; the front corner A sits at A0
A0 = (170, 230)

# --- tones (RGB), from the sheet's mill ------------------------------------------------------------------------------
PLASTER_T = [np.array(v, float) for v in ((240, 220, 182), (222, 194, 154), (196, 162, 126), (164, 130, 100),
                                          (136, 106, 84))]
STONE_T = [np.array(v, float) for v in ((164, 158, 148), (146, 140, 130), (124, 118, 110), (102, 98, 92),
                                        (86, 82, 78))]
CAP_T = [np.array(v, float) for v in ((176, 92, 42), (150, 74, 34), (124, 58, 28), (100, 46, 22), (82, 38, 18))]
CAP_LINE = np.array([72, 34, 16.0])
WOOD = np.array([152, 92, 42.0])         # sail frames, the wheel
WOOD_LT = np.array([182, 116, 54.0])
WOOD_DK = np.array([104, 60, 26.0])
STOCK = np.array([92, 54, 26.0])
CLOTH = np.array([246, 230, 196.0])
CLOTH_SH = np.array([222, 202, 166.0])
WHEEL_IN = np.array([58, 38, 22.0])
IRON = np.array([70, 70, 76.0])
TILE = np.array([178, 66, 42.0])
TILE_SEAM = np.array([152, 52, 34.0])
TILE_LINE = np.array([122, 40, 26.0])
RIDGE = np.array([112, 36, 24.0])
WATER = np.array([62, 118, 166.0])
WATER_LT = np.array([104, 160, 204.0])
FOAM = np.array([226, 240, 248.0])
LIT_GLASS = np.array([246, 180, 66.0])   # a lit window: the sprite shader keeps it bright at night
PLASTER, PLASTER_LO = warehouse.PLASTER, warehouse.PLASTER_LO
TIMBER, TIMBER_DK, TIMBER_LT = warehouse.TIMBER, warehouse.TIMBER_DK, warehouse.TIMBER_LT
DOOR, GLASS = warehouse.DOOR, warehouse.GLASS
STONE, STONE_DK = warehouse.STONE, warehouse.STONE_DK
CHAR = warehouse.CHAR
SHADE = warehouse.SHADE

SETS = {
    # name: footprint, height, seed, ruins source, ruins scale
    "windmill": ([0.9, 0.9], 60, 72, "town_tower", 0.9 / 1.6),
    "watermill": ([2.4, 1.9], 34, 73, "tavern", 1.0),
}

# windmill geometry: tower base and top radius (cells), wall height and cap rise (px), sail length and width (px)
TW_RB, TW_RT, TW_H, CAP_RISE = 0.56, 0.44, 64.0, 22.0
SAIL_L, SAIL_W, SAIL_S0 = 52.0, 12.0, 8.0
SAIL_UNIT = 90.0 / FRAMES                # degrees per frame; sails sit at 45 deg + k 90 deg
# watermill geometry (cells / px): wall height, ridge height, roof overhang; the wheel's axle along the wall (cells
# from the west corner), height and radius, its back and front planes (cells out from the wall)
WM_WH, WM_ZR, WM_O = 22.0, 46.0, 0.12
WHEEL_AT, WHEEL_Z, WHEEL_R = 0.9, 21.0, 22.0
WHEEL_B, WHEEL_F = 0.06, 0.28
WHEEL_UNIT = 45.0 / FRAMES               # degrees per frame; spokes every 8 units, paddles every 4, rim segments 2
RACE = (-0.05, 1.85, 0.5)                # the race: from / to along the wall (cells from the west corner), its width


def P(A, gx, gy, z):
    """Sprite px of ground point (gx, gy) (cells from the front corner A; the building at gx, gy <= 0) z px up."""
    return (A[0] + (gx - gy) * 32.0, A[1] + (gx + gy) * 16.0 - z)


def _noise(a, b):
    """A fixed hash of two coordinate arrays, 0..1 (ragged burnt edges)."""
    v = np.sin(np.floor(a) * 12.9898 + np.floor(b) * 78.233) * 43758.5453
    return v - np.floor(v)


def burn(out, keep, x, y, cx, cy, rx, ry):
    """A hole burnt through a roof or cap (pixels `keep`, coordinates x, y): a dark inside with rafters across it,
    a ragged charred rim, soot round it."""
    r = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + _noise(x / 2.0, y / 2.0) * 0.8 + _noise(x, y) * 0.2
    soot = keep & (r < 2.7)
    out[soot] = out[soot] * 0.62 + CHAR * 0.38
    rim = keep & (r < 1.6)
    out[rim] = CHAR * 0.9
    inside = keep & (r < 1.05)
    out[inside] = CHAR * 0.45
    raf = inside & ((np.floor(x - cx) % 4) == 0)
    out[raf] = TIMBER_DK * 0.7
    return out


def over(dst, src):
    m = src[..., 3] > 0
    dst[m] = src[m]
    return dst


# --- supersampled polygons -------------------------------------------------------------------------------------------
class Hi:
    """Polygons at SS x, each a flat colour with a weight; down() gives each pixel the weighted majority colour of its
    samples when at least half of them are covered, else transparent."""

    def __init__(self, w=CW, h=CH):
        self.w, self.h = w, h
        self.im = Image.new("I", (w * SS, h * SS), 0)
        self.d = ImageDraw.Draw(self.im)
        self.cols, self.wts, self.idx = [np.zeros(3)], [0.0], {}

    def _i(self, rgb, wt):
        key = (tuple(int(round(v)) for v in rgb), float(wt))
        if key not in self.idx:
            self.idx[key] = len(self.cols)
            self.cols.append(np.array(key[0], float))
            self.wts.append(key[1])
        return self.idx[key]

    def poly(self, pts, rgb, wt=1.0):
        # vertices rounded to 1/100 of a sample: a turn's float noise (cos 405 deg vs cos 45 deg) never flips one
        self.d.polygon([(round(x * SS - 0.5, 2), round(y * SS - 0.5, 2)) for x, y in pts], fill=self._i(rgb, wt))

    def bar(self, p0, p1, width, rgb, wt=2.0):
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        n = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / n * width / 2, dx / n * width / 2
        self.poly([(p0[0] + nx, p0[1] + ny), (p1[0] + nx, p1[1] + ny), (p1[0] - nx, p1[1] - ny),
                   (p0[0] - nx, p0[1] - ny)], rgb, wt)

    def blob(self, c, rx, ry, rgb, wt=2.0):
        self.d.ellipse([(c[0] - rx) * SS - 0.5, (c[1] - ry) * SS - 0.5, (c[0] + rx) * SS - 0.5,
                        (c[1] + ry) * SS - 0.5], fill=self._i(rgb, wt))

    def down(self):
        a = np.array(self.im, dtype=np.int32)
        h, w = self.h, self.w
        blk = a.reshape(h, SS, w, SS).transpose(0, 2, 1, 3).reshape(h, w, SS * SS)
        k = len(self.cols)
        cnt = np.stack([(blk == i).sum(-1) for i in range(k)]).astype(float)
        # ties go to the darker colour, whatever order the polygons came in (frame 8 must equal frame 0)
        tie = np.array([1e-3 * (1.0 - c.sum() / 766.0) for c in self.cols[1:]])
        score = cnt[1:] * np.array(self.wts[1:])[:, None, None] + (cnt[1:] > 0) * tie[:, None, None]
        best = score.argmax(0)
        out = np.zeros((h, w, 4))
        keep = (SS * SS - cnt[0]) * 2 >= SS * SS
        out[..., :3] = np.array(self.cols[1:])[best]
        out[..., 3] = np.where(keep, 255, 0)
        out[~keep] = 0
        return out


# --- flat faces ------------------------------------------------------------------------------------------------------
def face(c, A, O, E1, E2, fn):
    """Paint the parallelogram O + s E1 + t E2 (0 <= s, t <= 1; 3D cells/px vectors) on c (float RGBA), sampling at
    pixel centres. fn(s, t) -> (rgb (N, 3), keep (N,) bool)."""
    o = P(A, *O)
    e1 = ((E1[0] - E1[1]) * 32.0, (E1[0] + E1[1]) * 16.0 - E1[2])
    e2 = ((E2[0] - E2[1]) * 32.0, (E2[0] + E2[1]) * 16.0 - E2[2])
    xs = [o[0], o[0] + e1[0], o[0] + e2[0], o[0] + e1[0] + e2[0]]
    ys = [o[1], o[1] + e1[1], o[1] + e2[1], o[1] + e1[1] + e2[1]]
    x0, x1 = max(0, int(math.floor(min(xs)))), min(c.shape[1], int(math.ceil(max(xs))) + 1)
    y0, y1 = max(0, int(math.floor(min(ys)))), min(c.shape[0], int(math.ceil(max(ys))) + 1)
    yy, xx = np.mgrid[y0:y1, x0:x1]
    px, py = xx + 0.5 - o[0], yy + 0.5 - o[1]
    det = e1[0] * e2[1] - e1[1] * e2[0]
    s = (px * e2[1] - py * e2[0]) / det
    t = (e1[0] * py - e1[1] * px) / det
    inside = (s >= 0) & (s <= 1) & (t >= 0) & (t <= 1)
    if not inside.any():
        return c
    rgb, keep = fn(s[inside], t[inside])
    ys_, xs_ = yy[inside][keep], xx[inside][keep]
    c[ys_, xs_, :3] = rgb[keep]
    c[ys_, xs_, 3] = 255
    return c


def _pick(conds, default):
    """np.select over (cond, rgb) pairs, rgb broadcast to (N, 3)."""
    n = len(conds[0][0]) if conds else len(default)
    out = np.tile(np.asarray(default, float), (n, 1)) if np.ndim(default) == 1 else default.copy()
    for cond, rgb in reversed(conds):
        out[cond] = rgb
    return out


# --- the windmill ----------------------------------------------------------------------------------------------------
def _band(n):
    """Tone band across a round surface lit from the left: n = -1 (left limb) .. 1 (right limb)."""
    return np.select([n < -0.86, n < -0.1, n < 0.42, n < 0.8], [1, 0, 1, 2], 3)


def tower(c, A, state):
    """The round tower, scanned up from its foot: each height's front arc, coloured by band, course and opening."""
    C = P(A, -0.45, -0.45, 0)
    openings = [  # (n0, n1, z0, z1, kind)
        (-0.52, -0.2, 0.0, 11.0, "door"), (0.2, 0.34, 21.0, 26.0, "glass"), (-0.4, -0.26, 33.0, 38.0, "lit"),
        (-0.05, 0.09, 47.0, 52.0, "glass")]
    for zi in range(int(TW_H * 4) + 1):
        z = zi / 4.0
        r = TW_RB + (TW_RT - TW_RB) * z / TW_H
        hx, hy = 32.0 * math.sqrt(2) * r, 16.0 * math.sqrt(2) * r
        xs = np.arange(int(C[0] - hx) - 1, int(C[0] + hx) + 2)
        n = (xs + 0.5 - C[0]) / hx
        ok = np.abs(n) <= 1
        xs, n = xs[ok], n[ok]
        ys = np.floor(C[1] - z + hy * np.sqrt(1 - n * n)).astype(int)
        band = _band(n)
        if z < 6:
            phi = np.arcsin(np.clip(n, -1, 1))
            joint = ((phi / 0.42 + (0.5 if z >= 3 else 0.0)) % 1.0) < 0.14
            rgb = np.array([STONE_T[b] for b in band])
            dark = joint | (abs(z - 3.0) < 0.3) | (z < 0.3)
            if dark.any():
                rgb[dark] = np.array([STONE_T[min(b + 2, 4)] for b in band[dark]])
        elif z < 7:
            rgb = np.array([STONE_T[min(b + 1, 4)] for b in band])     # the foot's top course, a little shadowed
        else:
            rgb = np.array([PLASTER_T[b] for b in band])
        if z >= TW_H - 2:
            rgb = np.array([PLASTER_T[min(b + 1, 4)] for b in band])
        for n0, n1, z0, z1, kind in openings:
            m = (n >= n0) & (n <= n1) & (z >= z0) & (z <= z1)
            if not m.any():
                continue
            edge = (n < n0 + 0.035) | (n > n1 - 0.035) | (z > z1 - 1.0)
            if kind == "door":
                k = np.floor((n - n0) / (n1 - n0) * 4.0)
                fill = np.where(((n - n0) / (n1 - n0) * 4.0 - k)[:, None] < 0.22, TIMBER_DK, DOOR)
                if state == "damaged":
                    fill = np.tile(CHAR * 0.7, (len(n), 1))
            else:
                fill = np.tile(LIT_GLASS if kind == "lit" and state == "intact" else GLASS, (len(n), 1))
            sel = np.where(m & edge, 0, 1)
            rgb[m] = np.where(sel[m][:, None] == 0, TIMBER_DK, fill[m])
        # the door's lintel and sill-less foot; windows' sills
        for n0, n1, z0, z1, kind in openings:
            m = (n >= n0 - 0.04) & (n <= n1 + 0.04) & (abs(z - (z1 + 1.0)) < 0.5)
            rgb[m] = TIMBER
        h, w = c.shape[:2]
        ok = (ys >= 0) & (ys < h)
        c[ys[ok], xs[ok], :3] = rgb[ok]
        c[ys[ok], xs[ok], 3] = 255
    return c


def cap(A, state):
    """The wooden cap: a cone in shaded facets (back ones first), shingle courses, an eave, a finial."""
    hi = Hi()
    C = P(A, -0.45, -0.45, TW_H)
    rc = TW_RT + 0.09
    hx, hy = 32.0 * math.sqrt(2) * rc, 16.0 * math.sqrt(2) * rc
    apex = (C[0], C[1] - CAP_RISE)
    seg = 24
    facets = []
    for i in range(seg):
        a0, a1 = 2 * math.pi * i / seg, 2 * math.pi * (i + 1) / seg
        am = (a0 + a1) / 2
        facets.append((math.sin(am), a0, a1, am))      # back facets (sin < 0) first
    # angle a round the cap: x = C.x - cos(a) hx (a = 0 the left limb), y = C.y + sin(a) hy (a in (0, pi) the front)

    def pt(a, k=1.0):
        return (C[0] - math.cos(a) * hx * k, C[1] + math.sin(a) * hy * k)

    for depth, a0, a1, am in sorted(facets):
        n = -math.cos(am)
        b = int(_band(np.array([n]))[0])
        tone = CAP_T[b] if math.sin(am) > 0 else CAP_T[min(b + 1, 4)]
        hi.poly([apex, pt(a0), pt(a1)], tone)
    # courses: front arcs part way down the cone, and the eave
    for f in (0.32, 0.56, 0.78):
        arc = [(apex[0] + (pt(a)[0] - apex[0]) * f, apex[1] + (pt(a)[1] - apex[1]) * f)
               for a in np.linspace(0.05, math.pi - 0.05, 16)]
        for p0, p1 in zip(arc, arc[1:]):
            hi.bar(p0, p1, 1.0, CAP_LINE, 1.6)
    arc = [pt(a) for a in np.linspace(-0.08, math.pi + 0.08, 20)]
    for p0, p1 in zip(arc, arc[1:]):
        hi.bar(p0, p1, 1.4, CAP_T[4], 2.0)
    # boards down the cone, two per side of the front
    for a in (0.55, 1.1, 1.65, 2.2, 2.75):
        hi.bar((apex[0], apex[1] + 2), pt(a, 0.97), 0.9, CAP_LINE, 1.2)
    hi.blob((apex[0], apex[1] - 1), 1.6, 1.6, WOOD_DK)
    out = hi.down()
    if state == "damaged":
        # a hole burnt through the cap's left side: dark inside, rafters, a charred rim, sooted boards round it
        hx0, hy0 = apex[0] - 7, apex[1] + 13
        h, w = out.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w].astype(float)
        out[..., :3] = burn(out[..., :3], out[..., 3] > 0, xx, yy, hx0, hy0, 5.2, 3.8)
    return out


def hub_point(A):
    """The sails' hub: out from the cap on the tower's left face, a little above the eave."""
    return P(A, -0.45, -0.45 + TW_RT + 0.24, TW_H + 4.0)


def sails(A, units, broken=False):
    """The windshaft, hub and four sails at `units` x SAIL_UNIT deg (not wrapped: frame FRAMES is drawn from its own
    angle). broken: the damaged set (sail 0 snapped, sail 1 a stub, sail 2 its cloth burnt out, sail 3 whole)."""
    hi = Hi()
    hub = hub_point(A)
    capc = P(A, -0.45, -0.45 + TW_RT * 0.6, TW_H + 4.0)
    hi.bar(capc, hub, 3.2, STOCK, 2.0)

    def S(p, q):
        return (hub[0] + p, hub[1] + p * 0.5 - q)

    for k in range(4):
        a = math.radians((units + FRAMES / 2 + k * FRAMES) * SAIL_UNIT)
        d, nrm = (math.cos(a), math.sin(a)), (-math.sin(a), math.cos(a))

        def Q(s, t):
            return S(s * d[0] + t * nrm[0], s * d[1] + t * nrm[1])

        length = SAIL_L
        cells = [(i, j) for i in range(5) for j in range(2)]
        if broken and k == 0:
            length = SAIL_L * 0.56
            cells = [(i, j) for i, j in cells if i < 2]
        elif broken and k == 1:
            length = 11.0
            cells = []
        elif broken and k == 2:
            cells = [(0, 0), (0, 1), (1, 0), (4, 1)]
        s0, w = SAIL_S0, SAIL_W
        span = (SAIL_L - s0) / 5.0
        if cells:
            last = max(i for i, _ in cells) + 1 if not (broken and k == 2) else 5
            s_end = s0 + span * last
            # cloth cells, then the lattice over them: two rails along, crossbars
            for i, j in cells:
                sa, sb = s0 + span * i, s0 + span * (i + 1)
                ta, tb = 1.0 + (w - 1.0) * j / 2, 1.0 + (w - 1.0) * (j + 1) / 2
                tone = CLOTH if j == 1 else CLOTH_SH
                if broken and k == 2:
                    tone = tone * 0.7 + CHAR * 0.3
                hi.poly([Q(sa, ta), Q(sb, ta), Q(sb, tb), Q(sa, tb)], tone, 1.0)
            for t in (1.0 + (w - 1.0) / 2, w):
                hi.bar(Q(s0, t), Q(s_end, t), 1.3, WOOD, 2.2)
            for i in range(last + 1):
                s = s0 + span * i
                hi.bar(Q(s, 0.6), Q(s, w + 0.5), 1.3, WOOD if i else WOOD_DK, 2.2)
        # the stock (whip) on top, from behind the hub to the tip
        hi.bar(Q(-2.0, 0.0), Q(length + 1.0, 0.0), 2.2, STOCK, 3.0)
        if broken and k in (0, 1):
            hi.poly([Q(length, -1.4), Q(length + 2.4, 0.2), Q(length + 0.6, 1.4)], STOCK, 3.0)  # splintered end
    hi.blob(hub, 3.2, 3.2, WOOD_DK, 4.0)
    hi.blob(hub, 1.4, 1.4, IRON, 5.0)
    return hi.down()


def windmill(state, frame=0):
    c = np.zeros((CH, CW, 4))
    A = A0
    tower(c, A, state)
    over(c, cap(A, state))
    if state == "damaged":
        C = P(A, -0.45, -0.45, 0)
        x = C[0] - 16
        c = warehouse.scorch(c, x - 10, x + 10, C[1] - 30, C[1] - 4)
    over(c, sails(A, frame if state == "intact" else 0, broken=(state == "damaged")))
    return c, A


# --- the watermill ---------------------------------------------------------------------------------------------------
def _wall_fn(run, posts, openings, shade, wh=WM_WH, gable=None):
    """A timber-framed plaster wall: u (px along it) = s run, v (px up) = t height."""
    def fn(s, t):
        u = s * run
        top = gable[1] if gable else wh
        v = t * top
        keep = np.ones(len(s), bool)
        if gable:
            keep = v <= wh + (gable[1] - wh) * (1 - np.abs(2 * u / run - 1)) + 0.5
        post = (u < 1.5) | (u > run - 1.5)
        for p in posts:
            post |= np.abs(u - p) < 0.8
        conds = [
            (v < 1.0, STONE_DK), (v < 2.6, STONE), (v < 3.6, TIMBER_DK),
            ((v >= wh - 1.0) & (v < wh + 0.6), TIMBER_DK), ((v >= wh - 2.2) & (v < wh), TIMBER),
            (post & (v < wh), TIMBER), (v < 6.5, PLASTER_LO),
        ]
        if gable:
            conds += [(np.abs(u - run / 2) < 0.8, TIMBER),
                      ((v > wh) & (np.abs(np.abs(u - run / 2) - (v - wh) * 0.9) < 0.7), TIMBER),
                      ((v > wh) & (v < wh + 1.6), TIMBER)]
        rgb = _pick(conds, PLASTER)
        for (u0, u1, v0, v1, kind) in openings:
            m = (u >= u0 - 1) & (u <= u1 + 1) & (v >= v0 - 1) & (v <= v1 + 1)
            edge = (u < u0) | (u > u1) | (v < v0) | (v > v1)
            if kind == "door":
                fill = np.where(((u - u0) % 3 < 0.9)[:, None], TIMBER_DK, DOOR)
            elif kind == "char":
                fill = np.tile(CHAR * 0.7, (len(u), 1))
            else:
                fill = np.tile(LIT_GLASS if kind == "lit" else GLASS, (len(u), 1))
                fill[np.abs(u - (u0 + u1) / 2) < 0.6] = TIMBER_DK
            rgb[m] = np.where(edge[m][:, None], TIMBER_DK, fill[m])
        if shade:
            lit = np.all(rgb == LIT_GLASS, axis=1)
            rgb[~lit] *= SHADE
        return rgb, keep
    return fn


def _roof_fn(run, slope, shade, hole=None):
    """Tile courses: u (px along the eave) = s run, d (px up the slope from the eave) = t slope."""
    def fn(s, t):
        u, d = s * run, t * slope
        course = np.floor(d / 4.5)
        k = d - course * 4.5
        seam = ((u + 3.0 * (course % 2)) % 6.0) < 1.0
        rgb = _pick([(d < 1.2, TILE_LINE), (d > slope - 2.0, RIDGE), (u < 1.2, TILE_LINE), (u > run - 1.2, TILE_LINE),
                     (k < 1.0, TILE_LINE), (seam, TILE_SEAM)], TILE)
        if hole:
            hu, hd, ru, rd = hole
            rgb = burn(rgb, np.ones(len(u), bool), u, d, hu, hd, ru, rd)
        if shade:
            rgb *= 0.72
        return rgb, np.ones(len(s), bool)
    return fn


def _stone_fn(run, shade, joint=8.0):
    def fn(s, t):
        u = s * run
        rgb = _pick([((u % joint) < 0.9, STONE_DK), (t > 0.7, STONE_T[0])], STONE)
        if shade:
            rgb *= SHADE
        return rgb, np.ones(len(s), bool)
    return fn


def _water_fn(run, frame):
    def fn(s, t):
        u = s * run
        shift = frame * 12.0 / FRAMES
        streak = (((u - shift) % 12.0) < 3.0) & (np.abs(t - 0.38) < 0.07)
        streak |= (((u - shift + 6.0) % 12.0) < 3.0) & (np.abs(t - 0.74) < 0.07)
        rgb = _pick([(t < 0.12, WATER * 0.8), (streak, WATER_LT)], WATER)
        return rgb, np.ones(len(s), bool)
    return fn


def wheel(A, units, broken=False):
    """Three layers (back: rim and dark inside; mid: paddles; front: spokes, rim, hub), each clipped at its plane's
    water line, composed back to front."""
    W = SETS["watermill"][0][0]
    gx = -W + WHEEL_AT
    layers = []

    def at(c, p, q):
        o = P(A, gx, c, WHEEL_Z)
        return (o[0] + p, o[1] + p * 0.5 - q)

    def ang(u):
        return math.radians(u * WHEEL_UNIT)

    def ring(hi, c, r0, r1, skip=(), tone=None):
        for i in range(32):
            if i in skip:
                continue
            a0, a1 = ang(units + 2 * i), ang(units + 2 * i + 2)
            col = tone if tone is not None else (WOOD_LT if math.sin((a0 + a1) / 2) > 0.2 else
                                                  WOOD if math.sin((a0 + a1) / 2) > -0.5 else WOOD_DK)
            hi.poly([at(c, r1 * math.cos(a0), r1 * math.sin(a0)), at(c, r1 * math.cos(a1), r1 * math.sin(a1)),
                     at(c, r0 * math.cos(a1), r0 * math.sin(a1)), at(c, r0 * math.cos(a0), r0 * math.sin(a0))],
                    col, 2.0)

    R = WHEEL_R
    back = Hi()
    disk = [at(WHEEL_B, (R - 3) * math.cos(a), (R - 3) * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 40)]
    back.poly(disk, WHEEL_IN)
    ring(back, WHEEL_B, R - 3, R, tone=WOOD_DK)
    layers.append((back, WHEEL_B))
    mid = Hi()
    gone = (5, 6, 7) if broken else ()
    for i in range(16):
        if i in gone:
            continue
        a = ang(units + 4 * i)
        r0, r1 = R - 4.0, R + 2.0
        col = WOOD_LT if math.sin(a) > 0.3 else WOOD if math.sin(a) > -0.4 else WOOD_DK
        b0, b1 = at(WHEEL_B, r0 * math.cos(a), r0 * math.sin(a)), at(WHEEL_B, r1 * math.cos(a), r1 * math.sin(a))
        f0, f1 = at(WHEEL_F, r0 * math.cos(a), r0 * math.sin(a)), at(WHEEL_F, r1 * math.cos(a), r1 * math.sin(a))
        mid.poly([b0, b1, f1, f0], col, 1.5)
        mid.bar(b1, f1, 1.1, WOOD_DK, 1.8)          # the paddle's outer edge
    layers.append((mid, (WHEEL_B + WHEEL_F) / 2))
    front = Hi()
    for i in range(8):
        a = ang(units + 8 * i + 1)
        r1 = R - 2.0 if not (broken and i == 2) else R * 0.45
        front.bar(at(WHEEL_F, 3.0 * math.cos(a), 3.0 * math.sin(a)), at(WHEEL_F, r1 * math.cos(a), r1 * math.sin(a)),
                  1.8, WOOD, 2.5)
    ring(front, WHEEL_F, R - 3, R, skip=(13, 14) if broken else ())
    hub = at(WHEEL_F, 0, 0)
    front.blob(hub, 3.4, 3.0, WOOD_DK, 4.0)
    front.blob(hub, 1.5, 1.3, IRON, 5.0)
    layers.append((front, WHEEL_F))
    out = np.zeros((CH, CW, 4))
    for hi, c in layers:
        img = hi.down()
        xs = np.arange(CW) + 0.5
        wl = A[1] + ((xs - A[0]) / 32.0 + 2 * c) * 16.0 + 1.0     # the water line (z = -1) in plane c
        yy = np.arange(CH)[:, None] + 0.5
        img[yy > wl[None, :]] = 0
        over(out, img)
    return out


def foam(c, A, frame):
    """Foam where the wheel meets the water, stepping along its foot on the 8-frame loop."""
    W = SETS["watermill"][0][0]
    gx = -W + WHEEL_AT
    for i, base in enumerate((-12, -6, 0, 5, 10)):
        off = ((frame * 2 + i * 5) % 16) / 16.0
        p = base + off * 6.0
        x, y = P(A, gx + p / 32.0, WHEEL_F + 0.04, -1.0)
        xi, yi = int(round(x)), int(round(y))
        n = 3 if i % 2 == 0 else 2
        c[yi, xi:xi + n, :3] = FOAM
        c[yi, xi:xi + n, 3] = 255
        if (frame + i) % 4 < 2:
            c[yi - 1, xi + 1, :3] = FOAM
            c[yi - 1, xi + 1, 3] = 255
    return c


def watermill(state, frame=0):
    W, D = SETS["watermill"][0]
    o, wh, zr = WM_O, WM_WH, WM_ZR
    A = A0
    c = np.zeros((CH, CW, 4))
    z_e = zr - (D / 2 + o) / (D / 2) * (zr - wh)                       # the eave's height, the slope carried on
    slope = math.hypot((D / 2 + o) * 32.0, zr - z_e)                   # px up the slope, for the tile courses
    run = (W + 2 * o) * 32.0
    dmg = state == "damaged"
    # back slope (a band above the ridge), its gable-end board
    face(c, A, (-W - o, -D / 2, zr), (W + 2 * o, 0, 0), (0, -(D / 2 + o), z_e - zr), _roof_fn(run, slope, True))
    # the right wall and its gable (shaded), the left wall (lit)
    right_open = [(10, 15, 10, 15, "glass"), (44, 49, 10, 15, "lit"), (27.4, 33.4, 29, 33, "door")]
    if dmg:
        right_open[1] = (44, 49, 10, 15, "char")
    face(c, A, (0, 0, 0), (0, -D, 0), (0, 0, zr),
         _wall_fn(D * 32.0, [D * 16.0], right_open, True, gable=(D * 32.0, zr)))
    left_open = [(18, 23, 10, 15, "lit"), (34, 39, 10, 15, "glass"), (57, 63, 3, 15, "door" if not dmg else "char"),
                 (67, 72, 10, 15, "lit" if not dmg else "char")]
    face(c, A, (-W, 0, 0), (W, 0, 0), (0, 0, wh), _wall_fn(W * 32.0, [25.6, 51.2], left_open, False))
    # the roof's end boards and front eave board under the slopes, then the front slope
    e0, e1, e2 = P(A, o, o, z_e), P(A, o, -D / 2, zr), P(A, o, -D - o, z_e)
    hi = Hi()
    hi.poly([e0, e1, (e1[0], e1[1] + 2.5), (e0[0], e0[1] + 2.5)], TIMBER_DK)
    hi.poly([e1, e2, (e2[0], e2[1] + 2.5), (e1[0], e1[1] + 2.5)], TIMBER_DK * SHADE)
    l0 = P(A, -W - o, o, z_e)
    hi.poly([l0, e0, (e0[0], e0[1] + 2.0), (l0[0], l0[1] + 2.0)], TIMBER_DK)
    over(c, hi.down())
    hole = (run * 0.58, slope * 0.5, 8.0, 5.0) if dmg else None
    face(c, A, (-W - o, o, z_e), (W + 2 * o, 0, 0), (0, -(D / 2 + o), zr - z_e), _roof_fn(run, slope, False, hole))
    if dmg:
        x = P(A, -W + 60 / 32.0, 0, 0)[0]
        yb = P(A, -W + 60 / 32.0, 0, 16)[1]
        c = warehouse.scorch(c, x - 7, x + 7, yb - 6, yb)
    # the race: water sunk a px, its end and front kerbs; the wheel in it, foam at its foot, the front kerb over it
    r0, r1, rw = RACE
    rx0, rlen = -W + r0, r1 - r0
    face(c, A, (rx0, 0, -1), (rlen, 0, 0), (0, rw, 0), _water_fn(rlen * 32.0, frame if not dmg else 0))
    face(c, A, (rx0 + rlen, 0, -1), (0, rw, 0), (0, 0, 3), _stone_fn(rw * 32.0, True, 6.0))
    over(c, wheel(A, frame if not dmg else 0, broken=dmg))
    foam(c, A, frame if not dmg else 0)
    face(c, A, (rx0, rw, -1), (rlen, 0, 0), (0, 0, 3), _stone_fn(rlen * 32.0, False))
    face(c, A, (rx0, rw, 2), (rlen, 0, 0), (0, 0.06, 0), _stone_fn(rlen * 32.0, False, 99.0))
    return c, A


# --- sets ------------------------------------------------------------------------------------------------------------
DRAW = {"windmill": windmill, "watermill": watermill}


def ruins(name, shape, A):
    """The source set's approved ruins on this plot: scaled k (palette snapped, outlined), footprint centres met."""
    fp, _, _, src_name, k = SETS[name]
    sm = convert.json.load(open(B / "manifest.json", encoding="utf-8"))[src_name]
    src = Image.open(B / src_name / "ruins.png").convert("RGBA")
    Ws, Ds = sm["footprint"]
    As = sm["anchor"]
    if abs(k - 1.0) > 1e-6:
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


def loop_check(name):
    """The frame after the last (drawn from its own angle) against frame 0: pixels that differ."""
    a, _ = DRAW[name]("intact", 0)
    b, _ = DRAW[name]("intact", FRAMES)
    return int(np.any(np.round(a) != np.round(b), axis=2).sum())


def make(name, out_dir, debug=None):
    fp, height, seed, _, _ = SETS[name]
    frames = []
    A = None
    for f in range(FRAMES):
        img, A = DRAW[name]("intact", f)
        frames.append(img)
    damaged, _ = DRAW[name]("damaged")
    rn = ruins(name, frames[0].shape, A)
    al = np.zeros(frames[0].shape[:2], bool)
    for v in frames + [damaged, rn]:
        al |= v[..., 3] > 0
    ys, xs = np.nonzero(al)
    y0, x0, x1 = ys.min() - PAD, xs.min() - PAD, xs.max() + 1 + PAD
    y1 = max(ys.max() + 1 + PAD, A[1] + 11)
    cut = lambda v: v[y0:y1, x0:x1]
    A = (int(A[0] - x0), int(A[1] - y0))
    done = bridges.finish([cut(v) for v in frames] + [cut(damaged)], None)
    stills = {"intact": done[0], "damaged": done[FRAMES], "ruins": np.clip(cut(rn), 0, 255).astype(np.uint8)}
    idle = np.concatenate(done[:FRAMES], 1)
    d = out_dir / name
    d.mkdir(parents=True, exist_ok=True)
    for st, img in stills.items():
        Image.fromarray(img, "RGBA").save(d / (st + ".png"))
    Image.fromarray(idle, "RGBA").save(d / "idle.png")
    h, w = done[0].shape[:2]
    diff = loop_check(name)
    print(name, "size", [w, h], "anchor", list(A), "frames", FRAMES, "fps", FPS,
          "loop: frame %d vs frame 0 differs in %d px" % (FRAMES, diff),
          "base corners off by", warehouse.corner_errors(done[0].astype(float), A, fp))
    if debug:
        debug.mkdir(parents=True, exist_ok=True)
        sheet = np.zeros((h, w * 3 + 20, 4))
        for i, st in enumerate(("intact", "damaged", "ruins")):
            sheet[:, i * (w + 10):i * (w + 10) + w] = stills[st]
        warehouse._dbg(sheet, debug / (name + "_states.png"), 3)
        warehouse._dbg(idle.astype(float), debug / (name + "_idle.png"), 2)
    return {"size": [w, h], "footprint": fp, "anchor": list(A), "height": height, "seed": seed, "kind": "HOUSE",
            "role": "farm", "tag": name, "frames": FRAMES, "fps": FPS}


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
