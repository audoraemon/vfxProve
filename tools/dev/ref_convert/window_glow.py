"""Window glow masks: a set's lit windows, as white pixels in <set>/glow_mask.png (one frame in size, transparent
elsewhere). The sprite shader (structure_sprite.gdshader, window_flicker) flickers those pixels on the intact still and
its idle strip.

A lit pane is found in two steps (panes()):
  1. Cores (windows()): warm, bright lamp light with the window's dark bars and frame (luminance < DARK) in its 5x5
     neighbourhood. Warm and bright is the plan's rule (R >= 180, R > G > B, luminance >= 150) with three guards found
     on these sets: saturated ((R - B) / R >= SAT: no cream plaster), lamp-bright (R >= LAMP: no sandstone, sunlit
     wood or hay) and yellow-orange (G >= HUE * R: no red-orange roof-eave highlight).
  2. Panes: each core grows 4-connected over its pane's own tones (PANE_*, WHITE_*), which must be rare in the frame
     (RARE: plaster, beams, roof and stone are painted over hundreds of px). The grown region must fit a window
     (PANE_W x PANE_H, MAX_CLUSTER px) and be framed (_enclosed: dark on both sides of every row, above and below),
     else only its cores are kept. A pane with no core is seeded by a bright tone (SEED_*), and kept only if it fits.
     A MID_BARS set (the tavern) frames its lit panes partly in mid-brown bars (its (134,67,39), luminance 84, just
     over DARK): there a pane with a core may be framed by bars under MID_BAR that are also MID_MARGIN darker than its
     darkest tone. A coreless pane keeps the dark rule, so a pale plaster or timber streak never passes on brown wood.
Then:
  - flames are dropped: bonfire_flicker.flames() finds the baskets, the forge and the torches, and its whole flame box
    (grown by 1 px) is left out. That finder also matches warm stall awnings, so it is used only to exclude;
  - a cluster (8-connected) over MAX_CLUSTER px is a flame or a lit floor, not a window, and is dropped;
  - a set with an idle strip is read from the strip's frame 0 (that is what its intact state shows; the keep's
    PixelLab strip differs from its still), and a pixel must pass in every frame of the strip, so a banner swaying
    over a window in one frame is never lit. Frames share the layout, so one mask fits all.
Strip sets (manifest "strip": the town wall and postern) are refused: a piece draws a region wider than one frame, so
their mask lookup would stretch.

Usage (from the project root):
  python tools/dev/ref_convert/window_glow.py <set> [<set> ...]          writes the masks, prints pixels and clusters
  python tools/dev/ref_convert/window_glow.py <set> [<set> ...] --dry    prints only
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bonfire_flicker import _components, _dilate, flames, lum  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
DARK = 80           # a window's bars and frame (the keep's slits sit in L 63-75 stone)
MAX_CLUSTER = 60    # bigger warm clusters are flames or lit floors
LAMP = 240          # lamp-bright red: sandstone, pale wood and the barracks' hay stop near 235
HUE = 0.55          # G / R: lamp light is yellow-orange; the roofs' red-orange eave highlight (247,129,60) is not
SAT = 0.5           # (R - B) / R: lamp glow is saturated; cream plaster, pale wood and stone highlights are not
# A pane's tones besides its core: saturated ones (the tavern's (223,162,79), (247,129,60)) or a pale heart:
PANE_SAT = 0.5      # (R - B) / R: plaster and timber highlights (222,187,150), (189,158,125) are near 0.33
PANE_HUE = 0.5      # G / R: the red roofs (173,68,41), (240,106,69) stay out
PANE_L = 90         # the frame's bars sit below
PANE_W, PANE_H = 6, 8   # a pane's largest bounds
WHITE_L, WHITE_SAT = 200, 0.15   # a lamp's pale heart ((249,228,181), the keep slits' (249,239,203)) is a pane tone
SEED_R, SEED_L = 220, 160   # a coreless pane's seed: this red and this bright (the tavern's (223,162,79))
RARE = 40           # a pane tone is on this many px or fewer; plaster, beams, roof and stone are on hundreds
MID_BARS = {"tavern"}   # sets whose cored panes may be framed by mid-brown bars (panes(mid_bars=True))
MID_BAR = 100       # a mid-brown bar's luminance is under this (the tavern's (134,67,39) is 84; its timber 109 up)
MID_MARGIN = 60     # and this much under the pane's darkest tone (its panes' darkest, (223,162,79), is 171)


def frames_of(s, man):
    """The frames the intact state shows: the idle strip's, else the intact still alone (RGBA int arrays)."""
    w = int(man[s]["size"][0])
    idle = B / s / "idle.png"
    if idle.exists():
        st = np.array(Image.open(idle).convert("RGBA")).astype(int)
        return [st[:, k * w:(k + 1) * w] for k in range(st.shape[1] // w)]
    return [np.array(Image.open(B / s / "intact.png").convert("RGBA")).astype(int)]


def windows(a):
    """Bool mask of the lit-window candidates of one RGBA frame (flames not yet excluded)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    op = a[..., 3] > 0
    L = lum(a)
    warm = op & (r >= LAMP) & (r > g) & (g > b) & (L >= 150) & (r - b >= SAT * r) & (g >= HUE * r)
    dark = op & (L < DARK)
    near = dark.copy()
    for _ in range(2):          # 5x5 neighbourhood
        near = _dilate(near)
    return warm & near


def rare_tones(a):
    """Bool mask of the frame's rare colours (on RARE px or fewer). A lit pane's tones are rare; plaster, beams, roof
    and stone are each painted over hundreds of px."""
    op = a[..., 3] > 0
    key = (a[..., 0] << 16) | (a[..., 1] << 8) | a[..., 2]
    _, inv, cnt = np.unique(key[op], return_inverse=True, return_counts=True)
    out = np.zeros(op.shape, bool)
    out[op] = cnt[inv] <= RARE
    return out


def _enclosed(dark, pts):
    """Framed: each row of the region has a dark pixel within 2 px left and right of its span, and the region has one
    within 2 px above and below it. A pane between bars passes; a roof eave or a door edge (dark on one side only)
    does not."""
    h, w = dark.shape
    rows, cols = {}, {}
    for y, x in pts:
        rows.setdefault(y, []).append(x)
        cols.setdefault(x, []).append(y)
    for y, xs in rows.items():
        x0, x1 = min(xs), max(xs)
        if not (dark[y, max(0, x0 - 2):x0].any() and dark[y, x1 + 1:min(w, x1 + 3)].any()):
            return False
    y0, y1, x0, x1 = min(rows), max(rows), min(cols), max(cols)
    return bool(dark[max(0, y0 - 2):y0, x0:x1 + 1].any() and dark[y1 + 1:min(h, y1 + 3), x0:x1 + 1].any())


def panes(a, mid_bars=False):
    """Bool mask of one frame's lit panes. The lamp-bright cores (windows()) are the seeds; a pane is a 4-connected
    region of cores and rare warm tones (PANE_*, RARE) that fits a window (PANE_W x PANE_H, MAX_CLUSTER px) and has a
    dark bar within 2 px on both sides of every row and column (_enclosed). A region that fails keeps only its cores.
    Every region needs a seed: a core, or a bright tone (R >= SEED_R, luminance >= SEED_L: the tavern's pale
    (252,226,146) panes have no core), and a region seeded only by such a tone counts only if it fits. So a pane grows
    from its core over its own darker or paler tones; chimney brick, flowers and timber (never lamp-bright) do not.
    mid_bars (a MID_BARS set): a region with a core that fails the dark frame may be framed by mid-brown bars instead
    (luminance under MID_BAR and MID_MARGIN under the region's darkest pixel)."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    op = a[..., 3] > 0
    dark = op & (lum(a) < DARK)
    core = windows(a)
    L = lum(a)
    warm = op & rare_tones(a) & (r > g) & (g > b)
    tone = warm & (((r - b >= PANE_SAT * r) & (g >= PANE_HUE * r) & (L >= PANE_L))
                   | ((r >= LAMP) & (L >= WHITE_L) & (r - b >= WHITE_SAT * r)))
    seed = core | (tone & (r >= SEED_R) & (L >= SEED_L))
    out = np.zeros_like(core)
    for pts in _components(tone | core, conn8=False):
        if not any(seed[p] for p in pts):
            continue                    # no lamp-bright pixel: brick, flowers, timber
        ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
        fits = (max(xs) - min(xs) < PANE_W and max(ys) - min(ys) < PANE_H and len(pts) <= MAX_CLUSTER
                and _enclosed(dark, pts))
        if not fits and mid_bars and any(core[p] for p in pts) and max(xs) - min(xs) < PANE_W                 and max(ys) - min(ys) < PANE_H and len(pts) <= MAX_CLUSTER:
            bar = op & (L < min(MID_BAR, min(L[p] for p in pts) - MID_MARGIN))
            fits = _enclosed(bar, pts)
        for p in pts:
            if fits or core[p]:
                out[p] = True
    return out


def mask_of(s, man):
    fr = frames_of(s, man)
    mid = s in MID_BARS
    keep = np.ones(fr[0].shape[:2], bool)
    flame = np.zeros_like(keep)
    for a in fr:
        keep &= panes(a, mid)
        for f in flames(a):
            x0, y0, x1, y1 = f["box"]
            box = np.zeros_like(keep)
            box[max(0, y0):y1 + 1, max(0, x0):x1 + 1] = True
            flame |= _dilate(box)
    keep &= ~flame
    out = np.zeros_like(keep)
    n = 0
    for pts in _components(keep):
        if len(pts) > MAX_CLUSTER:
            continue
        n += 1
        for p in pts:
            out[p] = True
    return out, n, len(fr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sets", nargs="+")
    ap.add_argument("--dry", action="store_true")
    args = ap.parse_args()
    man = json.loads((B / "manifest.json").read_text())
    for s in args.sets:             # every name is checked before any file is written
        if s not in man or not (B / s / "intact.png").exists():
            sys.exit("%s is not a building set" % s)
        if man[s].get("strip"):
            sys.exit("%s is a strip set: its pieces draw regions wider than one frame, so a mask would stretch" % s)
    for s in args.sets:
        m, n, nf = mask_of(s, man)
        h, w = m.shape
        assert [w, h] == [int(v) for v in man[s]["size"]], s
        print("%-16s %4d px %3d windows (from %s)" % (s, int(m.sum()), n, "idle strip, %d frames" % nf if nf > 1
                                                       else "intact"))
        if args.dry:
            continue
        o = np.zeros((h, w, 4), np.uint8)
        o[m] = (255, 255, 255, 255)
        Image.fromarray(o, "RGBA").save(B / s / "glow_mask.png")


if __name__ == "__main__":
    main()
