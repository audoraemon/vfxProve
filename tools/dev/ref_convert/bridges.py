"""The south road's stone bridge and the north bank's dock from the reference sheets, built locally (no AI) from sheet
pieces laid on the structures' own iso geometry, so their decks sit exactly where people walk.

  bridge_stone  BRIDGE / bridge / stone, footprint 2.0 x 7.6 (a span along ground y), deck HEIGHT 6 px above the ground
                (PropArt._stone_bridge's deck): the paving is TownMap_Component3's cobbled tile (row 1, 6th), the side
                walls TownMap_Component4's plain wall face (row 1, 2nd), the torch piers TownMap_Component3's bridge
                pier (row 2, 4th) with its painted flame cut at the bowl. Three low arches on the side wall (no ring of
                arch stones), low stone parapets (4 px) both sides, eight piers where PropArt._bridge_posts puts them
                (11 px above the deck): the engine's procedural flames burn on their bowls (keep_flames). At each road
                end a flight of STEPS steps (STEP_RISE px each) down to the ground, outside the footprint on the road,
                so a walker coming off the road climbs instead of popping up a bare end wall.
  dock          BRIDGE / dock / dock, footprint 3.0 x 1.0 (along ground x), deck 3 px above the ground (TownLayout.DOCK_H):
                drawn clean (the sheet's textures read as noise at this size): straight planks across it with even
                seams in four wood tones taken from TownMap_Component3's dock floor (row 2, 5th), edge boards, round
                posts at its corners and the middle of each long side, one crate.

The sheet's bridge is a short hump with steps; it does not lie flat at the game's deck height nor at 7.6 cells. So each
of its surfaces is sampled from the sheet through its own projection (the sheets draw at about 2.5:1, the game at 2:1)
and tiled along the run with mirrored repeats (no seam), and the piers are fitted once and pasted. Light from the left:
TownMap_Component3 lights from the right, so its pier is mirrored; the wall face (TownMap_Component4) is lit from the
left already, and the bridge's long side, a right face, takes it mirrored and shaded like the sheet wall's end face.
dock_whole_cut() is the rejected candidate of the dock review (the sheet dock cut whole with convert.py).

States: intact, damaged (bridge: cracked deck stones and steps, a broken stretch of each parapet, chipped side wall;
dock: three boards gone, two split), ruins (bridge: a stub at each bank with its steps, half an arch under each, the
middle fallen away clean; dock: clean post stumps and one plank). No idle strip.

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
ARCH_SPRING, ARCH_RISE = -10.0, 9.0
# Steps at both road ends, outside the footprint on the road (the deck and the walkable cells are unchanged): STEPS
# flights' treads STEP_RUN deep, each STEP_RISE px lower, down from the deck to the road.
STEPS, STEP_RUN, STEP_RISE = 3, 0.2, 1.5
NOSING = 0.045                       # a tread's light front edge (units)  # z of the arch's sides' top and how much higher its crown is (px)
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
# The sheet dock's plank floor: its left, front and right deck corners (sheet px) and a clean stretch of it (the rest
# has the crane, crates and the lantern on it): the drawn dock's four wood tones come from there (dock_tones()).
DECK_L, DECK_F, DECK_R = (1140.0, 291.0), (1208.0, 316.0), (1350.0, 247.0)
DECK_P = (0.25, 0.97)                # across (left edge -> front edge), fractions
DECK_Q = (0.03, 0.40)                # along (front -> right corner), fractions
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
    run = STEPS * STEP_RUN
    A = (64 + int(32 * run) + 12 + PAD, int(16 * (W + D)) + int(h + POST_UP) + 10 + PAD)
    cv = Canvas(int(A[0] + 32 * (D + run) + 12 + PAD), int(A[1] - LOW + PAD + 2), A, W, D)
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

    def tread(edge_y):
        def tex(gx, gy):
            return cop * 0.95 if abs(gy - edge_y) < NOSING else deck(gx, gy)
        return tex

    def flight(far):
        """The steps down to the road at one end: each a block from the ground to its tread, drawn back to front.
        Light from the left: a riser (left face) lit like the end walls, a block's side (right face) shaded."""
        ks = range(STEPS - 1, -1, -1) if far else range(STEPS)
        for k in ks:
            top = h - STEP_RISE * (k + 1)
            if far:
                y0, y1, edge = -STEP_RUN * (k + 1), -STEP_RUN * k, -STEP_RUN * (k + 1)
            else:
                y0, y1, edge = D + STEP_RUN * k, D + STEP_RUN * (k + 1), D + STEP_RUN * (k + 1)
            cv.face_x(W, y0, y1, 0.0, top, lambda gy, z, i: wall(i, h + PARA_H - z, mirror=True) * WALL_SHADE)
            if not far:
                cv.face_y(y1, 0.0, W, 0.0, top, end)
            cv.top(0.0, y0, W, y1, top, tread(edge))

    flight(True)
    for y0, y1 in stubs:
        cv.face_x(W, y0, y1, LOW, h, side)
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

    # the deck's own riser down to the near flight's top tread (the rest of the old end wall is gone)
    cv.face_y(D, 0.0, W, h - STEP_RISE, h, end)
    flight(False)
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
    # a crack across the near flight's treads and one through the far flight's
    for gx0, gy0, top in ((0.5, BD + 0.1, BH - STEP_RISE), (1.3, BD + 0.3, BH - 2 * STEP_RISE), (0.9, -0.3, BH - 2 * STEP_RISE)):
        x, y = cv.pt(gx0, gy0, top)
        for k in range(9):
            xi, yi = int(x), int(y)
            if a[yi, xi, 3] > 0:
                a[yi, xi, :3] = dark
            x += 1
            y += rng.choice([0, 0.5, 1])
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
def dock_tones():
    """Four wood tones from the sheet dock's plank floor (its clean stretch), darkest first: the means of its
    lightness quartiles, muted toward the town's timber (DOCK_SAT, DOCK_VAL)."""
    sheet = load(C3)
    px = []
    for p in np.linspace(DECK_P[0], DECK_P[1], 24):
        for q in np.linspace(DECK_Q[0], DECK_Q[1], 40):
            x = DECK_L[0] + p * (DECK_F[0] - DECK_L[0]) + q * (DECK_R[0] - DECK_F[0])
            y = DECK_L[1] + p * (DECK_F[1] - DECK_L[1]) + q * (DECK_R[1] - DECK_F[1])
            px.append(sheet[int(y), int(x), :3])
    px = np.array(px)
    lum = px.sum(1)
    bins = np.digitize(lum, np.percentile(lum, [25, 50, 75]))
    out = []
    for k in range(4):
        c = px[bins == k].mean(0)
        g = c.mean()
        out.append(np.round((g + (c - g) * DOCK_SAT) * DOCK_VAL))
    return out


