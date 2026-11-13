"""Measure the Pale Serpent's neck socket per head sheet (Task 10, ruling R11).

The neck's cut edge is the opaque row nearest the back of the head: on every head sheet the neck leaves through the bottom
edge, so it is the lowest row holding opaque pixels. On that row the white/grey feather mantle can hang beside the neck, so
the neck is the widest run of non-feather pixels (green scales and their dark outline; a feather-coloured gap of at most
GAP_MAX px inside the neck, a light scale, is bridged). The socket is the centre of that run, in sprite px from HEAD_PIVOT
(32, 36), at the row's bottom edge. The cut is the span of the whole opaque row (feathers too), from its left edge to its
right edge, in sprite px from the socket: the collar (a green disc over the neck, a feather skirt over the rest) covers it.
Run: python -I tools/dev/serpent_neck_socket.py assets/pixellab/fx/pale_serpent/head_*.png
"""
import os
import sys

from PIL import Image

PIVOT = (32, 36)
ALPHA = 128
GAP_MAX = 3


def feather(px):
    r, g, b = px[:3]
    return max(r, g, b) - min(r, g, b) < 40 and max(r, g, b) > 90


for path in sys.argv[1:]:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    bottom = max(y for y in range(h) if any(im.getpixel((x, y))[3] >= ALPHA for x in range(w)))
    row = [im.getpixel((x, bottom)) for x in range(w)]
    opaque = [x for x in range(w) if row[x][3] >= ALPHA]
    neck = [x for x in opaque if not feather(row[x])]
    # Runs of neck pixels, bridging feather-coloured gaps of at most GAP_MAX opaque px.
    runs, start, last = [], None, None
    for x in neck:
        if start is None:
            start = last = x
        elif x - last - 1 <= GAP_MAX and all(row[k][3] >= ALPHA for k in range(last + 1, x)):
            last = x
        else:
            runs.append((start, last))
            start = last = x
    runs.append((start, last))
    a, b = max(runs, key=lambda s: s[1] - s[0])
    cx = (a + b + 1) / 2.0
    lo, hi = opaque[0] - cx, opaque[-1] + 1 - cx
    name = os.path.basename(path)[len("head_"):-len(".png")]
    print("%-11s cut row %d, opaque x %d..%d, neck x %d..%d (width %d) -> socket Vector2(%.1f, %.1f), cut Vector2(%.1f, %.1f)"
          % (name, bottom, opaque[0], opaque[-1], a, b, b - a + 1, cx - PIVOT[0], bottom + 1 - PIVOT[1], lo, hi))
