"""Pack the PixelLab people into one atlas (PixelLab people; docs/superpowers/plans/2026-10-03-pixellab-people.md).

Reads assets/pixellab/people/frames/<design>/<template>/<direction>_<i>.png (and rot_<direction>.png), writes
assets/pixellab/people/atlas.png and manifest.json. Each design is a block of 8 x 36 cells of 24 x 24 px: row =
state * 4 + direction, column = frame. After the design blocks come their silhouettes (white where the frame is
opaque), which the engine draws over a sprite to tint it. A direction a state lacks is its partner flipped; "getup" is
"death" played backwards; a state a design lacks takes its idle, and a missing idle
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
          ("stumble", "crouching"), ("death", "falling-back-death"), ("scream", "scream"), ("lurch", "scary-walk"),
          ("swing", "swing"), ("getup", None)]
# A direction PixelLab was not asked for is its partner flipped left-right: SE <-> SW, NE <-> NW.
MIRROR = {"south-east": "south-west", "south-west": "south-east", "north-east": "north-west", "north-west": "north-east"}
DIRS = ["south-east", "south-west", "north-east", "north-west"]
# Clips rejected on review (design, state, direction): their frames stay on disk for comparison but are not packed, so the
# cell shows the design's idle (a still stand) until the clip is re-rolled (docs/people_anim_reroll.md). A mirrored
# direction follows its partner, so each entry also rejects the partner.
_REJECTED_SOURCE = [(d, "scream", "north-east") for d in
                    ("merchant_a", "merchant_b", "craft_a", "craft_b", "clergy", "caregiver_a", "caregiver_b",
                     "bellkeeper", "engineer")]
REJECTED = set(_REJECTED_SOURCE) | {(d, s, MIRROR[x]) for d, s, x in _REJECTED_SOURCE}
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
        if template is None:
            continue
        s = os.path.join(src, template)
        if os.path.isdir(s):
            shutil.copytree(s, dst / template, dirs_exist_ok=True)
            fit_v3(design, template)
    print("imported", design, "from", src)


def _foot(im):
    bb = im.getchannel("A").getbbox()
    return ((bb[0] + bb[2]) // 2, bb[3])


def fit_v3(design, template):
    """PixelLab v3 clips come on a 28 x 28 canvas whose frame 0 is the reference (the idle pose). Move every frame so
    that reference's feet land on the design's idle feet in the 24 x 24 cell, never scaling, then drop the reference."""
    folder = FRAMES / design / template
    for d in DIRS:
        files = sorted(glob.glob(str(folder / (d + "_*.png"))))
        if not files or Image.open(files[0]).size == (CELL, CELL):
            continue
        idle = _read(design, "breathing-idle", d)
        frames = [Image.open(f).convert("RGBA") for f in files]
        fx, fy = _foot(frames[0])
        ix, iy = _foot(idle[0]) if idle else (fx - 2, fy - 2)
        dx, dy = ix - fx, iy - fy
        for f in files:
            os.remove(f)
        for i, fr in enumerate(frames[1:]):
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            cell.paste(fr, (dx, dy))
            if cell.getchannel("A").histogram()[1:] != fr.getchannel("A").histogram()[1:]:
                print("  WARNING: %s/%s/%s_%d is clipped by the 24 cell" % (design, template, d, i))
            cell.save(folder / ("%s_%02d.png" % (d, i)))
        print("  fitted %s/%s/%s: shift (%d, %d), %d frames" % (design, template, d, dx, dy, len(frames) - 1))


def _read(design, template, d):
    return [Image.open(p).convert("RGBA") for p in sorted(glob.glob(str(FRAMES / design / template / (d + "_*.png"))))]


def frames_of(design, template, d):
    """The frames of a template facing d; a direction not generated is its partner's, flipped left-right."""
    got = _read(design, template, d)
    if not got:
        got = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in _read(design, template, MIRROR[d])]
    return got


def state_frames(design, state, template, d):
    """The frames for an engine state: "getup" is the fall reversed; a state with none takes the idle, then the rotation."""
    if state == "getup":
        frames = list(reversed(state_frames(design, "death", "falling-back-death", d)))
    elif (design, state, d) in REJECTED:
        frames = []
    else:
        frames = frames_of(design, template, d)
    if not frames:
        frames = frames_of(design, "breathing-idle", d)
    if not frames:
        rot = FRAMES / design / ("rot_%s.png" % d)
        frames = [Image.open(rot).convert("RGBA")] if rot.exists() else []
    return frames


def main():
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == "--import":
            design, _, src = args[i + 1].partition("=")
            import_character(design, src)
    designs = sorted(p.name for p in FRAMES.iterdir() if p.is_dir())
    # The design blocks, their silhouettes, and one more for a white square (shadows drawn from the atlas itself, so a
    # person's every draw shares one texture and the crowd batches).
    blocks = len(designs) * 2 + 1
    rows_of_blocks = (blocks + BLOCKS_ACROSS - 1) // BLOCKS_ACROSS
    atlas = Image.new("RGBA", (BLOCKS_ACROSS * BLOCK_COLS * CELL, rows_of_blocks * BLOCK_ROWS * CELL), (0, 0, 0, 0))
    manifest = {"cell": [CELL, CELL], "designs": {}}

    def origin(k):
        return ((k % BLOCKS_ACROSS) * BLOCK_COLS * CELL, (k // BLOCKS_ACROSS) * BLOCK_ROWS * CELL)

    for di, design in enumerate(designs):
        block = origin(di)
        sil = origin(len(designs) + di)
        counts = {}
        own = 0  # bit si: the design's own art for that row, generated or mirrored, not the idle fallback
        for si, (state, template) in enumerate(STATES):
            counts[state] = {}
            src_template = "falling-back-death" if state == "getup" else template
            if all(frames_of(design, src_template, d) for d in DIRS):
                own |= 1 << si
            for dj, d in enumerate(DIRS):
                frames = state_frames(design, state, template, d)
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
                                       "frames": counts, "own": own}
        print("packed", design, "foot", manifest["designs"][design]["foot"])
    white = origin(len(designs) * 2)
    atlas.paste(Image.new("RGBA", (8, 8), (255, 255, 255, 255)), white)
    manifest["white"] = list(white)
    atlas.save(PEOPLE / "atlas.png")
    (PEOPLE / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print("atlas", atlas.size, "with", len(designs), "designs")


if __name__ == "__main__":
    main()
