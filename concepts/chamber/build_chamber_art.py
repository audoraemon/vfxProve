"""Builds res://assets/chamber/*.png from the PixelLab paintings in concepts/chamber/raw/ (God's Chamber step 6).

The room is ONE painting (raw/scene.png, 688 x 384) with the four stations painted in it, so camera, scale and light agree.
One art pixel is one design unit. The painting's x 28 is room x 0 (it is 48 units wider than a 16:9 frame).
Station rects in src/game/ui/chamber_layout.gd are fitted to where the painting has them; keep the two in step by hand.

  wall.png           840 x 360: the painting, its side edges faded out to the room's width
  awaken.png         the lit Rite Door as painted, cut to the door's own shape (door_mask), so a dim door darkens only itself
  awaken_closed.png  the same patch with the light put out: drawn over the painting while the god is not capped
  descend.png        the table's glowing map alone, so a dim table darkens the map
  tree.png, faith.png  empty (the painting already has them); they exist so the greybox is not drawn
  desk.png           840 x 77: the god's desk in the foreground, cut from raw/desk_scene.png
  life/*.png         step 7: the room's life -- glow masks (lit copies of the painting) and patches (unlit candles, cups,
                     the hourglass), see life() below
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


DOOR_ARCH = (121, 241, 81, 262)   # room x0, x1, the arch's top y, the step's bottom y: the door in its stone arch
DOOR_FEATHER = 9                  # px of soft edge round the door's shape


def door_mask(lit, closed):
    """The Rite Door's own shape in DOOR_ART's patch: its round-topped arch, and every pixel its light reaches (where the lit and
    the closed door differ), widened and feathered, never reaching the patch's edge -- so dimming or putting out the door darkens
    the door and its light, never a box round them."""
    w, h = lit.size
    ox, oy = DOOR_ART[0], DOOR_ART[1]
    x0, x1, top, bottom = DOOR_ARCH
    cx, r = (x0 + x1) / 2.0, (x1 - x0) / 2.0
    spring = top + r
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    lp, cp = lit.load(), closed.load()
    for y in range(h):
        for x in range(w):
            rx, ry = ox + x, oy + y
            inside = x0 <= rx <= x1 and (spring <= ry <= bottom or ry < spring and (rx - cx) ** 2 + (ry - spring) ** 2 <= r * r)
            changed = sum(abs(lp[x, y][i] - cp[x, y][i]) for i in range(3)) > 30
            if inside or changed:
                mp[x, y] = 255
    mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(DOOR_FEATHER / 2.0))
    edge = Image.new("L", (w, h), 0)
    edge.paste(255, (DOOR_FEATHER, DOOR_FEATHER, w - DOOR_FEATHER, h - DOOR_FEATHER))
    edge = edge.filter(ImageFilter.GaussianBlur(DOOR_FEATHER / 2.0))
    return ImageChops.multiply(mask, edge)


def door_patch(im, mask):
    out = im.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


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
            # Put out, the light becomes the wall's own cool stone: red over green, blue a little over red (no green, no teal).
            if v > 0.55 and warm:          # the crack, the runes, the lit edges
                d = 0.16 if v > 0.8 else 0.22
                px[x, y] = (int(255 * d), int(255 * d * 0.86), int(255 * d * 1.02), a)
            elif warm and s > 0.25:        # the glow on stone and floor
                g2 = (r * 0.3 + g * 0.5 + b * 0.2) * 0.62
                px[x, y] = (int(g2), int(g2 * 0.88), int(min(255, g2 * 1.05)), a)
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


# --- life (God's Chamber step 7, docs/superpowers/specs/2026-11-26-kak-chamber-life-design.md) ------------------------------------
# Masks and patches for the room's idle life and state objects, all cut from the painting (wall.png, desk.png as built above).
# Rects are room units (x, y, w, h), measured on the built wall.png (canvas x = room x + 100) and desk.png (room y 283 is its row
# 0); src/game/ui/chamber_life.gd holds the same rects, and tests/test_chamber_life.gd checks every file matches its rect's size.
#
# A glow mask is a lit copy of the painting: each pixel's own colour brightened by at most GLOW_BOOST, with alpha = how lit the
# pixel is (0..1). Drawn with a normal blend at alpha a, it brightens the painted light by a x weight x GLOW_BOOST, so the motion
# matches the art and never moves brightness by more than 25%. A patch is drawn opaque over the painting.

LIFE = os.path.join(OUT, "life")
GLOW_BOOST = 0.25

# The four candles the painting has on the altar, left to right, and the fifth cloned from the first (CANDLE_CLONE units to its
# left), so five candles can count the five tiers: (x, y, w, h) around each candle, flame included.
ALTAR_CANDLES = [(555, 205, 8, 25), (564, 203, 8, 25), (574, 195, 8, 33), (620, 203, 9, 33), (630, 207, 9, 29)]
# Candle 0 is candle 1 moved 9 units left, made CLONE_SHORTER rows shorter (rows from CLONE_CUT taken out of its wax) and stood
# CLONE_LOWER rows lower, so it does not read as a twin of its neighbour.
CANDLE_CLONE = (1, -9)
CLONE_SHORTER = 4
CLONE_LOWER = 2
CLONE_CUT = 217                    # the first of the wax rows taken out (room y of candle 1)
GLOWS = {
    # name: (layer, rect, kind, centre or None): kind picks the pixels that are lit; the centre fades the weight with distance.
    "brazier_glow": ("wall", (582, 186, 40, 48), "warm", (600, 210)),
    "shelf_glow": ("wall", (512, 162, 32, 32), "warm", None),
    "lantern_glow": ("wall", (298, 58, 34, 42), "warm", (315, 78)),
    "door_glow": ("wall", (140, 92, 70, 190), "warm", None),
    "tree_glow": ("wall", (-15, 130, 75, 185), "purple", None),
    "map_lit": ("wall", (215, 232, 200, 28), "blue", None),
    "desk_candle_glow": ("desk", (48, 283, 60, 60), "warm", (80, 292)),
}
BRAZIER_FLAME = (588, 190, 26, 30)
TROPHIES = [(489, 78, 28, 25), (521, 77, 28, 25)]
WINDOW = (280, 110, 75, 118)       # the window's glass: sky, sea and the town beyond
SKY_BOTTOM = 183                   # room y where the sky meets the sea
HORIZON_UP = 26                    # how far the Hunt's red-orange horizon glow reaches into the sky, and into the sea
HORIZON_DOWN = 9
MOON = (320, 120, 22, 30)
HOURGLASS = (606, 300, 30, 47)     # desk layer
HOURGLASS_UP = (306, 321)          # rows of the upper bulb, the neck, and the lower bulb (room y)
HOURGLASS_LOW = (326, 342)
HOURGLASS_X = (611, 630)           # columns inside the frame


def _hsv(c):
    return colorsys.rgb_to_hsv(c[0] / 255.0, c[1] / 255.0, c[2] / 255.0)


def _box(layer, rect):
    x, y, w, h = rect
    return (x + 100, y - (283 if layer == "desk" else 0), x + 100 + w, y - (283 if layer == "desk" else 0) + h)


def _lit_weight(kind, c):
    if c[3] < 8:
        return 0.0
    h, s, v = _hsv(c)
    if s < 0.2 and v > 0.85:
        return 1.0  # a light's white core
    if kind == "warm":
        if not (h < 0.15 or h > 0.95) or s < 0.2:
            return 0.0
        return max(0.0, min(1.0, (v - 0.3) / 0.6))
    if kind == "purple":
        if not (0.70 < h < 0.93) or s < 0.2:
            return 0.0
        return max(0.0, min(1.0, (v - 0.25) / 0.6))
    if kind == "blue":
        if not (0.5 < h < 0.72) or s < 0.3:
            return 0.0
        return max(0.0, min(1.0, (v - 0.4) / 0.5))
    return 0.0


def _lit(c, boost=GLOW_BOOST, tint=(1.0, 1.0, 1.0)):
    return tuple(min(255, int(round(c[i] * (1.0 + boost * tint[i])))) for i in range(3))


def glow_mask(canvas, layer, rect, kind, centre=None, exclude=()):
    """The lit copy of `rect`: alpha = how lit each pixel is (fading from `centre` when given), none inside `exclude` rects."""
    src = canvas.crop(_box(layer, rect))
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    x0, y0 = rect[0], rect[1]
    reach = max(rect[2], rect[3]) * 0.6
    for y in range(src.height):
        for x in range(src.width):
            rx, ry = x0 + x, y0 + y
            if any(ex[0] <= rx < ex[0] + ex[2] and ex[1] <= ry < ex[1] + ex[3] for ex in exclude):
                continue
            w = _lit_weight(kind, sp[x, y])
            if centre is not None:
                d = ((rx - centre[0]) ** 2 + (ry - centre[1]) ** 2) ** 0.5
                w *= max(0.25, 1.0 - d / reach)
            if w > 0.02:
                op[x, y] = _lit(sp[x, y]) + (int(round(255 * w)),)
    return out


def _candle_px(c):
    """A candle's own pixels: its wax and flame, warm and lit."""
    h, s, v = _hsv(c)
    return (h < 0.15 or h > 0.95) and s > 0.2 and v > 0.55 or (s < 0.12 and v > 0.9)


