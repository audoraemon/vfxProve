"""The south road's stone bridge and the north bank's dock from the reference sheets, built locally (no AI) from sheet
pieces laid on the structures' own iso geometry, so their decks sit exactly where people walk.

  bridge_stone  BRIDGE / bridge / stone, footprint 2.0 x 7.6 (a span along ground y), deck HEIGHT 6 px above the ground
                (PropArt._stone_bridge's deck): the paving is TownMap_Component3's cobbled tile (row 1, 6th), the side and
                end walls TownMap_Component4's plain wall face (row 1, 2nd), the torch piers TownMap_Component3's bridge
                pier (row 2, 4th) with its painted flame cut at the bowl. Three low arches on the side wall (no ring of
                arch stones), low stone parapets (4 px) both sides, eight piers where PropArt._bridge_posts puts them
                (11 px above the deck): the engine's procedural flames burn on their bowls (keep_flames).
  dock          BRIDGE / dock / dock, footprint 3.0 x 1.0 (along ground x), deck 3 px above the ground (TownLayout.DOCK_H):
                the plank floor and its posts, crate and barrel from TownMap_Component3's dock (row 2, 5th).

The sheet's bridge is a short hump with steps and its dock a squat platform; neither lies flat at the game's deck height
nor at 7.6 / 3 cells. So each surface is sampled from the sheet through its own projection (the sheets draw at about
2.5:1, the game at 2:1) and tiled along the run with mirrored repeats (no seam), and the cut pieces (piers, posts,
crate, barrel) are fitted once and pasted. Light from the left: TownMap_Component3 lights from the right, so its pieces
are mirrored; the wall face (TownMap_Component4) is lit from the left already, and the bridge's long side, a right
face, takes it mirrored and shaded like the sheet wall's own end face.

States: intact, damaged (bridge: cracked deck stones, a broken stretch of each parapet, chipped side wall; dock: two
missing planks, a broken board end and split planks), ruins (bridge: a broken stub at each bank, half an arch under
each, the middle fallen away clean; dock: post stumps with two planks still on them). No idle strip.

Usage (from anywhere):
  python tools/dev/ref_convert/bridges.py [all | bridge_stone | dock] [--out <scratch dir>]
"""
import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402

ROOT = convert.ROOT
B = convert.B
C3 = ROOT / "concepts" / "TOWN REF" / "TownMap_Component3.png"
C4 = ROOT / "concepts" / "TOWN REF" / "TownMap_Component4.png"
OUTLINE = np.array([34, 26, 24], float)

# --- the bridge (PropArt._stone_bridge / _bridge_posts / _parapet) ---------------------------------------------------
BW, BD, BH = 2.0, 7.6, 6.0           # footprint (ground units) and deck height (px)
LOW = -16.0                          # the walls reach this far below the ground, into the river
PARA_T, PARA_H = 0.14, 4.0           # parapet thickness (units) and height above the deck (px)
POST_IN, POST_UP = 0.08, 11.0        # piers: in from the corners (units), top above the deck (px)
ARCHES = [(0.08 + 0.3 * k, 0.32 + 0.3 * k) for k in range(3)]   # along the run, fractions of BD
ARCH_SPRING, ARCH_RISE = -10.0, 9.0  # z of the arch's sides' top and how much higher its crown is (px)
# The sheet wall face (TownMap_Component4, the plain wall): a clean patch of its long (left) face. Its courses slope
# WALL_SLOPE px per px; WALL_TOP(x) is the face's top row at sheet column x.
WALL_X0, WALL_X1, WALL_Y0, WALL_SLOPE = 345, 405, 118, 0.47
WALL_ROWS = 37
WALL_SCALE = 0.63
WALL_SHADE = 0.8                     # the shaded (right) face, as the sheet wall's end face against its long face
# The sheet's cobbled tile (TownMap_Component3 row 1): its top face's corners (top, right, left), sheet px.
TILE_T, TILE_R, TILE_L = (1138.0, 29.0), (1231.0, 92.0), (1044.0, 93.0)
TILE_UNITS = 2.0                     # ground units the tile's top covers per side: cobbles ~5 px, as the town's paving
TILE_IN = 0.04                       # skip the tile's rim
TILE_Q = (0.28, 0.86)                # along the run: clear of the tile's two drain gutters (dark bands at q ~0.08, 0.2)
TILE_SAT = 0.65                      # the tile's ochre cobbles toned toward the town's grey stone
# The sheet bridge's front pier (TownMap_Component3 row 2): its box below the bowl; the bowl's middle is BOWL.
PIER_BOX, BOWL, PIER_SCALE = (846, 226, 884, 262), (864.5, 231.0), 0.5

