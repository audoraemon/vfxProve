"""How dense the town inside the walls is, beside concepts/TOWN REF/Town Visual and Scale Upgrade.png.

- Coverage, by colour, in both pictures (screen space, inside the walls): slate, red-tile and teal roofs, and green
  canopy (trees, gardens). A roof or a crown found by colour, so it is a floor, not an exact count.
- Open ground in ours, exactly, from captures/layout.json: the share of the interior no building, tree, garden, stall,
  yard, pile or prop stands on (a house's footprint grown a little for its yard). The reference's cannot be measured
  that way; judged from the image it is roughly 30-40% (2026-09-27).
- An overlay per picture (captures/density_ref.png, captures/density_ours.png): roofs blue / red / teal, canopy green.

usage: python tools/dev/match_density.py [--dump]
  --dump  write captures/layout.json first (runs Godot: tools/dev/dump_layout.gd)
Needs numpy, scipy and Pillow; reads captures/town_overview.png (town_debug --capture-town --only=town_overview).
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import match_interior as mi  # noqa: E402
import match_layout as ml  # noqa: E402

ROOT = ml.ROOT
## Half the interior's side (ground units), inside the walls.
IN = 15.2


def mask_for(shape, to_px):
    corners = [to_px(-IN, -IN), to_px(IN, -IN), to_px(IN, IN), to_px(-IN, IN)]
    im = Image.new('L', (shape[1], shape[0]), 0)
    ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in corners], fill=1)
    return np.array(im).astype(bool)


def classify(img):
    hsv = np.array(Image.fromarray(img).convert('HSV')).astype(float)
    h, s, v = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
    return {
        'slate roof': (h > 195) & (h < 250) & (s > 0.12) & (v > 0.2) & (v < 0.85),
        'red roof': ((h < 20) | (h > 345)) & (s > 0.45) & (v > 0.3) & (v < 0.85),
        'teal roof': (h > 150) & (h < 195) & (s > 0.25),
        'canopy': (h > 65) & (h < 150) & (s > 0.3) & (v > 0.15),
    }


def coverage(name, img, to_px):
    m = mask_for(img.shape, to_px)
    classes = classify(img)
    out = {k: 100.0 * (c & m).sum() / m.sum() for k, c in classes.items()}
    ov = (img * 0.35).astype(np.uint8)
    for k, col in [('slate roof', (60, 110, 255)), ('red roof', (255, 60, 40)), ('teal roof', (0, 220, 220)),
                   ('canopy', (40, 255, 60))]:
        ov[classes[k] & m] = col
    ov[~m] = (img[~m] * 0.15).astype(np.uint8)
    Image.fromarray(ov).save(ROOT / 'captures' / ('density_%s.png' % name))
    return out


def open_ground(layout):
    xs = np.arange(-IN, IN, 0.1)
    X, Y = np.meshgrid(xs, xs)
    occ = np.zeros(X.shape, bool)
    for s in layout['structures']:
        x, y, w, h = s['rect']
        if s['kind'] in ('CASTLE_WALL', 'KEEP') and s['role'] != 'citadel':
            continue
        g = 0.22 if s['kind'] == 'HOUSE' else 0.1
        occ |= (X >= x - g) & (X <= x + w + g) & (Y >= y - g) & (Y <= y + h + g)
    for x, y, w, h in layout.get('blockers', []):
        occ |= (X >= x) & (X <= x + w) & (Y >= y) & (Y <= y + h)
    for e in layout['decor']:
        x, y = e['at']
        sx, sy = e['size']
        if abs(x) > IN or abs(y) > IN:
            continue
        if e['kind'] in ('GARDEN', 'FENCE', 'BUNTING'):
            occ |= (X >= x) & (X <= x + max(sx, 0.2)) & (Y >= y) & (Y <= y + max(sy, 0.2))
        else:
            occ |= (X - x) ** 2 + (Y - y) ** 2 < 0.25 ** 2
    return 100.0 * (~occ).mean()


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--dump', action='store_true')
    args = parser.parse_args()
    if args.dump:
        subprocess.run([ml.GODOT, '--headless', '--path', str(ROOT), '-s', 'tools/dev/dump_layout.gd'], check=True,
                       stdout=subprocess.DEVNULL)
    point, zoom = mi.overview_shot()
    ref = coverage('ref', np.array(Image.open(ml.REF).convert('RGB')), mi.ref_px)
    ours = coverage('ours', np.array(Image.open(mi.OURS).convert('RGB')), lambda x, y: mi.ours_px(x, y, point, zoom))
    print('%-14s %8s %8s' % ('coverage', 'ref', 'ours'))
    for k in ref:
        print('%-14s %7.1f%% %7.1f%%' % (k, ref[k], ours[k]))
    roofs = ['slate roof', 'red roof', 'teal roof']
    print('%-14s %7.1f%% %7.1f%%' % ('all roofs', sum(ref[k] for k in roofs), sum(ours[k] for k in roofs)))
    layout = json.loads((ROOT / 'captures' / 'layout.json').read_text(encoding='utf-8'))
    print('open ground (ours, from the layout): %.0f%% of the interior (the reference, judged: ~30-40%%)'
          % open_ground(layout))
    return 0


if __name__ == '__main__':
    sys.exit(main())
