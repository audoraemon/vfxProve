"""How closely each town component matches concepts/TOWN REF/Town Visual Upgrade.png.

Renders come from tools/dev/preview_components.gd (captures/components/*.png); each is set beside the same object
boxed in the reference and scored on four things:

Size:     the component's bounding box. The reference's pixels are 1.235x ours horizontally (its corner towers are
          1375 px apart against our 1113.6), so reference sizes are divided by that before comparing. Width is the
          fair measure: the reference's camera is steeper (its ground is 1.61:1 against our 2:1), so its heights
          read a little short and its ground depths a little long.
Material: 5-colour palettes (median cut) of the component in each image, weighted by share; the symmetric average
          of each colour's nearest CIE Lab distance (delta E) in the other palette. The reference crop's background
          (the colours of its border ring) is dropped first, or a thin prop would be measured as grass.
          0 = identical, under ~10 = the same material to the eye, over ~25 = a different material.
Shape:    the silhouette's width/height ratio, and a checklist of the reference's visible features, kept by hand
          in COMPONENTS below: set a flag to 1 when the game gains that feature.
Detail:   edge strength inside the silhouette against the reference's at the same scale (1.0 = as busy);
          reported, not scored.

Scores:   size = min(r, 1/r) of the width ratio, averaged with the height ratio's;
          material = clamp(1 - (dE - 6) / 30); shape = aspect agreement x 0.4 + checklist x 0.6;
          a component's total is the mean of the three.

usage: python tools/dev/match_components.py [--render] [--min PERCENT] [--sheet PATH] [--ref PATH]
  --render   render the components first (runs Godot: $GODOT, or the project's usual Godot path)
  --min      exit 1 when the overall match is below PERCENT (for use as a check)
  --sheet    where to write the side-by-side sheet (default captures/components_compare.png)
  --ref      the reference image (default concepts/TOWN REF/Town Visual Upgrade.png)
Needs numpy, scipy and Pillow.
"""
import argparse
import os
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import binary_erosion, sobel

ROOT = Path(__file__).resolve().parents[2]
COMPONENTS_DIR = ROOT / 'captures' / 'components'
## The project's usual Godot, as in tools/capture.sh; $GODOT overrides it.
DEFAULT_GODOT = 'F:/Godot/Godot_v4.7.2-stable_win64_console.exe'
K = 1.235

