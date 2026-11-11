"""Fits a child PixelLab character (a char-get download) into the people atlas's 24 x 24 cells.

Usage (from the project root):
  python tools/dev/fit_child_frames.py --src ../pl_child_a --design child_a
  python tools/dev/make_people_atlas.py

The children are standard-mode chibi characters (18 px tall like the adults, 24 canvas), drawn --scale smaller (15/18:
15 px) by nearest-neighbour over the whole canvas, the same grid for every frame so the clips do not shimmer. Their v3
clips (scream, cower, talk) come on a larger canvas whose frame 0 is the reference pose, dropped here. Every frame is then
shifted so the south-east still pose's feet land on FOOT (the adults' foot), and written to
assets/pixellab/people/frames/<design>/ under the template names make_people_atlas.py reads.
"""
import argparse
import glob
import os

from PIL import Image

CELL = 24
FOOT = (12, 21)
DIRS = ["south-east", "south-west", "north-east", "north-west"]
TEMPLATES = ["breathing-idle", "walking-4-frames", "running-4-frames", "crouching", "falling-back-death", "scream",
             "cower", "talk"]
# v3 clips: frame 0 is the reference (the still pose).
V3 = {"scream", "cower", "talk"}


def _foot(im):
    bb = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    return ((bb[0] + bb[2]) // 2, bb[3]) if bb else None


def _scaled(im, k):
    if k == 1.0:
        return im
    return im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.NEAREST)


def _place(im, dx, dy, label):
    cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    cell.paste(im, (dx, dy), im)
    if cell.getchannel("A").histogram()[1:] != im.getchannel("A").histogram()[1:]:
        print("  WARNING: %s is clipped by the 24 cell" % label)
    return cell


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--design", required=True)
    ap.add_argument("--scale", type=float, default=1.0, help="draw this much smaller, e.g. 0.8333 (18 px to 15)")
    args = ap.parse_args()
    k = args.scale
    out = os.path.join("assets", "pixellab", "people", "frames", args.design)
    os.makedirs(out, exist_ok=True)
    base = _scaled(Image.open(os.path.join(args.src, "rot_south-east.png")).convert("RGBA"), k)
    bx, by = _foot(base)
    # The rotation canvas's shift: every frame on that canvas moves by this.
    shift = (FOOT[0] - bx, FOOT[1] - by)
    for p in glob.glob(os.path.join(args.src, "rot_*.png")):
        im = _scaled(Image.open(p).convert("RGBA"), k)
        _place(im, shift[0], shift[1], os.path.basename(p)).save(os.path.join(out, os.path.basename(p)))
    for t in TEMPLATES:
        for d in DIRS:
            files = sorted(glob.glob(os.path.join(args.src, t, d + "_*.png")))
            if not files:
                continue
            frames = [_scaled(Image.open(f).convert("RGBA"), k) for f in files]
            if t in V3:
                # The 36 canvas: put its reference's feet where the rotation's feet go, then drop the reference.
                rot = _scaled(Image.open(os.path.join(args.src, "rot_%s.png" % d)).convert("RGBA"), k)
                rx, ry = _foot(rot)
                fx, fy = _foot(frames[0])
                dx, dy = shift[0] + rx - fx, shift[1] + ry - fy
                frames = frames[1:]
            else:
                dx, dy = shift
            os.makedirs(os.path.join(out, t), exist_ok=True)
            for old in glob.glob(os.path.join(out, t, d + "_*.png")):
                os.remove(old)
            for i, f in enumerate(frames):
                _place(f, dx, dy, "%s/%s_%d" % (t, d, i)).save(os.path.join(out, t, "%s_%02d.png" % (d, i)))
            print("  %s %s: %d frames, shift (%d, %d)" % (t, d, len(frames), dx, dy))
    print("fitted", args.design, "->", out)


if __name__ == "__main__":
    main()