CLONE_PIXELS = set()  # room (x, y) of the fifth candle's pixels, filled by with_clone()


def _spans(canvas, rect):
    """Row -> (x0, x1) room columns of the candle in `rect` (its pixels from the leftmost to the rightmost). The fifth candle's
    are the pixels with_clone() put there, not whatever warm pixel lies in its rect."""
    out = {}
    px = canvas.load()
    x, y, w, h = rect
    clone = rect == ALTAR_CANDLES[0]
    for ry in range(y, y + h):
        xs = [rx for rx in range(x, x + w) if ((rx, ry) in CLONE_PIXELS if clone else _candle_px(px[rx + 100, ry]))]
        if xs:
            out[ry] = (min(xs), max(xs))
    return out


def with_clone(canvas):
    """The wall with the fifth altar candle: candle 1's pixels copied CANDLE_CLONE units left (the painting has four)."""
    out = canvas.copy()
    src, dx = ALTAR_CANDLES[CANDLE_CLONE[0]], CANDLE_CLONE[1]
    px, op = canvas.load(), out.load()
    CLONE_PIXELS.clear()
    for ry, (a, b) in _spans(canvas, src).items():
        if CLONE_CUT <= ry < CLONE_CUT + CLONE_SHORTER:
            continue  # the wax taken out
        dy = CLONE_LOWER + (CLONE_SHORTER if ry < CLONE_CUT else 0)
        for rx in range(a, b + 1):
            op[rx + dx + 100, ry + dy] = px[rx + 100, ry]
            CLONE_PIXELS.add((rx + dx, ry + dy))
    return out


