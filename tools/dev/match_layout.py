"""How closely the town's layout matches concepts/TOWN REF/Town Visual and Scale Upgrade.png.

The reference is anchored to ground units by a homography through its four corner towers. Our towers stand at
(+-16.2, +-16.2); the reference's tops are N (655, 38), E (1428, 482), S (975, 905), W (42, 338), moved down 58 px to
their feet. Through it:
- Landmarks: each landmark's ground position in the reference (read from points at ground level: a building's
  foot, a fountain's base, a gate's opening) against ours, in ground units. Within 1.5 counts as in place.
  The reference's walls bulge where ours are straight, so its gates and the bridge sit ~2 units further out than
  a straight wall would put them; those three are measured against the wall-corrected point.
- Houses: roofs found by colour in the reference (slate, red tile), mapped to ground and counted per district,
  against our houses per district.
- Overlay: our footprints drawn over the reference (captures/layout_overlay.png).

usage: python tools/dev/match_layout.py [--dump] [--min-landmarks N]
  --dump           write captures/layout.json first (runs Godot: tools/dev/dump_layout.gd)
  --min-landmarks  exit 1 when fewer than N landmarks are in place
Needs numpy, scipy and Pillow.
"""
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
REF = ROOT / 'concepts' / 'TOWN REF' / 'Town Visual and Scale Upgrade.png'
LAYOUT = ROOT / 'captures' / 'layout.json'
GODOT = os.environ.get('GODOT', 'F:/Godot/Godot_v4.7.2-stable_win64_console.exe')
T = 16.2
GROUND = [(-T, -T), (T, -T), (T, T), (-T, T)]
PIXELS = [(655, 38), (1428, 482), (975, 905), (42, 338)]
LIFT = 58.0
IN_PLACE = 1.5

# name: (the reference's ground point, how to find ours in layout.json: (role, tag, kind) filters or 'citadel').
# Points are read from the reference at ground level; gate and bridge points are pulled back by the reference's
# wall bulge (about 2 units) onto a straight wall.
LANDMARKS = {
    'Cathedral (Temple)': ((0.75, -8.1), {'role': 'temple'}),
    'Market fountain': ((0.8, 5.7), {'kind': 'FOUNTAIN', 'index': 0}),
    'North-east fountain': ((10.0, -9.8), {'kind': 'FOUNTAIN', 'index': 1}),
    'Tavern, north': ((-8.9, -6.7), {'tag': 'tavern', 'index': 0}),
    'Tavern, west of market': ((-4.9, 0.5), {'tag': 'tavern', 'index': 1}),
    'Tavern, east of market': ((6.9, 3.6), {'tag': 'tavern', 'index': 2}),
    'Barracks hall': ((11.4, 5.3), {'role': 'barracks'}),
    'Workshop hall': ((12.1, 0.1), {'tag': 'smithy', 'index': 1}),
    'Forge': ((14.3, -0.6), {'tag': 'smithy', 'index': 0}),
    'Main Gate': ((2.8, 15.8), {'kind': 'GATE', 'index': 0}),
    'Side Gate': ((16.1, 9.0), {'kind': 'GATE', 'index': 1}),
    'Bridge': ((2.4, 21.6), {'role': 'bridge'}),
    'Windmill': ((-11.5, -24.5), {'tag': 'windmill'}),
    'Watermill': ((-5.0, 25.4), {'tag': 'watermill'}),
    'Dock': ((-0.4, 24.0), {'tag': 'dock'}),
}


def homography(src, dst):
    a = []
    for (x, y), (u, v) in zip(src, dst):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y, -u])
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y, -v])
    _, _, vt = np.linalg.svd(np.array(a, float))
    h = vt[-1].reshape(3, 3)
    return h / h[2, 2]


H = homography(GROUND, [(x, y + LIFT) for x, y in PIXELS])
HI = np.linalg.inv(H)


def to_px(g):
    v = H @ np.array([g[0], g[1], 1.0])
    return (v[0] / v[2], v[1] / v[2])


def to_ground(p):
    v = HI @ np.array([p[0], p[1], 1.0])
    return (v[0] / v[2], v[1] / v[2])


def find(structures, spec):
    sel = [s for s in structures
           if all(s.get(k) == v for k, v in spec.items() if k != 'index')]
    i = spec.get('index', 0)
    if len(sel) <= i:
        return None
    x, y, w, h = sel[i]['rect']
    return (x + w / 2, y + h / 2)


