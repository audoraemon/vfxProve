"""Lays a PixelLab character download (the get_character ZIP) out the way make_animal_sheet.py reads it.

Run from the repo root:
  python tools/dev/pixellab_src/death_review_2/layout_char.py ZIP DEST [--cell 48] [--keep ANIM ...]

Writes DEST/rot_<dir>.png and DEST/<anim>/<dir>_<i>.png. PixelLab stores the rotations on the character's own canvas
(28 px for the pale ghost and the skeleton, 40 px for the standard-mode ghoul) and the v3 animations on a larger one
(40 px); make_animal_sheet.py wants every frame on one square canvas, so each image is centred on a CELL x CELL
transparent canvas (48, R38/R42). Nothing is scaled or redrawn: only transparent padding is added.
"""
import argparse
import io
import os
import re
import zipfile

from PIL import Image


def pad(im, cell):
	out = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
	out.alpha_composite(im, ((cell - im.width) // 2, (cell - im.height) // 2))
	return out


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("zip")
	ap.add_argument("dest")
	ap.add_argument("--cell", type=int, default=48)
	ap.add_argument("--rename", action="append", default=[], help="FROM=TO: store animation FROM under TO")
	args = ap.parse_args()
	rename = dict(r.split("=", 1) for r in args.rename)
	z = zipfile.ZipFile(args.zip)
	for name in z.namelist():
		m = re.match(r"[^/]+/rotations/([a-z-]+)\.png$", name)
		if m:
			path = os.path.join(args.dest, "rot_%s.png" % m.group(1))
		else:
			m = re.match(r"[^/]+/animations/([^/]+)/([a-z-]+)/frame_(\d+)\.png$", name)
			if not m:
				continue
			anim = rename.get(m.group(1), m.group(1))
			path = os.path.join(args.dest, anim, "%s_%d.png" % (m.group(2), int(m.group(3))))
		im = Image.open(io.BytesIO(z.read(name))).convert("RGBA")
		os.makedirs(os.path.dirname(path), exist_ok=True)
		pad(im, args.cell).save(path)
		print(path, im.size)


if __name__ == "__main__":
	main()