# --- the dock (PropArt._dock) ----------------------------------------------------------------------------------------
DW, DD, DH = 3.0, 1.0, 3.0
# The sheet dock's plank floor: its left, front and right deck corners (sheet px); a clean stretch of it (the rest has
# the crane, crates and the lantern standing on it).
DECK_L, DECK_F, DECK_R = (1140.0, 291.0), (1208.0, 316.0), (1350.0, 247.0)
DECK_P = (0.25, 0.97)                # across (left edge -> front edge), fractions
DECK_Q = (0.03, 0.40)                # along (front -> right corner), fractions
DECK_UNITS = 3.0                     # ground units the sheet deck's long edge covers: planks ~9 px
POST_BOX = (1231, 281, 1249, 312)    # a front post (cap and shaft, the rope band in its middle)
CRATE_BOX = (1273, 254, 1299, 280)
BARREL_BOX = (1258, 207, 1281, 236)
PIECE_SCALE = 0.5
POSTS_X = (0.12, 1.0, 2.0, 2.88)
POST_Y = (0.1, 0.9)
POST_TOP, POST_BOT = 5.0, -6.0       # post top above the deck (px), bottom below the ground (into the water)
DOCK_SAT, DOCK_VAL = 0.72, 0.88      # the sheet wood toned toward the town's timber
FASCIA = 3.0                         # the deck's edge board (px)

PAD = 4


_cache = {}


def load(p):
    if p not in _cache:
        _cache[p] = np.array(Image.open(p).convert("RGBA")).astype(float)
    return _cache[p]


def blurred(img, sigma):
    """Premultiplied Gaussian blur (sheet px), so a downscaled bilinear read averages instead of aliasing."""
    key = (id(img), round(float(sigma), 4))
    if key in _cache:
        return _cache[key]
    _cache[key] = _blurred(img, sigma)
    return _cache[key]


def _blurred(img, sigma):
    a = img[..., 3:] / 255.0
    pm = np.concatenate([img[..., :3] * a, img[..., 3:]], -1).astype(np.uint8)
    out = []
    for ch in range(4):
        out.append(np.array(Image.fromarray(pm[..., ch]).filter(ImageFilter.GaussianBlur(float(sigma)))).astype(float))
    out = np.stack(out, -1)
    al = np.maximum(out[..., 3:], 1e-3) / 255.0
    out[..., :3] = np.clip(out[..., :3] / al, 0, 255)
    return out


def bilinear(img, x, y):
    """RGB of img at float (x, y) (pixel centres at +0.5)."""
    x, y = x - 0.5, y - 0.5
    h, w = img.shape[:2]
    x0 = int(np.floor(x)); y0 = int(np.floor(y))
    fx, fy = x - x0, y - y0
    def px(xx, yy):
        return img[min(max(yy, 0), h - 1), min(max(xx, 0), w - 1), :3]
    return (px(x0, y0) * (1 - fx) * (1 - fy) + px(x0 + 1, y0) * fx * (1 - fy) + px(x0, y0 + 1) * (1 - fx) * fy
            + px(x0 + 1, y0 + 1) * fx * fy)


def pingpong(t, lo, hi):
    """t folded into [lo, hi] by mirrored repeats: a tiled texture with no seam."""
    span = hi - lo
    k = np.mod(t - lo, 2 * span)
    return lo + (k if k <= span else 2 * span - k)


