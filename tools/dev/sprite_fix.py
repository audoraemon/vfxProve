"""Small image fixes and review aids used on PixelLab sprites (PixelLab structures proof; see docs/HANDOFF_pixellab.md).

  shift   <src> <dst> <dx> <dy>          move a sprite by whole pixels on its canvas (ruins edits come back high)
  corner  <png> [...]                    alpha bbox and lowest opaque row, to find the footprint's front corner
  profile <png> [step]                   lowest opaque row per column: the base's V shows the front corner
  unwhite <src> <dst> [tolerance]        a flat light background (a candidate returned on white) made transparent
  largest <src> <dst>                    keep the largest shape (+ small rubble bits low down), drop floating pieces
  strip   <glob> <dst>                   join frames (sorted by name) into one horizontal strip
  view    <dst> <scale> <png|glob> [...] side-by-side review sheet on grey, scaled up nearest
  sheet   <reference> <dir> <prefix> <dst> [scale] [cols]   candidates next to their reference, with bbox offsets
  footprint <png> <dst> <w> <d> <ax>,<ay> [...]   draw a w x d footprint's diamond at candidate anchors, to judge fit
  tile    <src> <dst> <u0x>,<u0y> <period> <span>   repeat one generated wall run into a seamless strip
  harmonize <target> <x0,y0,x1,y1|all> <png> [...]   recolour the sprites' stone to the target's stone (in place;
                                         the first png sets the source statistics for all of them: pass a set's
                                         intact first so damaged/ruins keep their scorch). `stonemean <png> [...]`
                                         prints the stone mask's share and mean RGB.
  huemap  <src> <dst> <h0,h1> <palette png> <x0,y0,x1,y1> [minsat=S] [minl=L] [lrange=lo,hi] [phue=a,b] [poly=x,y;x,y;...] [mask=png] [skip=x0,y0,x1,y1 ...]
                                         recolour one hue band (degrees; e.g. a red tile roof) to another sprite's
                                         palette (the box's colours, phue filters them by hue): each pixel takes the
                                         palette colour nearest its lightness, mapped linearly from lrange (default:
                                         its own 2..98 % lightness) onto the palette's range, so the light-dark order
                                         stays. Only pixels inside poly (if given) change; skip boxes are left
                                         alone (e.g. a brick chimney in the roof's hue). h0 > h1 wraps
                                         through 360 (reds: 340,20). mask=<png> limits it to that image's
                                         opaque (or, for a grey mask, non-black) pixels (e.g. a stall's awning, cut out by hand).
Run from the project root.
"""
import glob
import math
import os
import sys
from collections import deque

from PIL import Image, ImageDraw


def _rgba(p):
    return Image.open(p).convert("RGBA")


def _paths(args):
    return [p for a in args for p in (sorted(glob.glob(a)) if any(c in a for c in "*?[") else [a])]


def shift(src, dst, dx, dy):
    im = _rgba(src)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (int(dx), int(dy)))
    lost = sum(1 for p in im.getdata() if p[3]) - sum(1 for p in out.getdata() if p[3])
    out.save(dst)
    print("bbox", out.getchannel("A").getbbox(), "pixels lost off canvas", lost)


def corner(*paths):
    for p in _paths(paths):
        im = _rgba(p)
        a = im.getchannel("A").load()
        w, h = im.size
        low = max(y for y in range(h) for x in range(w) if a[x, y] > 0)
        xs = [x for x in range(w) if a[x, low] > 0]
        print(p, "size", im.size, "bbox", im.getchannel("A").getbbox(), "lowest row", low, "x", min(xs), "-", max(xs))


def profile(p, step="4"):
    im = _rgba(p)
    a = im.getchannel("A").load()
    print(" ".join("%d:%d" % (x, max((y for y in range(im.height) if a[x, y] > 0), default=-1))
                   for x in range(0, im.width, int(step))))


