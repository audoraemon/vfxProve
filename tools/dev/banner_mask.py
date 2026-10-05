"""The keep's banners and flag, for its banner drop (PixelLab structures proof).

mask:   python tools/dev/banner_mask.py mask <sprite.png> <mask.png>
        White over every blue banner and flag (their saturated blue, the white cross inside, a pixel round), black
        elsewhere: what PixelLab inpaints into bare stone for the keep's fallen stills.
layer:  python tools/dev/banner_mask.py layer <sprite.png> <mask.png> <banners.png>
        The sprite's pixels under the mask, on transparency: the banners that slide down and fade when they fall.
"""
import sys
from collections import deque

from PIL import Image

PAD = 1


def is_blue(r, g, b, a):
    return a > 0 and b > r + 40 and b > g + 20


def mask(src, dst):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = [[False] * w for _ in range(h)]
    out = Image.new("L", (w, h), 0)
    op = out.load()
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0][x0] or not is_blue(*px[x0, y0]):
                continue
            shape = []
            todo = deque([(x0, y0)])
            seen[y0][x0] = True
            while todo:
                x, y = todo.popleft()
                shape.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and is_blue(*px[nx, ny]):
                        seen[ny][nx] = True
                        todo.append((nx, ny))
            if len(shape) < 6:
                continue
            # The banner's box, so its white cross and gold rod come too.
            xs = [p[0] for p in shape]
            ys = [p[1] for p in shape]
            for y in range(max(min(ys) - PAD, 0), min(max(ys) + PAD + 1, h)):
                for x in range(max(min(xs) - PAD, 0), min(max(xs) + PAD + 1, w)):
                    if px[x, y][3] > 0:
                        op[x, y] = 255
    out.convert("RGB").save(dst)
    print("mask", dst, "covers", sum(1 for v in out.getdata() if v), "px")


def layer(src, mask_path, dst):
    im = Image.open(src).convert("RGBA")
    m = Image.open(mask_path).convert("L")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), m)
    out.save(dst)
    print("banner layer", dst)


if __name__ == "__main__":
    if sys.argv[1] == "mask":
        mask(sys.argv[2], sys.argv[3])
    else:
        layer(sys.argv[2], sys.argv[3], sys.argv[4])
