#!/usr/bin/env python3
"""God's Paths round 2 art: the six power effects, drawn in code (no AI generations). The emblems: god_select_emblems.py.

Writes into assets/pixellab/god_select/:
  fx_<type>_burst_1..8.png      112x128, transparent, play once at 12 fps (0.67 s)
  fx_<type>_loop_1..16.png      112x128, transparent, loop at 12 fps (1.33 s), seamless, burst_8 flows into loop_1
Every effect frame is anchored at (56, 119) = the statue's feet (plinth bottom centre). The statue sprite sits at
(24, 40) in the frame; parts of an effect that pass behind the statue are already cut out of its silhouette, so draw the
frame IN FRONT of the statue, exactly aligned. Veil's frames also hold a teal veil over the statue (it fades in and out).

Usage: python tools/dev/god_select_r2_art.py [--preview <dir>]   (--preview also writes contact sheets and GIFs there)
Deterministic: same code, same pixels.
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART = os.path.join(ROOT, "assets", "pixellab", "god_select")
W, H = 112, 128
AX, AY = 56, 119
SX, SY = AX - 32, AY - 79
NB, NL = 8, 16
TAU = math.tau
TYPES = ["ruin", "passage", "veil", "decree", "death", "dominion"]

# Five tones per god, dark to light (index 2 is near GOD_COL in god_select_screen.gd).
PAL = {
    "ruin": ["#4a1006", "#962410", "#e8602a", "#ffa83c", "#ffe890"],
    "passage": ["#0e2460", "#2050b0", "#4a90e8", "#98ccff", "#eef8ff"],
    "veil": ["#0a3034", "#156660", "#3ab8a8", "#86eadb", "#dcfff6"],
    "decree": ["#5e4214", "#a88030", "#dcb658", "#f0d890", "#fffbe8"],
    "death": ["#163a20", "#367046", "#68b05c", "#98d880", "#dcffd2"],
    "dominion": ["#260c44", "#56289a", "#a060e0", "#d0a2ff", "#f6ecff"],
}
STONE = ["#22262f", "#4c5262", "#7c8496", "#aab2c2"]


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def clamp(v, lo=0.0, hi=1.0):
    return lo if v < lo else hi if v > hi else v


def ease_out(v):
    v = clamp(v)
    return 1 - (1 - v) ** 2


def statue_mask(t):
    im = Image.open(os.path.join(ART, "statue_%s.png" % t)).convert("RGBA")
    m = np.zeros((H, W), bool)
    m[SY:SY + 80, SX:SX + 64] = np.array(im)[:, :, 3] > 0
    return m


def dilate(m, r):
    out = m.copy()
    for _ in range(r):
        n = out.copy()
        n[1:, :] |= out[:-1, :]
        n[:-1, :] |= out[1:, :]
        n[:, 1:] |= out[:, :-1]
        n[:, :-1] |= out[:, 1:]
        if r == 1:
            n[1:, 1:] |= out[:-1, :-1]
            n[:-1, :-1] |= out[1:, 1:]
            n[1:, :-1] |= out[:-1, 1:]
            n[:-1, 1:] |= out[1:, :-1]
        out = n
    return out


class Frame:
    def __init__(self, mask, w=W, h=H):
        self.w, self.h = w, h
        self.rgb = np.zeros((h, w, 3))
        self.a = np.zeros((h, w))
        self.mask = mask
        self.glow_f = np.zeros((h, w), bool)
        self.glow_b = np.zeros((h, w), bool)

    def put(self, x, y, col, alpha=1.0, behind=False, glow=False):
        x = int(math.floor(x + 0.5))
        y = int(math.floor(y + 0.5))
        if x < 0 or y < 0 or x >= self.w or y >= self.h or alpha <= 0:
            return
        if behind and self.mask is not None and self.mask[y, x]:
            return
        c = hexc(col) if isinstance(col, str) else col
        a0 = self.a[y, x]
        na = alpha + a0 * (1 - alpha)
        self.rgb[y, x] = (c * alpha + self.rgb[y, x] * a0 * (1 - alpha)) / na
        self.a[y, x] = na
        if glow:
            (self.glow_b if behind else self.glow_f)[y, x] = True

    def under(self, m, col, alpha):
        c = hexc(col)
        a0 = self.a[m]
        na = a0 + alpha * (1 - a0)
        self.rgb[m] = (self.rgb[m] * a0[:, None] + c[None, :] * alpha * (1 - a0)[:, None]) / na[:, None]
        self.a[m] = na

    def halo(self, c1, c2, a1=0.42, a2=0.16):
        for src, behind in ((self.glow_f, False), (self.glow_b, True)):
            if not src.any():
                continue
            d1 = dilate(src, 1)
            d2 = dilate(d1, 1)
            m1 = d1 & ~src
            m2 = d2 & ~d1
            if behind and self.mask is not None:
                m1 &= ~self.mask
                m2 &= ~self.mask
            self.under(m1, c1, a1)
            self.under(m2, c2, a2)

    def image(self):
        arr = np.zeros((self.h, self.w, 4), np.uint8)
        arr[:, :, :3] = np.clip(np.round(self.rgb * 255), 0, 255).astype(np.uint8)
        # see-through pixels (glow, mist) snap to eight fixed levels
        qa = np.where(self.a >= 0.97, 1.0, np.round(self.a * 8) / 8)
        arr[:, :, 3] = np.clip(np.round(qa * 255), 0, 255).astype(np.uint8)
        arr[arr[:, :, 3] == 0] = 0
        return Image.fromarray(arr, "RGBA")


# ---- primitives -----------------------------------------------------------------------------------------------------

def disc(fr, cx, cy, r, col, **kw):
    cx, cy = round(cx), round(cy)
    R = int(math.ceil(r)) + 1
    for dy in range(-R, R + 1):
        for dx in range(-R, R + 1):
            if dx * dx + dy * dy <= r * r + r * 0.6:
                fr.put(cx + dx, cy + dy, col, **kw)


def line_pts(x0, y0, x1, y1):
    x0, y0, x1, y1 = round(x0), round(y0), round(x1), round(y1)
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        pts.append((x0, y0))
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy
    return pts


def poly_pts(poly):
    pts = []
    for (a, b) in zip(poly, poly[1:]):
        seg = line_pts(a[0], a[1], b[0], b[1])
        pts.extend(seg if not pts else seg[1:])
    return pts


def ring(fr, cx, cy, rx, ry, col, back=True, keep=None, a0=0.0, all_behind=False, **kw):
    """An ellipse outline; its far (upper) half is cut out of the statue. keep(u) -> bool thins it (u in 0..1 round it)."""
    n = max(24, int(TAU * max(rx, ry) * 1.8))
    seen = set()
    for i in range(n):
        u = i / n
        if keep is not None and not keep(u):
            continue
        ang = a0 + TAU * u
        x, y = round(cx + rx * math.cos(ang)), round(cy + ry * math.sin(ang))
        if (x, y) in seen:
            continue
        seen.add((x, y))
        fr.put(x, y, col, behind=all_behind or (back and math.sin(ang) < -0.02), **kw)


def dashes(count, fill, phase=0.0):
    return lambda u: ((u * count + phase) % 1.0) < fill


def bezier(p0, p1, p2, n):
    out = []
    for i in range(n + 1):
        s = i / n
        x = (1 - s) ** 2 * p0[0] + 2 * (1 - s) * s * p1[0] + s * s * p2[0]
        y = (1 - s) ** 2 * p0[1] + 2 * (1 - s) * s * p1[1] + s * s * p2[1]
        out.append((round(x), round(y)))
    dedup = []
    for p in out:
        if not dedup or dedup[-1] != p:
            dedup.append(p)
    return dedup


def shock(fr, pal, bt, cx=AX, cy=AY - 4, r0=10, r1=46, t0=0.0, t1=0.55):
    """A flat ground shock ring on the platform top, fading as it widens."""
    s = (bt - t0) / (t1 - t0)
    if s < 0 or s > 1:
        return
    rx = r0 + (r1 - r0) * ease_out(s)
    col = pal[4] if s < 0.2 else pal[3] if s < 0.45 else pal[2] if s < 0.7 else pal[1]
    ring(fr, cx, cy, rx, rx * 0.26, col, keep=dashes(28, 1.0 - 0.6 * s), glow=s < 0.45)


def flash(fr, pal, cx, cy, r):
    disc(fr, cx, cy, r, pal[3], glow=True)
    disc(fr, cx, cy, max(1, r * 0.55), pal[4], glow=True)
    disc(fr, cx, cy, max(0.5, r * 0.25), "#ffffff")


# ---- Ruin: fire cracks up the plinth, rising embers and small rocks ---------------------------------------------------

RUIN_CRACKS = [
    [(46, 119), (47, 117), (45, 115), (46, 113), (45, 111)],
    [(57, 119), (56, 117), (58, 115), (57, 113), (59, 111), (58, 109)],
    [(67, 119), (68, 117), (66, 115), (67, 112)],
    [(41, 119), (37, 120), (34, 120), (31, 122), (27, 122), (24, 123)],
    [(71, 119), (75, 120), (78, 120), (81, 122), (85, 122), (88, 123)],
    [(40, 112), (37, 111), (35, 109), (32, 109), (29, 107)],
    [(72, 112), (75, 111), (77, 109), (80, 109), (83, 107)],
    [(55, 120), (54, 122), (52, 123)],
]
RUIN_FLAMES = [(45, 111), (58, 109), (67, 112), (24, 123), (88, 123), (31, 122), (81, 122), (29, 107), (83, 107),
               (52, 123)]


def rock(fr, x, y, size, pal):
    x, y = round(x), round(y)
    if size >= 3:
        rows = [[STONE[3], STONE[2], STONE[2]], [STONE[2], STONE[1], STONE[1]], [pal[3], pal[2], STONE[1]]]
    elif size == 2:
        rows = [[STONE[3], STONE[2]], [pal[2], STONE[1]]]
    else:
        rows = [[STONE[2]]]
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            fr.put(x + i, y + j, c)


def flame(fr, x, yb, h, pal, ph):
    for j in range(h):
        f = j / max(1, h)
        sway = round(math.sin(ph + j * 0.9) * 1.0 * f)
        core = pal[4] if f < 0.34 else pal[3] if f < 0.7 else pal[2]
        fr.put(x + sway, yb - j, core, glow=True)
        if f < 0.4 and h >= 3:
            fr.put(x + sway - 1, yb - j, pal[2])
            fr.put(x + sway + 1, yb - j, pal[2])
    fr.put(x + round(math.sin(ph + h) * 1.0), yb - h, pal[1])


def ruin(fr, bt, lt, li):
    pal = PAL["ruin"]
    burst = bt is not None
    rng = random.Random(11)
    cracks = [poly_pts(c) for c in RUIN_CRACKS]
    reveal = 1.0 if not burst else clamp(bt / 0.45)
    # cracks: glowing seams with magma pulses running out from the plinth
    for k, pts in enumerate(cracks):
        ph = k * 0.37
        v = 0.5 + 0.5 * math.sin(TAU * (lt * 2 + ph))
        n = len(pts)
        for idx, (x, y) in enumerate(pts):
            if idx / n > reveal:
                break
            if burst and bt < 0.3:
                col = "#ffffff" if idx / n > reveal - 0.25 else pal[4]
            else:
                pulse = ((idx / n - lt * 2 - ph) % 1.0) < 0.18
                col = pal[4] if pulse else (pal[3] if v > 0.4 else pal[2])
            fr.put(x, y, col, glow=True)
    # flames on the crack ends
    for k, (x, y) in enumerate(RUIN_FLAMES):
        hl = round(3 + 4 * (0.5 + 0.5 * math.sin(TAU * (lt * 3 + k * 0.29)))) - (2 if k >= 7 else 0)
        if burst:
            if bt < 0.15 + 0.04 * k:
                continue
            hb = round(9 - 6 * clamp((bt - 0.2) / 0.8)) + (k % 3)
            hl = round(hb * (1 - li) + hl * li)
        flame(fr, x, y, hl, pal, TAU * lt * 3 + k)
    # loop embers
    for k in range(18):
        p = rng.random()
        x0 = rng.uniform(26, 86)
        y0 = rng.choice([110, 112, 118, 120])
        rise = rng.uniform(55, 80)
        sw = rng.uniform(2, 5)
        if burst and rng.random() > li:
            continue
        age = (lt + p) % 1.0
        if age > 0.92:
            continue
        x = x0 + math.sin(TAU * (age * 1.3 + p)) * sw
        y = y0 - rise * age
        col = pal[4] if age < 0.25 else pal[3] if age < 0.55 else pal[2] if age < 0.8 else pal[1]
        fr.put(x, y, col, glow=age < 0.55)
        if k % 4 == 0 and age < 0.5:
            fr.put(x, y + 1, pal[2])
    # loop rocks: small stones lifted by the heat and crumbling
    for k in range(3):
        p = k / 3 + 0.1
        x0 = [32, 80, 63][k]
        age = (lt + p) % 1.0
        if burst and li < 0.6 + 0.15 * k:
            continue
        if age > 0.86:
            continue
        y = 116 - 34 * ease_out(age) + math.sin(TAU * age * 2) * 1.0
        x = x0 + (age * 6 if x0 > 56 else -age * 6)
        rock(fr, x, y, 3 if age < 0.55 else 2 if age < 0.75 else 1, pal)
    if not burst:
        return
    # burst: ground flash, shock ring, thrown rocks, an ember spray
    if bt < 0.13:
        flash(fr, pal, AX, AY - 2, 6)
    shock(fr, pal, bt, r0=14, r1=52, t1=0.6)
    r2 = random.Random(5)
    fi = bt * NB
    for k in range(7):
        x0, y0 = r2.choice(RUIN_FLAMES)
        vx = r2.uniform(-2.6, 2.6)
        vy = r2.uniform(5.5, 8.0)
        tt = fi - 0.6
        if tt < 0:
            continue
        y = y0 - vy * tt + 0.55 * 1.4 * tt * tt
        x = x0 + vx * tt
        if y > y0 + 2:
            continue
        rock(fr, x, y, 3 if k % 2 == 0 else 2, pal)
    for k in range(18):
        x0, y0 = r2.choice(RUIN_FLAMES)
        vy = r2.uniform(6, 11)
        vx = r2.uniform(-2.2, 2.2)
        tt = fi - r2.uniform(0, 1.5)
        if tt < 0:
            continue
        age = tt / NB
        x = x0 + vx * tt + math.sin(tt * 1.3 + k) * 1.5
        y = y0 - vy * tt * (1 - age * 0.45)
        col = pal[4] if age < 0.3 else pal[3] if age < 0.6 else pal[2]
        fr.put(x, y, col, glow=True)
        fr.put(x - vx * 0.25, y + 1, pal[2] if age < 0.5 else pal[1])


# ---- Passage: blue orbs spinning out into widening rings ------------------------------------------------------------

PASS_HANDS = [(34, 54), (75, 54)]
PASS_C = (56, 86)


def orb(fr, x, y, size, pal, behind):
    if size >= 2:
        disc(fr, x, y, 1.6, pal[2] if behind else pal[3], behind=behind, glow=True)
        fr.put(x, y, pal[4], behind=behind, glow=True)
        fr.put(x - 1, y - 1, pal[4], behind=behind)
    else:
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            fr.put(x + dx, y + dy, pal[3] if (dx, dy) != (0, 0) else pal[4], behind=behind, glow=True)


def orbit_pos(a, rx=32, ry=9, c=PASS_C):
    return c[0] + rx * math.cos(a), c[1] + ry * math.sin(a), math.sin(a) < 0


def passage(fr, bt, lt, li):
    pal = PAL["passage"]
    burst = bt is not None
    # widening rings, two per loop, spinning dashes
    for k in range(2):
        age = (lt + k / 2) % 1.0
        if burst and (li < 0.5 + 0.4 * k):
            continue
        rx = 30 + 24 * age
        ry = 9 + 6 * age
        cy = PASS_C[1] + 12 * age
        col = pal[4] if age < 0.12 else pal[3] if age < 0.35 else pal[2] if age < 0.65 else pal[1]
        ring(fr, PASS_C[0], cy, rx, ry, col, keep=dashes(24, 0.85 - 0.55 * age, age * 2.0), glow=age < 0.35)
    # three orbs on the orbit, each with a short trail
    for k in range(3):
        a = TAU * (lt + k / 3)
        if burst:
            e = ease_out(clamp((bt - 0.08 * k) / 0.85))
            if e <= 0:
                continue
            hand = PASS_HANDS[k % 2]
            a = a - (1 - e) * TAU * 0.8
            ox, oy, beh = orbit_pos(a)
            x, y = hand[0] * (1 - e) + ox * e, hand[1] * (1 - e) + oy * e
        else:
            x, y, beh = orbit_pos(a)
        for j in (3, 2, 1):
            tx, ty, tb = orbit_pos(a - 0.14 * j)
            if burst:
                tx, ty = x + (tx - orbit_pos(a)[0]), y + (ty - orbit_pos(a)[1])
            fr.put(tx, ty, pal[j - 1] if j > 1 else pal[2], behind=tb, glow=j == 1)
        orb(fr, x, y, 2, pal, beh)
    # two small orbs on a tilted inner orbit, the other way round
    for k in range(2):
        if burst and li < 0.7:
            continue
        a = -TAU * (lt + k / 2) + 1.0
        lx, ly = 22 * math.cos(a), 7 * math.sin(a)
        tilt = -0.35
        x = PASS_C[0] + lx * math.cos(tilt) - ly * math.sin(tilt)
        y = PASS_C[1] - 14 + lx * math.sin(tilt) + ly * math.cos(tilt)
        orb(fr, x, y, 1, pal, math.sin(a) < 0)
    if not burst:
        return
    fi = bt * NB
    if fi < 1.0:
        for hx, hy in PASS_HANDS:
            flash(fr, pal, hx, hy, 4)
    elif fi < 2.0:
        for hx, hy in PASS_HANDS:
            ring(fr, hx, hy, 5, 5, pal[3], back=False, glow=True)
    # four fliers spiral out from the hands and fade past the edge of the platform
    for k in range(4):
        s = clamp(bt * 1.25 - 0.05 * k)
        if s <= 0 or s >= 1:
            continue
        hand = PASS_HANDS[k % 2]
        a = (math.pi if k % 2 == 0 else 0.0) + (1 if k % 2 else -1) * s * TAU * 0.9 + k * 0.4
        rx = 18 + 40 * s
        ry = 6 + 14 * s
        x = PASS_C[0] + rx * math.cos(a)
        y = PASS_C[1] - 30 * (1 - s) + ry * math.sin(a)
        e = clamp(s * 4)
        x = hand[0] * (1 - e) + x * e
        y = hand[1] * (1 - e) + y * e
        orb(fr, x, y, 2 if s < 0.6 else 1, pal, math.sin(a) < 0 and e >= 1)
    # two big rings out of the burst
    for k, (t0, t1) in enumerate(((0.05, 0.75), (0.28, 1.0))):
        s = (bt - t0) / (t1 - t0)
        if s < 0 or s > 1:
            continue
        rx = 10 + 42 * ease_out(s)
        col = pal[4] if s < 0.2 else pal[3] if s < 0.5 else pal[2] if s < 0.8 else pal[1]
        ring(fr, PASS_C[0], PASS_C[1] + 8 * s, rx, rx * 0.28, col, keep=dashes(30, 1 - 0.5 * s, s), glow=s < 0.5)


# ---- Veil: teal mist pouring out and curling round; the statue fades in and out --------------------------------------

def veil(fr, bt, lt, li):
    pal = PAL["veil"]
    burst = bt is not None
    dens = {False: np.zeros((H, W)), True: np.zeros((H, W))}
    yy, xx = np.mgrid[0:H, 0:W]

    def blob(x, y, r, amp, behind):
        if r <= 0 or amp <= 0:
            return
        d2 = ((xx - x) ** 2 + ((yy - y) * 1.6) ** 2) / (r * r)
        dens[behind] += amp * np.clip(1 - d2, 0, None)

    rng = random.Random(23)
    # ground curls: mist spiralling out round the feet and curling up at the ends
    for k in range(12):
        p = k / 12 + rng.uniform(-0.02, 0.02)
        th0 = rng.uniform(0, TAU)
        if burst and rng.random() > li * 1.1:
            continue
        for j in range(5):
            age = (lt + p) % 1.0 - j * 0.045
            if age <= 0:
                continue
            th = th0 + age * TAU * 0.45
            r = 8 + age * 34
            x = AX + r * math.cos(th)
            y = AY - 4 + r * 0.3 * math.sin(th) - age * age * 18
            env = math.sin(math.pi * age) * (1 - j * 0.16)
            blob(x, y, 3.5 + 5 * env, 1.0 * env ** 0.6, math.sin(th) < 0)
    # rising curls that wind round the statue
    for k in range(5):
        p = k / 5 + 0.07
        if burst and li < 0.4 + 0.12 * k:
            continue
        for j in range(4):
            age = (lt + p) % 1.0 - j * 0.035
            if age <= 0:
                continue
            th = k * 1.7 + age * TAU
            r = 19 - age * 5
            x = AX + r * math.cos(th)
            y = AY - 6 - age * 62
            env = math.sin(math.pi * age) * (1 - j * 0.2)
            blob(x, y, 2.5 + 2.5 * env, 1.0 * env ** 0.7, math.sin(th) < 0)
    veil_a = 0.5 * (0.5 - 0.5 * math.cos(TAU * lt)) ** 1.6
    if burst:
        fi = bt * NB
        # the pour: a mass of mist leaves the hood and falls down the cloak, then floods out over the platform
        if fi < 4:
            yb = 72 + fi * 11
            blob(AX, yb, 10 + fi * 2, 1.8 - fi * 0.25, False)
            blob(AX - 4, yb - 8, 7, 1.0, True)
        for k in range(8):
            s = (bt - 0.25 - 0.03 * k) / 0.7
            if s < 0 or s > 1:
                continue
            th = k * TAU / 8 + s * 2.2
            r = 6 + 44 * ease_out(s)
            env = math.sin(math.pi * s)
            blob(AX + r * math.cos(th), AY - 4 + r * 0.3 * math.sin(th) - s * s * 14, 5 + 5 * env, 1.4 * env,
                 math.sin(th) < 0)
        veil_a = [0.15, 0.45, 0.6, 0.5, 0.38, 0.24, 0.12, 0.04][min(7, int(round(fi)))]
    # the statue fades: a teal veil over its silhouette, in fixed steps
    step = round(veil_a / 0.15) * 0.15
    if step > 0:
        ys, xs = np.nonzero(fr.mask)
        for y, x in zip(ys, xs):
            fr.put(x, y, pal[0] if (x + y) % 2 else pal[1], alpha=step)
    # mist bands: hard-edged tone steps, see-through on purpose
    bands = [(0.22, pal[1], 0.42), (0.5, pal[2], 0.55), (0.9, pal[3], 0.7), (1.45, pal[4], 0.8)]
    for behind in (True, False):
        d = dens[behind]
        for y in range(H):
            for x in range(W):
                v = d[y, x]
                if v < bands[0][0]:
                    continue
                b = 0
                for i, (th, _, _) in enumerate(bands):
                    if v >= th:
                        b = i
                # a lighter crest on the top edge of each band
                if b < 3 and y > 0 and d[y - 1, x] < bands[b][0]:
                    b += 1
                fr.put(x, y, bands[b][1], alpha=bands[b][2], behind=behind)


# ---- Decree: a gold rune circle stamping onto the platform and rising ------------------------------------------------

RUNES = [
    [(0, -1), (0, 0), (0, 1)],
    [(-1, -1), (0, -1), (1, -1), (0, 0), (0, 1)],
    [(-1, 1), (0, 0), (1, 1), (0, -1)],
    [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)],
    [(-1, -1), (-1, 0), (-1, 1), (0, 0), (1, -1)],
    [(-1, -1), (1, -1), (0, 0), (0, 1)],
]
DEC_C = (AX, AY - 6)


def rune_circle(fr, cx, cy, rx, pal, rot, bright, glyphs=True, thin=False):
    ry = rx * 0.26
    c_out = pal[4] if bright > 1 else pal[3] if bright > 0.5 else pal[2]
    c_in = pal[3] if bright > 0.5 else pal[2]
    ring(fr, cx, cy, rx, ry, c_out, glow=bright > 0.3)
    if thin:
        return
    ring(fr, cx, cy, rx * 0.74, ry * 0.72, c_in, glow=False)
    # an inscribed hexagram
    pts = [(cx + rx * 0.74 * math.cos(rot + k * TAU / 6), cy + ry * 0.72 * math.sin(rot + k * TAU / 6), k)
           for k in range(6)]
    for tri in ((0, 2, 4), (1, 3, 5)):
        for a, b in ((tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0])):
            for (x, y) in line_pts(pts[a][0], pts[a][1], pts[b][0], pts[b][1]):
                fr.put(x, y, pal[1] if bright < 1.2 else pal[2], behind=y < cy - 1)
    if glyphs:
        n = 10
        for k in range(n):
            ang = rot + TAU * k / n
            gx = cx + rx * 0.87 * math.cos(ang)
            gy = cy + ry * 0.86 * math.sin(ang)
            beh = math.sin(ang) < -0.02
            for dx, dy in RUNES[k % len(RUNES)]:
                fr.put(round(gx) + dx, round(gy) + (dy if math.sin(ang) > 0.5 else 0 if dy else 0),
                       pal[4] if bright > 0.5 else pal[3], behind=beh, glow=bright > 0.5)


def decree(fr, bt, lt, li):
    pal = PAL["decree"]
    burst = bt is not None
    rot = TAU * lt / 10  # one glyph step per loop: seamless
    pulse = 0.5 + 0.5 * math.sin(TAU * lt)
    rng = random.Random(31)
    if burst:
        fi = bt * NB
        if fi < 2.5:
            # the circle comes down from above, big, and slams onto the platform
            s = fi / 2.5
            rx = 56 - 18 * s
            cy = DEC_C[1] - 44 * (1 - s) ** 1.5
            rune_circle(fr, DEC_C[0], cy, rx, pal, -1.0 + s, 0.8, glyphs=False)
        else:
            rune_circle(fr, DEC_C[0], DEC_C[1], 38, pal, rot, 1.5 if fi < 4 else 0.6 + pulse * 0.6)
            if fi < 3.6:
                disc(fr, DEC_C[0], DEC_C[1], 3, pal[4], glow=True)
        if 2.5 <= fi < 5.5:
            # the stamp: shards of light kicked out and a flat shock ring
            s = (fi - 2.5) / 3.0
            for k in range(14):
                ang = TAU * k / 14 + 0.2
                r = 30 + 26 * s
                x = DEC_C[0] + r * math.cos(ang)
                y = DEC_C[1] + r * 0.26 * math.sin(ang) - 10 * s * (1 - s) * 4 * (k % 3) / 2
                fr.put(x, y, pal[4] if s < 0.4 else pal[3], behind=math.sin(ang) < 0, glow=s < 0.5)
                fr.put(x + math.cos(ang), y, pal[2], behind=math.sin(ang) < 0)
        shock(fr, pal, bt, cy=DEC_C[1], r0=38, r1=58, t0=0.31, t1=0.75)
        # the first ring rises off the circle up the statue
        s = (bt - 0.4) / 0.6
        if 0 <= s <= 1:
            rx = 38 - 14 * s
            col = pal[4] if s < 0.3 else pal[3] if s < 0.7 else pal[2]
            ring(fr, DEC_C[0], DEC_C[1] - 70 * ease_out(s), rx, rx * 0.26, col, keep=dashes(26, 1 - 0.4 * s),
                 glow=True)
    else:
        rune_circle(fr, DEC_C[0], DEC_C[1], 38, pal, rot, 0.6 + pulse * 0.6)
    # the loop's rising ring
    if not burst or li > 0.8:
        age = lt
        rx = 36 - 12 * age
        col = pal[4] if age < 0.2 else pal[3] if age < 0.55 else pal[2] if age < 0.8 else pal[1]
        if age < 0.95:
            ring(fr, DEC_C[0], DEC_C[1] - 2 - 72 * ease_out(age), rx, rx * 0.26, col,
                 keep=dashes(26, 0.95 - 0.55 * age, age), glow=age < 0.55)
    # gold motes rising off the circle
    for k in range(8):
        p = rng.random()
        ang = rng.uniform(0, TAU)
        if burst and rng.random() > li:
            continue
        age = (lt + p) % 1.0
        x = DEC_C[0] + 36 * math.cos(ang)
        y = DEC_C[1] + 9.5 * math.sin(ang) - age * 40
        if age > 0.85:
            continue
        fr.put(x, y, pal[4] if age < 0.4 else pal[3] if age < 0.7 else pal[2], behind=math.sin(ang) < 0,
               glow=age < 0.4)


# ---- Death: pale green soul wisps rising -----------------------------------------------------------------------------

def wisp(fr, path, age, size, pal, behind):
    """path(age) -> (x, y); a ghostly head with eyes and a tapering tail along its own past path."""
    if age < 0 or age > 0.94:
        return
    fade = 0 if age < 0.62 else 1 if age < 0.8 else 2
    for j in range(8, 0, -1):
        a = age - j * 0.022
        if a < 0:
            continue
        x, y = path(a)
        col = pal[3 - fade] if j <= 2 else pal[max(0, 2 - fade)] if j <= 5 else pal[max(0, 1 - fade)]
        fr.put(x, y, col, behind=behind, glow=j <= 2 and fade == 0)
        if j <= 2 and size >= 2:
            fr.put(x - 1, y, pal[max(0, 2 - fade)], behind=behind)
            fr.put(x + 1, y, pal[max(0, 2 - fade)], behind=behind)
    x, y = path(age)
    x, y = round(x), round(y)
    if size >= 2 and age > 0.06 and fade < 2:
        disc(fr, x, y, 2, pal[3 - fade], behind=behind, glow=True)
        fr.put(x - 1, y - 1, pal[4 - fade], behind=behind)
        fr.put(x, y - 1, pal[4 - fade], behind=behind)
        fr.put(x - 1, y, pal[0], behind=behind)
        fr.put(x + 1, y, pal[0], behind=behind)
    else:
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            fr.put(x + dx, y + dy, pal[3 - fade] if (dx, dy) != (0, 0) else pal[4 - fade], behind=behind,
                   glow=fade == 0)


def death(fr, bt, lt, li):
    pal = PAL["death"]
    burst = bt is not None
    rng = random.Random(41)
    # a faint soul pool on the platform, its rim dashes turning
    pa = 0.26 + 0.1 * math.sin(TAU * lt)
    if burst:
        pa *= clamp(bt * 2)
    for y in range(AY - 12, AY + 4):
        for x in range(AX - 30, AX + 31):
            if ((x - AX) / 28.0) ** 2 + ((y - (AY - 4)) / 7.0) ** 2 <= 1.0:
                fr.put(x, y, pal[1], alpha=round(pa / 0.08) * 0.08, behind=y < AY - 4)
    ring(fr, AX, AY - 4, 28, 7, pal[2], keep=dashes(18, 0.5, lt * 2))
    for k in range(9):
        p = k / 9 + rng.uniform(-0.03, 0.03)
        x0 = rng.uniform(32, 80)
        y0 = rng.uniform(110, 118)
        amp = rng.uniform(3, 6)
        ph = rng.random()
        size = 2 if k % 2 == 0 else 1
        beh = k % 3 == 1
        if burst and rng.random() > li:
            continue
        age = (lt + p) % 1.0

        def path(a, x0=x0, y0=y0, amp=amp, ph=ph):
            return x0 + amp * math.sin(TAU * (a * 1.2 + ph)), y0 - 80 * a

        wisp(fr, path, age, size, pal, beh)
    if not burst:
        return
    fi = bt * NB
    if fi < 1:
        flash(fr, pal, AX, AY - 4, 6)
    shock(fr, pal, bt, r0=12, r1=50, t1=0.6)
    # eight souls torn up out of the platform, winding round the statue as they climb fast
    for k in range(8):
        th0 = k * TAU / 8

        def path(a, th0=th0):
            th = th0 + a * TAU * 1.1
            return AX + (20 + 8 * a) * math.cos(th), AY - 6 - 125 * a

        s = clamp(bt - 0.04 * k) * 0.85
        if s <= 0:
            continue
        th = th0 + s * TAU * 1.1
        wisp(fr, path, s, 2 if k % 2 == 0 else 1, pal, math.sin(th) < 0)


# ---- Dominion: purple waves pulsing out, thin threads ----------------------------------------------------------------

DOM_C = (56, 74)
DOM_HANDS = [(30, 67), (81, 67)]
DOM_THREADS = [
    (0, (6, 40), (14, 44)), (0, (4, 90), (14, 74)), (0, (18, 122), (20, 98)),
    (1, (106, 40), (98, 44)), (1, (108, 90), (98, 74)), (1, (94, 122), (92, 98)),
]


def wave(fr, cx, cy, r, s, pal, thick):
    col_o = pal[2] if s < 0.65 else pal[1]
    col_i = pal[3] if s < 0.3 else pal[2] if s < 0.65 else pal[1]
    keep = dashes(36, 1 - 0.5 * s, s * 0.5)
    ring(fr, cx, cy, r, r * 1.08, col_o, all_behind=True, keep=keep, glow=s < 0.6)
    if thick:
        ring(fr, cx, cy, r - 1, (r - 1) * 1.08, col_i, all_behind=True, keep=keep)


def dominion(fr, bt, lt, li):
    pal = PAL["dominion"]
    burst = bt is not None
    # two aura waves per loop, pulsing out from behind the statue
    for k in range(2):
        age = (lt + k / 2) % 1.0
        if burst and li < 0.55 + 0.4 * k:
            continue
        wave(fr, DOM_C[0], DOM_C[1], 24 + 22 * age, age, pal, age < 0.5)
    # a ground wave on the platform once per loop
    if not burst or li > 0.7:
        age = lt
        rx = 16 + 34 * age
        ring(fr, AX, AY - 4, rx, rx * 0.26, pal[2] if age < 0.5 else pal[1], keep=dashes(24, 0.9 - 0.5 * age))
    # threads from the hands out to the edges, swaying, with sparks running out along them
    grow = 1.0 if not burst else ease_out(clamp((bt - 0.08) / 0.45))
    for k, (hand, end, ctrl) in enumerate(DOM_THREADS):
        hx, hy = DOM_HANDS[hand]
        sway = 2.0 * math.sin(TAU * (lt + k * 0.17))
        pts = bezier((hx, hy), (ctrl[0], ctrl[1] + sway), end, 40)
        n = len(pts)
        lim = int(n * grow)
        for idx, (x, y) in enumerate(pts[:lim]):
            u = idx / n
            if u > 0.7 and idx % 2:
                continue
            fr.put(x, y, pal[3] if u < 0.25 else pal[2] if u < 0.6 else pal[1])
        if burst and grow < 1 and lim > 0:
            x, y = pts[lim - 1]
            disc(fr, x, y, 1, pal[4], glow=True)
        for q in range(2):
            u = (lt * 2 + q / 2 + k * 0.23) % 1.0
            idx = int(u * lim)
            if 0 < idx < lim and u < 0.85:
                x, y = pts[idx]
                fr.put(x, y, pal[4], glow=True)
                x2, y2 = pts[max(0, idx - 1)]
                fr.put(x2, y2, pal[3])
    # hand glows
    for hx, hy in DOM_HANDS:
        if (round(lt * NL) + hx) % 4 < 2:
            fr.put(hx, hy - 2, pal[4], glow=True)
    if not burst:
        return
    fi = bt * NB
    if fi < 1:
        flash(fr, pal, DOM_C[0], DOM_C[1] - 6, 6)
    for k, (t0, t1) in enumerate(((0.0, 0.7), (0.22, 0.95))):
        s = (bt - t0) / (t1 - t0)
        if 0 <= s <= 1:
            wave(fr, DOM_C[0], DOM_C[1], 10 + 38 * ease_out(s), s, pal, True)
    shock(fr, pal, bt, r0=14, r1=50, t0=0.1, t1=0.7)
    # sparks flung out from the chest
    for k in range(12):
        ang = TAU * k / 12 + 0.26
        s = clamp(bt * 1.4 - 0.05 * (k % 3))
        if s <= 0.05 or s > 0.9:
            continue
        r = 10 + 38 * ease_out(s)
        x = DOM_C[0] + r * math.cos(ang)
        y = DOM_C[1] - 6 + r * 1.08 * math.sin(ang)
        fr.put(x, y, pal[4] if s < 0.4 else pal[3], behind=True, glow=True)
        fr.put(x - math.cos(ang) * 2, y - math.sin(ang) * 2, pal[2], behind=True)


FX = {"ruin": ruin, "passage": passage, "veil": veil, "decree": decree, "death": death, "dominion": dominion}


def render_fx(t):
    mask = statue_mask(t)
    pal = PAL[t]
    out = {"burst": [], "loop": []}
    for i in range(NB):
        bt = i / NB
        lt = ((i - NB) / NL) % 1.0
        li = clamp((bt - 0.3) / 0.575)
        fr = Frame(mask)
        FX[t](fr, bt, lt, li)
        fr.halo(pal[2], pal[1])
        out["burst"].append(fr.image())
    for i in range(NL):
        fr = Frame(mask)
        FX[t](fr, None, i / NL, 1.0)
        fr.halo(pal[2], pal[1])
        out["loop"].append(fr.image())
    return out


# ---- previews --------------------------------------------------------------------------------------------------------

FEET = [(324, 151), (476, 170), (521, 253), (317, 300), (118, 253), (161, 170)]
EMBLEM_AT = (320, 200)  # the screen's EMBLEM_AT


def screen(sel, fx_img, emblem=None):
    bg = Image.open(os.path.join(ART, "background.png")).convert("RGBA")
    order = sorted(range(6), key=lambda i: FEET[i][1])
    for i in order:
        st = Image.open(os.path.join(ART, "statue_%s.png" % TYPES[i])).convert("RGBA")
        if i != sel:
            a = np.array(st).astype(float)
            a[:, :, :3] *= 0.72
            st = Image.fromarray(a.astype(np.uint8), "RGBA")
        bg.alpha_composite(st, (FEET[i][0] - 32, FEET[i][1] - 79))
        if i == sel and fx_img is not None:
            bg.alpha_composite(fx_img, (FEET[i][0] - AX, FEET[i][1] - AY))
    if emblem is not None:
        bg.alpha_composite(emblem, (EMBLEM_AT[0] - emblem.width // 2, EMBLEM_AT[1] - emblem.height // 2))
    return bg


def previews(out_dir, fx):
    os.makedirs(out_dir, exist_ok=True)
    for name, pick in (("burst", lambda t: fx[t]["burst"][4]), ("loop", lambda t: fx[t]["loop"][5])):
        sheet = Image.new("RGBA", (640 * 3, 360 * 2))
        for i, t in enumerate(TYPES):
            sheet.paste(screen(i, pick(t)), ((i % 3) * 640, (i // 3) * 360))
        sheet.save(os.path.join(out_dir, "r2_sheet_%s.png" % name))
    # close-ups: every frame of every effect on the real platform, at 2x
    cw, ch = W + 16, H + 8
    zoom = Image.new("RGBA", (cw * (NB + 4), ch * 6 * 2), (10, 10, 14, 255))
    for i, t in enumerate(TYPES):
        fx_list = fx[t]["burst"] + fx[t]["loop"]
        for j, im in enumerate(fx_list):
            full = screen(i, im, None)
            fxp, fyp = FEET[i][0] - AX, FEET[i][1] - AY
            crop = full.crop((fxp - 8, fyp, fxp + W + 8, fyp + H + 8))
            row = i * 2 + (0 if j < NB else 1)
            col = j if j < NB else (j - NB) % (NB + 4)
            if j >= NB + NB + 4:
                continue
            zoom.paste(crop, (col * cw, row * ch))
    zoom.resize((zoom.width * 2, zoom.height * 2), Image.NEAREST).save(os.path.join(out_dir, "r2_sheet_frames.png"))
    # one GIF per god: burst once, then the loop three times, a 2x crop round the statue and the pool
    for i, t in enumerate(TYPES):
        fxp, fyp = FEET[i][0] - AX, FEET[i][1] - AY
        box = (max(0, fxp - 24), max(0, fyp - 8), min(640, fxp + W + 24), min(360, fyp + H + 16))
        frames = [screen(i, im).crop(box) for im in fx[t]["burst"] + fx[t]["loop"] * 3]
        frames = [f.convert("RGB").resize((f.width * 2, f.height * 2), Image.NEAREST) for f in frames]
        frames[0].save(os.path.join(out_dir, "r2_fx_%s.gif" % t), save_all=True, append_images=frames[1:],
                       duration=83, loop=0)


def main():
    fx = {}
    for t in TYPES:
        fx[t] = render_fx(t)
        for k, im in enumerate(fx[t]["burst"]):
            im.save(os.path.join(ART, "fx_%s_burst_%d.png" % (t, k + 1)))
        for k, im in enumerate(fx[t]["loop"]):
            im.save(os.path.join(ART, "fx_%s_loop_%d.png" % (t, k + 1)))
        print(t, "done")
    if "--preview" in sys.argv:
        previews(sys.argv[sys.argv.index("--preview") + 1], fx)


if __name__ == "__main__":
    main()