def unwhite(src, dst, tol="18"):
    im = _rgba(src)
    tol = int(tol)
    w, h = im.size
    px = im.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    bg = max(set(corners), key=corners.count)
    near = lambda c: c[3] > 0 and all(abs(c[i] - bg[i]) <= tol for i in range(3))
    seen = set()
    todo = deque([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)]
                 + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
    cleared = 0
    while todo:
        x, y = todo.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        c = px[x, y]
        if c[3] == 0 or near(c):
            if c[3]:
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
            todo.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    # Background seen through an opening is walled in by outlines: clear what matches it closely anywhere.
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] and all(abs(c[i] - bg[i]) <= 6 for i in range(3)):
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
    im.save(dst)
    print("background", bg, "cleared", cleared, "bbox", im.getchannel("A").getbbox())


def largest(src, dst):
    im = _rgba(src)
    w, h = im.size
    a = im.getchannel("A").load()
    label = [[-1] * w for _ in range(h)]
    shapes = []
    for y0 in range(h):
        for x0 in range(w):
            if a[x0, y0] == 0 or label[y0][x0] >= 0:
                continue
            pts = []
            q = deque([(x0, y0)])
            label[y0][x0] = len(shapes)
            while q:
                x, y = q.popleft()
                pts.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and a[nx, ny] > 0 and label[ny][nx] < 0:
                            label[ny][nx] = len(shapes)
                            q.append((nx, ny))
            shapes.append(pts)
    main = max(shapes, key=len)
    mid = (min(p[1] for p in main) + max(p[1] for p in main)) / 2
    keep = set(main)
    for s in shapes:
        if s is not main and len(s) < 40 and all(p[1] >= mid for p in s):
            keep.update(s)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    po, ps = out.load(), im.load()
    for x, y in keep:
        po[x, y] = ps[x, y]
    out.save(dst)
    print("shapes", len(shapes), "kept", len(keep), "px; bbox", out.getchannel("A").getbbox())


def strip(pattern, dst):
    frames = [_rgba(p) for p in sorted(glob.glob(pattern))]
    w, h = frames[0].size
    out = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    out.save(dst)
    print(len(frames), "frames ->", out.size)


def view(dst, scale, *paths):
    ims = [_rgba(p) for p in _paths(paths)]
    w = sum(i.width + 6 for i in ims)
    h = max(i.height for i in ims)
    s = Image.new("RGBA", (w, h), (96, 92, 82, 255))
    x = 0
    for i in ims:
        s.alpha_composite(i, (x, h - i.height))
        x += i.width + 6
    s.resize((w * int(scale), h * int(scale)), Image.NEAREST).save(dst)


