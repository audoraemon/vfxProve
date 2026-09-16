"""Tile capture PNGs for one effect into a labeled contact sheet at native 640x360."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

key = sys.argv[1]
cols = int(sys.argv[2]) if len(sys.argv) > 2 else 2
root = Path(__file__).resolve().parents[1] / "captures"
files = sorted(root.glob(f"{key}_*.png"))
if not files:
    sys.exit(f"no captures for {key}")
w, h = 640, 360
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (w * cols, h * rows), (0, 0, 0))
draw = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    img = Image.open(f).convert("RGB").resize((w, h), Image.NEAREST)
    x, y = (i % cols) * w, (i // cols) * h
    sheet.paste(img, (x, y))
    label = f"t={int(f.stem.split('_')[-1]) / 1000:.2f}s"
    draw.rectangle([x + w - 70, y + 2, x + w - 2, y + 14], fill=(0, 0, 0))
    draw.text((x + w - 66, y + 3), label, fill=(255, 255, 0))
out = root / f"sheet_{key}.png"
sheet.save(out)
print(out)
