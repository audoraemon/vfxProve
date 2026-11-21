"""Builds res://assets/chamber/*.png from the PixelLab paintings in concepts/chamber/raw/ (God's Chamber step 6).

The room is ONE painting (raw/scene.png, 688 x 384) with the four stations painted in it, so camera, scale and light agree.
One art pixel is one design unit. The painting's x 28 is room x 0 (it is 48 units wider than a 16:9 frame).
Station rects in src/game/ui/chamber_layout.gd are fitted to where the painting has them; keep the two in step by hand.

  wall.png           840 x 360: the painting, its side edges faded out to the room's width
  awaken.png         the lit Rite Door as painted (feathered), so a dim door darkens only itself
  awaken_closed.png  the same patch with the light put out: drawn over the painting while the god is not capped
  descend.png        the table's glowing map alone, so a dim table darkens the map
  tree.png, faith.png  empty (the painting already has them); they exist so the greybox is not drawn
  desk.png           840 x 77: the god's desk in the foreground, cut from raw/desk_scene.png
"""
import colorsys
import os
from PIL import Image, ImageChops, ImageEnhance, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "raw")
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "chamber"))
OX = 28                          # painting x of room x 0 (4 left of centre, so the altar is whole on a 16:9 screen)
SIDE = 100 - OX                  # room x -100 is canvas x 0; where the painting starts on the canvas
DOOR_ART = (116, 62, 132, 226)   # room rect of the door with its step and the light it throws (ChamberLayout "art")
TABLE = (207, 232, 218, 88)      # room rect of the table (ChamberLayout descend "rect")
DESK_ROWS = (255, 332)           # rows of raw/desk_scene.png drawn at room y 283..360
DESK_TOP = 290                   # the slab's top edge in raw/desk_scene.png
DESK_THINGS = [(72, 252, 128, 290), (136, 244, 176, 290), (524, 262, 664, 290)]  # candle, inkwell, books + hourglass


def raw(name):
    return Image.open(os.path.join(RAW, name + ".png")).convert("RGBA")


def room_crop(scene, rect):
    x, y, w, h = rect
    return scene.crop((x + OX, y, x + OX + w, y + h))


def feather(im, px=6):
    """Alpha falling to 0 over the outer px pixels, so a tinted or swapped patch has no hard box edge."""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    mask.paste(255, (px, px, w - px, h - px))
    mask = mask.filter(ImageFilter.GaussianBlur(px / 2.0))
    out = im.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def wall(scene):
    src = scene.crop((0, 0, 688, 360))
    out = Image.new("RGBA", (840, 360), (4, 4, 8, 255))
    out.paste(src, (SIDE, 0))
    for side, col_x in ((0, 0), (1, src.width - 1)):
        col = src.crop((col_x, 0, col_x + 1, 360))
        width = SIDE if side == 0 else 840 - SIDE - src.width
        for n in range(width):
            k = 1.0 - n / float(width)
            strip = ImageEnhance.Brightness(col).enhance(k * k)
            out.paste(strip, (SIDE - 1 - n if side == 0 else SIDE + src.width + n, 0))
    return out


def closed_door(patch):
    """The lit door with its light put out: bright warm pixels fall to the stone around them, the glow cools and dims."""
    out = patch.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            hh, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            warm = hh < 0.17 or hh > 0.95
            if v > 0.55 and warm:          # the crack, the runes, the lit edges
                d = 0.16 if v > 0.8 else 0.22
                px[x, y] = (int(255 * d), int(255 * d * 0.95), int(255 * d * 0.95), a)
            elif warm and s > 0.25:        # the glow on stone and floor
                g2 = (r * 0.3 + g * 0.5 + b * 0.2) * 0.62
                px[x, y] = (int(g2 * 0.95), int(g2), int(min(255, g2 * 1.08)), a)
    return out


def map_only(table):
    out = table.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            if not (0.5 <= h <= 0.72 and s > 0.3 and v > 0.4 and y < 40):
                px[x, y] = (r, g, b, 0)
    return out


def desk():
    src = raw("desk_scene")
    keep = Image.new("L", src.size, 0)
    keep.paste(255, (0, DESK_TOP, src.width, src.height))
    for box in DESK_THINGS:
        keep.paste(255, box)
    # The candle's painted halo is a flat disc: drop it, keep the candle.
    px = src.load()
    kp = keep.load()
    halo = [px[80, 262][:3], px[92, 272][:3]]
    for y in range(DESK_THINGS[0][1], DESK_TOP):
        for x in range(DESK_THINGS[0][0], DESK_THINGS[0][2]):
            c = px[x, y][:3]
            if any(sum(abs(c[i] - hc[i]) for i in range(3)) < 24 for hc in halo):
                kp[x, y] = 0
    src.putalpha(ImageChops.multiply(src.getchannel("A"), keep))
    band = src.crop((0, DESK_ROWS[0], 688, DESK_ROWS[1]))
    out = Image.new("RGBA", (840, band.height), (0, 0, 0, 0))
    at = 76  # the desk is centred on the room, whatever the painting's offset
    out.paste(band, (at, 0))
    top = DESK_TOP - DESK_ROWS[0]
    for side, col_x in ((0, 0), (1, band.width - 1)):   # the slab runs on to the room's edges
        col = band.crop((col_x, top, col_x + 1, band.height))
        for n in range(at):
            out.paste(col, (at - 1 - n if side == 0 else at + band.width + n, top))
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    scene = raw("scene")
    door = room_crop(scene, DOOR_ART)
    empty = Image.new("RGBA", (2, 2), (0, 0, 0, 0))
    pieces = {"wall": wall(scene), "awaken": feather(door), "awaken_closed": feather(closed_door(door)),
              "descend": map_only(room_crop(scene, TABLE)), "tree": empty, "faith": empty, "desk": desk()}
    for name, im in pieces.items():
        im.save(os.path.join(OUT, name + ".png"))
        print(name, im.size)