class Canvas:
    """A sprite canvas for a footprint W x D whose front corner is at pixel A (the anchor). Ground point (gx, gy) is
    footprint-relative, z is px above the ground."""

    def __init__(self, w, h, A, W, D):
        self.a = np.zeros((h, w, 4), float)
        self.A = A
        self.W, self.D = W, D

    def pt(self, gx, gy, z):
        return (self.A[0] + 32 * ((gx - self.W) - (gy - self.D)), self.A[1] + 16 * ((gx - self.W) + (gy - self.D)) - z)

    def _bbox(self, pts):
        h, w = self.a.shape[:2]
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        return (max(int(np.floor(min(xs))) - 1, 0), max(int(np.floor(min(ys))) - 1, 0),
                min(int(np.ceil(max(xs))) + 1, w), min(int(np.ceil(max(ys))) + 1, h))

    def put(self, i, j, rgb):
        self.a[j, i, :3] = rgb
        self.a[j, i, 3] = 255

    def top(self, x0, y0, x1, y1, z, tex, keep=None):
        """The flat face at height z over [x0, x1] x [y0, y1]; tex(gx, gy) -> rgb or None (a hole)."""
        bx0, by0, bx1, by1 = self._bbox([self.pt(x0, y0, z), self.pt(x1, y0, z), self.pt(x1, y1, z), self.pt(x0, y1, z)])
        for j in range(by0, by1):
            for i in range(bx0, bx1):
                a = (i + 0.5 - self.A[0]) / 32.0
                b = (j + 0.5 - self.A[1] + z) / 16.0
                gx = (a + b) / 2 + self.W
                gy = (b - a) / 2 + self.D
                if x0 <= gx < x1 and y0 <= gy < y1 and (keep is None or keep(gx, gy)):
                    c = tex(gx, gy)
                    if c is not None:
                        self.put(i, j, c)

    def face_x(self, X, y0, y1, z0, z1, tex):
        """The vertical face on the plane gx = X (a right face) over gy in [y0, y1], z in [z0, z1(gy)]; tex(gy, z, i)."""
        zt = z1 if callable(z1) else (lambda gy: z1)
        ztop = max(zt(y0), zt(y1), zt((y0 + y1) / 2))
        bx0, by0, bx1, by1 = self._bbox([self.pt(X, y0, z0), self.pt(X, y1, z0), self.pt(X, y0, ztop), self.pt(X, y1, ztop)])
        for j in range(by0, by1):
            for i in range(bx0, bx1):
                gy = (X - self.W) - (i + 0.5 - self.A[0]) / 32.0 + self.D
                z = 16 * ((X - self.W) + (gy - self.D)) - (j + 0.5 - self.A[1])
                if y0 <= gy < y1 and z0 <= z < zt(gy):
                    c = tex(gy, z, i)
                    if c is not None:
                        self.put(i, j, c)

    def face_y(self, Y, x0, x1, z0, z1, tex):
        """The vertical face on the plane gy = Y (a left face) over gx in [x0, x1], z in [z0, z1(gx)]; tex(gx, z, i)."""
        zt = z1 if callable(z1) else (lambda gx: z1)
        ztop = max(zt(x0), zt(x1), zt((x0 + x1) / 2))
        bx0, by0, bx1, by1 = self._bbox([self.pt(x0, Y, z0), self.pt(x1, Y, z0), self.pt(x0, Y, ztop), self.pt(x1, Y, ztop)])
        for j in range(by0, by1):
            for i in range(bx0, bx1):
                gx = (i + 0.5 - self.A[0]) / 32.0 + self.W + (Y - self.D)
                z = 16 * ((gx - self.W) + (Y - self.D)) - (j + 0.5 - self.A[1])
                if x0 <= gx < x1 and z0 <= z < zt(gx):
                    c = tex(gx, z, i)
                    if c is not None:
                        self.put(i, j, c)

    def paste(self, piece, at, anchor_px):
        """Paste an RGBA piece so its pixel anchor_px lands on canvas point `at`."""
        x = int(round(at[0] - anchor_px[0])); y = int(round(at[1] - anchor_px[1]))
        h, w = piece.shape[:2]
        for j in range(h):
            for i in range(w):
                if piece[j, i, 3] > 0 and 0 <= y + j < self.a.shape[0] and 0 <= x + i < self.a.shape[1]:
                    self.a[y + j, x + i] = piece[j, i]


