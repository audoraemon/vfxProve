"""Window glow masks: a set's lit windows, as white pixels in <set>/glow_mask.png (one frame in size, transparent
elsewhere). The sprite shader (structure_sprite.gdshader, window_flicker) flickers those pixels on the intact still and
its idle strip.

A window pixel is warm, bright lamp light with the window's dark bars and frame (luminance < DARK) in its 5x5
neighbourhood. Warm and bright is the plan's rule (R >= 180, R > G > B, luminance >= 150) with three guards found on
these sets: saturated ((R - B) / R >= SAT: no cream plaster), lamp-bright (R >= LAMP: no sandstone, sunlit wood or
hay) and yellow-orange (G >= HUE * R: no red-orange roof-eave highlight). Then:
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


def mask_of(s, man):
    fr = frames_of(s, man)
    keep = np.ones(fr[0].shape[:2], bool)
    flame = np.zeros_like(keep)
    for a in fr:
        keep &= windows(a)
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
    for s in args.sets:
        if man[s].get("strip"):
            sys.exit("%s is a strip set: its pieces draw regions wider than one frame, so a mask would stretch" % s)
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
