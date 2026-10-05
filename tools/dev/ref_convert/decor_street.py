"""Street decor sets (decor batch 4), built locally (no AI): the house-front lamp and the market bunting, drawn clean
in the style of decor_goods.py (fixed tone patterns, light from the left, 1 px dark outline where the piece is big
enough to carry one).

  lamp_house  Decor.Kind.LAMP: DecorArt._lamp's post lamp (a post on a flared foot, a capped top, an arm reaching right
              on a brace, a lantern hanging from its end) in the batch 3 lamp_post set's tones: its wood (the warm
              pixels' lightness quintiles, unmuted) and its lantern iron (its grey pixels). The glass is lit, in the flame
              tones the lamp_post shows over its glass (Structure.COL_FLAME): a pale core, amber round it, deep orange
              at the corners and the foot, inside the dark iron frame. No halo is painted outside the lantern: the
              light round it is Decor's QuadFx ground pool.
              17 x 38 px (the procedural lamp is 15 x 36), anchored at the middle of the foot's base row. Decor's
              light pool (a QuadFx on the ground, at the procedural lamp's ground point, 8 px left of its lantern)
              moves under this lantern: "glow" [8, 0] (the lantern's centre is 8.5 px right of the anchor; the pool
              stays on the ground).
              "glass" [11, 10, 3, 5]: the lantern's glass (sprite px from its top left, as lamp_post's): Decor draws the
              street lamp's undimmed lit glass over it (Structure.draw_lamp_glass), so the painted flame shows only
              under it, and the strip's steps are covered by that glass's own flicker.
              A 4-frame strip at 6 fps (Group C): the flame in the glass (3 x 5 px) changes shape, the still's (0),
              leaning left (1), sunk low (2), leaning right (3); never more than 7 amber px a frame.
  bunting_x   Decor.Kind.BUNTING along ground x (down-right on screen): one ground unit of string (32 px across,
  bunting_y   16 down, sagging 2 px between its ends) with six pennants hanging from it, blue and cream in turn
              (ArtKit.BANNER[0] and [2], as DecorArt._bunting), each lit on its left column and shaded on its right.
              bunting_y the same along ground y (down-left). Segment 1.0: the run tiles one per unit from its back end,
              the string's ends meeting tile to tile. Anchored at the string's start (its first pixel row) 18 px
              below it, the procedural hang height (DecorArt._bunting's _gp(.., 18.0, ..)): bunting_x at (0, 18),
              bunting_y at (32, 18).

Usage (from anywhere):
  python tools/dev/ref_convert/decor_street.py [all | lamp | bunting] [--out <scratch dir>]
      (--out: write PNGs there, no manifest)
"""
import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
import decor_common  # noqa: E402

LAMP_POST = convert.ROOT / "assets" / "pixellab" / "buildings" / "lamp_post" / "intact.png"
OUTLINE = tuple(int(v) for v in convert.OUTLINE)

# Lit lantern glass: Structure.COL_FLAME's tones (the lamp_post's keep_flames glass). Only the amber (a) meets
# check_sprite_glow's glow rule: 6 px of the lamp's 271.
FLAME_CORE = (255, 240, 176)   # COL_FLAME[0]
FLAME_AMBER = (255, 176, 64)   # COL_FLAME[1]
FLAME_DEEP = (214, 96, 26)     # COL_FLAME[2], darkened a little for the glass's edges

# The lamp, light from the left. 0..4 wood (darkest..lightest), i iron, j its lit side, glass c core, a amber,
# e deep orange, o outline.
LAMP = [
    "..oooo...........",
    ".o4443o..........",
    ".oo42ooooooooooo.",
    "..o424444444444o.",
    "..o422222222221o.",
    "..o4211ooooooooo.",
    "..o421o.....i....",
    "..o42o.....ojo...",
    "..o42o....ojjio..",
    "..o42o...ojjiiio.",
    "..o42o...ojeaeio.",
    "..o42o...ojacaio.",
    "..o42o...ojacaio.",
    "..o42o...ojeaeio.",
    "..o42o...ojeeeio.",
    "..o42o...ojiiiio.",
    "..o42o....ooooo..",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o31o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    "..o31o...........",
    "..o42o...........",
    "..o42o...........",
    "..o42o...........",
    ".o4421o..........",
    "o444221o.........",
    "o433210o.........",
    ".oooooo..........",
]
# The flame's shapes in the glass (rows 10..14, columns 11..13 of LAMP), frame 0 the still's.
FLAME = [
    ("eae", "aca", "aca", "eae", "eee"),
    ("aee", "cae", "aca", "eae", "eee"),
    ("eee", "eae", "aca", "aca", "eae"),
    ("eea", "eac", "aca", "eae", "eee"),
]
FLAME_ROW, FLAME_COL = 10, 11
LAMP_FPS = 6.0
LAMP_ANCHOR = (4, 37)
LAMP_GLOW = (8, 0)        # the light pool: on the ground under the lantern (sprite px from the anchor)
LAMP_GLASS = (FLAME_COL, FLAME_ROW, 3, 5)   # the glass Decor lights (the flame's cells; sprite px from the top left)

