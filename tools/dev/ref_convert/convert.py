"""Convert a component from the reference art sheets (concepts/TOWN REF/TownMap_Component*.png) into a game sprite.
No AI calls: crop, keep the main shape, scale so the body width matches the plot's diamond, fit (premultiplied Lanczos,
unsharp, hard alpha, median-cut palette, 1 px dark outline), optionally mirror and harmonize the stone, place on a padded
canvas and set the anchor at the lowest body pixel.

  python tools/dev/ref_convert/convert.py <set> --sheet <png> --box x0,y0,x1,y1 --footprint W,D
         [--mirror] [--colors 40] [--harmonize] [--keep-green] [--canvas-pad 6] [--width-rows 0.62,0.78]
         [--measure body|bbox] [--kind K --role R --tag T --height H --seed N]
  python tools/dev/ref_convert/convert.py selftest

Writes assets/pixellab/buildings/<set>/intact.png and adds/updates the set's manifest entry (existing keys kept).
`selftest` converts the bell tower into a scratch folder (no committed asset is touched) and compares its silhouette
bbox to the committed bell_tower intact (within 2 px). Run from anywhere; paths resolve from the repo root.
"""
import argparse
import json
import subprocess
import sys
import tempfile
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
HARMONIZE_TARGET = (ROOT / "concepts" / "TOWN REF" / "TownMap_Component4.png", "40,40,300,245")
OUTLINE = np.array([34, 26, 24])
MIN_PIECE, MAX_PIECE = 20, 40   # a small separate piece (20..39 px, as sprite_fix largest keeps <40) wholly below the main shape's middle is kept; bigger ones are neighbours


def green_mask(rgb):
    rgb = rgb.astype(int)
    return (rgb[..., 1] > rgb[..., 0] + 15) & (rgb[..., 1] > rgb[..., 2] + 15)


def keep_shapes(a):
    """Largest 8-connected solid shape, plus small pieces (>= MIN_PIECE px) lying wholly below its middle."""
    h, w = a.shape[:2]
    solid = a[..., 3] > 128
    lab = -np.ones((h, w), int)
    shapes = []
    for y0 in range(h):
        for x0 in range(w):
            if solid[y0, x0] and lab[y0, x0] < 0:
                q = deque([(y0, x0)]); lab[y0, x0] = len(shapes); pts = []
                while q:
                    y, x = q.popleft(); pts.append((y, x))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            yy, xx = y + dy, x + dx
                            if 0 <= yy < h and 0 <= xx < w and solid[yy, xx] and lab[yy, xx] < 0:
                                lab[yy, xx] = len(shapes); q.append((yy, xx))
                shapes.append(pts)
    if not shapes:
        sys.exit("convert: nothing opaque in the box")
    main = max(range(len(shapes)), key=lambda i: len(shapes[i]))
    ys = [p[0] for p in shapes[main]]
    mid = (min(ys) + max(ys)) / 2
    keep = np.zeros((h, w), bool)
    for i, pts in enumerate(shapes):
        if i == main or (MIN_PIECE <= len(pts) < MAX_PIECE and min(p[0] for p in pts) >= mid):
            for y, x in pts:
                keep[y, x] = True
    a = a.copy()
    a[~keep, 3] = 0
    return a


def convert(sheet, box, footprint, mirror=False, colors=40, keep_green=False, canvas_pad=6, width_rows=(0.62, 0.78),
            measure="body", harmonize=False):
    """Returns (canvas RGBA array, anchor (x, y), info dict). Harmonize is applied by the caller on the saved file."""
    src = Image.open(sheet).convert("RGBA").crop(box)
    a = keep_shapes(np.array(src))
    h, w = a.shape[:2]
    W, D = footprint

    # body width -> scale
    body = a[..., 3] > 0
    if not keep_green:
        body &= ~green_mask(a[..., :3])
    ys = np.nonzero(body.any(axis=1))[0]
    top, bot = ys.min(), ys.max()
    if measure == "bbox":
        xs = np.nonzero(body.any(axis=0))[0]
        body_w = float(xs.max() - xs.min() + 1)
    else:
        lo, hi = width_rows
        rows = range(int(top + (bot - top) * lo), int(top + (bot - top) * hi))
        widths = [np.ptp(np.nonzero(body[y])[0]) + 1 for y in rows if body[y].any()]
        if not widths:
            sys.exit("convert: no body rows in --width-rows")
        body_w = float(np.median(widths))
    target = 32 * (W + D)
    scale = target / body_w

    # fit: premultiplied Lanczos, unsharp, hard alpha, median-cut palette, 1 px outline
    nw, nh = round(w * scale), round(h * scale)
    small = Image.fromarray(a, "RGBA").convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    alpha = np.array(small.getchannel("A")) >= 110
    rgbimg = small.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
    q = rgbimg.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = np.zeros((nh, nw, 4), np.uint8)
    out[..., :3] = np.array(q)
    out[..., 3] = np.where(alpha, 255, 0)
    edge = np.zeros_like(alpha)
    pad = np.pad(alpha, 1)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        edge |= alpha & ~pad[1 + dy:1 + dy + nh, 1 + dx:1 + dx + nw]
    dark = out[..., :3].astype(int).sum(axis=2) < 200
    m = edge & ~dark
    out[m, :3] = (out[m, :3] * 0.45 + OUTLINE * 0.55).astype(np.uint8)
    if mirror:
        out = out[:, ::-1].copy()

    # place on a padded canvas; anchor = lowest body pixel row, middle x of that row
    cw, ch = nw + 2 * canvas_pad, nh + 2 * canvas_pad
    c = np.zeros((ch, cw, 4), np.uint8)
    c[canvas_pad:canvas_pad + nh, canvas_pad:canvas_pad + nw] = out
    gb = c[..., 3] > 0
    if not keep_green:
        gb &= ~green_mask(c[..., :3])
    yb = int(np.nonzero(gb.any(axis=1))[0].max())
    xs = np.nonzero(gb[yb])[0]
    anchor = (int(round((xs.min() + xs.max()) / 2)), yb)
    info = {"body_w": body_w, "scale": scale}
    return c, anchor, info


