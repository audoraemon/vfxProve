"""Style references for PixelLab (PixelLab structures proof): crop each building from the concept sheet
concepts/TOWN REF/ (default TownMap_Component1.png; already on transparency), trimmed to its pixels, kept at the sheet's resolution
(PixelLab reads detail and style from it; the composition comes from reference.png).
Usage: python tools/dev/make_style_refs.py [--sheet]   (--sheet also writes captures/style_refs_sheet*.png, one per sheet, to check the boxes)
"""
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SHEETS = ROOT / "concepts" / "TOWN REF"
DEFAULT_SHEET = "TownMap_Component1.png"
OUT = ROOT / "assets" / "pixellab" / "buildings"
# Boxes (x0, y0, x1, y1) on the 1448x1086 default sheet, or (sheet name, box) for another sheet in concepts/TOWN REF. The Citadel's parts all take the castle.
CASTLE = (105, 793, 670, 1086)
BOXES = {
    "cottage_red": (30, 0, 315, 270),
    "cottage_blue": (380, 0, 665, 270),
    "tavern": (1070, 0, 1395, 265),
    "smithy": (5, 275, 355, 550),
    # Two-storey timber-framed house with dormers (top middle). townhouse_b is townhouse_a recoloured locally.
    "townhouse_a": (720, 15, 1050, 270),
    "townhouse_b": (720, 15, 1050, 270),
    "cathedral": (365, 250, 705, 585),
    "citadel_keep": CASTLE,
    "citadel_tower": CASTLE,
    "citadel_wall": CASTLE,
    "citadel_wall_side": CASTLE,
    "citadel_gate": CASTLE,
    "town_tower": ("TownMap_Component4.png", (40, 470, 185, 695)),
    "town_tower_corner": ("TownMap_Component4.png", (40, 470, 185, 695)),
    "town_wall": ("TownMap_Component4.png", (310, 66, 535, 250)),
    "town_gate": ("TownMap_Component4.png", (125, 262, 285, 440)),
    "bell_tower": ("TownMap_Component4.png", (495, 470, 620, 700)),
    # Final Town_Ref01 barracks yard (top left): the long timber-framed hall with the lit open front (an opaque sheet, so the crop keeps some yard ground).
    "barracks": ("Final Town_Ref01.png", (38, 156, 135, 232)),
    # Open-sided timber hall with the red tile roof (middle right): the craft workshop's pavilion (its yard ground comes along).
    "workshop": (1085, 300, 1430, 555),
    "stall_red": ("TownMap_Component2.png", (10, 20, 155, 165)),
    "stall_blue": ("TownMap_Component2.png", (150, 20, 295, 165)),
    "stall_cream": ("TownMap_Component2.png", (15, 170, 155, 295)),
}
# Pixels at least this opaque join a shape: the sheet's soft glows and shadows would bridge a building to its neighbour.
SOLID = 160


def _largest_shape(crop):
    """The crop with only its largest connected run of visible pixels: a box also catches a neighbour's spire tip or
    the market stalls above the castle."""
    w, h = crop.size
    alpha = crop.getchannel("A").load()
    seen = [[False] * w for _ in range(h)]
    best = []
    for y0 in range(h):
        for x0 in range(w):
            if seen[y0][x0] or alpha[x0, y0] < SOLID:
                continue
            shape = []
            todo = deque([(x0, y0)])
            seen[y0][x0] = True
            while todo:
                x, y = todo.popleft()
                shape.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and alpha[nx, ny] >= SOLID:
                        seen[ny][nx] = True
                        todo.append((nx, ny))
            if len(shape) > len(best):
                best = shape
    keep = Image.new("L", (w, h), 0)
    px = keep.load()
    for x, y in best:
        px[x, y] = 255
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(crop, (0, 0), keep)
    return out.crop(keep.getbbox())


def _box(entry):
    """(sheet path, box) for a BOXES entry; a bare box is on the default sheet."""
    if isinstance(entry[0], str):
        return SHEETS / entry[0], entry[1]
    return SHEETS / DEFAULT_SHEET, entry


def _check_sheets(sheets):
    """One check image per sheet with every box drawn on it: captures/style_refs_sheet[_<stem>].png."""
    (ROOT / "captures").mkdir(exist_ok=True)
    for path, im in sheets.items():
        check = Image.new("RGBA", im.size, (60, 58, 52, 255))
        check.alpha_composite(im)
        d = ImageDraw.Draw(check)
        for name, entry in BOXES.items():
            p, box = _box(entry)
            if p == path:
                d.rectangle(box, outline=(255, 255, 0, 255))
                d.text((box[0] + 3, box[1] + 3), name, fill=(255, 255, 0, 255))
        stem = "" if path.name == DEFAULT_SHEET else "_" + path.stem
        check.save(ROOT / "captures" / ("style_refs_sheet" + stem + ".png"))


def main():
    manifest = json.loads((OUT / "manifest.json").read_text(encoding="utf-8"))
    sheets = {}
    for name, entry in BOXES.items():
        path, box = _box(entry)
        sheets.setdefault(path, Image.open(path).convert("RGBA"))
        if name not in manifest:
            continue
        crop = _largest_shape(sheets[path].crop(box))
        (OUT / name).mkdir(exist_ok=True)
        crop.save(OUT / name / "style_ref.png")
        print("style ref", name, crop.size)
    if "--sheet" in sys.argv:
        _check_sheets(sheets)


if __name__ == "__main__":
    main()
