"""ChatGPT-painted building sheets (concepts/GPT/*_sheet_v1.webp) as game sprite sets, for the GPT buildings proof
(src/environment/art/gpt_proof.gd puts each on one existing plot; art only). No AI calls: cut, fit, draw.

Each sheet is one SHEETS entry: its source file, its grid, the painted smoke to strip, and its sets (grid cell,
footprint corners, plot footprint, height, kind, role, tag, chimney, ruins). Every sheet is a 3 x 2 grid on a
transparent or white ground, painted at about 3-4x game size from the blockouts in concepts/GPT/, lit from the left
and in the game's orientation (a wide building's long side is its left face), so nothing is mirrored.

  defence (defence_sheet_v1.webp, from blockouts_defence.png)
  set              sheet cell     plot (gpt_proof.gd)                          structure drawn on
  gpt_townhall     top-left       TAVERNS[0]  2.4 x 1.5                         HOUSE / house / tavern     h 30
  gpt_armoury      top-middle     WORKSHOP    2.6 x 1.5                         HOUSE / house / workshop   h 22
  gpt_jail         top-right      townhouse   1.3 x 0.95 at (-8.4, 1.38)        HOUSE / house / townhouse  h 29
  gpt_courthouse   bottom-left    TAVERNS[1]  1.6 x 2.4 (drawn 2.4 x 1.6, mirrored on the deep plot)  tavern  h 30
  gpt_watchtower   bottom-middle  cottage     0.95 x 0.75 at (-8.28, 3.27)      HOUSE / house / ""         h 19
  gpt_treasury     bottom-right   townhouse   1.3 x 0.95 at (-10.39, -0.38)     HOUSE / house / townhouse  h 28

  faith (faith_sheet_v1.webp, white ground, from blockouts/2_faith.png)
  gpt_chapel       top-left       townhouse   1.3 x 0.95 at (5.33, -10.9)       HOUSE / house / townhouse  h 29
  gpt_monastery    top-middle     TAVERNS[2]  2.8 x 1.8                         HOUSE / house / tavern     h 30
  gpt_graveyard    top-right      townhouse   0.95 x 1.3 at (3.53, -7.5) (drawn 1.3 x 0.95, mirrored)   townhouse h 28
  gpt_hospital     bottom-left    CARPENTER   2.3 x 1.15                        HOUSE / house / carpenter  h 20
  gpt_leperhouse   bottom-middle  townhouse   0.95 x 1.3 at (7.44, 10.3) (drawn 1.3 x 0.95, mirrored)   townhouse h 29
  gpt_bathhouse    bottom-right   townhouse   1.3 x 0.95 at (7.1, -4.0)         HOUSE / house / townhouse  h 28

Cut: the background goes (alpha below 128, then near-white flooded in from the border, so interior whites such as
the clock face stay); smoke painted on a sheet goes too (pale grey px in its smoke boxes: cleared above a chimney,
darkened to the flue inside it), as ChimneySmoke draws the smoke; the cell's largest shape is kept with every detached
piece in the same cell of at least MIN_PROP px (barrels, the stocks, the coin chest).

Fit: each building's footprint diamond is measured on the sheet by hand (its base corners L, F, R: left, front,
right; for the armoury R is the diamond's corner behind the shed, for the watchtower the outer corners of its leg
plinths). The scale makes the diamond 32 * (W + D) px wide for the plot's footprint; Y_STRETCH evens out a building
painted flatter than 2:1 (the courthouse). The anchor is the least-squares fit of the three corners to the plot's
diamond, so a building whose proportions differ a little from its plot's splits the difference. Premultiplied Lanczos,
hard alpha (>= 110). The final step is the style match pass (style_match.py): saturation per material, local
contrast, the lock to the game palette (game_palette.png), the speck clean, the eaves and the outline in the in-game
buildings' colours, the lit windows on their ramp (and glow_mask.png); its knobs are tuned on the intact and used on
all three stills. Corner errors print for the three fitted corners
and, as convert.py reports them, the nearest base pixel to each side corner.

Damaged (drawn locally, batch 3 style): holes through the roof (charred rim, dark loft, rafters, sooted tiles), a
scorch up a wall (warehouse.scorch, darker) and a door or shutter hanging off its hinge. Clean shapes, no noise.

Ruins: the approved ruins of the closest existing set scaled onto the plot (the batch 3 method, warehouse.ruins):
the tavern's for the town hall (timber, the same plot); the town tower's (stone, as the bell tower's) for the stone
buildings (the armoury, the courthouse, the jail and the treasury), filling each plot (filled_ruins: scaled to the
plot's short side and laid twice along its long side), its fallen blue banner painted out (no_banner).
The watchtower's are local: its four leg stumps and the cabin fallen on its side behind them. Reused ruins go through
the style match's lock and outline only (they are already in the game's style); the watchtower's get the whole pass.

No idle strips; the collapse is the engine's sink. A set whose building has a chimney gets a chimney key (its top's
middle) so ChimneySmoke rises from it; the watchtower, the chapel and the graveyard have none.

Usage (from anywhere):
  python tools/dev/ref_convert/gpt_convert.py [all | <sheet> | <set> ...] [--out <scratch dir>] [--debug <dir>]
"""
import argparse
import json
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bridges  # noqa: E402
import convert  # noqa: E402
import style_match  # noqa: E402
import warehouse  # noqa: E402

