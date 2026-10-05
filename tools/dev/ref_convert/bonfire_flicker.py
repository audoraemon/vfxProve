"""Fire baskets flicker: every painted flame over a dark basket (the town towers' roof fires, the gate's wall torches,
the Citadel's braziers) gets a 6-frame flicker in the set's idle strip.

A flame is found as warm, bright pixels (R >= 200, R > G > B) grown from its pale core and held to its basket's columns
(the dark basket under it), so a lit floor round the basket stays still. Each frame redraws the flame column by column:
the columns are split into 3-5 tongues, and tongue i's height is its painted height plus
amp_i * sin(2 pi f / 6 + phi_i) - amp_i * sin(phi_i), so frame 0 is the painted flame and frame 6 is frame 0 again.
A column is the painted column resampled to its new height, so its tones (pale core at the bottom, amber, deep orange at
the tip) are the painter's own; the basket's dark bars and outline in front of the flame are never drawn over. Two or
three embers blink above the tips, rising a pixel. Pixels a shrinking tongue uncovers take the nearest pixel beside the
flame on that row.

A set with an idle strip (the banners' sway) keeps it: each strip frame gets the flame frame pasted over its flame boxes.
A strip of n != 6 frames becomes lcm(n, 6) frames cycling both when that is <= 12, else its banner frames are re-timed
to 6; fps keeps the banner's cycle time within 15%. A set without a strip gets a new 6-frame strip at 6 fps.

The Citadel keep's strip is PixelLab's own (its frame 0 is not its intact still): its flames are read from that frame 0.

Usage (from the project root):
  python tools/dev/ref_convert/bonfire_flicker.py <set> [<set> ...]          writes the strips and the manifest
  python tools/dev/ref_convert/bonfire_flicker.py <set> [<set> ...] --check  verifies them (exit 1 on a failure)
"""
import argparse
import json
import math
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from banner_sway import banners  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
FRAMES = 6          # the flame's loop
NEW_FPS = 6         # a set that had no strip: the towers' banner-sway speed, so the family flickers as one
UP = 3              # the flame box reaches this far above the painted tips
MIN_PX = 10         # smaller warm clusters are lit windows
PIXELLAB_STRIPS = {"citadel_keep"}  # strips not built from the intact still: flames come from their frame 0
AMP_SHAPE = [0.6, 1.0, 0.8, 1.0, 0.7]
PHASES = [0.0, 2.3, 4.4, 1.2, 3.4]
EMBERS = [(1, 2), (3, 4), (4, 5)]   # the frames each ember shows (never frame 0, so frame 0 is the painted flame)


def lum(p):
    return p[..., 0] * 0.3 + p[..., 1] * 0.59 + p[..., 2] * 0.11


