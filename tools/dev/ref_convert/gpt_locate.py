"""Measuring aid for gpt_convert.py: where each blockout's footprint diamond lies on its ChatGPT sheet.

ChatGPT traced the blockouts (concepts/GPT/blockout_sheets.py), so each painted building is its blockout scaled and
moved. Per set: the blockout is rendered again with blockout_kit, its ground footprint (the x/y box of every point at
most LOW above the ground: walls, posts, plinths, water, props; roof overhangs are above it) gives the plot W x D and the three base corners
L, F, R in blockout px; the blockout's silhouette is then fitted onto the painted one (one scale and a move, the best
overlap of the two masks), and the corners are carried across. The result is a starting point for the SETS table, read
on the debug overlay and corrected by hand where the painting strays from its blockout.

Usage: python tools/dev/ref_convert/gpt_locate.py <sheet> [--debug <dir>]
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gpt_convert as gc  # noqa: E402

sys.path.insert(0, str(gc.GPT))
import blockout_kit as bk  # noqa: E402
import blockout_sheets as bs  # noqa: E402

LOW = 6.0               # height units: a point this low stands on the plot (lying logs and barrels too; roofs never)

# Ground boxes (x0, y0, x1, y1) set by hand where the low points miss the building: the orchard's plot is its crowns'.
BOX = {"orchard": (0.05, 0.05, 1.55, 1.55)}

# gpt_convert sheet -> blockout_sheets.SHEETS name
BLOCKOUTS = {"faith": "2_faith", "trade": "3_trade", "crafts_a": "4_crafts_a", "crafts_b": "5_crafts_b", "food": "6_food",
             "water": "7_water", "housing": "8_housing", "public": "9_public", "civic_b": "10_civic_b",
             "transport": "11_transport", "defence_b": "1_defence_b", "small": "12_small"}


def blockout(fn):
    """(RGBA tile as blockout_kit.render crops it, ground box (x0, y0, x1, y1), the tile's origin on the canvas)."""
    c = bk.Canvas()
    ground, every = [], []
    xf = c._xf

    def rec(p):
        q = xf(p)
        every.append((q[0], q[1]))
        if q[2] <= LOW:
            ground.append((q[0], q[1]))
        return q
    c._xf = rec
    flues = []
    box, frustum = c.box, c.frustum

    def rec_box(x0, y0, w, d, z0, h, mat="wall", top=None):
        if mat == "stone" and w <= 0.2 and d <= 0.2 and z0 + h >= 20:
            flues.append((x0 + w / 2, y0 + d / 2, z0 + h))
        return box(x0, y0, w, d, z0, h, mat, top)

    def rec_frustum(cx, cy, r0, r1, z0, h, mat="stone", *a, **k):
        if mat in ("stone", "earth") and 0 < r1 <= 0.25 and z0 + h >= 18 and (z0 >= 14 or h >= 40):
            flues.append((cx, cy, z0 + h))
        return frustum(cx, cy, r0, r1, z0, h, mat, *a, **k)
    c.box, c.frustum = rec_box, rec_frustum
    fn(c)
    c._xf = xf
    blockout.flues = flues
    im = c.image()
    # image() crops to its own bbox: find that box on the uncropped canvas the same way
    ids = c.ids
    edge = np.zeros_like(ids, bool)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        sh = np.roll(np.roll(ids, dy, 0), dx, 1)
        edge |= (sh != ids) & ((sh > 0) | (ids > 0))
    ys, xs = np.nonzero((ids > 0) | edge)
    g, e = np.array(ground), np.array(every)
    blockout.whole = (e[:, 0].min(), e[:, 1].min(), e[:, 0].max(), e[:, 1].max())
    return im, (g[:, 0].min(), g[:, 1].min(), g[:, 0].max(), g[:, 1].max()), (xs.min(), ys.min()), c


def corners(c, box, org):
    x0, y0, x1, y1 = box
    f = lambda x, y: np.array(c._scr((x, y, 0.0))) - org  # noqa: E731
    return f(x0, y1), f(x1, y1), f(x1, y0)          # L, F, R


def fit_masks(src, dst, s0):
    """(scale, dx, dy) mapping `src` (bool) onto `dst` (bool) with the best overlap, scale near s0."""
    dh, dw = dst.shape
    best = (-1, None)
    ys, xs = np.nonzero(dst)
    dc = np.array([xs.mean(), ys.mean()])
    for s in np.arange(s0 * 0.86, s0 * 1.14, s0 * 0.01):
        im = Image.fromarray(src.astype(np.uint8) * 255).resize((max(1, round(src.shape[1] * s)),
                                                                  max(1, round(src.shape[0] * s))), Image.BILINEAR)
        m = np.array(im) > 127
        my, mx = np.nonzero(m)
        sc = np.array([mx.mean(), my.mean()])
        base = np.round(dc - sc).astype(int)
        for ddy in range(-24, 25, 3):
            for ddx in range(-24, 25, 3):
                ox, oy = base[0] + ddx, base[1] + ddy
                X, Y = mx + ox, my + oy
                ok = (X >= 0) & (X < dw) & (Y >= 0) & (Y < dh)
                inter = dst[Y[ok], X[ok]].sum()
                iou = inter / (len(mx) + len(xs) - inter)
                if iou > best[0]:
                    best = (iou, (s * m.shape[1] / src.shape[1], ox, oy, s))
    iou, (s, ox, oy, s_raw) = best
    # refine the move by 1 px at the best scale
    im = Image.fromarray(src.astype(np.uint8) * 255).resize((max(1, round(src.shape[1] * s_raw)),
                                                              max(1, round(src.shape[0] * s_raw))), Image.BILINEAR)
    m = np.array(im) > 127
    my, mx = np.nonzero(m)
    bo = (ox, oy)
    for ddy in range(-3, 4):
        for ddx in range(-3, 4):
            X, Y = mx + ox + ddx, my + oy + ddy
            ok = (X >= 0) & (X < dw) & (Y >= 0) & (Y < dh)
            inter = dst[Y[ok], X[ok]].sum()
            v = inter / (len(mx) + len(xs) - inter)
            if v > iou:
                iou, bo = v, (ox + ddx, oy + ddy)
    ox, oy = bo
    return s_raw, ox, oy, iou


def locate(key, debug=None):
    items = dict(bs.SHEETS)[BLOCKOUTS[key]]
    a = gc.sheet(key)
    out = []
    ov = Image.fromarray(a.copy(), "RGBA").convert("RGB") if debug else None
    dr = ImageDraw.Draw(ov) if debug else None
    for i, it in enumerate(items):
        tile, box, org, c = blockout(it[0])
        box = BOX.get(it[0].__name__, box)
        cutm = gc.cut((i % 3, i // 3) if gc.SHEETS[key]["grid"] else i, key)[..., 3] > 0
        ys, xs = np.nonzero(cutm)
        bx0, by0 = xs.min(), ys.min()
        dst = cutm[by0:ys.max() + 1, bx0:xs.max() + 1]
        src = np.array(tile)[..., 3] > 0
        s0 = dst.shape[1] / src.shape[1]
        s, ox, oy, iou = fit_masks(src, dst, s0)
        L, F, R = (p * s + np.array([ox + bx0, oy + by0]) for p in corners(c, box, org))
        W, D = box[2] - box[0], box[3] - box[1]
        org_ = np.array(org, float)
        fl = [tuple(np.round(np.array(c._scr(f)) - org_) * 0 + np.round((np.array(c._scr(f)) - org_) * s
                                                                     + np.array([ox + bx0, oy + by0])).astype(int))
              for f in blockout.flues]
        print("   flues (sheet px):", [(int(a), int(b)) for a, b in fl])
        out.append((i, it[1], (round(W, 2), round(D, 2)), tuple(np.round(L).astype(int)),
                    tuple(np.round(F).astype(int)), tuple(np.round(R).astype(int)), iou, s))
        wb = blockout.whole
        print("   whole (incl. roofs, crowns) %.2f x %.2f at %.2f,%.2f; ground at %.2f,%.2f" % (
            wb[2] - wb[0], wb[3] - wb[1], wb[0], wb[1], box[0], box[1]))
        print("%d %-26s fp %.2f x %.2f  L=%s F=%s R=%s  iou %.3f scale %.3f  painted W:D %.2f" % (
            i, it[1], W, D, tuple(np.round(L).astype(int)), tuple(np.round(F).astype(int)),
            tuple(np.round(R).astype(int)), iou, s, np.linalg.norm(F - L) / max(np.linalg.norm(R - F), 1e-6)))
        if debug:
            dr.rectangle([bx0, by0, xs.max(), ys.max()], outline=(0, 160, 255))
            T = L + (R - F)
            dr.polygon([tuple(L), tuple(F), tuple(R), tuple(T)], outline=(255, 0, 255))
    if debug:
        Path(debug).mkdir(parents=True, exist_ok=True)
        ov.save(Path(debug) / ("%s_locate.png" % key))
    return out


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("sheet")
    p.add_argument("--debug")
    args = p.parse_args()
    locate(args.sheet, args.debug)
