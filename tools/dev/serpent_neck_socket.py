"""Measure the Pale Serpent's neck socket per head sheet (Task 10, ruling R11).

The neck's cut edge is the opaque row nearest the back of the head: on every head sheet the neck leaves through the bottom
edge, so it is the lowest row holding opaque pixels. The socket is the centre of the widest opaque run on that row, given
in sprite px from HEAD_PIVOT (32, 36). Run: python -I tools/dev/serpent_neck_socket.py assets/pixellab/fx/pale_serpent/head_*.png
"""
import os
import sys

from PIL import Image

PIVOT = (32, 36)
ALPHA = 128


def runs(row):
    out, start = [], None
    for x, a in enumerate(row + [0]):
        if a >= ALPHA and start is None:
            start = x
        elif a < ALPHA and start is not None:
            out.append((start, x - 1))
            start = None
    return out


for path in sys.argv[1:]:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    alpha = [[im.getpixel((x, y))[3] for x in range(w)] for y in range(h)]
    bottom = max(y for y in range(h) if any(a >= ALPHA for a in alpha[y]))
    spans = runs(alpha[bottom])
    a, b = max(spans, key=lambda s: s[1] - s[0])
    cx = (a + b + 1) / 2.0
    name = os.path.basename(path)[len("head_"):-len(".png")]
    print("%-11s bottom row %d, neck x %d..%d (width %d) -> socket Vector2(%.1f, %.1f)"
          % (name, bottom, a, b, b - a + 1, cx - PIVOT[0], bottom + 1 - PIVOT[1]))