def body_top(spans):
    """The first row where the candle is its full width (4 units or more): above it, the flame and the wick."""
    for ry in sorted(spans):
        a, b = spans[ry]
        if b - a + 1 >= 4:
            return ry
    return min(spans)


def candle_out(canvas, rect):
    """The candle in `rect` put out: the flame gone (each row filled from the wall beside it), a dark wick, the wax unlit."""
    patch = canvas.crop(_box("wall", rect))
    pp = patch.load()
    spans = _spans(canvas, rect)
    top = body_top(spans)
    x0, y0 = rect[0], rect[1]
    for ry, (a, b) in spans.items():
        if ry < top:
            left = pp[max(0, a - x0 - 1), ry - y0] if a - x0 - 1 >= 0 else pp[b - x0 + 1, ry - y0]
            right = pp[b - x0 + 1, ry - y0] if b - x0 + 1 < rect[2] else left
            for rx in range(a, b + 1):
                pp[rx - x0, ry - y0] = left if rx - a < (b - a + 1) / 2 else right
        else:
            for rx in range(a, b + 1):
                r, g, bl, al = pp[rx - x0, ry - y0]
                h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, bl / 255.0)
                # Unlit wax is still wax: warm (the brazier lights it), only darker; the pale lit tops gain their colour back.
                h = h if (h < 0.12 or h > 0.97) else 0.08
                r2, g2, b2 = colorsys.hsv_to_rgb(h, min(0.85, max(0.45, s * 1.1 + 0.12)), v * 0.62)
                pp[rx - x0, ry - y0] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), al)
    a, b = spans[top]
    mid = (a + b) // 2
    for ry in (top - 2, top - 1):
        pp[mid - x0, ry - y0] = (0x2a, 0x10, 0x1a, 255)
    WICKS[rect] = (mid, top - 2)
    return patch


WICKS = {}  # candle rect -> room (x, y) of its dark wick's top, where an unlit candle's smoke starts


def candle_lit(canvas, rect):
    """The candle as painted (the clone's lit picture: drawn over the wall, which has no candle there)."""
    patch = Image.new("RGBA", (rect[2], rect[3]), (0, 0, 0, 0))
    src = canvas.crop(_box("wall", rect))
    for ry, (a, b) in _spans(canvas, rect).items():
        for rx in range(a, b + 1):
            if (rx, ry) in CLONE_PIXELS:
                patch.putpixel((rx - rect[0], ry - rect[1]), src.getpixel((rx - rect[0], ry - rect[1])))
    return patch


def _trophy_px(c):
    h, s, v = _hsv(c)
    return (h < 0.15 or h > 0.95) and v > 0.16 and s > 0.2


def trophy(canvas, rect, how):
    """A cup alone: "gold" (bright, as a conquered town's), "dull" (dark, unsaturated) or "glint" (near white, for the sweep)."""
    src = canvas.crop(_box("wall", rect))
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    for y in range(src.height):
        for x in range(src.width):
            c = sp[x, y]
            if not _trophy_px(c):
                continue
            h, s, v = _hsv(c)
            if how == "gold":
                rgb = colorsys.hsv_to_rgb(0.115, min(1.0, s * 1.1 + 0.18), min(1.0, v * 1.45 + 0.1))
            elif how == "dull":
                rgb = colorsys.hsv_to_rgb(h, s * 0.3, v * 0.62)
            else:
                rgb = colorsys.hsv_to_rgb(0.13, 0.25, 1.0)
            op[x, y] = tuple(int(round(k * 255)) for k in rgb) + (255,)
    return out


def brazier_flame(canvas):
    src = canvas.crop(_box("wall", BRAZIER_FLAME))
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    sp, op = src.load(), out.load()
    for y in range(src.height):
        for x in range(src.width):
            h, s, v = _hsv(sp[x, y])
            if v > 0.75 and ((h < 0.12 or h > 0.95) and s > 0.5 or s < 0.3 and v > 0.9):
                op[x, y] = sp[x, y][:3] + (255,)
    return out


def _sky_px(c, ry):
    h, s, v = _hsv(c)
    return ry < SKY_BOTTOM and 0.55 < h < 0.72 and s > 0.35