# --- textures ---------------------------------------------------------------------------------------------------------
class Wall:
    """The sheet wall's masonry: wall(c, r) is the colour at game px column c, r rows below the wall's top course."""

    def __init__(self):
        self.img = blurred(load(C4), 0.45 / WALL_SCALE)
        self.cw = (WALL_X1 - WALL_X0) * WALL_SCALE
        self.rh = WALL_ROWS * WALL_SCALE

    def __call__(self, c, r, mirror=False):
        u = pingpong(-c if mirror else c, 0.0, self.cw) / WALL_SCALE
        v = pingpong(r, 0.0, self.rh) / WALL_SCALE
        x = WALL_X0 + u
        return bilinear(self.img, x, WALL_Y0 + WALL_SLOPE * u + v)

    def coping(self):
        """The wall's light cap stone: its brightest tenth, averaged."""
        sheet = load(C4)
        reg = sheet[100:150, 320:500]
        reg = reg[reg[..., 3] > 200][:, :3]
        lum = reg.sum(1)
        return reg[lum >= np.percentile(lum, 90)].mean(0)


class Tile:
    """The sheet's cobbled tile: tile(p, q) at fractions of its top face (p toward its right corner, q its left)."""

    def __init__(self):
        edge = np.hypot(TILE_R[0] - TILE_T[0], TILE_R[1] - TILE_T[1])
        game = TILE_UNITS * np.hypot(32, 16)
        self.img = blurred(load(C3), 0.45 * edge / game)

    def __call__(self, p, q):
        p = pingpong(p, TILE_IN, 1 - TILE_IN)
        q = pingpong(q, *TILE_Q)
        x = TILE_T[0] + p * (TILE_R[0] - TILE_T[0]) + q * (TILE_L[0] - TILE_T[0])
        y = TILE_T[1] + p * (TILE_R[1] - TILE_T[1]) + q * (TILE_L[1] - TILE_T[1])
        c = bilinear(self.img, x, y)
        grey = c.mean()
        return grey + (c - grey) * TILE_SAT


class Deck:
    """The sheet dock's plank floor: deck(p, q), p across (its left edge -> front edge), q along (front -> right)."""

    def __init__(self):
        edge = np.hypot(DECK_R[0] - DECK_F[0], DECK_R[1] - DECK_F[1])
        game = DECK_UNITS * np.hypot(32, 16)
        self.img = blurred(load(C3), 0.45 * edge / game)

    def __call__(self, p, q):
        p = pingpong(p, *DECK_P)
        q = pingpong(q, *DECK_Q)
        x = DECK_L[0] + p * (DECK_F[0] - DECK_L[0]) + q * (DECK_R[0] - DECK_F[0])
        y = DECK_L[1] + p * (DECK_F[1] - DECK_L[1]) + q * (DECK_R[1] - DECK_F[1])
        return bilinear(self.img, x, y)


def fit_piece(box, scale, mirror=True, drop_blue=True):
    """A sheet piece cut at `box`: its main shape (blue water dropped), downscaled (premultiplied Lanczos, hard alpha),
    mirrored to light from the left. Returns (RGBA uint8, the scale actually used per axis)."""
    a = np.array(Image.open(C3).convert("RGBA").crop(box))
    if drop_blue:
        rgb = a[..., :3].astype(int)
        blue = (rgb[..., 2] > rgb[..., 0] + 30) & (rgb[..., 2] > rgb[..., 1] + 5)
        a[blue, 3] = 0
    a = convert.keep_shapes(a)
    h, w = a.shape[:2]
    nw, nh = max(1, round(w * scale)), max(1, round(h * scale))
    small = Image.fromarray(a, "RGBA").convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    out = np.array(small).astype(float)
    out[..., 3] = np.where(out[..., 3] >= 110, 255, 0)
    if mirror:
        out = out[:, ::-1].copy()
    return out, (nw / w, nh / h)


