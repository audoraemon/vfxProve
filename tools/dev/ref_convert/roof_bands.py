"""Roof banding: how much of a gpt_* set's slate roof is drawn as stepped blocks instead of even tile courses.

The style match pass re-draws a slate roof as courses (style_match.courses()), each face in its own tone with its
courses parallel to its eave. Where the faces are split by the painting's light (slate_planes()) and the painting is
mottled (moss, lichen, painted wear), a roof that is one plane is cut into light and dark blobs, each drawn as a face
of its own: big flat light/dark blocks whose courses turn at a staircase edge (the user's "strange roofs", capital
polish 3). A roof's true faces are planes, so on the sprite they meet along straight lines (a ridge, a hip); the
blobs do not. This scores that, per still (intact, damaged, ruins):

  roof     the roof px: slate blue (style_stats.family) in pieces of at least style_match.SLATE_MIN px, not the outline,
           not painted water (gpt_convert.water_mask() of a set with water)
  drawn    per roof px, the way its courses run: +1 down-right, -1 up-right, from the still's exact colour repeats
           along the two course diagonals (2, 1) and (2, -1) over a 5 x 5 window
  blocks   the share of the roof drawn against the best straight split of each roof piece: per piece, the line (every
           3 degrees, every offset) that best parts its +1 from its -1 (or no line: one face), and the px on the wrong
           side of it. A roof of one face or of two faces meeting at a ridge scores near 0; blobs score high.
  patches  turned patches of at least PATCH px (the stepped blocks themselves: the px on the wrong side, joined)
  shades   distinct roof colours
  banding  blocks (the ranking and the flag)

A set is flagged when its intact's banding is THRESHOLD or more, the threshold set to flag the user's three examples
(the library, the user's "chapel"; the lumber yard; the manor, whose roof is the one by the Keep's drill yard). Red
roofs are not scored: they keep their painted tiles (style_match.RED_ROOFS off), nothing re-draws them.

Usage (from anywhere):
  python tools/dev/ref_convert/roof_bands.py [<set> ...] [--dir <buildings dir>] [--top N]
  no sets: every gpt_* set (style_stats.GPT), ranked by the intact's banding.
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gpt_convert as gc  # noqa: E402
import style_match as sm  # noqa: E402
import style_stats as ss  # noqa: E402
from bonfire_flicker import _components  # noqa: E402

STATES = ("intact", "damaged", "ruins")
THRESHOLD = 0.045
PATCH = 12
ANGLES = np.radians(np.arange(0, 180, 3))


def roof(a, water=None):
    """The scored roof px of an output still (see the module doc)."""
    al = a[..., 3] > 0
    f = ss.family(a[..., :3].astype(float))
    m = al & (f == ss.BLUE) & ~ss.outline_mask(al)
    if water is not None:
        m &= ~water
    out = np.zeros_like(m)
    for pts in _components(m, conn8=False):
        if len(pts) >= sm.SLATE_MIN:
            ys, xs = zip(*pts)
            out[list(ys), list(xs)] = True
    return out


def drawn(a, m):
    """+1 where the still's courses run down-right (colour repeats along (2, 1)), -1 up-right, on the roof px."""
    key = (a[..., 0].astype(np.int64) << 16) | (a[..., 1].astype(np.int64) << 8) | a[..., 2]
    key = np.where(m, key, -1)
    h, w = m.shape
    p = np.pad(key, 3, constant_values=-2)

    def at(dy, dx):
        return p[3 + dy:3 + dy + h, 3 + dx:3 + dx + w]
    down = ((at(1, 2) == key).astype(float) + (at(-1, -2) == key)) * m
    up = ((at(-1, 2) == key).astype(float) + (at(1, -2) == key)) * m
    s = sm._box(down, 2) - sm._box(up, 2)
    s = sm._box(np.where(m, np.sign(s), 0.0), 1)
    return np.where(s >= 0, 1, -1)


def wrong_side(ys, xs, o):
    """The px of one roof piece on the wrong side of the straight split that best parts its +1 from its -1 (or of no
    split, when one face fits better), as a boolean array along (ys, xs)."""
    pos = o > 0
    n = len(pos)
    best = (min(pos.sum(), n - pos.sum()), None)          # no split: the minority sign is wrong
    for ang in ANGLES:
        t = xs * np.cos(ang) + ys * np.sin(ang)
        idx = np.argsort(t, kind="stable")
        c = np.concatenate([[0], np.cumsum(pos[idx])])     # +1 px before each cut
        k = np.arange(n + 1)
        wrong_a = (k - c) + (pos.sum() - c)                # +1 before the cut, -1 after
        wrong_b = c + (n - k) - (pos.sum() - c)            # -1 before the cut, +1 after
        for wr, plus_first in ((wrong_a, True), (wrong_b, False)):
            i = int(wr.argmin())
            if wr[i] < best[0]:
                best = (int(wr[i]), (idx, i, plus_first))
    if best[1] is None:
        return pos if pos.sum() * 2 < n else ~pos
    idx, i, plus_first = best[1]
    want = np.zeros(n, bool)
    want[idx[:i]] = plus_first
    want[idx[i:]] = not plus_first
    return want != pos


def score(a, water=None):
    """{px, blocks, patches, shades, banding} of one output still, or None when it has no slate roof."""
    m = roof(a, water)
    n = int(m.sum())
    if n == 0:
        return None
    o = drawn(a, m)
    bad = np.zeros_like(m)
    for pts in _components(m, conn8=False):
        ys, xs = (np.array(v) for v in zip(*pts))
        w = wrong_side(ys, xs, o[ys, xs])
        bad[ys[w], xs[w]] = True
    patches = sum(1 for q in _components(bad, conn8=False) if len(q) >= PATCH)
    key = (a[..., 0].astype(np.int64) << 16) | (a[..., 1].astype(np.int64) << 8) | a[..., 2]
    blocks = float(bad.sum()) / n
    return {"px": n, "blocks": blocks, "patches": patches, "shades": int(len(np.unique(key[m]))), "banding": blocks}


def score_set(name, base):
    out = {}
    water = None
    for st in STATES:
        a = np.array(Image.open(Path(base) / name / (st + ".png")).convert("RGBA"))
        if st == "intact" and gc.SETS[name].get("water"):
            water = gc.water_mask(a)
        out[st] = score(a, water)
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("sets", nargs="*")
    p.add_argument("--dir", default=str(ss.B))
    p.add_argument("--top", type=int, default=0, help="print only the N highest")
    args = p.parse_args()
    rows = [(n, score_set(n, args.dir)) for n in (args.sets or ss.GPT)]
    rows.sort(key=lambda r: -(r[1]["intact"]["banding"] if r[1]["intact"] else -1.0))
    if args.top:
        rows = rows[:args.top]
    print("threshold %.3f (the intact's banding); per still: banding, patches, shades, roof px" % THRESHOLD)
    print("%-18s %-24s %-24s %-24s %s" % ("set", "intact", "damaged", "ruins", "flag"))

    def cell(r):
        return "-" if r is None else "%.3f %3d %3d px %5d" % (r["banding"], r["patches"], r["shades"], r["px"])
    for n, r in rows:
        flag = "FLAG" if r["intact"] and r["intact"]["banding"] >= THRESHOLD else ""
        print("%-18s %-24s %-24s %-24s %s" % (n, cell(r["intact"]), cell(r["damaged"]), cell(r["ruins"]), flag))


if __name__ == "__main__":
    main()