def window_masks(canvas):
    """The sky turned red (the Hunt), the moon dimmed, and the stars in three groups that twinkle apart."""
    box = _box("wall", WINDOW)
    src = canvas.crop(box)
    sp = src.load()
    red = Image.new("RGBA", src.size, (0, 0, 0, 0))
    stars = [Image.new("RGBA", src.size, (0, 0, 0, 0)) for _ in range(3)]
    rp = red.load()
    n = 0
    for y in range(src.height):
        for x in range(src.width):
            c = sp[x, y]
            ry, rx = WINDOW[1] + y, WINDOW[0] + x
            h, s, v = _hsv(c)
            in_moon = MOON[0] <= rx < MOON[0] + MOON[2] and MOON[1] <= ry < MOON[1] + MOON[3]
            if _sky_px(c, ry):
                rgb = colorsys.hsv_to_rgb(0.99, 0.78, min(1.0, v * 0.8 + 0.03))  # a blood-red night
                rp[x, y] = tuple(int(k * 255) for k in rgb) + (255,)
            near = [sp[x + dx, y + dy] for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2))
                    if 0 <= x + dx < src.width and 0 <= y + dy < src.height]
            if ry < SKY_BOTTOM and not in_moon and len(near) == 4 and all(_sky_px(k, ry) for k in near)                     and v > max(_hsv(k)[2] for k in near) + 0.2:
                stars[n % 3].putpixel((x, y), (255, 255, 255, 255))
                n += 1  # a star: a lone pixel much brighter than the sky beside it
    moon = canvas.crop(_box("wall", MOON))
    mp = moon.load()
    blood = Image.new("RGBA", moon.size, (0, 0, 0, 0))
    bp = blood.load()
    for y in range(moon.height):
        for x in range(moon.width):
            h, s, v = _hsv(mp[x, y])
            if v > 0.45 and s < 0.6:  # the crescent and its pale rim
                rgb = colorsys.hsv_to_rgb(0.0, 0.78, min(1.0, v * 0.92))
                bp[x, y] = tuple(int(k * 255) for k in rgb) + (255,)
    # A red-orange glow on the horizon: the sky just above it and the sea just under it, fading away from the line.
    glow = Image.new("RGBA", src.size, (0, 0, 0, 0))
    gp = glow.load()
    for y in range(src.height):
        ry = WINDOW[1] + y
        reach = HORIZON_UP if ry < SKY_BOTTOM else HORIZON_DOWN
        w = 1.0 - abs(ry - SKY_BOTTOM) / float(reach)
        if w <= 0.0:
            continue
        for x in range(src.width):
            h, s, v = _hsv(sp[x, y])
            if 0.5 < h < 0.75 and s > 0.3:  # sky and sea, not the frame or the town
                rgb = colorsys.hsv_to_rgb(0.035, 0.85, min(1.0, 0.45 + v * 0.9))
                gp[x, y] = tuple(int(k * 255) for k in rgb) + (int(255 * w * w),)
    return red, blood, glow, stars, n


def map_pins(canvas):
    """The town pins on the table's map, in two groups that twinkle apart (near white where they are lit)."""
    rect = GLOWS["map_lit"][1]
    src = canvas.crop(_box("wall", rect))
    sp = src.load()
    outs = [Image.new("RGBA", src.size, (0, 0, 0, 0)) for _ in range(2)]
    for y in range(src.height):
        for x in range(src.width):
            h, s, v = _hsv(sp[x, y])
            if v > 0.8 and (s < 0.45 or h < 0.15):
                outs[0 if (rect[0] + x) < 320 else 1].putpixel((x, y), (255, 250, 228, 255))
    return outs


def _sand_px(c):
    h, s, v = _hsv(c)
    return 0.02 < h < 0.1 and s > 0.35 and v > 0.38


