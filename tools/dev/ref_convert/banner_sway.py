"""Hanging banners sway: writes (or extends) a set's idle strip so each banner's top stays fixed while its lower part
swings sideways a pixel or two, lagging down the cloth like a gentle breeze. The wall it uncovers is filled from
the wall pixel just beside the banner on that row. Banners are found as large saturated-blue blobs taller than wide,
below `--max-top` (so roofs and flags are left alone).

Usage (from the project root):
  python tools/dev/ref_convert/banner_sway.py <set> [<set> ...] [--frames 6] [--fps 6] [--amp 1.6]
A set that already has an idle strip with the same frame count keeps it and gets the sway on top (bell_tower's flag).
"""
import argparse
import json
import math
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
MIN_PX = 30


def banners(a):
    """Bounding boxes of hanging banners: blue blobs of 30+ px that are taller than wide."""
    rgb = a[..., :3].astype(int)
    blue = (a[..., 3] > 0) & (rgb[..., 2] > rgb[..., 0] + 40) & (rgb[..., 2] > rgb[..., 1] + 20)
    h, w = blue.shape
    seen = np.zeros_like(blue)
    out = []
    for y0 in range(h):
        for x0 in range(w):
            if blue[y0, x0] and not seen[y0, x0]:
                q = deque([(y0, x0)]); seen[y0, x0] = True; pts = []
                while q:
                    y, x = q.popleft(); pts.append((y, x))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and blue[yy, xx] and not seen[yy, xx]:
                            seen[yy, xx] = True; q.append((yy, xx))
                ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
                bw, bh = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
                if len(pts) >= MIN_PX and bh > bw * 1.4:
                    out.append(pts)
    return out


def sway_frame(frame, ref, blobs, phase, amp):
    """`frame` with every banner (cut from `ref`, the still) re-drawn swayed for this phase."""
    out = frame.copy()
    for pts in blobs:
        ys = [p[0] for p in pts]
        top, bot = min(ys), max(ys)
        rows = {}
        for y, x in pts:
            lo, hi = rows.get(y, (x, x))
            rows[y] = (min(lo, x), max(hi, x))
        for y in range(top, bot + 1):
            if y not in rows:
                continue
            lo, hi = rows[y][0] - 1, rows[y][1] + 1            # the banner row plus its outline
            t = (y - top) / max(bot - top, 1)
            dx = int(round(amp * t ** 1.3 * math.sin(phase - t * 1.4)))
            if dx == 0:
                continue
            seg = ref[y, lo:hi + 1].copy()
            # uncover: refill the row from the wall just outside the banner
            wall_l = ref[y, lo - 1] if lo - 1 >= 0 else seg[0]
            wall_r = ref[y, hi + 1] if hi + 1 < ref.shape[1] else seg[-1]
            for x in range(lo, hi + 1):
                out[y, x] = wall_l if x - lo < (hi - lo) / 2 else wall_r
            for i, px in enumerate(seg):
                x = lo + i + dx
                if 0 <= x < out.shape[1] and px[3] > 0:
                    out[y, x] = px
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sets", nargs="+")
    p.add_argument("--frames", type=int, default=6)
    p.add_argument("--fps", type=float, default=6.0)
    p.add_argument("--amp", type=float, default=1.6)
    p.add_argument("--min-px", type=int, default=30, help="smallest blob that counts as a banner")
    p.add_argument("--max-top", type=int, default=40, help="ignore blue blobs starting above this row (flags, roofs)")
    a = p.parse_args()
    global MIN_PX
    MIN_PX = a.min_px
    man_path = B / "manifest.json"
    man = json.load(open(man_path, encoding="utf-8"))
    for name in a.sets:
        still = np.array(Image.open(B / name / "intact.png").convert("RGBA"))
        h, w = still.shape[:2]
        blobs = [b for b in banners(still) if min(y for y, _ in b) >= a.max_top]
        if not blobs:
            print(name, "no hanging banner, skipped")
            continue
        idle_p = B / name / "idle.png"
        n = a.frames
        frames = [still] * n
        if idle_p.exists() and int(man[name].get("frames", 1)) == n:
            strip = np.array(Image.open(idle_p).convert("RGBA"))
            frames = [strip[:, i * w:(i + 1) * w] for i in range(n)]
        out = np.zeros((h, w * n, 4), np.uint8)
        for i in range(n):
            out[:, i * w:(i + 1) * w] = sway_frame(frames[i], still, blobs, 2 * math.pi * i / n, a.amp)
        Image.fromarray(out, "RGBA").save(idle_p)
        man[name]["frames"] = n
        man[name].setdefault("fps", a.fps)
        print(name, "banners", len(blobs), "->", idle_p.name, n, "frames")
    text = "{\n" + ",\n".join("\t" + json.dumps(k) + ": " + json.dumps(v) for k, v in man.items()) + "\n}\n"
    open(man_path, "w", encoding="utf-8").write(text)


if __name__ == "__main__":
    main()
