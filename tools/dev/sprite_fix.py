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
Run from the project root.
"""
import glob
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


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"shift": shift, "corner": corner, "profile": profile, "unwhite": unwhite, "largest": largest, "strip": strip,
     "view": view, "sheet": sheet, "footprint": footprint}[cmd](*args)