def unglow(a):
    """Pixels the sprite shader would take for a flame (structure_sprite.gdshader glows()) toned down: only the
    procedural flames glow."""
    rgb = a[..., :3] / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    g = (a[..., 3] > 0) & (rgb[..., 0] >= mx) & (mx > 0.85) & ((mx - mn) / np.maximum(mx, 1e-6) > 0.45) & (rgb[..., 1] > 0.35)
    a[g, :3] = a[g, :3] * 0.72
    return a


# --- the bridge -------------------------------------------------------------------------------------------------------
def bridge_posts():
    """PropArt._bridge_posts for the stone bridge along y: the far side's four (x = POST_IN), then the near side's."""
    out = []
    for x in (POST_IN, BW - POST_IN):
        for t in (0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0):
            out.append((x, POST_IN + t * (BD - 2 * POST_IN)))
    return out


def pier_piece():
    """The sheet pier below its bowl, fitted; returns (piece, the bowl's middle in the piece, the flame tip row)."""
    a = np.array(Image.open(C3).convert("RGBA").crop(PIER_BOX)).astype(float)
    # The painted flame and its glow: everything orange-bright goes; the bowl (dark iron) stays.
    rgb = a[..., :3]
    hot = (rgb[..., 0] > 150) & (rgb[..., 0] > rgb[..., 2] + 70) & (rgb[..., 1] > 60) & (rgb[..., 1] < rgb[..., 0] - 20)
    a[hot, 3] = 0
    # The bushes at its foot and the rail behind it: keep the pier's columns only.
    a[:, 36:, 3] = 0
    green = (rgb[..., 1] > rgb[..., 0] + 10) & (rgb[..., 1] > rgb[..., 2] + 10)
    a[green, 3] = 0
    a = convert.keep_shapes(a.astype(np.uint8))
    h, w = a.shape[:2]
    nw, nh = round(w * PIER_SCALE), round(h * PIER_SCALE)
    small = Image.fromarray(a, "RGBA").convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    out = np.array(small).astype(float)
    out[..., 3] = np.where(out[..., 3] >= 110, 255, 0)
    out = out[:, ::-1].copy()
    bx = (BOWL[0] - PIER_BOX[0]) * nw / w
    by = (BOWL[1] - PIER_BOX[1]) * nh / h
    return unglow(out), (nw - bx, by)


