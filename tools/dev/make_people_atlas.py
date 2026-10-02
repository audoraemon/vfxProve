"""Pack the PixelLab people into one atlas (PixelLab people; docs/superpowers/plans/2026-10-03-pixellab-people.md).

Reads assets/pixellab/people/frames/<design>/<template>/<direction>_<i>.png (and rot_<direction>.png), writes
assets/pixellab/people/atlas.png and manifest.json. Each design is a block of 8 x 20 cells of 24 x 24 px: row =
state * 4 + direction, column = frame. After the design blocks come their silhouettes (white where the frame is
opaque), which the engine draws over a sprite to tint it. A state a design lacks takes its idle, and a missing idle
takes the rotation image, so the engine always finds a frame.

Usage (from the project root):
  python tools/dev/make_people_atlas.py [--import <design>=<downloaded character dir> ...]
"""
import glob
import json
import os
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PEOPLE = ROOT / "assets" / "pixellab" / "people"
FRAMES = PEOPLE / "frames"
# Engine state, PixelLab template (the folder the frames come in).
STATES = [("idle", "breathing-idle"), ("walk", "walking-4-frames"), ("run", "running-4-frames"),
          ("stumble", "crouching"), ("death", "falling-back-death")]
DIRS = ["south-east", "south-west", "north-east", "north-west"]
CELL = 24
BLOCK_COLS = 8
BLOCK_ROWS = len(STATES) * len(DIRS)
BLOCKS_ACROSS = 6


def import_character(design, src):
    dst = FRAMES / design
    dst.mkdir(parents=True, exist_ok=True)
    for p in glob.glob(os.path.join(src, "rot_*.png")):
        shutil.copy(p, dst / os.path.basename(p))
    for _, template in STATES:
        s = os.path.join(src, template)
        if os.path.isdir(s):
            shutil.copytree(s, dst / template, dirs_exist_ok=True)
    print("imported", design, "from", src)


def frames_of(design, template, d):
    return [Image.open(p).convert("RGBA") for p in sorted(glob.glob(str(FRAMES / design / template / (d + "_*.png"))))]


def main():
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--import":
            design, _, src = args[i + 1].partition("=")
            import_character(design, src)
    designs = sorted(p.name for p in FRAMES.iterdir() if p.is_dir())
    blocks = len(designs) * 2
    rows_of_blocks = (blocks + BLOCKS_ACROSS - 1) // BLOCKS_ACROSS
    atlas = Image.new("RGBA", (BLOCKS_ACROSS * BLOCK_COLS * CELL, rows_of_blocks * BLOCK_ROWS * CELL), (0, 0, 0, 0))
    manifest = {"cell": [CELL, CELL], "designs": {}}

    def origin(k):
        return ((k % BLOCKS_ACROSS) * BLOCK_COLS * CELL, (k // BLOCKS_ACROSS) * BLOCK_ROWS * CELL)

    for di, design in enumerate(designs):
        block = origin(di)
        sil = origin(len(designs) + di)
        counts = {}
        for si, (state, template) in enumerate(STATES):
            counts[state] = {}
            for dj, d in enumerate(DIRS):
                frames = frames_of(design, template, d) or frames_of(design, "breathing-idle", d)
                if not frames:
                    rot = FRAMES / design / ("rot_%s.png" % d)
                    frames = [Image.open(rot).convert("RGBA")] if rot.exists() else []
                if not frames:
                    sys.exit("%s has no %s frame for %s" % (design, state, d))
                frames = frames[:BLOCK_COLS]
                for fi, f in enumerate(frames):
                    if f.size != (CELL, CELL):
                        sys.exit("%s/%s/%s_%d is %s, not %dx%d" % (design, template, d, fi, f.size, CELL, CELL))
                    x = fi * CELL
                    y = (si * len(DIRS) + dj) * CELL
                    atlas.paste(f, (block[0] + x, block[1] + y))
                    white = Image.new("RGBA", f.size, (255, 255, 255, 255))
                    white.putalpha(f.getchannel("A"))
                    atlas.paste(white, (sil[0] + x, sil[1] + y))
                counts[state][d] = len(frames)
        idle = frames_of(design, "breathing-idle", "south-east") or [Image.open(FRAMES / design / "rot_south-east.png")]
        bb = idle[0].getchannel("A").getbbox()
        manifest["designs"][design] = {"block": list(block), "sil": list(sil), "foot": [(bb[0] + bb[2]) // 2, bb[3]],
                                       "frames": counts}
        print("packed", design, "foot", manifest["designs"][design]["foot"])
    atlas.save(PEOPLE / "atlas.png")
    (PEOPLE / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print("atlas", atlas.size, "with", len(designs), "designs")


if __name__ == "__main__":
    main()