ROOT = convert.ROOT
B = convert.B
GPT = ROOT / "concepts" / "GPT"
MIN_PROP = 40
PAD = 6
CHAR = warehouse.CHAR
TIMBER_DK = warehouse.TIMBER_DK

# Per set: cell (col, row), corners L F R (sheet px), y stretch k, footprint [W, D] (its plot's), height, seed, kind,
# role, tag, chimney top (sheet px) or None, ruins (source set, scale or "fill") or None for a local ruin.
DEFENCE_SETS = {
    "gpt_townhall": dict(cell=(0, 0), L=(73, 324), F=(337, 455), R=(511, 365), k=1.0, fp=[2.4, 1.5], height=30,
                         seed=80, kind="HOUSE", role="house", tag="tavern", chimney=(275, 52), ruins=("tavern", 1.0)),
    "gpt_armoury": dict(cell=(1, 0), L=(623, 336), F=(939, 493), R=(1094, 416), k=1.0, fp=[2.6, 1.5], height=22,
                        seed=81, kind="HOUSE", role="house", tag="workshop", chimney=(771, 102),
                        ruins=("town_tower", "fill")),
    "gpt_jail": dict(cell=(2, 0), L=(1200, 398), F=(1361, 481), R=(1497, 416), k=1.0, fp=[1.3, 0.95], height=29,
                     seed=82, kind="HOUSE", role="house", tag="townhouse", chimney=(1385, 220),
                     ruins=("town_tower", "fill")),
    "gpt_courthouse": dict(cell=(0, 1), L=(72, 784), F=(346, 904), R=(551, 818), k=1.16, fp=[2.4, 1.6], height=30,
                           seed=83, kind="HOUSE", role="house", tag="tavern", chimney=(409, 572),
                           ruins=("town_tower", "fill")),
    "gpt_watchtower": dict(cell=(1, 1), L=(726, 848), F=(824, 901), R=(924, 844), k=1.0, fp=[0.95, 0.75], height=19,
                           seed=84, kind="HOUSE", role="house", tag="", chimney=None, ruins=None),
    "gpt_treasury": dict(cell=(2, 1), L=(1168, 816), F=(1356, 916), R=(1521, 836), k=1.0, fp=[1.3, 0.95], height=28,
                         seed=85, kind="HOUSE", role="house", tag="townhouse", chimney=(1441, 632),
                         ruins=("town_tower", "fill")),
}
# The faith sheet. L and R are the building's outer base corners and F is where their edges meet: empty ground in
# front of the monastery's open cloister and of the bathhouse's furnace annex; the chapel's porch stands just outside
# its diamond (as the jail's stocks do). All six fall to the town tower's stone rubble filling the plot (the tavern's
# timber ruins scaled down to a townhouse plot break up into specks).
FAITH_SETS = {
    "gpt_chapel": dict(cell=(0, 0), L=(33, 394), F=(241, 502), R=(386, 430), k=1.0, fp=[1.3, 0.95], height=29,
                       seed=86, kind="HOUSE", role="house", tag="townhouse", chimney=None,
                       ruins=("town_tower", "fill")),
    "gpt_monastery": dict(cell=(1, 0), L=(466, 403), F=(746, 550), R=(962, 428), k=0.92, fp=[2.8, 1.8], height=30,
                          seed=87, kind="HOUSE", role="house", tag="tavern", chimney=(828, 160),
                          ruins=("town_tower", "fill")),
    "gpt_graveyard": dict(cell=(2, 0), L=(994, 454), F=(1253, 587), R=(1431, 494), k=0.97, fp=[1.3, 0.95],
                          height=28, seed=88, kind="HOUSE", role="house", tag="townhouse", chimney=None,
                          ruins=("town_tower", "fill")),
    "gpt_hospital": dict(cell=(0, 1), L=(48, 811), F=(360, 974), R=(483, 913), k=1.0, fp=[2.3, 1.15], height=20,
                         seed=89, kind="HOUSE", role="house", tag="carpenter", chimney=(215, 533),
                         ruins=("town_tower", "fill")),
    "gpt_leperhouse": dict(cell=(1, 1), L=(535, 872), F=(763, 985), R=(954, 885), k=1.0, fp=[1.3, 0.95], height=29,
                           seed=90, kind="HOUSE", role="house", tag="townhouse", chimney=(780, 655),
                           ruins=("town_tower", "fill")),
    "gpt_bathhouse": dict(cell=(2, 1), L=(1008, 873), F=(1279, 1014), R=(1436, 932), k=0.96, fp=[1.3, 0.95],
                          height=28, seed=91, kind="HOUSE", role="house", tag="townhouse", chimney=(1346, 676),
                          ruins=("town_tower", "fill")),
}
# Its painted smoke (x0, y0, x1, y1 sheet px; "clear" above a chimney, "flue" inside it): the monastery's chimney,
# the bathhouse's tall chimney (and the wisp beside it) and its left roof vent.
FAITH_SMOKE = [(812, 120, 848, 157, "clear"), (812, 157, 848, 168, "flue"),
               (1325, 565, 1435, 670, "clear"), (1334, 670, 1362, 690, "flue"), (1366, 720, 1405, 792, "clear"),
               (1140, 570, 1200, 625, "clear")]