def corner_errors(c, anchor, footprint):
    """Distance (dx, dy) from each diamond base corner to the nearest opaque base pixel (per column's lowest pixel)."""
    W, D = footprint
    al = c[..., 3] > 0
    h, w = al.shape
    base = [(x, int(np.nonzero(al[:, x])[0].max())) for x in range(w) if al[:, x].any()]
    res = []
    for name, (cx, cy) in (("left", (anchor[0] - 32 * D, anchor[1] - 16 * D)),
                           ("right", (anchor[0] + 32 * W, anchor[1] - 16 * W))):
        bx, by = min(base, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cy) ** 2)
        res.append((name, (round(cx, 1), round(cy, 1)), (bx - cx, by - cy)))
    return res


def write_manifest(man_path, name, entry):
    man = json.load(open(man_path, encoding="utf-8"))
    cur = man.get(name, {})
    cur.update({k: v for k, v in entry.items() if v is not None})
    man[name] = cur
    text = "{\n" + ",\n".join("\t" + json.dumps(k) + ": " + json.dumps(v) for k, v in man.items()) + "\n}\n"
    open(man_path, "w", encoding="utf-8", newline="
").write(text)


def run(a, out_dir, manifest=True):
    box = tuple(int(v) for v in a.box.split(","))
    fp = tuple(float(v) for v in a.footprint.split(","))
    wr = tuple(float(v) for v in a.width_rows.split(","))
    c, anchor, info = convert(a.sheet, box, fp, a.mirror, a.colors, a.keep_green, a.canvas_pad, wr, a.measure)
    out_dir.mkdir(parents=True, exist_ok=True)
    png = out_dir / "intact.png"
    Image.fromarray(c, "RGBA").save(png)
    if a.harmonize:
        subprocess.run([sys.executable, str(ROOT / "tools" / "dev" / "sprite_fix.py"), "harmonize",
                        str(HARMONIZE_TARGET[0]), HARMONIZE_TARGET[1], str(png)], cwd=ROOT, check=True)
        c = np.array(Image.open(png).convert("RGBA"))
    h, w = c.shape[:2]
    print("body width %.1f scale %.3f" % (info["body_w"], info["scale"]))
    print("size", [w, h], "anchor", list(anchor))
    for name, corner, err in corner_errors(c, anchor, fp):
        print("%s corner at %s: nearest base pixel off by dx=%+.1f dy=%+.1f" % (name, corner, err[0], err[1]))
    if manifest:
        def num(v):
            return int(v) if float(v) == int(float(v)) else float(v)
        write_manifest(B / "manifest.json", a.set, {
            "size": [w, h], "footprint": [num(v) for v in fp], "anchor": list(anchor), "height": a.height,
            "seed": a.seed, "kind": a.kind, "role": a.role, "tag": a.tag})
        print("manifest updated:", a.set)
    return c


def parser():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("set", help="set name (assets/pixellab/buildings/<set>) or 'selftest'")
    p.add_argument("--sheet"); p.add_argument("--box"); p.add_argument("--footprint")
    p.add_argument("--mirror", action="store_true")
    p.add_argument("--colors", type=int, default=40)
    p.add_argument("--harmonize", action="store_true")
    p.add_argument("--keep-green", action="store_true", help="count green (moss, bushes) as body")
    p.add_argument("--canvas-pad", type=int, default=6)
    p.add_argument("--width-rows", default="0.62,0.78")
    p.add_argument("--measure", choices=("body", "bbox"), default="body")
    p.add_argument("--kind"); p.add_argument("--role"); p.add_argument("--tag")
    p.add_argument("--height", type=int); p.add_argument("--seed", type=int)
    return p


def selftest():
    args = parser().parse_args(["bell", "--sheet", str(ROOT / "concepts" / "TOWN REF" / "TownMap_Component4.png"),
                                "--box", "470,460,640,710", "--footprint", "1.1,1.1", "--mirror", "--colors", "48",
                                "--canvas-pad", "4", "--harmonize"])
    with tempfile.TemporaryDirectory() as tmp:
        c = run(args, Path(tmp) / "bell_tower", manifest=False)
    got = Image.fromarray(c, "RGBA").getchannel("A").getbbox()
    ref_im = Image.open(B / "bell_tower" / "intact.png").convert("RGBA")
    ref = ref_im.getchannel("A").getbbox()
    print("converted bbox", got, "size", Image.fromarray(c).size)
    print("committed bbox", ref, "size", ref_im.size)
    diffs = [abs(g - r) for g, r in zip(got, ref)]
    ok = max(diffs) <= 2
    print("bbox diffs", diffs, "SELFTEST", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    if sys.argv[1:2] == ["selftest"]:
        selftest()
    a = parser().parse_args()
    for k in ("sheet", "box", "footprint"):
        if not getattr(a, k):
            sys.exit("convert: --%s is required" % k)
    run(a, B / a.set)