def _components(m, conn8=True):
    """Connected components of a bool mask, as lists of (y, x)."""
    h, w = m.shape
    seen = np.zeros_like(m)
    nb = [(dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dy or dx) and (conn8 or not (dy and dx))]
    out = []
    for y0, x0 in zip(*np.nonzero(m)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for dy, dx in nb:
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and m[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    q.append((yy, xx))
        out.append(pts)
    return out


def _dilate(m):
    o = m.copy()
    o[1:] |= m[:-1]; o[:-1] |= m[1:]
    o[:, 1:] |= o[:, :-1].copy(); o[:, :-1] |= o[:, 1:].copy()
    return o


def flames(a):
    """The flames of an RGBA still (int array): a list of dicts with `mask` (the painted flame, grown by 1 px: what
    is redrawn), `paint` (the painted flame itself) and `box` (x0, y0, x1, y1 inclusive: the mask's bounds, UP px
    higher). Warm, bright pixels (R >= 200, R > G > B, R - B >= 60, luminance >= 110) are grown from a pale core
    (R >= 240, G >= 195), held to the columns of the dark basket under the core and to the rows above its foot. A core
    with no dark basket under it, a cluster under MIN_PX, or one without a deep-orange tip (R >= 220, G <= 140,
    B <= 80) is no flame: lit windows and gold trim. Tuned on the tower, gate and Citadel sets: elsewhere it also
    matches warm stall awnings and similar warm areas (stall_7, stall_11), so callers outside those sets (Task 5's
    window_glow.py) must add their own guards."""
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    op = a[..., 3] > 0
    L = lum(a)
    warm = op & (r >= 200) & (r > g) & (g > b) & (r - b >= 60) & (L >= 110)
    core = warm & (r >= 240) & (g >= 195)
    tip = warm & (r >= 220) & (g <= 140) & (b <= 80)
    dark = op & (L < 40)
    h, w = r.shape
    out = []
    for pts in _components(core):
        ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
        sy0, sy1, sx0, sx1 = min(ys), max(ys), min(xs), max(xs)
        if len(pts) < 2:
            continue
        mid = (sy0 + sy1) // 2
        win = np.zeros_like(dark)
        win[mid:min(h, sy1 + 11), max(0, sx0 - 4):min(w, sx1 + 5)] = True
        dy_, dx_ = np.nonzero(dark & win)
        if len(dy_) < 3 or dy_.max() <= sy1:
            continue
        bx0, bx1 = min(int(dx_.min()), sx0), max(int(dx_.max()), sx1)
        allow = np.zeros_like(warm)
        allow[:sy1 + 3, bx0:bx1 + 1] = True
        allow &= warm
        grown = np.zeros_like(warm)
        q = deque(pts)
        for p in pts:
            grown[p] = True
        while q:
            y, x = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and allow[yy, xx] and not grown[yy, xx]:
                    grown[yy, xx] = True
                    q.append((yy, xx))
        if grown.sum() < MIN_PX or not (grown & tip).any():
            continue                                            # a lit window or a gold trim: no deep-orange tip
        fy, fx = np.nonzero(grown)
        out.append({"paint": grown, "mask": _dilate(grown),
                    "box": (int(fx.min()) - 1, max(0, int(fy.min()) - UP), int(fx.max()) + 1, int(fy.max()) + 1)})
    # Two cores of one flame (split by a dark bar) are one flame.
    merged = []
    for f in sorted(out, key=lambda f: f["box"]):
        for m in merged:
            a0, b0 = m["box"], f["box"]
            if a0[0] <= b0[2] + 1 and b0[0] <= a0[2] + 1 and a0[1] <= b0[3] + 1 and b0[1] <= a0[3] + 1:
                m["paint"] |= f["paint"]; m["mask"] |= f["mask"]
                m["box"] = (min(a0[0], b0[0]), min(a0[1], b0[1]), max(a0[2], b0[2]), max(a0[3], b0[3]))
                break
        else:
            merged.append(f)
    return merged


def zone(shape, fl):
    """Every flame box, as one bool mask: the pixels the flicker may change."""
    z = np.zeros(shape[:2], bool)
    for f in fl:
        x0, y0, x1, y1 = f["box"]
        z[y0:y1 + 1, x0:x1 + 1] = True
    return z


def _beside(a, mask, y, x):
    """The nearest pixel on row y outside `mask`: what shows where a tongue has shrunk away."""
    w = a.shape[1]
    for k in range(1, w):
        for xx in (x - k, x + k):
            if 0 <= xx < w and not mask[y, xx]:
                return a[y, xx]
    return np.array([0, 0, 0, 0])


def flame_frame(a, fl, f):
    """Frame f of the flicker drawn on the still `a` (RGBA int array); f = 0 (or 6) is `a` itself."""
    o = a.copy()
    for fi, fm in enumerate(fl):
        paint, mask = fm["paint"], fm["mask"]
        x0, y0, x1, y1 = fm["box"]
        cols = [x for x in range(x0, x1 + 1) if paint[:, x].any()]
        heights = {x: int(np.nonzero(paint[:, x])[0].max() - np.nonzero(paint[:, x])[0].min() + 1) for x in cols}
        k = max(3, min(5, len(cols) // 2))
        amp = max(1.0, min(1.6, max(heights.values()) / 6.0))
        tops = {}
        for j, x in enumerate(cols):
            i = j * k // len(cols)
            ai = amp * AMP_SHAPE[i]
            ph = PHASES[i] + fi * 0.9
            d = int(round(ai * (math.sin(2 * math.pi * f / FRAMES + ph) - math.sin(ph))))
            ys = np.nonzero(paint[:, x])[0]
            top, bot = int(ys.min()), int(ys.max())
            d = max(-(bot - top - 1) if bot > top else 0, min(UP - 1, top - y0, d))
            ntop = top - d
            tops[x] = ntop
            src_rows = [y for y in range(top, bot + 1) if paint[y, x]]
            # vacated rows: what is beside the flame
            for y in range(top, ntop):
                if paint[y, x]:
                    o[y, x] = _beside(a, mask, y, x)
            for y in range(ntop, bot + 1):
                if y >= top and not paint[y, x]:
                    continue                    # the basket's bars and outline (and its lit rim) stay in front
                s = bot - (bot - y) * (bot - top) / max(bot - ntop, 1)
                sy = min(src_rows, key=lambda r: (abs(r - s), r))
                o[y, x] = a[sy, x]
        # embers: above the tips, two frames each, rising a pixel and cooling from amber to deep orange
        tones = sorted({tuple(a[y, x]) for y, x in zip(*np.nonzero(paint))}, key=lambda c: -lum(np.array(c)))
        hot, cool = np.array(tones[min(1, len(tones) - 1)]), np.array(tones[-1])
        n_emb = 3 if len(cols) >= 6 else 2
        for e in range(n_emb):
            fr = EMBERS[e]
            if f % FRAMES not in fr:
                continue
            step = fr.index(f % FRAMES)
            x = cols[(2 * e + 1) * len(cols) // (2 * n_emb)]
            y = max(y0, min(tops.values()) - 1 - step - (e % 2))
            if not paint[y, x] or y < tops[x]:
                o[y, x] = hot if step == 0 else cool
    return o


def strip_frames(name, man, w):
    p = B / name / "idle.png"
    n = int(man[name].get("frames", 1))
    if n <= 1 or not p.exists():
        return []
    s = np.array(Image.open(p).convert("RGBA")).astype(int)
    return [s[:, i * w:(i + 1) * w] for i in range(n)]


def plan(n, fps):
    """(frames, fps, banner frames per banner cycle, banner frame for output frame k) for a strip of n banner frames
    at fps; n = 0: no strip."""
    if n <= 1:
        return FRAMES, NEW_FPS, 0, lambda k: None
    if n == FRAMES:
        return FRAMES, fps, n, lambda k: k
    l = n * FRAMES // math.gcd(n, FRAMES)
    if l <= 12:
        return l, fps, n, lambda k: k % n
    # Re-time the banners to 6 frames; fps keeps their cycle time (6 / new fps = n / fps).
    return FRAMES, round(fps * FRAMES / n, 2), FRAMES, lambda k: int(round(k * n / FRAMES)) % n


def build(name, man):
    still = np.array(Image.open(B / name / "intact.png").convert("RGBA")).astype(int)
    h, w = still.shape[:2]
    old = strip_frames(name, man, w)
    base = old[0] if name in PIXELLAB_STRIPS else still
    fl = flames(base)
    if not fl:
        print(name, "no fire basket, skipped")
        return
    n, fps = len(old), man[name].get("fps", NEW_FPS)
    total, new_fps, cyc, bf = plan(n, fps)
    z = zone(base.shape, fl)
    out = np.zeros((h, w * total, 4), np.uint8)
    gen = [flame_frame(base, fl, f) for f in range(FRAMES)]
    for k in range(total):
        frame = (old[bf(k)] if old else still).copy()
        frame[z] = gen[k % FRAMES][z]
        out[:, k * w:(k + 1) * w] = frame
    Image.fromarray(out, "RGBA").save(B / name / "idle.png")
    if n:
        print("%s: %d frames @ %s fps -> %d frames @ %s fps; banner cycle %.3f s -> %.3f s; flame cycle %.3f s; %d flames"
              % (name, n, fps, total, new_fps, n / fps, cyc / new_fps, FRAMES / new_fps, len(fl)))
    else:
        print("%s: no strip -> %d frames @ %s fps; flame cycle %.3f s; %d flames"
              % (name, total, new_fps, FRAMES / new_fps, len(fl)))
    man[name]["frames"] = total
    man[name]["fps"] = new_fps


def check(name, man):
    """Failures for one set: the strip loops, frame 0 is the painted flame, and nothing else moves but banners."""
    bad = []
    still = np.array(Image.open(B / name / "intact.png").convert("RGBA")).astype(int)
    h, w = still.shape[:2]
    fr = strip_frames(name, man, w)
    total = int(man[name].get("frames", 1))
    if len(fr) < FRAMES or total % FRAMES:
        return ["%s: %d frames, want a multiple of %d" % (name, total, FRAMES)]
    base = fr[0] if name in PIXELLAB_STRIPS else still
    fl = flames(base)
    if not fl:
        return ["%s: no flame found" % name]
    z = zone(base.shape, fl)
    gen = [flame_frame(base, fl, f) for f in range(FRAMES + 1)]
    if not np.array_equal(gen[FRAMES], gen[0]):
        bad.append("%s: flame frame 6 is not frame 0" % name)
    if not np.array_equal(gen[0][z], base[z]):
        bad.append("%s: flame frame 0 differs from the painted flame in %d px" % (name, int(np.any(gen[0] != base, 2).sum())))
    for k, f in enumerate(fr):
        if not np.array_equal(f[z], gen[k % FRAMES][z]):
            bad.append("%s: strip frame %d's flames are not flame frame %d" % (name, k, k % FRAMES))
    steps = [int(np.any(gen[(f + 1) % FRAMES][z] != gen[f][z], 1).sum()) for f in range(FRAMES)]
    if steps[-1] > max(steps[:-1]):
        bad.append("%s: the loop pops (last->first %d px, others %s)" % (name, steps[-1], steps[:-1]))
    if min(steps) == 0:
        bad.append("%s: a flame frame repeats (%s)" % (name, steps))
    # Outside the flames: the banners' own period, and (for strips built on the still) only banners differ from it.
    p = next(p for p in range(1, total + 1) if total % p == 0
             and all(np.array_equal(fr[k][~z], fr[(k + p) % total][~z]) for k in range(total)))
    ban = np.zeros((h, w), bool)
    for pts in banners(still):
        for y, x in pts:
            ban[max(0, y - 1):y + 2, max(0, x - 4):x + 5] = True
    if name not in PIXELLAB_STRIPS:
        for k, f in enumerate(fr):
            diff = np.any(f != still, 2) & ~z & ~ban
            if diff.any():
                bad.append("%s: frame %d differs from intact outside flames and banners in %d px" % (name, k, int(diff.sum())))
                break
    print("%s: %d frames @ %s fps, %d flames, flame steps %s, banner period %d%s"
          % (name, total, man[name].get("fps"), len(fl), steps, p, "" if not bad else "  FAIL"))
    return bad


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sets", nargs="+")
    p.add_argument("--check", action="store_true")
    a = p.parse_args()
    man_path = B / "manifest.json"
    man = json.load(open(man_path, encoding="utf-8"))
    if a.check:
        bad = [m for n in a.sets for m in check(n, man)]
        for m in bad:
            print("FAIL", m)
        sys.exit(1 if bad else 0)
    for name in a.sets:
        build(name, man)
    text = "{\n" + ",\n".join("\t" + json.dumps(k) + ": " + json.dumps(v) for k, v in man.items()) + "\n}\n"
    open(man_path, "w", encoding="utf-8", newline="\n").write(text)


if __name__ == "__main__":
    main()