def sheet(ref_path, cdir, prefix, dst, scale="3", cols="6"):
    scale, cols = int(scale), int(cols)
    ref = _rgba(ref_path)
    ims = [("ref", ref)] + [(os.path.basename(p)[len(prefix) + 1:-4], _rgba(p))
                            for p in sorted(glob.glob(os.path.join(cdir, prefix + "_*.png")))]
    w = max(i.width for _, i in ims)
    h = max(i.height for _, i in ims)
    rows = (len(ims) + cols - 1) // cols
    out = Image.new("RGBA", (cols * (w + 4) * scale, rows * (h + 12) * scale), (40, 40, 40, 255))
    d = ImageDraw.Draw(out)
    rb = ref.getchannel("A").getbbox()
    for k, (label, im) in enumerate(ims):
        x = (k % cols) * (w + 4) * scale
        y = (k // cols) * (h + 12) * scale
        tile = Image.new("RGBA", im.size, (96, 92, 82, 255))
        tile.alpha_composite(im)
        out.paste(tile.resize((im.width * scale, im.height * scale), Image.NEAREST), (x, y + 10 * scale))
        d.text((x + 4, y + 2), label, fill=(255, 255, 255, 255))
        bb = im.getchannel("A").getbbox()
        if label != "ref" and bb:
            print(label, "bbox", bb, "bottom dy", bb[3] - rb[3], "centre dx", (bb[0] + bb[2]) / 2 - (rb[0] + rb[2]) / 2)
    out.save(dst)


def footprint(png, dst, fw, fd, *anchors):
    S = 6
    src = _rgba(png)
    fw, fd = float(fw), float(fd)
    tiles = []
    for a in anchors:
        ax, ay = (int(v) for v in a.split(","))
        bg = Image.new("RGBA", src.size, (96, 92, 82, 255))
        bg.alpha_composite(src)
        im = bg.resize((src.width * S, src.height * S), Image.NEAREST)
        d = ImageDraw.Draw(im)
        pts = [(0, 0), (32 * fd, -16 * fd), (32 * fd - 32 * fw, -16 * fd - 16 * fw), (-32 * fw, -16 * fw)]
        poly = [((ax + x) * S, (ay + y) * S) for x, y in pts]
        d.line(poly + [poly[0]], fill=(0, 255, 255, 255), width=2)
        d.text((4, 4), a, fill=(255, 255, 0, 255))
        tiles.append(im)
    out = Image.new("RGBA", (sum(t.width + 8 for t in tiles), tiles[0].height), (30, 30, 30, 255))
    x = 0
    for t in tiles:
        out.paste(t, (x, 0))
        x += t.width + 8
    out.save(dst)


def tile(src, dst, u0, period, span):
    """A seamless wall strip from one generated run along ground x. `u0` is the pixel of the run's front edge at
    u = 0; `period` (ground units, a multiple of 1/16 so it shifts by whole pixels) is where the art repeats -- pick it
    at matching merlons. The strip keeps the source's columns left of u = period, then repeats the band of columns for
    u in [0, period) every period (32*period px right, 16*period px down) until it spans `span` units plus the wall's
    0.7-unit depth. Prints the manifest values for the strip."""
    im = _rgba(src)
    ux, uy = (float(v) for v in u0.split(","))
    S, span = float(period), float(span)
    if ux != int(ux) or uy != int(uy):
        sys.exit("u0 must be whole pixels")
    if S <= 0:
        sys.exit("period must be positive")
    if span < S:
        sys.exit("span must be at least one period")
    dx, dy = 32.0 * S, 16.0 * S
    if dx != int(dx) or dy != int(dy):
        sys.exit("period must be a multiple of 1/16 unit")
    dx, dy = int(dx), int(dy)
    ax = int(round(ux))
    cut = ax + dx
    w = int(math.ceil(ux + 32.0 * (span + 0.7))) + 2
    h = im.height + int(math.ceil(16.0 * (span - S)))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(im.crop((0, 0, min(cut, im.width), im.height)), (0, 0))
    band = im.crop((ax, 0, cut, im.height))
    k = 1
    while ax + k * dx < w:
        out.paste(band, (ax + k * dx, k * dy))
        k += 1
    out.save(dst)
    anchor = (ux + 32.0 * span, uy + 16.0 * span)
    print("size", [w, h], "anchor", [round(anchor[0], 3), round(anchor[1], 3)], "footprint", [span, 0.7], "period", S)


# --- harmonize: one stone colour for a family of sprites ----------------------------------------------------------
_D65 = (0.95047, 1.0, 1.08883)
_M = ((0.4124564, 0.3575761, 0.1804375), (0.2126729, 0.7151522, 0.0721750), (0.0193339, 0.1191920, 0.9503041))


def _lab(rgb):
    import numpy as np
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    xyz = c @ np.array(_M).T / np.array(_D65)
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def _rgb(lab):
    import numpy as np
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], -1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) / (24389 / 27)) * np.array(_D65)
    c = xyz @ np.linalg.inv(np.array(_M)).T
    c = np.clip(c, 0, 1)
    c = np.where(c <= 0.0031308, 12.92 * c, 1.055 * c ** (1 / 2.4) - 0.055)
    return np.clip(np.round(c * 255), 0, 255).astype(np.uint8)


