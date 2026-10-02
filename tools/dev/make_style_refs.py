"""Style references for PixelLab (PixelLab structures proof): crop each building from the concept sheet
concepts/TOWN REF/TownMap_Component1.png (already on transparency), trimmed to its pixels, kept at the sheet's resolution
(PixelLab reads detail and style from it; the composition comes from reference.png).
Usage: python tools/dev/make_style_refs.py [--sheet]   (--sheet also writes captures/style_refs_sheet.png to check the boxes)
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "concepts" / "TOWN REF" / "TownMap_Component1.png"
OUT = ROOT / "assets" / "pixellab" / "buildings"
# Boxes (x0, y0, x1, y1) on the 1448x1086 sheet. The Citadel's parts all take the castle.
CASTLE = (105, 793, 670, 1086)
BOXES = {
    "cottage_red": (30, 0, 315, 270),
    "cottage_blue": (380, 0, 665, 270),
    "tavern": (1070, 0, 1395, 265),
    "smithy": (5, 275, 355, 550),
    "cathedral": (365, 250, 705, 585),
    "citadel_keep": CASTLE,
    "citadel_tower": CASTLE,
    "citadel_wall": CASTLE,
    "citadel_wall_side": CASTLE,
    "citadel_gate": CASTLE,
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


def main():
    sheet = Image.open(SRC).convert("RGBA")
    crops = []
    for name, box in BOXES.items():
        crop = _largest_shape(sheet.crop(box))
        crop.save(OUT / name / "style_ref.png")
        crops.append(crop)
        print("style ref", name, crop.size)
    if "--sheet" in sys.argv:
        uniq = []
        for c in crops:
            if not any(c.size == u.size and c.tobytes() == u.tobytes() for u in uniq):
                uniq.append(c)
        w = sum(c.width for c in uniq) + 8 * len(uniq)
        h = max(c.height for c in uniq)
        out = Image.new("RGBA", (w, h), (60, 58, 52, 255))
        x = 0
        for c in uniq:
            out.alpha_composite(c, (x, h - c.height))
            x += c.width + 8
        out.save(ROOT / "captures" / "style_refs_sheet.png")


if __name__ == "__main__":
    main()
