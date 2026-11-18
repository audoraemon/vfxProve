"""Pack the PixelLab wraith frames into assets/pixellab/fx/wraith/wraith.png (+ json).

Run from the repo root:  python tools/dev/pixellab_src/death_review/pack_wraith.py

Sheet: 8 columns x 3 rows of 64x64. Rows: drift_se (8), drift_ne (8), strike_se (6).
Each row gets ONE offset (so the authored bob / lunge motion survives): the row's lowest
opaque pixel lands on foot y=60 and frame 0's bbox centre on foot x=32. When the figure is
too tall for that (the SE drift hood would clip), the shift is clamped so the hood stays in
the cell and the wisp tips hang 1-2 px below the foot.

Recolour: PixelLab drew the bony hands pale green; the Death palette keeps grave green for
eyes/glows only, so light greenish pixels become bone white, except small clusters high in
the figure (the eyes), which keep their green.
"""
import json
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join("assets", "pixellab", "fx", "wraith")
CELL = 64
FOOT = (32, 60)
ROWS = [
	("drift_se", [f"drift_se_{i}.png" for i in range(0, 8)]),   # index 8 == index 0: dropped for the loop
	("drift_ne", [f"drift_ne_{i}.png" for i in range(0, 8)]),
	("strike_se", [f"strike2_se_{i}.png" for i in range(1, 7)]),  # the 6 generated frames
]


def is_greenish(p):
	r, g, b, a = p
	return a > 0 and g > r + 6 and g > b + 6 and g > 60


def bone(p):
	r, g, b, a = p
	lum = 0.3 * r + 0.59 * g + 0.11 * b
	return (min(255, int(lum * 0.98)), min(255, int(lum * 0.95)), min(255, int(lum * 0.84)), a)


def recolour(im):
	im = im.copy()
	w, h = im.size
	px = im.load()
	bb = im.getchannel("A").getbbox()
	top, bot = bb[1], bb[3]
	seen = set()
	for y in range(h):
		for x in range(w):
			if (x, y) in seen or not is_greenish(px[x, y]):
				continue
			comp, stack = [], [(x, y)]
			seen.add((x, y))
			while stack:
				cx, cy = stack.pop()
				comp.append((cx, cy))
				for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
					if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and is_greenish(px[nx, ny]):
						seen.add((nx, ny))
						stack.append((nx, ny))
			cy_mean = sum(c[1] for c in comp) / len(comp)
			is_eye = len(comp) <= 4 and cy_mean < top + (bot - top) * 0.4
			if not is_eye:
				for cx, cy in comp:
					px[cx, cy] = bone(px[cx, cy])
	return im


def main():
	os.makedirs(OUT_DIR, exist_ok=True)
	sheet = Image.new("RGBA", (CELL * 8, CELL * len(ROWS)), (0, 0, 0, 0))
	frames_per_row = []
	for r, (name, files) in enumerate(ROWS):
		ims = [recolour(Image.open(os.path.join(HERE, f)).convert("RGBA")) for f in files]
		boxes = [im.getchannel("A").getbbox() for im in ims]
		union_top = min(b[1] for b in boxes)
		union_bot = max(b[3] for b in boxes) - 1  # last opaque row
		dy = FOOT[1] - union_bot
		if union_top + dy < 0:
			dy = -union_top
		b0 = boxes[0]
		dx = int(round(FOOT[0] - (b0[0] + b0[2]) / 2))
		print(f"{name}: dx={dx} dy={dy} lowest row -> {union_bot + dy}")
		for c, im in enumerate(ims):
			cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
			cell.alpha_composite(im, (max(0, dx), max(0, dy)), (max(0, -dx), max(0, -dy)))
			sheet.alpha_composite(cell, (c * CELL, r * CELL))
		frames_per_row.append(len(ims))
	sheet.save(os.path.join(OUT_DIR, "wraith.png"))
	meta = {"cell": [64, 64], "foot": [32, 60], "fps": 8,
		"rows": {"drift_se": 0, "drift_ne": 1, "strike_se": 2}, "frames": frames_per_row}
	with open(os.path.join(OUT_DIR, "wraith.json"), "w", newline="\n") as fh:
		fh.write(json.dumps(meta) + "\n")


if __name__ == "__main__":
	main()
