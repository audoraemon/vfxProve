"""Pack the PixelLab grasping-hand frames into assets/pixellab/fx/grave_hand/grave_hand.png (+ json), R34.

Run from the repo root:  python tools/dev/pixellab_src/death_review_2/pack_hand.py

Sheet: 6 x 1 cells of 64x64. Frames 0-1 rising, 2-3 clawing, 4-5 closing and pulling down (see prompts.txt for the
job each source frame comes from). The row gets ONE offset (so the authored rise and sink survive): its lowest opaque
pixel lands on foot y=62 and frame 0's bbox centre on foot x=32.
"""
import json
import os
from PIL import Image

HERE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hand")
OUT_DIR = os.path.join("assets", "pixellab", "fx", "grave_hand")
CELL = 64
FOOT = (32, 62)
FRAMES = [
	"rise_2.png",       # rising: the clawed hand breaks the soil
	"rise_4.png",       # rising: the forearm pushes up, fingers spread
	"hand_b.png",       # clawing: full height, fingers clawed upward (the base image)
	"anim81_1.png",     # clawing: the fingers rake and curl
	"anim82_3.png",     # closing: a clenched fist at full height
	"sink_fist_3.png",  # pulling down: the fist drags into the earth
]


def main():
	os.makedirs(OUT_DIR, exist_ok=True)
	ims = [Image.open(os.path.join(HERE, f)).convert("RGBA") for f in FRAMES]
	boxes = [im.getchannel("A").getbbox() for im in ims]
	union_bot = max(b[3] for b in boxes) - 1  # last opaque row
	dy = FOOT[1] - union_bot
	b0 = boxes[0]
	dx = int(round(FOOT[0] - (b0[0] + b0[2]) / 2))
	print(f"dx={dx} dy={dy} lowest row -> {union_bot + dy}")
	sheet = Image.new("RGBA", (CELL * len(ims), CELL), (0, 0, 0, 0))
	for c, im in enumerate(ims):
		cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
		cell.alpha_composite(im, (max(0, dx), max(0, dy)), (max(0, -dx), max(0, -dy)))
		sheet.alpha_composite(cell, (c * CELL, 0))
	sheet.save(os.path.join(OUT_DIR, "grave_hand.png"))
	meta = {"cell": [CELL, CELL], "frames": len(ims), "foot": list(FOOT)}
	with open(os.path.join(OUT_DIR, "grave_hand.json"), "w", newline="\n") as fh:
		fh.write(json.dumps(meta) + "\n")


if __name__ == "__main__":
	main()