# Bunting: ROPE and the pennant tones (lit, body, shade), from ArtKit.BANNER[0..2] and PropArt.ROPE.
ROPE = (61, 41, 26)
BLUE = ((53, 99, 200), (31, 69, 166), (22, 48, 120))
CREAM = ((240, 232, 212), (232, 220, 192), (190, 174, 144))
TILE_W, RISE, SAG = 32, 16, 2       # one ground unit: 32 px across, 16 down; the string sags 2 px mid-tile
FLAGS_AT = (1, 6, 12, 17, 22, 28)   # pennant left columns (6 a tile: blue and cream stay in turn tile to tile)
FLAG_DEPTH = (3, 5, 5, 3)           # each pennant's px below the string, by column: a point under its middle
HANG = 18                           # DecorArt._bunting's height above the ground (px)


def lamp_tones():
    """Five wood tones (darkest first) and the iron (dark, lit) from the lamp_post sprite: the wood is its warm
    (saturated) pixels split in lightness quintiles; the iron its grey (low-saturation) pixels, lit as decor_goods's."""
    a = np.array(Image.open(LAMP_POST).convert("RGBA")).astype(float)
    px = a[a[..., 3] > 200][:, :3]
    lum = px.sum(1)
    sat = (px.max(1) - px.min(1)) / np.maximum(px.max(1), 1)
    wood = px[(sat > 0.45) & (lum > 120)]
    wl = wood.sum(1)
    bins = np.digitize(wl, np.percentile(wl, [20, 40, 60, 80]))
    woods = [tuple(int(v) for v in np.round(wood[bins == k].mean(0))) for k in range(5)]
    grey = px[(sat < 0.45) & (lum > 60)]
    iron = tuple(int(v) for v in np.round(grey.mean(0)))
    iron_lit = tuple(int(v) for v in np.minimum(np.array(iron) * 1.5 + 10, 255))
    return woods, iron, iron_lit


def lamp_rows(frame=0):
    """LAMP with frame `frame`'s flame in its glass."""
    rows = list(LAMP)
    for j, flame in enumerate(FLAME[frame]):
        r = rows[FLAME_ROW + j]
        rows[FLAME_ROW + j] = r[:FLAME_COL] + flame + r[FLAME_COL + len(flame):]
    return rows


def lamp(frame=0):
    woods, iron, iron_lit = lamp_tones()
    rows = lamp_rows(frame)
    h, w = len(rows), len(rows[0])
    pal = {str(k): woods[k] for k in range(5)}
    pal.update({"i": iron, "j": iron_lit, "c": FLAME_CORE, "a": FLAME_AMBER, "e": FLAME_DEEP, "o": OUTLINE})
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        assert len(row) == w, "ragged row %d" % y
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), pal[ch] + (255,))
    return img, LAMP_ANCHOR


def string_y(c):
    """The string's row at tile column c (0..TILE_W), from its start at row 0."""
    return int(math.floor(c * RISE / TILE_W + SAG * math.sin(math.pi * c / TILE_W) + 0.5))


def bunting(along_y=False):
    """One segment of bunting, as bunting_x (the string falling to the right); bunting_y is its mirror, its pennants
    shaded the other way round before the flip so their lit column still ends up on the left."""
    h = RISE + SAG + max(FLAG_DEPTH) + 2
    img = Image.new("RGBA", (TILE_W, h), (0, 0, 0, 0))
    for c in range(TILE_W):
        img.putpixel((c, string_y(c)), ROPE + (255,))
        # Keep the string one piece where it steps two rows between columns.
        nxt = string_y(c + 1) if c + 1 < TILE_W else None
        if nxt is not None and nxt - string_y(c) > 1:
            img.putpixel((c, string_y(c) + 1), ROPE + (255,))
    for f, x0 in enumerate(FLAGS_AT):
        tones = BLUE if f % 2 == 0 else CREAM
        for k, depth in enumerate(FLAG_DEPTH):
            # Mirrored for bunting_y: its column k is drawn at the mirrored x, so the left column is k = 3 there.
            lit_k, shade_k = (3, 0) if along_y else (0, 3)
            c = x0 + k
            top = string_y(c) + 1
            for d in range(depth):
                tone = tones[1]
                if k == lit_k:
                    tone = tones[0]
                elif k == shade_k or d == depth - 1:
                    tone = tones[2]
                img.putpixel((c, top + d), tone + (255,))
    if along_y:
        img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        return img, (TILE_W, HANG)
    return img, (0, HANG)


SETS = {
    "lamp": lambda: [("lamp_house",) + decor_common.strip([lamp(k) for k in range(4)]) + (None, LAMP_GLOW)],
    "bunting": lambda: [("bunting_x",) + bunting() + (1.0, None), ("bunting_y",) + bunting(True) + (1.0, None)],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("which", nargs="?", default="all", choices=["all"] + list(SETS))
    ap.add_argument("--out")
    args = ap.parse_args()
    for key in SETS if args.which == "all" else [args.which]:
        for name, img, anchor, segment, glow in SETS[key]():
            if args.out:
                Path(args.out).mkdir(parents=True, exist_ok=True)
                img.save(Path(args.out) / (name + ".png"))
                path = Path(args.out) / (name + ".png")
            else:
                anim = {"frames": 4, "fps": LAMP_FPS, "glass": LAMP_GLASS} if name == "lamp_house" else {}
                path = decor_common.write_set(name, img, anchor, segment, glow, **anim)
            print("%-12s %dx%d anchor %s%s%s -> %s" % (name, img.width, img.height, anchor,
                                                      "" if segment is None else " segment %s" % segment,
                                                      "" if glow is None else " glow %s" % (glow,), path))


if __name__ == "__main__":
    main()