# Plank tones along the dock (indices into dock_tones()), repeating: a fixed, even pattern, no noise.
PLANK_SEQ = (2, 1, 2, 3, 1, 2, 1, 3, 2, 1, 3, 2)
PLANK_W = 0.25                       # a plank's width along the dock (units)
SEAM = 0.035                         # the dark gap between planks (units)
DOCK_POSTS = ((0.12, 0.12), (1.5, 0.12), (2.88, 0.12), (0.12, 0.88), (1.5, 0.88), (2.88, 0.88))
CRATE = (0.3, 0.3, 0.6, 0.6, 8.0)   # x0, y0, x1, y1 (units), height (px)


def round_post(tones, rows, cut=False):
    """A round post `rows` px tall plus its cap, lit from the left: a 5 px shaft (light, mid, mid, dark, darkest)
    between 1 px outlines and a 2-row cap (a stump: a pale cut face)."""
    ink = OUTLINE
    shaft = [tones[3], tones[2], tones[2], tones[1], tones[0]]
    w, h = 7, rows + 3
    a = np.zeros((h, w, 4), float)
    a[1:, :, 3] = 255
    a[0, 1:6, 3] = 255
    a[0, 1:6, :3] = ink
    a[1:, 0, :3] = ink
    a[1:, 6, :3] = ink
    face = np.minimum(np.array(tones[3]) * (1.3 if cut else 1.1), 255)
    a[1, 1:6, :3] = face
    for y in range(2, h):
        for k, c in enumerate(shaft):
            a[y, 1 + k, :3] = c
    if not cut:
        a[2, 1:6, :3] = np.array(tones[2])
        band = 3 + rows // 3
        if band < h - 1:
            a[band, 1:6, :3] = np.array(tones[0]) * 0.8
    a[h - 1, :, :3] = ink
    return a