def _stone(arr):
    """Lab of every pixel and how much of a stone pixel it is (0..1). Stone is low-chroma: neutral greys, slate greys
    (cool to blue-violet hues 150..290, chroma <= 18; the blue banners sit at chroma 30+) and light warm limestone (warm hues, chroma up to 24 when light). Out: transparent,
    outline-dark (L < 14), saturated (banners, fire, torch light, moss, wood), each fading over a few units of
    chroma or lightness so no hard seam appears between recoloured and kept pixels."""
    import numpy as np
    lab = _lab(arr[..., :3].astype(float))
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    C = np.hypot(a, b)
    h = np.degrees(np.arctan2(b, a)) % 360
    cmax = np.full(L.shape, 10.0)
    warm = (h >= 20) & (h <= 100)
    cmax = np.where(warm, 10 + 14 * np.clip((L - 50) / 20, 0, 1), cmax)
    cmax = np.where((h >= 150) & (h <= 290), 18.0, cmax)
    w = np.clip((cmax + 4 - C) / 4, 0, 1) * np.clip((L - 10) / 6, 0, 1)
    w = np.where(arr[..., 3] > 0, w, 0)
    return lab, w


def _stats(lab, w):
    import numpy as np
    sw = w.sum()
    mean = (lab * w[..., None]).sum((0, 1)) / sw
    std = np.sqrt((((lab - mean) ** 2) * w[..., None]).sum((0, 1)) / sw)
    return mean, std


def stonemean(*paths):
    import numpy as np
    for p in _paths(paths):
        arr = np.array(_rgba(p))
        _, w = _stone(arr)
        if w.sum() <= 0:
            sys.exit("stonemean: %s has no stone pixels" % p)
        m = (arr[..., :3] * w[..., None]).sum((0, 1)) / w.sum()
        print(p, "stone share %.2f" % (w.sum() / max(1, (arr[..., 3] > 0).sum())), "mean RGB", m.round(1).tolist())


def harmonize(target, box, *paths):
    """Recolour the stone of `paths` (in place) so its Lab statistics match the target crop's stone: chroma (a, b)
    mean and spread matched (spread ratio kept within 0.5..2), lightness mean matched with its spread scaled at most
    0.75..1.25, so each pixel keeps its place in the light-dark order and the texture and shading survive. Non-stone
    pixels keep their exact colour, alpha is untouched, nothing moves: crisp pixel art in, crisp out."""
    import numpy as np
    ref = _rgba(target)
    if box != "all":
        ref = ref.crop(tuple(int(v) for v in box.split(",")))
    tlab, tw = _stone(np.array(ref))
    if tw.sum() <= 0:
        sys.exit("harmonize: the target %s (%s) has no stone pixels" % (target, box))
    tm, ts = _stats(tlab, tw)
    paths = _paths(paths)
    if not paths:
        sys.exit("harmonize: no png to recolour")
    slab, sw = _stone(np.array(_rgba(paths[0])))
    if sw.sum() <= 0:
        sys.exit("harmonize: the source %s has no stone pixels" % paths[0])
    sm, ss = _stats(slab, sw)
    k = np.clip(ts / np.maximum(ss, 1e-6), [0.75, 0.5, 0.5], [1.25, 2.0, 2.0])
    print("target Lab", tm.round(2).tolist(), "spread", ts.round(2).tolist())
    print("source Lab", sm.round(2).tolist(), "spread", ss.round(2).tolist(), "gain", k.round(2).tolist())
    for p in paths:
        arr = np.array(_rgba(p))
        lab, w = _stone(arr)
        if w.sum() <= 0:
            print(p, "no stone pixels: left unchanged")
            continue
        mapped = tm + (lab - sm) * k
        out = lab + (mapped - lab) * w[..., None]
        rgb = _rgb(out)
        keep = w <= 0
        rgb[keep] = arr[..., :3][keep]
        res = np.concatenate([rgb, arr[..., 3:]], -1)
        Image.fromarray(res, "RGBA").save(p)
        m0 = (arr[..., :3] * w[..., None]).sum((0, 1)) / w.sum()
        m1 = (res[..., :3] * w[..., None]).sum((0, 1)) / w.sum()
        print(p, "stone px %.0f" % w.sum(), "mean RGB", m0.round(1).tolist(), "->", m1.round(1).tolist())