def build_bridge(state):
    wall = Wall()
    tile = Tile()
    cop = wall.coping()
    pier, bowl = pier_piece()
    W, D, h = BW, BD, BH
    A = (64 + 12 + PAD, int(16 * (W + D)) + int(h + POST_UP) + 10 + PAD)
    cv = Canvas(int(A[0] + 32 * D + 12 + PAD), int(A[1] - LOW + PAD + 2), A, W, D)
    rng = np.random.default_rng(91)

    # What stands: the whole run, or (ruins) a stub at each bank with the middle fallen away.
    stubs = [(0.0, D)] if state != "ruins" else [(0.0, 1.7), (5.9, D)]

    def in_arch(gy, z):
        for f0, f1 in ARCHES:
            y0, y1 = f0 * D, f1 * D
            if y0 <= gy < y1:
                m, r = (y0 + y1) / 2, (y1 - y0) / 2
                k = 1 - ((gy - m) / r) ** 2
                return z < ARCH_SPRING + ARCH_RISE * np.sqrt(max(k, 0.0))
        return False

    def arch_dark(gy, z):
        t = np.clip((z - LOW) / (ARCH_SPRING + ARCH_RISE - LOW), 0, 1)
        return np.array([40, 62, 84]) * (1 - t) + np.array([20, 26, 36]) * t

    def side(gy, z, i):           # the long side wall (right face, shaded)
        if in_arch(gy, z):
            return arch_dark(gy, z)
        return wall(i, h + PARA_H - z, mirror=True) * WALL_SHADE

    def end(gx, z, i):            # an end wall (left face, lit)
        return wall(i, h + PARA_H - z)

    def deck(gx, gy):
        return tile(gx / TILE_UNITS, gy / TILE_UNITS)

    def cap(gx, gy):
        joint = (gy % 0.35) < 0.045
        return cop * (0.82 if joint else 1.0)

    for y0, y1 in stubs:
        cv.face_x(W, y0, y1, LOW, h, side)
        if y1 >= D:
            cv.face_y(D, 0.0, W, LOW, h, end)
        cv.top(0.0, y0, W, y1, h, deck)
    if state == "ruins":
        # The far stub's broken end: a clean cut, a left face at y = 1.7 (the near stub's faces away).
        y1 = stubs[0][1]
        cv.face_y(y1, 0.0, W, LOW, h, end)

    # Parapets: far one, its piers, near one, its piers (a broken stretch of each when damaged).
    gaps = {"far": [], "near": []}
    if state == "damaged":
        gaps = {"far": [(2.95, 3.3)], "near": [(4.0, 4.75)]}

    def para_z(gaps_here):
        def z(gy):
            for g0, g1 in gaps_here:
                if g0 <= gy < g1:
                    return h + (1.0 if (gy - g0) < 0.12 or (g1 - gy) < 0.12 else 0.0)
            return h + PARA_H
        return z

    def para_top(gaps_here):
        def keep(gx, gy):
            return not any(g0 <= gy < g1 for g0, g1 in gaps_here)
        return keep

    posts = bridge_posts()
    for side_name, (px0, px1), side_posts in (("far", (0.0, PARA_T), posts[:4]), ("near", (W - PARA_T, W), posts[4:])):
        for y0, y1 in stubs:
            zf = para_z(gaps[side_name])
            # its inner (deck-side) face is a right face only on the far parapet; the near one's outer face continues
            # the side wall.
            if side_name == "far":
                cv.face_x(px1, y0, y1, h, zf, lambda gy, z, i: wall(i, h + PARA_H - z, mirror=True) * WALL_SHADE)
            else:
                cv.face_x(px1, y0, y1, h, zf, side)
            if y1 >= D:
                cv.face_y(D, px0, px1, h, h + PARA_H, end)
            cv.top(px0, y0, px1, y1, h + PARA_H, cap, keep=para_top(gaps[side_name]))
            for g0, g1 in gaps[side_name]:
                cv.top(px0, g0 + 0.12, px1, g1 - 0.12, h + 0.01, lambda gx, gy: cop * 0.7)
        for c in side_posts:
            if not any(y0 <= c[1] < y1 for y0, y1 in stubs):
                continue
            tip = cv.pt(c[0], c[1], h + POST_UP)
            cv.paste(pier, tip, bowl)

    a = cv.a
    if state == "damaged":
        crack_deck(cv, rng)
    return a, A


def crack_deck(cv, rng):
    """A few dark cracks wandering across the deck and down the side wall, a missing cobble or two."""
    a = cv.a
    dark = np.array([46, 40, 40], float)
    for gy0, gx0, n in ((1.6, 0.4, 26), (3.6, 1.1, 30), (5.4, 0.3, 22), (6.6, 1.3, 16)):
        x, y = cv.pt(gx0, gy0, BH)
        for _ in range(n):
            xi, yi = int(x), int(y)
            if 0 <= yi < a.shape[0] and 0 <= xi < a.shape[1] and a[yi, xi, 3] > 0:
                a[yi, xi, :3] = dark
            x += rng.choice([1, 1, 2]) * (1 if gx0 < 1 else -1)
            y += rng.choice([0, 1, 1, -1]) * 0.5 + 0.5
    for gy0 in (2.2, 4.9):
        x, y = cv.pt(BW - 0.3, gy0, BH)
        for k in range(5):
            for dx in range(3):
                xi, yi = int(x) + dx, int(y) + k - 1
                if a[yi, xi, 3] > 0:
                    a[yi, xi, :3] *= 0.55
    # cracks down the side wall (right face, shaded)
    for gy0, n in ((1.2, 9), (4.4, 12), (6.2, 8)):
        x, y = cv.pt(BW, gy0, BH - 1)
        for k in range(n):
            xi, yi = int(x), int(y)
            if a[yi, xi, 3] > 0:
                a[yi, xi, :3] = dark * 0.8
            x += rng.choice([-1, 0, 1])
            y += 1


