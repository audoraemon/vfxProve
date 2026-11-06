"""Packs a PixelLab animal (a char-get download: rot_<dir>.png and <anim>/<dir>_<i>.png) into one sheet for AnimalArt.

Usage (from the project root):
  python tools/dev/make_animal_sheet.py --src DIR --out assets/pixellab/animals/<name>.png

Rows of square cells (the character's canvas, 24 px): 0 the still poses (south-east, north-east), 1 walk south-east,
2 walk north-east, 3 sit, 4 bite, 5 idle, 6 bark, 7 sniff, 8 scratch, 9 lie (all south-east). The west-facing views
are these mirrored in game. A missing row is left empty and the game falls back to the still pose. Every frame is
shifted so its lowest pixel sits on the ground line of the south-east still pose (PixelLab clips drift a pixel or two);
only the still poses are centred sideways too, so a clip keeps its own sideways motion (a head lowered to sniff). Writes <out> and <out>.json (cell, foot, frame
counts).
"""
import argparse
import glob
import json
import os

from PIL import Image

ROWS = [("rot", ["south-east", "north-east"]), ("walk", "south-east"), ("walk", "north-east"), ("sit", "south-east"),
        ("bite", "south-east"), ("idle", "south-east"), ("bark", "south-east"), ("sniff", "south-east"),
        ("scratch", "south-east"), ("lie", "south-east")]


def _foot(im):
    bb = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    return ((bb[0] + bb[2]) // 2, bb[3]) if bb else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    base = Image.open(os.path.join(args.src, "rot_south-east.png")).convert("RGBA")
    cell = base.width
    foot = _foot(base)
    rows = []
    for kind, d in ROWS:
        if kind == "rot":
            frames = [Image.open(os.path.join(args.src, "rot_%s.png" % x)).convert("RGBA") for x in d]
        else:
            paths = sorted(glob.glob(os.path.join(args.src, kind, "%s_*.png" % d)))
            frames = [Image.open(p).convert("RGBA") for p in paths]
        rows.append(frames)
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * cell, len(rows) * cell), (0, 0, 0, 0))
    for y, frames in enumerate(rows):
        for x, im in enumerate(frames):
            if im.size != (cell, cell):
                im = im.crop((0, 0, cell, cell))
            f = _foot(im)
            dx, dy = (foot[0] - f[0], foot[1] - f[1]) if f else (0, 0)
            if ROWS[y][0] != "rot":
                dx = 0
            moved = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
            moved.paste(im, (dx, dy), im)  # clipped to its own cell
            sheet.alpha_composite(moved, (x * cell, y * cell))
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    sheet.save(args.out)
    meta = {"cell": cell, "foot": list(foot), "frames": [len(r) for r in rows]}
    with open(args.out + ".json", "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=1)
    print("packed", args.out, meta)


if __name__ == "__main__":
    main()