# A sheet: its source (in concepts/GPT), its grid (cols, rows), the painted smoke to strip, and its sets.
SHEETS = {
    "defence": dict(src="defence_sheet_v1.webp", grid=(3, 2), smoke=[], sets=DEFENCE_SETS),
    "faith": dict(src="faith_sheet_v1.webp", grid=(3, 2), smoke=FAITH_SMOKE, sets=FAITH_SETS),
}
# name -> its set's spec, "sheet" (its SHEETS key) added
SETS = {n: dict(v, sheet=k) for k, sh in SHEETS.items() for n, v in sh["sets"].items()}


# --- cut -----------------------------------------------------------------------------------------------------------

def _label(mask):
    """8-connected components of a boolean mask: a list of (ys, xs) arrays."""
    h, w = mask.shape
    seen = np.zeros((h, w), bool)
    comps = []
    for y0, x0 in zip(*np.nonzero(mask)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        ys, xs = [], []
        while q:
            y, x = q.popleft()
            ys.append(y); xs.append(x)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    yy, xx = y + dy, x + dx
                    if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not seen[yy, xx]:
                        seen[yy, xx] = True
                        q.append((yy, xx))
        comps.append((np.array(ys), np.array(xs)))
    return comps


def background(a):
    """Transparent pixels, plus near-white ones reached from the border (interior whites are kept)."""
    bg = a[..., 3] < 128
    rgb = a[..., :3].astype(int)
    white = (rgb.min(2) > 225) & (rgb.max(2) - rgb.min(2) < 26) & ~bg
    h, w = bg.shape
    m = Image.new("L", (w + 2, h + 2), 255)
    m.paste(Image.fromarray(np.where(white | bg, 255, 0).astype(np.uint8)), (1, 1))
    ImageDraw.floodfill(m, (0, 0), 128)
    return bg | (np.array(m)[1:-1, 1:-1] == 128)


def is_smoke(rgb):
    """Pale grey: the painted smoke's colour (the stone, plaster and chimney caps round it are warmer or darker)."""
    rgb = rgb.astype(int)
    return (rgb.min(-1) > 140) & (rgb.max(-1) - rgb.min(-1) < 24)


def strip_smoke(a, boxes):
    """The painted smoke in `boxes` gone: cleared above a chimney ("clear"), the flue's dark inside it ("flue")."""
    for x0, y0, x1, y1, mode in boxes:
        sub = a[y0:y1, x0:x1]
        m = is_smoke(sub[..., :3]) & (sub[..., 3] > 0)
        if mode == "clear":
            sub[m, 3] = 0
        else:
            sub[m, :3] = np.round(np.array(CHAR) * 0.6).astype(np.uint8)
    return a


_SHEETS = {}
_COMPS = {}


def sheet(key):
    if key not in _SHEETS:
        sh = SHEETS[key]
        a = np.array(Image.open(GPT / sh["src"]).convert("RGBA"))
        a[background(a), 3] = 0
        a[a[..., 3] > 0, 3] = 255
        _SHEETS[key] = strip_smoke(a, sh["smoke"])
    return _SHEETS[key]


def cut(cell, key):
    """The cell's building on its sheet's full canvas: its largest shape and the detached props in its cell."""
    a = sheet(key)
    h, w = a.shape[:2]
    grid = SHEETS[key]["grid"]
    cw, ch = w / grid[0], h / grid[1]
    if key not in _COMPS:
        _COMPS[key] = _label(a[..., 3] > 0)
    # a shape belongs to the cell its middle lies in (the watchtower's flag pokes into the row above)
    mine = [c for c in _COMPS[key] if int(c[1].mean() // cw) == cell[0] and int(c[0].mean() // ch) == cell[1]]
    big = max(mine, key=lambda c: len(c[0]))
    keep = np.zeros((h, w), bool)
    for ys, xs in mine:
        if ys is big[0] or len(ys) >= MIN_PROP:
            keep[ys, xs] = True
    out = a.copy()
    out[~keep, 3] = 0
    return out


# --- fit -----------------------------------------------------------------------------------------------------------

def fit(spec):
    """(native RGBA float array, anchor (x, y) float, transform sheet px -> sprite px, info)."""
    a = cut(spec["cell"], spec["sheet"])
    W, D = spec["fp"]
    L, F, R = (np.array(spec[c], float) for c in "LFR")
    k = spec["k"]
    s = 32.0 * (W + D) / (R[0] - L[0])
    ys, xs = np.nonzero(a[..., 3] > 0)
    bx0, by0, bx1, by1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    crop = a[by0:by1, bx0:bx1]
    nw, nh = round((bx1 - bx0) * s), round((by1 - by0) * s * k)
    small = Image.fromarray(crop, "RGBA").convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    out = np.array(small).astype(float)
    out[..., 3] = np.where(out[..., 3] >= 110, 255, 0)
    out[out[..., 3] == 0, :3] = 0
    sx, sy = nw / (bx1 - bx0), nh / (by1 - by0)

    def tf(p):
        return np.array([(p[0] - bx0) * sx, (p[1] - by0) * sy])

    Lp, Fp, Rp = tf(L), tf(F), tf(R)
    A = ((Lp + np.array([32 * W, 16 * W])) + Fp + (Rp - np.array([32 * D, -16 * D]))) / 3.0
    A = np.round(A)
    errs = {"left": Lp - (A - np.array([32 * W, 16 * W])), "front": Fp - A,
            "right": Rp - (A + np.array([32 * D, -16 * D]))}
    return out, A, tf, {"scale": s, "fit_errors": errs}


def pad_to(img, A, tf, m=50):
    out = np.pad(img, ((m, m), (m, m), (0, 0)))
    return out, A + m, (lambda p: tf(p) + m)


# --- damage --------------------------------------------------------------------------------------------------------

def roof_mask(c):
    """Roof tiles: the red clay or blue slate (not timber, plaster, stone, glass or flowers)."""
    rgb = c[..., :3]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    al = c[..., 3] > 0
    red = (r > g + 45) & (r > b + 45) & (g < r * 0.55)
    blue = (b > r + 6) & (b > g - 4) & (r < 130)
    return al & (red | blue)


def roof_holes(c, holes, roof=None):
    """Holes through the tiles: each (x, y, rx, ry) an ellipse on the canvas sheared along the roof (slope -1 for a
    left slope, +1 for a right one: (x, y, rx, ry, slope)). A dark loft with rafters, a charred rim, sooted tiles round
    it. Only roof pixels change."""
    out = c.copy()
    h, w = c.shape[:2]
    ys, xs = np.mgrid[0:h, 0:w]
    roof = roof_mask(c) if roof is None else roof
    for (hx, hy, rx, ry, sl) in holes:
        u = xs - hx
        v = (ys - hy) - (xs - hx) * 0.5 * sl
        r = (u / rx) ** 2 + (v / ry) ** 2
        jag = ((xs * 7 + ys * 13 + int(hx)) % 5) * 0.06          # a ragged, fixed edge, no noise field
        inside = roof & (r + jag < 1.0)
        rim = roof & ~inside & (r + jag < 1.55)
        soot = roof & ~inside & ~rim & (r < 2.6)
        out[soot, :3] = out[soot, :3] * 0.68 + CHAR * 0.32
        out[rim, :3] = CHAR * 0.85 + out[rim, :3] * 0.15
        out[inside, :3] = CHAR * 0.45
        raf = inside & ((((xs - hx) - 2 * (ys - hy) * sl) % 6) < 1.2)
        out[raf, :3] = TIMBER_DK * 0.7
    return out


def scorch(img, x0, x1, y_top, y_bot):
    """warehouse.scorch, darker: soot up a wall from a burnt opening, darkest low in the middle, fading up and out in
    three clean steps (these walls are pale and busy, so the lightest step still reads)."""
    out = img.copy()
    mid, half = (x0 + x1) / 2.0, (x1 - x0) / 2.0
    for y in range(int(round(y_top)), int(round(y_bot)) + 1):
        t = (y_bot - y) / max(y_bot - y_top, 1)
        width = half * (1.0 - 0.45 * t)
        for x in range(int(x0), int(x1) + 1):
            if out[y, x, 3] == 0 or abs(x - mid) > width:
                continue
            k = abs(x - mid) / max(width, 1)
            f = round((0.12 + 0.6 * min(1.0, 0.75 * t + 0.6 * k)) * 3) / 3
            out[y, x, :3] = out[y, x, :3] * f + CHAR * (1 - f)
    return out


def hang(c, box, sag=3, side="right"):
    """A door or shutter in `box` (x0, y0, x1, y1, canvas px) hanging off its hinge side: the opening goes dark and the
    leaf drops by up to `sag` px at its free edge, the dark gap showing above it."""
    out = c.copy()
    x0, y0, x1, y1 = box
    leaf = c[y0:y1 + 1, x0:x1 + 1].copy()
    out[y0:y1 + 1, x0:x1 + 1, :3] = np.where(c[y0:y1 + 1, x0:x1 + 1, 3:] > 0, CHAR * 0.35, out[y0:y1 + 1, x0:x1 + 1, :3])
    n = x1 - x0
    for i in range(n + 1):
        f = i / max(n, 1) if side == "right" else 1 - i / max(n, 1)
        drop = int(round(sag * f))
        col = leaf[:, i]
        for j in range(col.shape[0]):
            y = y0 + j + drop
            if col[j, 3] > 0 and y <= y1 + 1 and out[y, x0 + i, 3] > 0:
                out[y, x0 + i, :3] = col[j, :3] * 0.85
    return out


# Per set, in sheet px (mapped through the fit): roof holes (x, y, rx, ry in sprite px, slope), scorch (x, wall top y,
# wall bottom y, half width in sprite px) and the hanging leaf (box corners in sheet px, sag, hinge side).
DAMAGE = {
    "gpt_townhall": dict(holes=[(330, 150, 7.5, 4.2, 1), (150, 112, 5.0, 3.0, 1)],
                         scorch=(455, 230, 330, 10), hang=((195, 330, 236, 404), 6, "right")),
    "gpt_armoury": dict(holes=[(720, 200, 7.0, 4.0, 1), (930, 330, 5.0, 3.0, 1)],
                        scorch=(796, 300, 385, 7), hang=((741, 346, 764, 411), 5, "right")),
    "gpt_jail": dict(holes=[(1290, 280, 6.0, 3.5, 1)],
                     scorch=(1322, 330, 440, 7), hang=((1420, 385, 1453, 460), 5, "left")),
    "gpt_courthouse": dict(holes=[(230, 640, 7.0, 4.0, 1), (470, 690, 5.0, 3.0, -1)],
                           scorch=(407, 720, 830, 8), hang=((172, 770, 205, 824), 5, "right")),
    "gpt_watchtower": dict(holes=[(790, 595, 4.0, 2.4, 1)],
                           scorch=None, hang=None),
    "gpt_treasury": dict(holes=[(1290, 700, 6.0, 3.5, 1)],
                         scorch=(1226, 740, 850, 7), hang=((1404, 805, 1432, 888), 5, "left")),
    "gpt_chapel": dict(holes=[(160, 265, 4.5, 2.6, 1)],
                       scorch=(150, 340, 425, 4), hang=((172, 432, 195, 488), 4, "right")),
    "gpt_monastery": dict(holes=[(590, 250, 6.5, 3.8, 1), (860, 250, 5.0, 3.0, -1)],
                          scorch=(765, 400, 470, 5), hang=((752, 468, 778, 520), 4, "right")),
    "gpt_graveyard": dict(holes=[(1360, 370, 3.0, 1.8, -1)],
                          scorch=(1378, 420, 470, 3), hang=((1125, 455, 1170, 525), 4, "left")),
    "gpt_hospital": dict(holes=[(130, 640, 6.5, 3.8, 1), (300, 700, 5.0, 3.0, 1)],
                         scorch=(285, 830, 900, 5), hang=((166, 832, 190, 892), 4, "right")),
    "gpt_leperhouse": dict(holes=[(690, 700, 4.5, 2.6, 1)],
                           scorch=(718, 790, 850, 4), hang=((642, 818, 668, 878), 4, "right")),
    "gpt_bathhouse": dict(holes=[(1120, 690, 5.0, 3.0, 1), (1240, 740, 4.0, 2.4, 1)],
                          scorch=(1188, 840, 940, 4), hang=((1105, 830, 1130, 925), 4, "right")),
}


def damaged(name, c, tf):
    d = DAMAGE[name]
    s = SETS[name]
    holes = []
    for (hx, hy, rx, ry, sl) in d["holes"]:
        p = tf((hx, hy))
        holes.append((p[0], p[1], rx, ry, sl))
    out = roof_holes(c, holes)
    if d["scorch"]:
        x, yt, yb, half = d["scorch"]
        p0, p1 = tf((x, yt)), tf((x, yb))
        out = scorch(out, int(p0[0] - half), int(p0[0] + half), p0[1], p1[1])
    if d["hang"]:
        (bx0, by0, bx1, by1), sag, side = d["hang"]
        q0, q1 = tf((bx0, by0)), tf((bx1, by1))
        out = hang(out, (int(round(q0[0])), int(round(q0[1])), int(round(q1[0])), int(round(q1[1]))), sag, side)
    if name == "gpt_watchtower":
        out = watchtower_damage(out, tf)
    del s
    return out


def watchtower_damage(c, tf):
    """The watchtower's flag torn off its pole (the pole stays) and one rail of the cabin gone."""
    out = c.copy()
    fl0, fl1 = tf((840, 500)), tf((890, 545))
    out[int(fl0[1]):int(fl1[1]) + 1, int(fl0[0]):int(fl1[0]) + 1, 3] = 0
    return out


# --- ruins ---------------------------------------------------------------------------------------------------------

def borrowed_ruins(src_name, k, fp, A, shape):
    """The approved ruins of `src_name`, scaled k, their footprint's centre on this plot's (warehouse.ruins). k "fill":
    filled_ruins()."""
    if k == "fill":
        return filled_ruins(src_name, fp, A, shape)
    man = json.load(open(B / "manifest.json", encoding="utf-8"))
    sm = man[src_name]
    src = Image.fromarray(no_banner(np.array(Image.open(B / src_name / "ruins.png").convert("RGBA"))), "RGBA")
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
    # paste the source's opaque box only (a tall tower canvas's empty top may not fit above this plot's)
    ys, xs = np.nonzero(a[..., 3] > 0)
    a = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    ox, oy = ox + xs.min(), oy + ys.min()
    h, w = a.shape[:2]
    out[oy:oy + h, ox:ox + w] = a
    return out


def scaled_ruins(src_name, k):
    """(RGBA float array, anchor) of `src_name`'s approved ruins, banner painted out, scaled k at native pixels: a
    premultiplied Lanczos, snapped back to the source's own 32 colours, outlined (as bell_ruins_from_tower.py)."""
    man = json.load(open(B / "manifest.json", encoding="utf-8"))
    As = man[src_name]["anchor"]
    src = Image.fromarray(no_banner(np.array(Image.open(B / src_name / "ruins.png").convert("RGBA"))), "RGBA")
    if k == 1.0:
        return np.array(src).astype(float), (float(As[0]), float(As[1]))
    nw, nh = round(src.width * k), round(src.height * k)
    small = src.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    al = np.array(small.getchannel("A")) >= 120
    pal = src.convert("RGB").quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    q = small.convert("RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
    a = np.zeros((nh, nw, 4))
    a[..., :3] = np.array(q)
    a[..., 3] = np.where(al, 255, 0)
    return bridges.outline(a), (As[0] * k, As[1] * k)


def filled_ruins(src_name, fp, A, shape):
    """A square set's ruins (the town tower's, footprint S x S) filling a W x D plot: scaled to the plot's short side
    (k = min(W, D) / S) and laid twice along its long side, one copy at the plot's front corner and one at the far end
    of the long side, the far one drawn first. So the rubble covers the whole diamond, at the tower's own pixel size
    and light, and reads as one long ruined building of two bays."""
    man = json.load(open(B / "manifest.json", encoding="utf-8"))
    S = man[src_name]["footprint"][0]
    W, D = fp
    short = min(W, D)
    a, As = scaled_ruins(src_name, short / S)
    # offsets of the copies' front corners from the plot's: along the W edge (up-left) or the D edge (up-right)
    step = np.array([-32.0, -16.0]) if W >= D else np.array([32.0, -16.0])
    offs = [abs(W - D), 0.0] if abs(W - D) > 1e-6 else [0.0]
    out = np.zeros(shape)
    ys, xs = np.nonzero(a[..., 3] > 0)
    box = a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h, w = box.shape[:2]
    for o in offs:                       # far copy first: the near one draws over it
        fx, fy = np.array(A, float) + step * o
        ox, oy = int(round(fx - As[0])) + xs.min(), int(round(fy - As[1])) + ys.min()
        on = box[..., 3] > 0
        region = out[oy:oy + h, ox:ox + w]
        region[on] = box[on]
    return out


BANNER_SHIFT = 28       # px: the stone a fallen banner is painted over with is copied from this far to its right


def no_banner(a):
    """A reused ruins still without the stray banner (the town tower's blue one lies on its rubble): each row of the
    banner's span (its blue px, b > r + 25 and b > g, first to last per row, 1 px more around) is painted over with
    the stone BANNER_SHIFT px to its right. No blue: unchanged."""
    a = a.copy()
    r, g, b = (a[..., i].astype(int) for i in range(3))
    op = a[..., 3] > 0
    blue = op & (b > r + 25) & (b > g)
    if not blue.any():
        return a
    m = np.zeros_like(op)
    for y in np.unique(np.nonzero(blue)[0]):
        xs = np.nonzero(blue[y])[0]
        m[y, xs.min():xs.max() + 1] = True
    grown = m.copy()
    grown[1:] |= m[:-1]; grown[:-1] |= m[1:]; grown[:, 1:] |= m[:, :-1]; grown[:, :-1] |= m[:, 1:]
    ys, xs = np.nonzero(grown & op)
    assert (a[ys, xs + BANNER_SHIFT, 3] > 0).all(), "the banner's patch source runs off the rubble"
    a[ys, xs] = a[ys, xs + BANNER_SHIFT]
    return a


def watchtower_ruins(c, tf, A, fp):
    """Its four leg stumps (cut at sheet y STUMP_Y, their tops charred) with the crate and the ladder's foot, and the
    cabin with its roof fallen on its side across the plot behind them: turned a quarter (roof to the right), laid flat
    (y x LIE), burnt darker; the flag gone."""
    out = np.zeros_like(c)
    h, w = c.shape[:2]
    top = int(round(tf((0, STUMP_Y))[1]))
    out[top:] = c[top:]
    for y in (top, top + 1):
        m = out[y, :, 3] > 0
        out[y, m, :3] = out[y, m, :3] * 0.35 + CHAR * 0.65
    y0, y1 = (int(round(tf((0, v))[1])) for v in CABIN_Y)
    cabin = c[y0:y1 + 1].copy()
    ys, xs = np.nonzero(cabin[..., 3] > 0)
    cabin = cabin[:, xs.min():xs.max() + 1]
    im = Image.fromarray(np.clip(cabin, 0, 255).astype(np.uint8), "RGBA").rotate(-90, expand=True,
                                                                                 resample=Image.NEAREST)
    im = im.resize((im.width, max(1, round(im.height * LIE))), Image.NEAREST)
    fallen = np.array(im).astype(float)
    fallen[..., :3] = fallen[..., :3] * 0.7 + CHAR * 0.3
    fallen[..., 3] = np.where(fallen[..., 3] >= 128, 255, 0)
    fh, fw = fallen.shape[:2]
    W, D = fp
    cx = A[0] + 16 * (D - W)                      # the plot's centre on screen
    cy = A[1] - 8 * (W + D)
    ox, oy = int(round(cx - fw / 2)), int(round(cy + 6 - fh))
    under = np.zeros_like(out)
    under[oy:oy + fh, ox:ox + fw] = fallen
    # the cabin lies behind the stumps: they draw over it
    keep = out[..., 3] > 0
    under[keep] = out[keep]
    return under


STUMP_Y = 848            # sheet y the legs are cut at
CABIN_Y = (553, 739)     # sheet rows of the roof (below the flag's pole) and the cabin, down to its floor beam
LIE = 0.6


# --- make ----------------------------------------------------------------------------------------------------------

def nearest_base_errors(img, A, fp):
    """As convert.py reports them (left = A - (32 W, 16 W), right = A + (32 D, -16 D)): the nearest column-bottom pixel
    to each side corner."""
    return warehouse.corner_errors(img, A, fp)


def make(name, out_dir, debug=None):
    spec = SETS[name]
    native, A, tf, info = fit(spec)
    native, A, tf = pad_to(native, A, tf)
    dam = damaged(name, native, tf)
    st = {"intact": native, "damaged": dam}
    if spec["ruins"]:
        st["ruins"] = borrowed_ruins(spec["ruins"][0], spec["ruins"][1], spec["fp"], A, native.shape)
    else:
        st["ruins"] = watchtower_ruins(native, tf, A, spec["fp"])
    al = np.zeros(native.shape[:2], bool)
    for v in st.values():
        al |= v[..., 3] > 0
    ys, xs = np.nonzero(al)
    y0, x0, x1 = ys.min() - PAD, xs.min() - PAD, xs.max() + 1 + PAD
    y1 = max(ys.max() + 1 + PAD, int(A[1]) + 11)
    crop = {k2: v[y0:y1, x0:x1] for k2, v in st.items()}
    A = (int(A[0] - x0), int(A[1] - y0))
    # the final step: the style match pass (style_match.py), its knobs tuned on the intact; reused ruins are already
    # in the game's style, so they get only its palette lock, speck clean and outline
    knobs, st_after = style_match.tune(crop["intact"])
    intact, lit = style_match.match(crop["intact"], knobs)
    done = [intact, style_match.match(crop["damaged"], knobs, ref=crop["intact"])[0],
            style_match.match(crop["ruins"], knobs, light=bool(spec["ruins"]), glow=False)[0]]
    d = out_dir / name
    d.mkdir(parents=True, exist_ok=True)
    for state, img in zip(("intact", "damaged", "ruins"), done):
        Image.fromarray(img, "RGBA").save(d / (state + ".png"))
    gm = d / "glow_mask.png"
    if lit.any():           # window_glow.py's convention: white where lit, one frame in size, transparent elsewhere
        o = np.zeros(intact.shape, np.uint8)
        o[lit] = (255, 255, 255, 255)
        Image.fromarray(o, "RGBA").save(gm)
    else:                   # no lit windows: no mask, nor its import file
        for f in (gm, d / "glow_mask.png.import"):
            if f.exists():
                f.unlink()
    roof = " ".join("%s x%.2f/x%.2f c%.2f" % (("red", "slate")[m == style_match.ss.BLUE], g[0], g[1],
                                             knobs.get("tile", {}).get(m, 1.0))
                    for m, g in sorted(knobs["roof"].items()))
    print("  style match: lift %.2f amount %.2f sat x%.2f roof %s; edge %.3f lum %.3f outline %.3f colours %d "
          "sat %.3f; %d lit px" % (knobs["lift"], knobs["amount"], knobs["glob"], roof or "-", st_after["edge"],
                                   st_after["lum"], st_after["outline"], st_after["colours"], st_after["sat"],
                                   int(lit.sum())))
    h, w = done[0].shape[:2]
    fe = {k2: (round(float(v[0]), 1), round(float(v[1]), 1)) for k2, v in info["fit_errors"].items()}
    nb = nearest_base_errors(done[0], A, spec["fp"])
    print("%s size %s footprint %s anchor %s scale %.3f" % (name, [w, h], spec["fp"], list(A), info["scale"]))
    print("  fitted corners off by (dx, dy):", fe)
    print("  nearest base pixel to the side corners:", nb)
    entry = {"size": [w, h], "footprint": spec["fp"], "anchor": list(A), "height": spec["height"],
             "seed": spec["seed"], "kind": spec["kind"], "role": spec["role"], "tag": spec["tag"]}
    if spec["chimney"]:
        p = tf(spec["chimney"])
        entry["chimney"] = [int(round(p[0] - x0)), int(round(p[1] - y0))]
        print("  chimney", entry["chimney"])
    if debug:
        dbg(done, A, spec["fp"], debug / (name + "_states.png"), entry.get("chimney"))
    return entry, done, A


def dbg(done, A, fp, path, chimney=None, k=3):
    """The three stills side by side at k x on a grey ground, the footprint diamond drawn on each."""
    h, w = done[0].shape[:2]
    W, D = fp
    sheet_ = Image.new("RGBA", ((w + 10) * 3 * k, h * k), (92, 96, 104, 255))
    dr = ImageDraw.Draw(sheet_)
    for i, img in enumerate(done):
        ox = i * (w + 10) * k
        sheet_.alpha_composite(Image.fromarray(img, "RGBA").resize((w * k, h * k), Image.NEAREST), (ox, 0))
        pts = [A, (A[0] - 32 * W, A[1] - 16 * W), (A[0] - 32 * W + 32 * D, A[1] - 16 * W - 16 * D),
               (A[0] + 32 * D, A[1] - 16 * D)]
        dr.polygon([(ox + (x + 0.5) * k, (y + 0.5) * k) for x, y in pts], outline=(80, 255, 120, 255))
        if chimney and i == 0:
            dr.ellipse([ox + chimney[0] * k - 4, chimney[1] * k - 4, ox + chimney[0] * k + 4, chimney[1] * k + 4],
                       outline=(255, 0, 255, 255))
    sheet_.save(path)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", help="write the sets here instead of assets/pixellab/buildings (no manifest change)")
    p.add_argument("--debug", help="write a 3x sheet of each set's stills, its diamond drawn on, here")
    args = p.parse_args()
    dbg_dir = Path(args.debug) if args.debug else None
    if dbg_dir:
        dbg_dir.mkdir(parents=True, exist_ok=True)
    names = []
    for w in args.what:
        names += list(SETS) if w == "all" else list(SHEETS[w]["sets"]) if w in SHEETS else [w]
    for n in names:
        entry, _, _ = make(n, Path(args.out) if args.out else B, dbg_dir)
        if not args.out:
            convert.write_manifest(B / "manifest.json", n, entry)
            print("manifest updated:", n)
