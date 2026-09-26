"""How closely the town's interior (inside the walls) looks like concepts/TOWN REF/Town Visual and Scale Upgrade.png
as a whole: how warm, how grey, how green and how busy it is, not where things stand (match_layout.py) or how each
part is drawn (match_components.py).

Both pictures are laid flat onto the ground inside the walls: the reference through match_layout.py's homography
(its corner towers), ours from captures/town_overview.png through the overview shot's camera (town_debug.gd's
TOWN_SHOTS). Every ground point then has a colour from each, and the two are compared as wholes:
- warm:   share of warm, saturated colour (lit plaster, dirt, tile, lamplight): hue under 50 degrees, saturation
          over 0.35, value over 0.45;
- grey:   share of grey (saturation under 0.22): bare stone paving and walls;
- green:  share of foliage and grass (hue 60-160 degrees, saturation over 0.3);
- sat:    mean saturation;
- R-B:    mean red minus blue, the picture's overall warmth;
- detail: mean luminance spread in 0.64-unit cells, how busy the ground is;
- flat:   share of those cells that are nearly flat (lawn, bare paving).
Each scores 1 - |ours - ref| / max(ours, ref); the interior score is the mean of the scored ones. grey and flat are
shown but not scored: the reference's walls bulge into the sampled ground, so most of its grey is wall and awning
stripe, and both are shares of a few percent, where a sliver of difference reads as a large miss.

usage: python tools/dev/match_interior.py [--capture] [--out PATH]
  --capture  re-capture the overview first (runs Godot: town_debug --capture-town --only=town_overview)
  --out      side-by-side of the two flattened interiors (default captures/interior_compare.png)
Needs numpy and Pillow.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import match_layout as ml  # noqa: E402

ROOT = ml.ROOT
OURS = ROOT / 'captures' / 'town_overview.png'
GODOT = os.environ.get('GODOT', 'F:/Godot/Godot_v4.7.2-stable_win64_console.exe')
## The overview is captured from a 640 x 360 viewport, saved at twice that; the camera sits 30 px above its point.
VIEW = (640, 360)
SAVE_SCALE = 2
CAM_LIFT = -30
## Ground sampled inside the walls, and how finely.
T = 15.8
STEP = 0.08


def overview_shot():
    src = (ROOT / 'src' / 'game' / 'town_debug.gd').read_text(encoding='utf-8')
    m = re.search(r'\["town_overview\.png", Vector2\(([-\d.]+), ([-\d.]+)\), ([\d.]+)\]', src)
    return (float(m.group(1)), float(m.group(2))), float(m.group(3))


def iso(x, y):
    return (x - y) * 32.0, (x + y) * 16.0


def ours_px(x, y, point, zoom):
    cx, cy = iso(*point)
    cy = round(cy + CAM_LIFT)
    cx = round(cx)
    sx, sy = iso(x, y)
    return ((sx - cx) * zoom + VIEW[0] / 2) * SAVE_SCALE, ((sy - cy) * zoom + VIEW[1] / 2) * SAVE_SCALE


def ref_px(x, y):
    h = ml.H
    w = h[2, 0] * x + h[2, 1] * y + h[2, 2]
    return (h[0, 0] * x + h[0, 1] * y + h[0, 2]) / w, (h[1, 0] * x + h[1, 1] * y + h[1, 2]) / w


def sample(img, fx, fy):
    xi = np.clip(np.round(fx).astype(int), 0, img.shape[1] - 1)
    yi = np.clip(np.round(fy).astype(int), 0, img.shape[0] - 1)
    return img[yi, xi]


def flatten(img, to_px):
    n = int(2 * T / STEP)
    gx, gy = np.meshgrid(np.linspace(-T, T, n), np.linspace(-T, T, n))
    return sample(img, *to_px(gx, gy))


def metrics(a):
    a = a.astype(float) / 255.0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1)
    mn = a.min(-1)
    d = np.maximum(mx - mn, 1e-6)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    n = lum.shape[0] // 8
    cells = lum[:n * 8, :n * 8].reshape(n, 8, n, 8).std(axis=(1, 3))
    return {
        'warm': float(((hue < 0.14) & (sat > 0.35) & (mx > 0.45)).mean()),
        'grey': float((sat < 0.22).mean()),
        'green': float(((hue > 0.17) & (hue < 0.45) & (sat > 0.3)).mean()),
        'sat': float(sat.mean()),
        'R-B': float((r - b).mean()),
        'detail': float(cells.mean()),
        'flat': float((cells < 0.035).mean()),
    }


SCORED = ['warm', 'green', 'sat', 'R-B', 'detail']


def score(o, r):
    return {k: 1.0 - abs(o[k] - r[k]) / max(abs(o[k]), abs(r[k]), 1e-6) for k in r}


def capture():
    env = dict(os.environ, SCENE='res://scenes/town_debug.tscn', GODOT=GODOT)
    subprocess.run(['bash', 'tools/capture.sh', '--capture-town', '--only=town_overview'], cwd=ROOT, env=env,
                   check=True, stdout=subprocess.DEVNULL)
    subprocess.run(['git', 'checkout', '--', 'default_bus_layout.tres'], cwd=ROOT, stderr=subprocess.DEVNULL)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--out', default=str(ROOT / 'captures' / 'interior_compare.png'))
    args = parser.parse_args()
    if args.capture:
        capture()
    point, zoom = overview_shot()
    ref = flatten(np.array(Image.open(ml.REF).convert('RGB')), ref_px)
    ours = flatten(np.array(Image.open(OURS).convert('RGB')), lambda x, y: ours_px(x, y, point, zoom))
    rm, om = metrics(ref), metrics(ours)
    sc = score(om, rm)
    print('%-8s %7s %7s %7s' % ('metric', 'ref', 'ours', 'score'))
    for k in rm:
        print('%-8s %7.3f %7.3f %6.0f%%%s' % (k, rm[k], om[k], 100 * sc[k], '' if k in SCORED else '  (not scored)'))
    total = sum(sc[k] for k in SCORED) / len(SCORED)
    print('interior %.0f%%' % (100 * total))
    gap = np.zeros((ref.shape[0], 10, 3), np.uint8)
    Image.fromarray(np.concatenate([ref, gap, ours], axis=1)).save(args.out)
    print('side by side: %s (reference left, ours right; north at the top-left corner)' % args.out)
    return 0


if __name__ == '__main__':
    sys.exit(main())