# name: ours render, reference box (x0, y0, x1, y1), features [(reference feature, we have it)]; a box with
# y1 = None means the base is hidden in the reference, so only the width is compared.
COMPONENTS = [
    ('Cottage', 'cottage_wide', (680, 617, 760, 700), [
        ('blue slate roof', 1), ('cream plaster walls', 1), ('dark timber frame', 1), ('stone chimney', 1),
        ('lit windows', 1), ('plank door', 1), ('roof overhang', 1), ('front steps on some', 1),
        ('roof about as tall as the walls', 1)]),
    ('Tavern', 'tavern', (425, 300, 605, 450), [
        ('red tile roof', 1), ('two storeys', 1), ('timber frame', 1), ('rows of lit windows', 1),
        ('awning over the door', 1), ('hanging blue sign', 1), ('tables and benches outside', 1),
        ('wall lanterns', 1)]),
    ('Blacksmith', 'blacksmith', (308, 222, 405, 330), [
        ('tall square stone chimney', 1), ('dark wooden shed', 1), ('glowing forge', 1), ('anvil', 1),
        ('tools on the wall', 1), ('barrels and crates around it', 1), ('chimney twice the shed height', 1)]),
    ('Temple', 'temple', (1083, 323, 1302, 510), [
        ('sandstone blocks', 1), ('teal seamed roof', 1), ('tall pointed lit windows', 1), ('arched front door', 1),
        ('steps to the door', 1), ('banners on the front', 1), ('side door', 1), ('small bell block on a corner', 1),
        ('front gable follows the roof line (no square parapet)', 1), ('no rose window', 1)]),
    ('Barracks', 'barracks', (955, 480, 1195, 665), [
        ('long red tile roof', 1), ('open front', 1), ('grey stone pillars', 1), ('forge chimney at the corner', 1),
        ('glowing furnace mouth', 1), ('tables and racks inside', 1), ('crates and barrels in front', 1),
        ('lower lean-to at the far end', 1)]),
    ('Market stall', 'stall_blue', (630, 437, 697, 505), [
        ('striped awning', 1), ('red/white, blue/white, cream colours', 1), ('scalloped front edge', 1),
        ('wooden counter', 1), ('produce on the counter', 1), ('baskets and crates beside it', 1)]),
    ('Fountain', 'fountain', (725, 475, 790, 537), [
        ('stone basin', 1), ('blue water', 1), ('centre pillar and upper bowl', 1), ('two tiers', 1),
        ('square blocky base', 1), ('water glow', 1)]),
    ('Corner tower', 'corner_tower', (715, 805, 820, 960), [
        ('square block', 1), ('stone blocks and mortar', 1), ('merlons', 1), ('blue banners', 1),
        ('lit arrow slits', 1), ('only a little taller than the wall', 1)]),
    ('Curtain wall', 'wall_piece', (850, 805, 910, 895), [
        ('stone blocks', 1), ('chunky merlons', 1), ('pale walkway', 1), ('torches on top', 1),
        ('lit coping edge', 1)]),
    ('Main gate', 'main_gate', (330, 640, 460, 760), [
        ('dark opening', 1), ('portcullis bars', 1), ('opening nearly the wall height', 1),
        ('stone blocks at its feet', 1)]),
    ('Citadel keep', 'citadel_keep', (908, 117, 1055, None), [
        ('stone blocks', 1), ('merlons', 1), ('banner pole on a wooden stand', 1), ('lit windows', 1),
        ('banners on the walls', 1), ('stair up to the door', 1)]),
    ('Citadel tower', 'citadel_tower', (947, 247, 1053, None), [
        ('stone blocks', 1), ('merlons', 1), ('banner', 1), ('lit windows', 1)]),
    ('Bridge', 'bridge', (205, 760, 385, 850), [
        ('plank deck', 1), ('torch posts on the corners', 1), ('rope rails', 1), ('side beams', 1),
        ('stone blocks at the ends', 1)]),
    ('Wheat field', 'field_a', (252, 885, 400, 990), [
        ('golden wheat', 1), ('tall ears in tufts', 1), ('fence', 1), ('ragged top edge', 1)]),
    ('Cabbage field', 'field_b', (80, 900, 300, 1045), [
        ('rows of bushy plants', 1), ('orange/yellow flowers', 1), ('fence', 1), ('soil between the rows', 1)]),
    ('Oak tree', 'oak', (1292, 778, 1350, 847), [
        ('lumpy round crown', 1), ('dark outline', 1), ('lit top', 1), ('visible trunk', 1)]),
    ('Pine tree', 'pine', (50, 90, 100, 165), [
        ('tiered cone', 1), ('dark greens', 1), ('short trunk', 1)]),
    ('Rock', 'rock', (1307, 735, 1340, 762), [
        ('grey stone', 1), ('blocky cube shapes', 1), ('clusters of several', 1), ('moss', 1)]),
    ('Fence run', 'fence', (1258, 888, 1302, 928), [
        ('posts', 1), ('two rails', 1), ('chunky 4-5 px posts', 1)]),
    ('Street lamp', 'lamp', (1327, 948, 1353, 1000), [
        ('wooden post', 1), ('arm', 1), ('hanging lantern', 1), ('glow', 1)]),
    ('Torch post', 'torch', (353, 703, 363, 738), [
        ('post', 1), ('flame', 1), ('iron cup', 1)]),
    ('Signpost', 'signpost', (1213, 780, 1242, 818), [
        ('post', 1), ('board', 1), ('second board / arrow', 1)]),
    ('Scarecrow', 'scarecrow', (67, 987, 107, 1030), [
        ('cross post', 1), ('straw hat', 1), ('shirt', 1), ('straw hands', 1)]),
    ('Barrel', 'barrel', (440, 405, 452, 420), [
        ('wooden staves', 1), ('iron hoops', 1), ('lid', 1)]),
    ('Bush', 'bush', (1210, 870, 1233, 890), [
        ('round clumps', 1), ('dark outline', 1)]),
    ('Garden plot', 'garden', (560, 655, 650, 710), [
        ('fence round it', 1), ('green plants', 1), ('flowers', 1), ('soil', 1)]),
    ('Reeds', 'reeds', (273, 717, 290, 750), [
        ('tall blades', 1), ('cattail heads', 1)]),
]