# --- the dock -----------------------------------------------------------------------------------------------------------
def build_dock(state):
    deck_tex = Deck()
    post, _ = fit_piece(POST_BOX, PIECE_SCALE)
    crate, _ = fit_piece(CRATE_BOX, PIECE_SCALE)
    barrel, _ = fit_piece(BARREL_BOX, PIECE_SCALE)
    crate, barrel = unglow(crate), unglow(barrel)
    W, D, h = DW, DD, DH
    A = (int(32 * W) + 8 + PAD, int(16 * (W + D)) + 22 + PAD)
    cv = Canvas(int(A[0] + 32 * D + 8 + PAD), int(A[1] - POST_BOT + PAD + 2), A, W, D)
    rng = np.random.default_rng(92)

    edge = np.array(deck_tex(0.98, 0.2)) * 0.62
    holes = []
    if state == "damaged":
        holes = [(1.55, 1.82, 0.22, 1.01), (2.3, 2.55, 0.0, 0.55)]

    def board(gx, gy):
        if any(x0 <= gx < x1 and y0 <= gy < y1 for x0, x1, y0, y1 in holes):
            return None
        return deck_tex(gy / DD * (DECK_P[1] - DECK_P[0]) + DECK_P[0], gx / DECK_UNITS)

    def fascia(g, z, i, shade):
        seam = (i % 9) == 0
        return edge * shade * (0.8 if seam else 1.0) * (0.9 if z < h - 1.5 else 1.0)

    def post_at(x, y, top):
        """A post standing at (x, y): the piece's cap to its foot, cut to [POST_BOT, top] (z px)."""
        foot = cv.pt(x, y, POST_BOT)
        rows = int(round(top - POST_BOT)) + 3      # + its cap's top face
        if state != "ruins":
            p = post[:rows]
        else:
            # a stump: the post's lower part, its clean cut top a row of light wood
            p = post[-rows:].copy()
            cut = p[0, :, 3] > 0
            p[0, cut, :3] = np.minimum(p[0, cut, :3] * 1.35 + 20, 255)
        cv.paste(p, foot, (p.shape[1] / 2, p.shape[0]))

    if state == "ruins":
        # Stumps: most posts snapped a little above the water, two planks still lying across the landward pair.
        for x in POSTS_X:
            for y in POST_Y:
                if (x, y) in ((2.0, 0.1),):
                    continue
                post_at(x, y, -1.0 if x > 1.5 else 1.0)
        for x0, x1 in ((0.0, 0.25), (0.88, 1.12)):
            cv.face_y(DD, x0, x1, h - FASCIA, h, lambda g, z, i: fascia(g, z, i, 0.85))
            cv.face_x(x1, 0.0, DD, h - FASCIA, h, lambda g, z, i: fascia(g, z, i, 0.7))
            cv.top(x0, 0.0, x1, DD, h, board)
        return cv.a, A

    for x in POSTS_X:
        post_at(x, POST_Y[0], h + POST_TOP)
    cv.face_y(DD, 0.0, DW, h - FASCIA, h, lambda g, z, i: fascia(g, z, i, 0.85))
    cv.face_x(DW, 0.0, DD, h - FASCIA, h, lambda g, z, i: fascia(g, z, i, 0.7))
    cv.top(0.0, 0.0, DW, DD, h, board)
    if state == "damaged":
        # the broken board's end hangs at the front: a notch out of the fascia below the hole
        for x0, x1, y0, y1 in holes:
            if y1 > DD:
                cv.face_y(DD, x0, x1, h - FASCIA, h - FASCIA + 0.01, lambda g, z, i: None)
                a = cv.a
                for gx in np.arange(x0, x1, 1 / 32):
                    xi, yi = cv.pt(gx, DD, h - 1)
                    for k in range(int(FASCIA) + 1):
                        yy = int(yi) + k - 1
                        if 0 <= yy < a.shape[0]:
                            a[yy, int(xi), 3] = 0
    cv.paste(crate, cv.pt(0.45, 0.35, h), (crate.shape[1] / 2, crate.shape[0] - 3))
    cv.paste(barrel, cv.pt(2.55, 0.35, h), (barrel.shape[1] / 2, barrel.shape[0] - 2))
    for x in POSTS_X:
        post_at(x, POST_Y[1], h + POST_TOP)
    if state == "damaged":
        a = cv.a
        dark = np.array([40, 26, 18], float)
        for gx0, gy0, n in ((0.8, 0.1, 10), (2.0, 0.5, 8), (1.2, 0.6, 7)):
            x, y = cv.pt(gx0, gy0, h)
            for _ in range(n):
                if a[int(y), int(x), 3] > 0:
                    a[int(y), int(x), :3] = dark
                x += -1
                y += 0.5
    return cv.a, A