def ref_roofs(ref):
    """Ground points of the reference's slate and red-tile roofs (a roof stands ~16 px + a third of its height
    above its footprint)."""
    hsv = np.array(ref.convert('HSV')).astype(float)
    hh, ss, vv = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
    masks = [(hh > 205) & (hh < 235) & (ss > 0.28) & (vv > 0.25) & (vv < 0.75),
             ((hh < 22) | (hh > 350)) & (ss > 0.45) & (vv > 0.35) & (vv < 0.85)]
    out = []
    for mask in masks:
        m = ndimage.binary_closing(ndimage.binary_opening(mask, iterations=1), iterations=2)
        lab, _ = ndimage.label(m)
        for i, sl in enumerate(ndimage.find_objects(lab)):
            comp = lab[sl] == i + 1
            if comp.sum() < 120:
                continue
            ys, xs = np.nonzero(comp)
            h = ys.max() - ys.min() + 1
            w = xs.max() - xs.min() + 1
            if w > 160 or h > 120:
                continue
            g = to_ground((xs.mean() + sl[1].start, ys.mean() + sl[0].start + 16 + h * 0.35))
            out.append(g)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--dump', action='store_true')
    parser.add_argument('--min-landmarks', type=int)
    args = parser.parse_args()
    if not REF.exists():
        print('reference image not found: %s' % REF)
        return 2
    if args.dump:
        subprocess.run([GODOT, '--headless', '--path', str(ROOT), '-s', 'tools/dev/dump_layout.gd'],
            capture_output=True, text=True, check=True)
    if not LAYOUT.exists():
        print('no captures/layout.json: run with --dump first')
        return 2
    data = json.loads(LAYOUT.read_text(encoding='utf-8'))
    structures = data['structures']
    ref = Image.open(REF).convert('RGB')

    print('%-26s %16s %16s %7s' % ('landmark', 'reference', 'ours', 'off'))
    in_place = 0
    for name, (at, spec) in LANDMARKS.items():
        ours = find(structures, spec)
        if ours is None:
            print('%-26s %16s %16s %7s' % (name, '(%.1f, %.1f)' % at, 'missing', '-'))
            continue
        off = float(np.hypot(ours[0] - at[0], ours[1] - at[1]))
        in_place += off <= IN_PLACE
        print('%-26s %16s %16s %6.1f%s' % (name, '(%.1f, %.1f)' % at, '(%.1f, %.1f)' % ours, off,
            '' if off <= IN_PLACE else '  <-'))
    print('in place: %d of %d landmarks (within %.1f units)' % (in_place, len(LANDMARKS), IN_PLACE))

    # Houses per district: the reference's roofs against our houses.
    town = data['town']
    ours_h = [s for s in structures if s['role'] == 'house']
    roofs = [g for g in ref_roofs(ref) if town[0] < g[0] < town[0] + town[2] and town[1] < g[1] < town[1] + town[3]]
    quads = {'north-west': (-16, -16, 16, 16), 'north-east': (0, -16, 16, 16), 'south-west': (-16, 0, 16, 16),
             'south-east': (0, 0, 16, 16)}
    print()
    print('%-12s %10s %6s' % ('quarter', 'reference', 'ours'))
    tot_r = tot_o = 0
    for q, (x, y, w, h) in quads.items():
        r = sum(1 for g in roofs if x <= g[0] < x + w and y <= g[1] < y + h)
        o = sum(1 for s in ours_h if x <= s['rect'][0] + s['rect'][2] / 2 < x + w and y <= s['rect'][1] + s['rect'][3] / 2 < y + h)
        tot_r += r
        tot_o += o
        print('%-12s %10d %6d' % (q, r, o))
    print('%-12s %10d %6d   (reference roofs are found by colour: a floor, not an exact count)' % ('town', tot_r, tot_o))

    over = ref.copy()
    d = ImageDraw.Draw(over)
    colours = {'house': (255, 255, 0), 'temple': (0, 255, 255), 'barracks': (255, 0, 0), 'market': (0, 255, 0),
               'citadel': (255, 255, 255), 'wall': (255, 0, 255), 'tower': (255, 0, 255), 'gate': (255, 128, 0),
               'bridge': (255, 128, 0), 'farm': (255, 200, 0)}
    for s in structures:
        col = colours.get(s['role'])
        if col is None:
            continue
        x, y, w, h = s['rect']
        d.line([to_px(p) for p in [(x, y), (x + w, y), (x + w, y + h), (x, y + h), (x, y)]], fill=col, width=2)
    for g in roofs:
        p = to_px(g)
        d.ellipse((p[0] - 3, p[1] - 3, p[0] + 3, p[1] + 3), outline=(0, 0, 0), width=2)
    out = ROOT / 'captures' / 'layout_overlay.png'
    over.save(out)
    print()
    print('overlay: %s (ours: footprints in colour; the reference\'s detected roofs: black rings)' % out)
    if args.min_landmarks is not None and in_place < args.min_landmarks:
        print('FAIL: %d landmarks in place, fewer than %d' % (in_place, args.min_landmarks))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