def crop_ours(name):
    a = np.array(Image.open(COMPONENTS_DIR / ('%s.png' % name)).convert('RGB')).astype(int)
    bg = (a[..., 1] < 60) & (a[..., 0] > 120) & (a[..., 2] > 120) & (np.abs(a[..., 0] - a[..., 2]) < 30)
    ys, xs = np.where(~bg)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    return Image.fromarray(a.astype(np.uint8)).crop(box), (~bg)[box[1]:box[3], box[0]:box[2]]


def to_lab(rgb):
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def palette(pixels, n=5):
    img = Image.fromarray(pixels.reshape(1, -1, 3).astype(np.uint8))
    q = img.quantize(n, method=Image.Quantize.MEDIANCUT)
    raw = q.getpalette()
    n = min(n, len(raw) // 3)
    pal = np.array(raw[:n * 3]).reshape(n, 3)
    counts = np.bincount(np.array(q).ravel(), minlength=n)[:n]
    keep = counts > 0
    return pal[keep], counts[keep] / counts.sum()


def palette_de(pa, wa, pb, wb):
    la, lb = to_lab(pa.astype(float)), to_lab(pb.astype(float))
    d = np.linalg.norm(la[:, None] - lb[None], axis=-1)
    return float((d.min(1) * wa).sum() * 0.5 + (d.min(0) * wb).sum() * 0.5)


def detail(img, mask=None):
    g = np.array(img.convert('L')).astype(float)
    e = np.hypot(sobel(g, 0), sobel(g, 1))
    if mask is not None:
        m = binary_erosion(mask, iterations=2)
        return float(e[m].mean()) if m.any() else float(e.mean())
    return float(e[2:-2, 2:-2].mean())


def foreground(arr):
    """The reference crop without its background: colours of the crop's border ring (the ground around the thing)
    are taken as background, and pixels within delta E 10 of them dropped. Thin props (a lamp, reeds) would
    otherwise be measured as mostly grass."""
    h, w, _ = arr.shape
    ring = np.concatenate([arr[:2].reshape(-1, 3), arr[-2:].reshape(-1, 3), arr[:, :2].reshape(-1, 3),
        arr[:, -2:].reshape(-1, 3)])
    bp, _ = palette(ring, 4)
    lab = to_lab(arr.reshape(-1, 3).astype(float))
    d = np.linalg.norm(lab[:, None] - to_lab(bp.astype(float))[None], axis=-1).min(1)
    keep = arr.reshape(-1, 3)[d > 10.0]
    return keep if len(keep) > 30 else arr.reshape(-1, 3)


def render():
    godot = os.environ.get('GODOT', DEFAULT_GODOT)
    print('rendering components with %s' % godot)
    run = subprocess.run([godot, '--path', str(ROOT), '--audio-driver', 'Dummy', '-s', 'tools/dev/preview_components.gd'],
        capture_output=True, text=True)
    if run.returncode != 0:
        print(run.stdout + run.stderr)
        raise SystemExit('rendering failed')
    # Godot rewrites the bus layout on some runs; it is not ours to change.
    subprocess.run(['git', '-C', str(ROOT), 'checkout', '--', 'default_bus_layout.tres'], stderr=subprocess.DEVNULL)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--render', action='store_true')
    parser.add_argument('--min', type=float)
    parser.add_argument('--sheet', default=str(ROOT / 'captures' / 'components_compare.png'))
    parser.add_argument('--ref', default=str(ROOT / 'concepts' / 'TOWN REF' / 'Town Visual Upgrade.png'))
    args = parser.parse_args()
    if not Path(args.ref).exists():
        print('reference image not found: %s' % args.ref)
        return 2
    ref = Image.open(args.ref).convert('RGB')
    if args.render:
        render()
    missing = [c[1] for c in COMPONENTS if not (COMPONENTS_DIR / ('%s.png' % c[1])).exists()]
    if missing:
        print('no render for %s: run with --render (or tools/dev/preview_components.gd) first' % ', '.join(missing))
        return 2
    rows = []
    tiles = []
    details = []
    for label, name, box, feats in COMPONENTS:
        ours, mask = crop_ours(name)
        ow, oh = ours.size
        x0, y0, x1, y1 = box
        rbox = (x0, y0, x1, y1 if y1 is not None else y0 + int((x1 - x0) * 1.2))
        rimg = ref.crop(rbox)
        rw, rh = (x1 - x0) / K, ((y1 - y0) / K if y1 is not None else None)
        wr = ow / rw
        hr = oh / rh if rh else None
        size_s = min(wr, 1 / wr) if hr is None else (min(wr, 1 / wr) + min(hr, 1 / hr)) / 2
        pa, wa = palette(np.array(ours)[mask])
        pb, wb = palette(foreground(np.array(rimg)))
        de = palette_de(pa, wa, pb, wb)
        mat_s = float(np.clip(1 - (de - 6) / 30, 0, 1))
        if rh:
            ar_o, ar_r = ow / oh, rw / rh
            aspect = min(ar_o / ar_r, ar_r / ar_o)
        else:
            aspect = 1.0
        check = sum(f[1] for f in feats) / len(feats)
        shape_s = aspect * 0.4 + check * 0.6
        # Surface detail: edge strength inside the silhouette, the reference scaled down to our pixel scale first.
        r_small = rimg.resize((max(4, round(rimg.width / K)), max(4, round(rimg.height / K))), Image.LANCZOS)
        dr = detail(ours, mask) / max(detail(r_small), 1e-6)
        details.append((label, dr))
        total = (size_s + mat_s + shape_s) / 3
        rows.append((label, ow, oh, rw, rh, wr, hr, de, aspect, check, feats, size_s, mat_s, shape_s, total))
        tiles.append((label, rimg, ours, pa, wa, pb, wb, total))

    print('%-14s %11s %13s %7s %7s %6s %7s %6s | %5s %5s %5s %6s' % (
        'component', 'ours px', 'ref px (/K)', 'width', 'height', 'dE', 'aspect', 'feat', 'size', 'mat', 'shape', 'TOTAL'))
    for r in rows:
        label, ow, oh, rw, rh, wr, hr, de, aspect, check, feats, ss, ms, sh, tot = r
        print('%-14s %4dx%-6d %5.0fx%-7s %6.2fx %7s %6.1f %7.2f %5.0f%% | %4.0f%% %4.0f%% %4.0f%% %5.0f%%' % (
            label, ow, oh, rw, ('%.0f' % rh) if rh else '-', wr, ('%.2fx' % hr) if hr else '-', de, aspect,
            check * 100, ss * 100, ms * 100, sh * 100, tot * 100))
    groups = {
        'Buildings': ['Cottage', 'Tavern', 'Blacksmith', 'Temple', 'Barracks', 'Market stall', 'Fountain'],
        'Fortifications': ['Corner tower', 'Curtain wall', 'Main gate', 'Citadel keep', 'Citadel tower'],
        'Land & nature': ['Bridge', 'Wheat field', 'Cabbage field', 'Oak tree', 'Pine tree', 'Rock', 'Reeds'],
        'Props': ['Fence run', 'Street lamp', 'Torch post', 'Signpost', 'Scarecrow', 'Barrel', 'Bush', 'Garden plot'],
    }
    print()
    for g, names in groups.items():
        sel = [r for r in rows if r[0] in names]
        print('%-16s size %3.0f%%  material %3.0f%%  shape %3.0f%%  overall %3.0f%%   width ratio median %.2fx' % (
            g, 100 * np.mean([r[11] for r in sel]), 100 * np.mean([r[12] for r in sel]), 100 * np.mean([r[13] for r in sel]),
            100 * np.mean([r[14] for r in sel]), np.median([r[5] for r in sel])))
    print('%-16s size %3.0f%%  material %3.0f%%  shape %3.0f%%  overall %3.0f%%' % (
        'ALL', 100 * np.mean([r[11] for r in rows]), 100 * np.mean([r[12] for r in rows]), 100 * np.mean([r[13] for r in rows]),
        100 * np.mean([r[14] for r in rows])))
    print()
    print('Surface detail (our edge strength over the reference, same scale; 1.0 = as busy):')
    for label, dr in details:
        print('  %-14s %.2f' % (label, dr))
    print('  median %.2f' % np.median([d for _, d in details]))
    print()
    print('Missing features:')
    missing_any = False
    for r in rows:
        miss = [f[0] for f in r[10] if not f[1]]
        if miss:
            missing_any = True
            print('  %-14s %s' % (r[0], '; '.join(miss)))
    if not missing_any:
        print('  none')

    # Sheet: reference crop (scaled to our pixel scale) beside ours, both at 3x, with palettes and the score.
    cells = []
    for label, rimg, ours, pa, wa, pb, wb, tot in tiles:
        r2 = rimg.resize((max(1, round(rimg.width / K)), max(1, round(rimg.height / K))), Image.LANCZOS)
        sc = 3 if max(r2.width, ours.width) < 110 else 2
        if max(r2.width, ours.width) > 200:
            sc = 1
        a = r2.resize((r2.width * sc, r2.height * sc), Image.NEAREST)
        b = ours.resize((ours.width * sc, ours.height * sc), Image.NEAREST)
        w = a.width + b.width + 30
        h = max(a.height, b.height) + 48
        c = Image.new('RGB', (max(w, 260), h), (32, 32, 36))
        d = ImageDraw.Draw(c)
        d.text((4, 2), '%s  %.0f%%' % (label, tot * 100), fill=(255, 230, 120))
        d.text((4, 14), 'REF', fill=(200, 200, 200))
        d.text((a.width + 14, 14), 'OURS', fill=(200, 200, 200))
        c.paste(a, (4, 26))
        c.paste(b, (a.width + 14, 26))
        x = 4
        for pal, wt in [(pb, wb), (pa, wa)]:
            for col, share in zip(pal, wt):
                ww = max(3, int(share * 110))
                d.rectangle((x, h - 16, x + ww, h - 6), fill=tuple(int(v) for v in col))
                x += ww
            x += 16
        cells.append(c)
    W = 1900
    sheet = Image.new('RGB', (W, 6000), (20, 20, 22))
    x = y = rowh = 0
    for c in cells:
        if x + c.width > W:
            x = 0
            y += rowh + 8
            rowh = 0
        sheet.paste(c, (x, y))
        x += c.width + 8
        rowh = max(rowh, c.height)
    sheet = sheet.crop((0, 0, W, y + rowh))
    Path(args.sheet).parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.sheet)
    print('sheet: %s' % args.sheet)
    overall = 100 * np.mean([r[14] for r in rows])
    if args.min is not None and overall < args.min:
        print('FAIL: overall %.0f%% is below %.0f%%' % (overall, args.min))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