# --- finish -------------------------------------------------------------------------------------------------------------
def outline(a):
    al = a[..., 3] > 0
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    dark = a[..., :3].sum(axis=2) < 200
    m = e & ~dark
    a[m, :3] = a[m, :3] * 0.45 + OUTLINE * 0.55
    return a


def finish(stills, colors):
    """Unsharp, one shared median-cut palette over all states, then the 1 px outline. In: float RGBA arrays."""
    h = max(s.shape[0] for s in stills)
    w = sum(s.shape[1] for s in stills)
    strip = np.zeros((h, w, 4), np.uint8)
    x = 0
    for s in stills:
        strip[:s.shape[0], x:x + s.shape[1]] = np.clip(s, 0, 255).astype(np.uint8)
        x += s.shape[1]
    rgb = Image.fromarray(strip[..., :3]).filter(ImageFilter.UnsharpMask(radius=1, percent=50, threshold=2))
    q = np.array(rgb.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB"))
    out = []
    x = 0
    for s in stills:
        o = np.zeros(s.shape, float)
        o[..., :3] = q[:s.shape[0], x:x + s.shape[1]]
        o[..., 3] = np.where(s[..., 3] > 0, 255, 0)
        out.append(outline(o).astype(np.uint8))
        x += s.shape[1]
    return out


SETS = {
    # name: (builder, footprint, height, seed, tag, role, colours, harmonize)
    "bridge_stone": (build_bridge, [BW, BD], 6, 61, "stone", "bridge", 56, True),
    "dock": (build_dock, [DW, DD], 3, 62, "dock", "dock", 40, False),
}


def make(name, out_dir):
    build, fp, height, seed, tag, role, colors, harm = SETS[name]
    raw = {}
    anchor = None
    for st in ("intact", "damaged", "ruins"):
        a, A = build(st)
        if name == "dock":
            # the sheet's wood is a hot orange next to the town's timber: muted and a little darker
            grey = a[..., :3].mean(-1, keepdims=True)
            a[..., :3] = (grey + (a[..., :3] - grey) * DOCK_SAT) * DOCK_VAL
        raw[st] = a
        anchor = A
    done = finish([raw[s] for s in ("intact", "damaged", "ruins")], colors)
    d = out_dir / name
    d.mkdir(parents=True, exist_ok=True)
    paths = []
    for st, img in zip(("intact", "damaged", "ruins"), done):
        p = d / (st + ".png")
        Image.fromarray(img, "RGBA").save(p)
        paths.append(str(p))
    if harm:
        subprocess.run([sys.executable, str(ROOT / "tools" / "dev" / "sprite_fix.py"), "harmonize",
                        str(convert.HARMONIZE_TARGET[0]), convert.HARMONIZE_TARGET[1]] + paths, cwd=ROOT, check=True)
    h, w = done[0].shape[:2]
    entry = {"size": [w, h], "footprint": fp, "anchor": list(anchor), "height": height, "seed": seed,
             "kind": "BRIDGE", "role": role, "tag": tag}
    if name == "bridge_stone":
        entry["keep_flames"] = True
    print(name, "size", [w, h], "anchor", list(anchor))
    return entry


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", help="write the sets here instead of assets/pixellab/buildings (no manifest change)")
    a = p.parse_args()
    for n in (list(SETS) if a.what == ["all"] else a.what):
        if a.out:
            make(n, Path(a.out))
        else:
            entry = make(n, B)
            convert.write_manifest(B / "manifest.json", n, entry)
            print("manifest updated:", n)