def _hls(arr):
    """Hue (degrees), lightness, saturation (0..1) of an RGB(A) array, as in colorsys."""
    import numpy as np
    rgb = arr[..., :3].astype(np.float64) / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    l = (mx + mn) / 2
    d = mx - mn
    s = np.where(d == 0, 0, d / np.where(l <= 0.5, mx + mn, 2 - mx - mn + 1e-12))
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    dd = np.where(d == 0, 1, d)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60
    h = np.where(d == 0, 0, h)
    return h, l, s


def huemap(src, dst, hues, palette, box, *opts):
    import numpy as np
    o = dict(kv.split("=", 1) for kv in opts if not kv.startswith("skip="))
    skips = [tuple(int(v) for v in kv[5:].split(",")) for kv in opts if kv.startswith("skip=")]
    h0, h1 = (float(v) for v in hues.split(","))
    minsat, minl = float(o.get("minsat", 0.4)), float(o.get("minl", 0.08))
    pal = np.array(_rgba(palette).crop(tuple(int(v) for v in box.split(","))))
    ph, pl, ps = _hls(pal)
    pm = (pal[..., 3] == 255) & (ps >= 0.12) & (pl > 0.05) & (pl < 0.9)
    if "phue" in o:
        a, b = (float(v) for v in o["phue"].split(","))
        pm &= (ph >= a) & (ph <= b)
    cols = np.unique(pal[..., :3][pm], axis=0)
    if len(cols) == 0:
        sys.exit("huemap: the palette box %s of %s has no usable colour (opaque, saturated, mid-light%s)"
                 % (box, palette, ", in phue" if "phue" in o else ""))
    _, cl, _ = _hls(cols[None])
    cl = cl[0]
    arr = np.array(_rgba(src))
    h, l, s = _hls(arr)
    band = ((h >= h0) & (h <= h1)) if h0 <= h1 else ((h >= h0) | (h <= h1))
    m = (arr[..., 3] > 0) & band & (s >= minsat) & (l >= minl)
    if "poly" in o:
        area = Image.new("L", (arr.shape[1], arr.shape[0]), 0)
        ImageDraw.Draw(area).polygon([tuple(float(v) for v in pt.split(",")) for pt in o["poly"].split(";")], fill=255)
        m &= np.array(area) > 0
    if "mask" in o:
        mk = Image.open(o["mask"])
        if mk.size != (arr.shape[1], arr.shape[0]):
            sys.exit("huemap: mask %s is %dx%d, the sprite is %dx%d" % ((o["mask"],) + mk.size + (arr.shape[1], arr.shape[0])))
        m &= np.array(mk.getchannel("A") if "A" in mk.getbands() else mk.convert("L")) > 0
    for x0, y0, x1, y1 in skips:
        m[y0:y1, x0:x1] = False
    if not m.any():
        sys.exit("huemap: no pixel in the hue band / area")
    if "lrange" in o:
        lo, hi = (float(v) for v in o["lrange"].split(","))
    else:
        lo, hi = np.percentile(l[m], 2), np.percentile(l[m], 98)
    t = np.clip((l - lo) / max(hi - lo, 1e-6), 0, 1)
    lt = cl.min() + t * (cl.max() - cl.min())
    idx = np.abs(lt[..., None] - cl[None, None, :]).argmin(-1)
    out = arr.copy()
    out[..., :3][m] = cols[idx][m]
    Image.fromarray(out, "RGBA").save(dst)
    print(dst, "recoloured px", int(m.sum()), "palette", len(cols), "lrange %.3f,%.3f" % (lo, hi))


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"shift": shift, "corner": corner, "profile": profile, "unwhite": unwhite, "largest": largest, "strip": strip,
     "view": view, "sheet": sheet, "footprint": footprint, "tile": tile, "harmonize": harmonize,
     "stonemean": stonemean, "huemap": huemap}[cmd](*args)
