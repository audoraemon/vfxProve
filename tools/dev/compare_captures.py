"""Mean absolute pixel difference between same-named PNGs in two folders (0-255 scale, averaged over RGB).
usage: python tools/dev/compare_captures.py <dir_a> <dir_b>"""
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

a_dir, b_dir = Path(sys.argv[1]), Path(sys.argv[2])
worst = 0.0
count = 0
for a in sorted(a_dir.glob('*.png')):
    b = b_dir / a.name
    if not b.exists():
        print('missing', b)
        continue
    ia = Image.open(a).convert('RGB')
    ib = Image.open(b).convert('RGB')
    if ia.size != ib.size:
        print('size differs', a.name, ia.size, ib.size)
        continue
    diff = sum(ImageStat.Stat(ImageChops.difference(ia, ib)).mean) / 3.0
    worst = max(worst, diff)
    count += 1
    print('%-28s %.3f' % (a.name, diff))
print('files=%d worst_mean_diff=%.3f' % (count, worst))