def build_dock(state):
    """The drawn dock: straight planks across it with even seams in four sheet tones, edge boards, round posts at its
    corners and the middle of each long side, one crate; light from the left."""
    t = dock_tones()
    ink = OUTLINE
    W, D, h = DW, DD, DH
    A = (int(32 * W) + 8 + PAD, int(16 * (W + D)) + 22 + PAD)
    cv = Canvas(int(A[0] + 32 * D + 8 + PAD), int(A[1] - POST_BOT + PAD + 2), A, W, D)
    holes, splits = [], []
    if state == "damaged":
        holes = [(6, 0.32, 1.01), (7, 0.55, 1.01), (10, 0.0, 0.4)]      # (plank, y0, y1): boards gone
        splits = [2, 9]                                                  # split along their middle

    def plank(gx):
        return min(int(gx / PLANK_W), len(PLANK_SEQ) - 1)

    def board(gx, gy):
        i = plank(gx)
        if any(i == k and y0 <= gy < y1 for k, y0, y1 in holes):
            return None
        f = gx - i * PLANK_W
        if f < SEAM:
            return np.array(t[0]) * 0.7
        if i in splits and abs(f - PLANK_W / 2) < 0.02 and 0.15 < gy < 0.85:
            return np.array(t[0]) * 0.8
        return t[PLANK_SEQ[i % len(PLANK_SEQ)]]

    def front(g, z, i):                       # the long edge board (left face, lit)
        k = plank(g)
        if any(k == j and y1 > D for j, _, y1 in holes):
            return None
        if g - k * PLANK_W < SEAM:
            return ink
        return np.array(t[1]) * (1.0 if z >= h - 1.5 else 0.88)

    def end(g, z, i):                         # the end board (right face, shaded)
        return np.array(t[0]) * (1.0 if z >= h - 1.5 else 0.88)

    def post_at(x, y, top, cut=False):
        p = round_post(t, int(round(top - POST_BOT)), cut)
        cv.paste(p, cv.pt(x, y, POST_BOT), (3.5, p.shape[0]))

    if state == "ruins":
        # Clean stumps a little above the water, one plank left lying across the two landward ones.
        for x, y in DOCK_POSTS:
            post_at(x, y, (h - 1.0) if x < 1.0 else 0.0, cut=True)
        x0, x1 = 0.2, 0.2 + PLANK_W - SEAM          # half on the landward stumps: they show beside it
        cv.face_y(D, x0, x1, h - FASCIA, h, lambda g, z, i: np.array(t[1]))
        cv.face_x(x1, 0.0, D, h - FASCIA, h, end)
        cv.top(x0, 0.0, x1, D, h, lambda gx, gy: t[2])
        return cv.a, A

    for x, y in DOCK_POSTS:
        if y < 0.5:
            post_at(x, y, h + POST_TOP)
    cv.face_y(D, 0.0, W, h - FASCIA, h, front)
    cv.face_x(W, 0.0, D, h - FASCIA, h, end)
    cv.top(0.0, 0.0, W, D, h, board)
    # the crate: lit top, lit left face, shaded right face, inked edges and a board line round its middle
    x0, y0, x1, y1, ch = CRATE
    e = 0.03

    def crate_side(lo, hi, shade):
        def tex(g, z, i):
            if abs(z - h - ch / 2) < 0.5 or z > h + ch - 1 or g < lo + e or g > hi - e:
                return ink
            return np.array(t[shade])
        return tex

    cv.face_y(y1, x0, x1, h, h + ch, crate_side(x0, x1, 2))
    cv.face_x(x1, y0, y1, h, h + ch, crate_side(y0, y1, 0))
    cv.top(x0, y0, x1, y1, h + ch, lambda gx, gy: ink if min(gx - x0, x1 - gx, gy - y0, y1 - gy) < e
           else np.minimum(np.array(t[3]) * 1.08, 255))
    for x, y in DOCK_POSTS:
        if y >= 0.5:
            post_at(x, y, h + POST_TOP)
    return cv.a, A


def dock_whole_cut(out_png):
    """Candidate A of the dock review (not wired): the sheet dock cut whole with convert.py (its water, reeds and boat
    dropped), mirrored and fitted to 3 x 1. Returns (canvas, the deck's front corner + 3 px: where the anchor goes)."""
    box = (1120, 175, 1445, 425)
    a = np.array(Image.open(C3).convert("RGBA").crop(box))
    rgb = a[..., :3].astype(int)
    drop = ((rgb[..., 2] > rgb[..., 0] + 30) & (rgb[..., 2] > rgb[..., 1] + 5)) | \
           ((rgb[..., 1] > rgb[..., 0] + 10) & (rgb[..., 1] > rgb[..., 2] + 10))
    a[drop, 3] = 0
    a = convert.keep_shapes(a)
    tmp = Path(tempfile.mkdtemp()) / "dock_cut.png"
    Image.fromarray(a, "RGBA").save(tmp)
    w, h = a.shape[1], a.shape[0]
    c, _, info = convert.convert(str(tmp), (0, 0, w, h), (DW, DD), mirror=True, colors=32, measure="bbox")
    s = info["scale"]
    pad = 6
    fx = round(w * s) - (DECK_F[0] - box[0]) * s + pad
    fy = (DECK_F[1] - box[1]) * s + pad
    c = unglow(c.astype(float)).astype(np.uint8)
    Image.fromarray(c, "RGBA").save(out_png)
    return c, (int(round(fx)), int(round(fy + DH)))


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
    """Unsharp, one shared median-cut palette over all states, then the 1 px outline. In: float RGBA arrays. A drawn
    set (colors None) keeps its own few colours: outline only."""
    if colors is None:
        return [outline(np.where(st[..., 3:] > 0, st, 0)).astype(np.uint8) for st in stills]
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
    "dock": (build_dock, [DW, DD], 3, 62, "dock", "dock", None, False),
}


def make(name, out_dir):
    build, fp, height, seed, tag, role, colors, harm = SETS[name]
    raw = {}
    anchor = None
    for st in ("intact", "damaged", "ruins"):
        a, A = build(st)
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