def hourglass(deskim):
    """The hourglass with its sand taken out (glass in its place), the sand of each bulb as a fill drawn up to a level, and the
    glass turned red for the Hunt."""
    box = _box("desk", HOURGLASS)
    src = deskim.crop(box)
    sp = src.load()
    empty = src.copy()
    ep = empty.load()
    low = Image.new("RGBA", src.size, (0, 0, 0, 0))
    up = Image.new("RGBA", src.size, (0, 0, 0, 0))
    lp, upp = low.load(), up.load()
    glass = (0x31, 0x22, 0x2c, 255)
    sand = [(0xc1, 0x8e, 0x60, 255), (0xac, 0x64, 0x36, 255), (0x95, 0x55, 0x32, 255), (0x7e, 0x50, 0x38, 255)]
    x0, y0 = HOURGLASS[0], HOURGLASS[1]
    last = {}
    for (r0, r1), fill, fp in ((HOURGLASS_UP, up, upp), (HOURGLASS_LOW, low, lp), ((HOURGLASS_UP[1], HOURGLASS_LOW[0]), None, None)):
        for ry in range(r0, r1 + 1):
            # The glass's walls are its grey outline pixels; the bulb is what lies between them on the row.
            walls = [rx for rx in range(HOURGLASS_X[0] - 2, HOURGLASS_X[1] + 2) if _hsv(sp[rx - x0, ry - y0])[1] < 0.15
                     and 0.4 < _hsv(sp[rx - x0, ry - y0])[2] < 0.6]
            left = [rx for rx in walls if rx < 620]
            right = [rx for rx in walls if rx > 620]
            if left and right and min(right) - max(left) >= 2:
                a, b = max(left) + 1, min(right) - 1
                last[ry] = (a, b)
            elif ry - 1 in last:
                a, b = last[ry - 1]  # an outline pixel not grey on this row: the bulb runs on as on the row above
                last[ry] = (a, b)
            else:
                continue
            for rx in range(a, b + 1):
                c = sp[rx - x0, ry - y0]
                hh, ss, vv = _hsv(c)
                if vv > 0.85 and ss < 0.45:
                    continue  # the glass's own glint stays over the sand
                ep[rx - x0, ry - y0] = glass  # the bulbs and the neck emptied: plain glass, the sand drawn over it by level
                if fp is not None:
                    k = (0 if ry == r0 else 1) + (1 if rx > (a + b) // 2 + 2 else 0) + (1 if rx == b else 0)
                    fp[rx - x0, ry - y0] = sand[min(k, 3)]
    # Under the Hunt the sand is red, and a lit copy of it (GLOW_BOOST brighter) pulses over it.
    red_sand = dict(zip(sand, [(0xc8, 0x30, 0x24, 255), (0xa8, 0x1e, 0x1a, 255), (0x8a, 0x16, 0x16, 255), (0x6c, 0x10, 0x12, 255)]))
    reds = []
    for fill in (low, up):
        r = Image.new("RGBA", src.size, (0, 0, 0, 0))
        rp, fp = r.load(), fill.load()
        for y in range(src.height):
            for x in range(src.width):
                if fp[x, y][3]:
                    rp[x, y] = red_sand.get(fp[x, y], fp[x, y])
        reds.append(r)
    glow = Image.new("RGBA", src.size, (0, 0, 0, 0))
    gp, rp = glow.load(), reds[0].load()
    for y in range(src.height):
        for x in range(src.width):
            if rp[x, y][3]:
                gp[x, y] = _lit(rp[x, y]) + (255,)
    return empty, low, up, reds[0], reds[1], glow


def _placed(canvas, patch, rect):
    """The wall with `patch` drawn over it at `rect`."""
    out = canvas.copy()
    out.alpha_composite(patch, (rect[0] + 100, rect[1]))
    return out


# Each station's silhouette is traced from the painting's own pixels (round 3b), within a box round it (room units): the pixels that
# look like the object, the connected piece of them that holds the seed, closed and filled. Seeds and boxes are the only numbers.
TRACE = {
    # key: (box x0, y0, x1, y1 inclusive, seed)
    "descend": ((205, 228, 430, 268), (316, 246)),
    "tree": ((-8, 131, 53, 286), (30, 200)),
    "awaken": ((128, 84, 236, 251), (150, 180)),
    "faith": ((549, 226, 639, 300), (590, 232)),
}
HOVER_BOOST = GLOW_BOOST                           # a hovered object is its own picture this much brighter
RIM = (236, 196, 112)                              # the hover rim's warm gold
RIM_ALPHA = (0.85, 0.35)                           # its inner and outer pixel
VIGNETTE_MAX = 0.2                                 # the darkest the vignette gets (corners and the ceiling)


def _hsv_array(im):
    import numpy as np
    a = np.asarray(im.convert("RGB"), dtype=np.float64) / 255.0
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(axis=2), a.min(axis=2)
    d = mx - mn
    h = np.zeros_like(mx)
    nz = d > 1e-9
    rr = nz & (mx == r)
    gg = nz & (mx == g) & ~rr
    bb = nz & ~rr & ~gg
    h[rr] = ((g - b)[rr] / d[rr]) % 6.0
    h[gg] = (b - r)[gg] / d[gg] + 2.0
    h[bb] = (r - g)[bb] / d[bb] + 4.0
    h = h / 6.0
    s_ = np.where(mx > 1e-9, d / np.maximum(mx, 1e-9), 0.0)
    return h, s_, mx


def _traced(like, box, seed):
    """The piece of `like` (a bool array over the wall canvas) inside `box` that holds `seed`, closed (3x3), holes filled, then opened
    (3x3) so no 1-px spur makes a rim corner."""
    import numpy as np
    from scipy import ndimage
    x0, y0, x1, y1 = box
    inside = np.zeros_like(like)
    inside[y0:y1 + 1, x0 + 100:x1 + 101] = True
    m = like & inside
    m = ndimage.binary_closing(m, structure=np.ones((3, 3)), iterations=1) & inside
    keep = _piece(m, seed)
    keep = ndimage.binary_fill_holes(keep)
    keep = ndimage.binary_opening(keep, structure=np.ones((3, 3)))
    return _piece(keep, seed)


def _piece(m, seed):
    """The connected piece of `m` nearest the seed (the largest piece found within 6 px of it)."""
    import numpy as np
    from scipy import ndimage
    lab, _ = ndimage.label(m)
    sx, sy = seed[0] + 100, seed[1]
    near = lab[sy - 6:sy + 7, sx - 6:sx + 7]
    ids, counts = np.unique(near[near > 0], return_counts=True)
    assert len(ids), ("no traced pixel near the seed", seed)
    return lab == ids[np.argmax(counts)]


DOOR_SNAP = 4
TABLE_REACH = 18                   # how far past the map's ends the table's frame may run to its dark outline
ALTAR_FLOOR = 286                  # room y from which warm pixels left of the altar are the floor


def _arch_mask():
    import numpy as np
    from PIL import ImageDraw
    m = Image.new("L", (840, 360), 0)
    d = ImageDraw.Draw(m)
    x0, x1, top, bottom = DOOR_ARCH
    r = (x1 - x0) / 2.0
    d.ellipse((x0 + 100, top, x1 + 100, top + 2 * r), fill=255)
    d.rectangle((x0 + 100, top + r, x1 + 100, bottom), fill=255)
    return np.asarray(m) > 127


def _snapped(shape, v, reach):
    """`shape` with each row's left and right ends moved to the strongest change of light (|v[x] - v[x-1]|) within `reach` px, then
    each end smoothed as the median of its row and the rows either side."""
    import numpy as np
    grad = np.abs(np.diff(v, axis=1, prepend=v[:, :1]))
    rows = [y for y in range(shape.shape[0]) if shape[y].any()]
    ends = {}
    for y in rows:
        xs = np.where(shape[y])[0]
        a, b = xs.min(), xs.max()
        la = max(1, a - reach) + int(np.argmax(grad[y, max(1, a - reach):a + reach + 1]))
        rb = b - reach + int(np.argmax(grad[y, b - reach + 1:b + reach + 2]))
        ends[y] = (la, rb)
    out = np.zeros_like(shape)
    for y in rows:
        trio = [ends[k] for k in (y - 1, y, y + 1) if k in ends]
        a = sorted(e[0] for e in trio)[len(trio) // 2]
        b = sorted(e[1] for e in trio)[len(trio) // 2]
        out[y, a:b + 1] = True
    return out


def silhouette(key):
    """The station's shape as an L mask over the whole wall canvas (840 x 360), traced from the painting:
    - the World Table: its map's blue (the pins filled in), widened by the table's frame, and the front slab under it;
    - the Ability Tree: the stone's lit purple, which a dark seam parts from the wall and the shelves;
    - the Rite Door: the doors' warm wood and their light, inside the stone arch;
    - the Faith Altar: the altar's lit stone, cloth and step left of the dark block (each row from its first lit pixel to the
      painting's edge), the brazier's dark iron bowl, its flame and the candles by their own pixels."""
    import numpy as np
    from scipy import ndimage
    canvas = with_clone(wall(raw("scene")))
    h, s_, v = _hsv_array(canvas)
    box, seed = TRACE[key]
    warm = ((h < 0.14) | (h > 0.95)) & (s_ > 0.2)
    if key == "descend":
        blue = (h > 0.5) & (h < 0.72) & (s_ > 0.3) & (v > 0.4)
        mp = _traced(blue, box, seed)
        mp = ndimage.binary_closing(mp, structure=np.ones((5, 5)), iterations=2)
        mp = ndimage.binary_fill_holes(mp)
        mp = ndimage.binary_dilation(mp, structure=np.ones((3, 3)), iterations=2)   # the frame round the map
        widths = mp.sum(axis=1)
        bottom = int(np.where(widths >= 0.9 * widths.max())[0].max())  # the map's front edge (its light spilling lower is not table)
        mp[bottom + 1:, :] = False
        cols = np.where(mp[bottom])[0]
        # The front slab under the map runs from the dark outline the painting draws at its left end to the one at its right (looked
        # for within TABLE_REACH px of the map's bottom corners); the table's top is then the hull of the map and the slab -- its
        # edges are straight in the painting.
        slab = np.zeros_like(mp)
        for y in range(bottom + 1, min(box[3], bottom + 7) + 1):
            a, b = cols.min(), cols.max()
            for k in range(1, TABLE_REACH + 1):
                if v[y, cols.min() - k] < 0.14:
                    a = cols.min() - k + 1
                    break
            for k in range(1, TABLE_REACH + 1):
                if v[y, cols.max() + k] < 0.14:
                    b = cols.max() + k - 1
                    break
            slab[y, a:b + 1] = True
        from scipy.spatial import ConvexHull
        from PIL import ImageDraw
        pts = np.argwhere(mp | slab)[:, ::-1]
        hull = pts[ConvexHull(pts).vertices]
        poly = Image.new("L", (840, 360), 0)
        ImageDraw.Draw(poly).polygon([tuple(map(int, p)) for p in hull], fill=255)
        mp = np.asarray(poly) > 127
        out = mp
    elif key == "tree":
        out = _traced(v >= 0.2, box, seed)
    elif key == "awaken":
        # The doors and the arch's stones are one purple-grey, and the dark joint round the doors is broken, so colour cannot part
        # them: the arch's outline is found instead on the painting's own edges -- each row's sides moved to the strongest change of
        # light within DOOR_SNAP px of the round-topped arch, the rows then smoothed (median of three).
        out = _snapped(_arch_mask(), v, DOOR_SNAP)
    else:  # faith
        x0, y0, x1, y1 = box
        lit = v >= 0.27
        floor = np.zeros_like(lit)
        floor[ALTAR_FLOOR:, :] = warm[ALTAR_FLOOR:, :]  # below the step the warm floorboards are not the altar
        lit &= ~floor
        out = np.zeros_like(lit)
        for y in range(y0, y1 + 1):
            xs = np.where(lit[y, x0 + 100:x1 + 101])[0]
            if len(xs):
                out[y, x0 + 100 + xs.min():x1 + 101] = True
        # each row from its first lit pixel: a lone lit speck must not pull the edge out, so take the median of three rows
        left = [np.argmax(out[y]) if out[y].any() else None for y in range(360)]
        for y in range(y0 + 1, y1):
            trio = [left[k] for k in (y - 1, y, y + 1) if left[k] is not None]
            if len(trio) == 3:
                out[y, :] = False
                out[y, sorted(trio)[1]:x1 + 101] = True
        mp = Image.fromarray((out * 255).astype("uint8"), "L").copy()
        mpx = mp.load()
        for rect in ALTAR_CANDLES:
            for ry, (a, b) in _spans(canvas, rect).items():
                for rx in range(a, b + 1):
                    mpx[rx + 100, ry] = 255
        fl = brazier_flame(canvas)
        for y in range(fl.height):
            for x in range(fl.width):
                if fl.getpixel((x, y))[3]:
                    mpx[BRAZIER_FLAME[0] + x + 100, BRAZIER_FLAME[1] + y] = 255
        bowl = (v < 0.27)
        bowl_m = np.zeros_like(bowl)
        bowl_m[214:233, 586 + 100:617 + 100] = bowl[214:233, 586 + 100:617 + 100]
        out = (np.asarray(mp) > 127) | bowl_m
        out = ndimage.binary_closing(out, structure=np.ones((3, 3)))
        out = ndimage.binary_fill_holes(out)
    return Image.fromarray((out * 255).astype("uint8"), "L")


def in_front(key):
    """What stands in front of the station (its hover and rim are hidden there): the World Table before the Rite Door; the desk's
    books before the altar's foot (from ALTAR_FLOOR down, where the plinth meets the floor out of sight)."""
    if key == "awaken":
        # the table's top, and its slab, legs and shadow below it down to the floor
        import numpy as np
        top = np.asarray(silhouette("descend")) > 127
        under = top.copy()
        for x in np.where(top.any(axis=0))[0]:
            under[np.where(top[:, x])[0].max():300, x] = True
        return Image.fromarray((under * 255).astype("uint8"), "L").filter(ImageFilter.MaxFilter(3))
    m = Image.new("L", (840, 360), 0)
    if key == "faith":
        m.paste(255, (0, ALTAR_FLOOR - 1, 840, 360))
    return m


def _bbox_rect(mask, margin):
    x0, y0, x1, y1 = mask.getbbox()
    x0, y0 = max(0, x0 - margin), max(0, y0 - margin)
    x1, y1 = min(840, x1 + margin), min(360, y1 + margin)
    return (x0 - 100, y0, x1 - x0, y1 - y0)


def hover_pieces(key, canvas, lit_door):
    """hover_<key>: the object's own picture, GLOW_BOOST brighter, inside its silhouette (a 1-px soft edge); rim_<key>: a warm 2-px rim
    just outside it (the inner pixel strong, the outer faint)."""
    sil = silhouette(key)
    src = canvas.copy()
    if key == "awaken":
        src.alpha_composite(lit_door, (DOOR_ART[0] + 100, DOOR_ART[1]))
    rect = _bbox_rect(sil, 2)
    box = _box("wall", rect)
    front = in_front(key)
    soft = ImageChops.subtract(sil.filter(ImageFilter.GaussianBlur(0.6)), front).crop(box)
    pic = src.crop(box)
    glow = Image.new("RGBA", pic.size, (0, 0, 0, 0))
    gp, pp, sp = glow.load(), pic.load(), soft.load()
    for y in range(pic.height):
        for x in range(pic.width):
            if sp[x, y] > 4:
                glow.putpixel((x, y), _lit(pp[x, y], HOVER_BOOST) + (sp[x, y],))
    d1 = sil.filter(ImageFilter.MaxFilter(3))
    d2 = sil.filter(ImageFilter.MaxFilter(5))
    rim_rect = _bbox_rect(sil, 4)
    rbox = _box("wall", rim_rect)
    rim = Image.new("RGBA", (rim_rect[2], rim_rect[3]), (0, 0, 0, 0))
    s0, s1, s2, f0 = sil.crop(rbox).load(), d1.crop(rbox).load(), d2.crop(rbox).load(), front.crop(rbox).load()
    for y in range(rim.height):
        for x in range(rim.width):
            if s0[x, y] > 127 or f0[x, y] > 0:
                continue
            if s1[x, y] > 127:
                rim.putpixel((x, y), RIM + (int(255 * RIM_ALPHA[0]),))
            elif s2[x, y] > 127:
                rim.putpixel((x, y), RIM + (int(255 * RIM_ALPHA[1]),))
    return (rect, glow), (rim_rect, rim)


def vignette():
    """The room's value hierarchy: the frame's corners and the ceiling darkened by up to VIGNETTE_MAX, the four stations and the lantern
    left alone (their shapes, widened and feathered), so the eye goes to the lit objects and the map table stays the brightest."""
    from PIL import ImageDraw
    keep = Image.new("L", (840, 360), 0)
    for key in ("descend", "tree", "faith", "awaken"):
        keep = ImageChops.lighter(keep, silhouette(key))
    ImageDraw.Draw(keep).rectangle((298 + 100, 40, 332 + 100, 100), fill=255)  # the lantern hangs from the ceiling: keep its light
    keep = keep.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(5))
    out = Image.new("RGBA", (840, 360), (0, 0, 0, 0))
    op, kp = out.load(), keep.load()

    def smooth(a, b, x):
        t = min(1.0, max(0.0, (x - a) / (b - a)))
        return t * t * (3.0 - 2.0 * t)

    for y in range(360):
        for x in range(840):
            rx = x - 100
            nx, ny = (rx - 320) / 320.0, (y - 180) / 180.0
            corner = VIGNETTE_MAX * smooth(0.45, 0.9, (0.6 * nx * nx + 0.4 * ny * ny) ** 0.5)
            ceiling = 0.18 * (1.0 - smooth(20.0, 80.0, y))
            a = min(VIGNETTE_MAX, max(corner, ceiling)) * (1.0 - kp[x, y] / 255.0)
            op[x, y] = (0, 0, 0, int(255 * a))
    return out


def life():
    """Writes assets/chamber/life/*.png and returns {name: (layer, rect, image)} for the contact sheet."""
    os.makedirs(LIFE, exist_ok=True)
    base = wall(raw("scene"))
    canvas = with_clone(base)
    deskim = desk()
    out = {}
    for name, (layer, rect, kind, centre) in GLOWS.items():
        exclude = ALTAR_CANDLES if name == "brazier_glow" else ()
        out[name] = (layer, rect, glow_mask(deskim if layer == "desk" else canvas, layer, rect, kind, centre, exclude))
    for i, rect in enumerate(ALTAR_CANDLES):
        out["candle_glow_%d" % i] = ("wall", rect, glow_mask(canvas, "wall", rect, "warm"))
        out["candle_out_%d" % i] = ("wall", rect, candle_out(canvas, rect))
        # The unlit wax in the brazier's light: a lit copy of the put-out candle, flickering with the brazier.
        out["candle_warm_%d" % i] = ("wall", rect, glow_mask(_placed(canvas, out["candle_out_%d" % i][2], rect), "wall", rect, "warm"))
    out["candle_lit_0"] = ("wall", ALTAR_CANDLES[0], candle_lit(canvas, ALTAR_CANDLES[0]))
    out["brazier_flame"] = ("wall", BRAZIER_FLAME, brazier_flame(canvas))
    for i, rect in enumerate(TROPHIES):
        for how in ("gold", "dull", "glint"):
            out["trophy_%s_%d" % (how, i)] = ("wall", rect, trophy(canvas, rect, how))
    red, blood, horizon, stars, n = window_masks(canvas)
    out["window_red"] = ("wall", WINDOW, red)
    out["window_moon_red"] = ("wall", MOON, blood)
    out["window_horizon"] = ("wall", WINDOW, horizon)
    for i, im in enumerate(stars):
        out["window_stars_%d" % i] = ("wall", WINDOW, im)
    for i, im in enumerate(map_pins(canvas)):
        out["map_pins_%d" % i] = ("wall", GLOWS["map_lit"][1], im)
    door = room_crop(raw("scene"), DOOR_ART)
    for key in ("descend", "tree", "faith", "awaken"):
        (grect, gim), (rrect, rim) = hover_pieces(key, base, door)
        out["hover_" + key] = ("wall", grect, gim)
        out["rim_" + key] = ("wall", rrect, rim)
    out["vignette"] = ("wall", (-100, 0, 840, 360), vignette())
    empty, low, up, low_red, up_red, glow = hourglass(deskim)
    out["hourglass_empty"] = ("desk", HOURGLASS, empty)
    out["hourglass_sand_low"] = ("desk", HOURGLASS, low)
    out["hourglass_sand_up"] = ("desk", HOURGLASS, up)
    out["hourglass_sand_low_red"] = ("desk", HOURGLASS, low_red)
    out["hourglass_sand_up_red"] = ("desk", HOURGLASS, up_red)
    out["hourglass_sand_glow"] = ("desk", HOURGLASS, glow)
    for name, (layer, rect, im) in out.items():
        assert im.size == (rect[2], rect[3]), (name, im.size, rect)
        im.save(os.path.join(LIFE, name + ".png"))
    for old in os.listdir(LIFE):  # a piece no longer built (and its import file) goes
        if old.endswith(".png") and old[:-4] not in out:
            os.remove(os.path.join(LIFE, old))
            if os.path.exists(os.path.join(LIFE, old + ".import")):
                os.remove(os.path.join(LIFE, old + ".import"))
    print("life:", len(out), "pieces,", n, "stars; wicks", [WICKS[r] for r in ALTAR_CANDLES])
    print("hover rects:", {k: v[1] for k, v in out.items() if k.startswith(("hover_", "rim_"))})
    return out, base, canvas, deskim


def contact_sheet(path, pieces, base, canvas, deskim, scale=3):
    """Each piece at `scale`x nearest: the painting there, the piece alone, and the piece over the painting."""
    from PIL import ImageDraw
    rows = []
    for name, (layer, rect, im) in sorted(pieces.items()):
        src = (deskim if layer == "desk" else base).crop(_box(layer, rect))
        bg = Image.new("RGBA", src.size, (20, 20, 26, 255))
        if layer == "desk":
            bg.alpha_composite(src)
            src = bg.copy()
        alone = Image.new("RGBA", im.size, (40, 40, 48, 255))
        alone.alpha_composite(im)
        over = src.copy()
        if name in ("candle_glow_0", "candle_out_0"):
            over.alpha_composite(pieces["candle_lit_0"][2])  # the fifth candle is drawn by the game, not painted
        over.alpha_composite(im)
        rows.append((name, [src, alone, over]))
    pad, label = 6, 14
    width = max(sum(i.width * scale for i in r) + pad * 4 for _, r in rows)
    width = max(width, 420)
    height = sum(max(i.height for i in r) * scale + label + pad for _, r in rows) + pad
    sheet = Image.new("RGB", (width, height), (12, 12, 16))
    d = ImageDraw.Draw(sheet)
    y = pad
    for name, r in rows:
        d.text((pad, y), "%s  %s %s  (painting | piece | piece over painting)" % (name, pieces[name][0], pieces[name][1]),
               fill=(220, 200, 120))
        x = pad
        for im in r:
            big = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
            sheet.paste(big.convert("RGB"), (x, y + label))
            x += big.width + pad
        y += max(i.height for i in r) * scale + label + pad
    sheet.save(path)
    print("contact sheet", path, sheet.size)

if __name__ == "__main__":
    # `python build_chamber_art.py` builds every piece; `... life [sheet.png]` only the life pass (and its contact sheet).
    import sys
    if sys.argv[1:2] != ["life"]:
        os.makedirs(OUT, exist_ok=True)
        scene = raw("scene")
        door = room_crop(scene, DOOR_ART)
        empty = Image.new("RGBA", (2, 2), (0, 0, 0, 0))
        shut = closed_door(door)
        shape = door_mask(door, shut)
        pieces = {"wall": wall(scene), "awaken": door_patch(door, shape), "awaken_closed": door_patch(shut, shape),
                  "descend": map_only(room_crop(scene, TABLE)), "tree": empty, "faith": empty, "desk": desk()}
        for name, im in pieces.items():
            im.save(os.path.join(OUT, name + ".png"))
            print(name, im.size)
    built = life()
    if len(sys.argv) > 2:
        contact_sheet(sys.argv[2], *built)
