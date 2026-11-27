"""God's Chamber blockouts for the ChatGPT painting pass (step 6 of the Chamber order).

Writes three guide images and their prompts to concepts/GPT/chamber/. The rects are copied from
src/game/ui/chamber_layout.gd (design units); keep the two in step by hand.

  chamber_1_room.png    the whole room, 840 x 360 units at 2 px a unit: the style anchor
  chamber_2_empty.png   the same room with the stations removed: becomes wall.png and desk.png
  chamber_3_pieces.png  the stations one by one on white, 3 px a unit: tree, faith, awaken, awaken_closed, table
"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "chamber")
ROOM = (-100, 0, 840, 360)
STATIONS = {  # name: (x, y, w, h) in design units
    "tree": (40, 70, 110, 130),
    "faith": (490, 80, 110, 120),
    "awaken": (170, 62, 80, 78),
    "table": (180, 140, 280, 130),
}
MAP = (200, 150, 240, 110)  # the World Table's map (the "descend" station), inside the table
DESK = (-100, 300, 840, 60)
FLOOR_Y = 200
COL = {"tree": (102, 64, 140), "faith": (191, 133, 41), "awaken": (107, 102, 97), "table": (66, 43, 26),
       "map": (77, 94, 122), "wall": (38, 36, 44), "floor": (58, 50, 46), "desk": (51, 31, 18)}
NUM = {"tree": "1", "faith": "2", "awaken": "3", "table": "4"}
PIECE_SCALE = 3
PIECE_AT = {"tree": (40, 40), "faith": (410, 70), "awaken": (780, 196), "awaken_closed": (1060, 196), "table": (348, 560)}
PIECE_NUM = {"tree": "1", "faith": "2", "awaken": "3", "awaken_closed": "4", "table": "5"}


def font(size):
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def box(d, r, s, col, ox=0.0):
    x, y, w, h = r
    x0, y0 = (x - ox) * s, y * s
    d.rectangle([x0, y0, x0 + w * s - 1, y0 + h * s - 1], fill=col, outline=(20, 18, 18), width=2)


def room(stations):
    s = 2
    im = Image.new("RGB", (ROOM[2] * s, ROOM[3] * s), COL["wall"])
    d = ImageDraw.Draw(im)
    ox = ROOM[0]
    d.rectangle([0, FLOOR_Y * s, im.width, im.height], fill=COL["floor"])
    if stations:
        # The middle 640 units are what a 16:9 window shows.
        for x in (0, 640):
            d.line([(x - ox) * s, 0, (x - ox) * s, im.height], fill=(70, 70, 80), width=1)
        for k in ("awaken", "tree", "faith", "table"):
            box(d, STATIONS[k], s, COL[k], ox)
        box(d, MAP, s, COL["map"], ox)
        for k, r in STATIONS.items():
            d.text(((r[0] - ox) * s + 6, r[1] * s + 4), NUM[k], fill=(200, 200, 200), font=font(22))
    else:
        r = STATIONS["awaken"]
        d.rectangle([(r[0] - ox) * s, r[1] * s, (r[0] + r[2] - ox) * s - 1, (r[1] + r[3]) * s - 1],
                    outline=(90, 88, 84), width=2)
    box(d, DESK, s, COL["desk"], ox)
    return im


def pieces():
    s = PIECE_SCALE
    im = Image.new("RGB", (1536, 1024), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for k, (px, py) in PIECE_AT.items():
        src = "awaken" if k == "awaken_closed" else k
        _, _, w, h = STATIONS[src]
        col = COL[src] if k != "awaken_closed" else (50, 48, 46)
        d.rectangle([px, py, px + w * s - 1, py + h * s - 1], fill=col, outline=(20, 18, 18), width=2)
        if k == "table":
            mx, my = (MAP[0] - STATIONS["table"][0]) * s, (MAP[1] - STATIONS["table"][1]) * s
            d.rectangle([px + mx, py + my, px + mx + MAP[2] * s - 1, py + my + MAP[3] * s - 1],
                        fill=COL["map"], outline=(20, 18, 18), width=2)
        d.text((px + 6, py + 4), PIECE_NUM[k], fill=(210, 210, 210), font=font(24))
    return im


PROMPT_STYLE = (
    "STYLE: the pixel art of my game (image 2): chunky pixels, muted palette, dark warm outlines, no soft blur. "
    "A dark, quiet stone chamber where a god plans the night: deep blue-black shadow, warm candle and ember light, gold trim. "
    "Seen straight on, like a stage: flat front view, NOT isometric, no perspective tilt. Light from the upper LEFT.")

PROMPTS = {
    "chamber_1_room.txt": (
        "Image 1 = BLOCKOUT GUIDE of a room. Image 2 = my game's art style. Image 3 = my concept for this room.\n\n"
        "TASK: Paint image 1 as a finished room in the style of image 2 and the mood of image 3. Keep every block's position and "
        "size EXACTLY: trace over them. The grey numbers and the two thin vertical lines are guides only, do not draw them.\n\n"
        + PROMPT_STYLE + "\n\n"
        "PIECES (by number):\n"
        "1 (left, purple) ABILITY TREE: a tall carved stone shrine holding a glowing tree of linked runes, violet light.\n"
        "2 (right, gold) FAITH ALTAR: a stone altar with a gold cloth, candles, a brazier and offerings, warm gold light.\n"
        "3 (back wall, grey) RITE DOOR: a heavy stone double door in the wall with rune carvings, open a crack with "
        "white-gold light behind it.\n"
        "4 (centre, brown) WORLD TABLE: a broad dark wooden war table; the blue area on top is a map of a small kingdom, "
        "softly lit, with tiny town markers.\n"
        "The dark band along the bottom is the near edge of the god's own desk, in shadow, with a few scrolls and a candle.\n"
        "The lighter band behind the pieces is the stone floor; above it the back wall with pillars and banners.\n\n"
        "OUTPUT: one image, same proportions as image 1 (7:3), no text, no numbers, no UI."),
    "chamber_2_empty.txt": (
        "Same chat as the room painting. Image 1 = BLOCKOUT GUIDE of the same room, EMPTY.\n\n"
        "TASK: Paint the same room as your last painting with pieces 1 to 4 REMOVED: only the back wall, the pillars and "
        "banners, the stone floor and the desk edge along the bottom. Where the Rite Door was (thin outline in image 1) paint "
        "an empty dark stone doorway recess of exactly that size. Same style, palette, light and proportions as your last "
        "painting. Nothing may stand on the floor: no furniture, no props, no characters.\n\n"
        "OUTPUT: one image, 7:3, no text, no numbers."),
    "chamber_3_pieces.txt": (
        "Same chat. Image 1 = BLOCKOUT GUIDE of five separate pieces on white.\n\n"
        "TASK: Paint each block as the finished piece from your room painting, each one filling its block EXACTLY (same "
        "position, width and height), each alone on a plain WHITE background. No floor, no wall, no cast shadow outside "
        "the piece.\n\n"
        "PIECES (by number):\n"
        "1 ABILITY TREE (purple).\n"
        "2 FAITH ALTAR (gold).\n"
        "3 RITE DOOR, OPEN A CRACK AND LIT: white-gold light behind it, runes glowing.\n"
        "4 RITE DOOR, SHUT AND DARK: the same door, same size, closed, no light, runes dead.\n"
        "5 WORLD TABLE with the map on top (the blue area).\n\n"
        "OUTPUT: same layout as image 1, white background, no text, no numbers."),
}

HOW_TO = """GOD'S CHAMBER ART: how to paint it (one ChatGPT chat, three paintings)

Painting 1, the room:
  attach chamber_1_room.png (image 1), ingame_buildings_4x.png (image 2), your Chamber concept image (image 3)
  paste chamber_1_room.txt
  repaint until you like the room: this one sets the look for the other two
Painting 2, the empty room (same chat):
  attach chamber_2_empty.png, paste chamber_2_empty.txt
Painting 3, the pieces (same chat):
  attach chamber_3_pieces.png, paste chamber_3_pieces.txt

Save the three results to "KAK ChatGPT refs\\Output\\" as chamber_room.png, chamber_empty.png, chamber_pieces.png.
Then tell Claude: it cuts them into the game's files (wall, desk, table, descend, tree, faith, awaken, awaken_closed).
"""

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    room(True).save(os.path.join(OUT, "chamber_1_room.png"))
    room(False).save(os.path.join(OUT, "chamber_2_empty.png"))
    pieces().save(os.path.join(OUT, "chamber_3_pieces.png"))
    for name, text in PROMPTS.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
            f.write(text + "\n")
    with open(os.path.join(OUT, "HOW_TO.txt"), "w", encoding="utf-8") as f:
        f.write(HOW_TO)
    print("wrote", OUT)
