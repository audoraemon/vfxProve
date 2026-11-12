#!/usr/bin/env python3
"""God's Paths round 2b: the living centre-pool emblems, pre-rendered in code (no AI generations).

Each god's sign is modelled as a cast medal: its layers (body, inlays, jewels) are raised reliefs with bevels on a 4 px
thick solid. A tiny renderer turns it round its upright axis like a spinning coin (lingering face-on, quick through
edge-on), lights it from the top left with a rim light from behind right (edge light that follows the turn), renders 4x
supersampled and snaps every pixel to the god's tone ramp: hard edges, no blur. The god's own touch is animated inside
the same frames.

Writes into assets/pixellab/god_select/:
  emblem_<type>_1..24.png        72x72, transparent, one full turn, 8 fps (3 s), loops; centre (36, 36)
  emblem_flash_<type>_1..6.png   96x96, transparent, the entrance flash, 12 fps once; centre (48, 48)
  emblem_spark_<type>_1..4.png   9x9, transparent, a twinkling spark; centre (4, 4)

Usage: python tools/dev/god_select_emblems.py [--preview <dir>]   (--preview writes r2b_sheet_emblems.png, r2b_screen.png
and r2b_emblem_<type>.gif mock-ups with the engine's bob, glow, sparks, ring, reflection and entrance)
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import god_select_r2_art as fxart  # noqa: E402
from god_select_r2_art import ART, PAL, TYPES, TAU, FEET, Frame, hexc, disc, ring  # noqa: E402

SS = 4                 # supersampling
OBJ = 64               # the object's box, px (design units 2..54 map onto it)
EC = 72                # canvas
HI = OBJ * SS
CH = EC * SS
N_TURN = 24
TURN_FPS = 8
N_FLASH = 6
N_SPARK = 4
T_HALF = 2.0 * SS      # half the coin's thickness
DS = HI / 52.0
EMBLEM_AT = (320, 200)


def unit(*v):
    a = np.array(v, float)
    return a / np.linalg.norm(a)


LIGHT = unit(-0.55, -0.65, 0.55)
RIM = unit(0.8, -0.25, -0.3)
HALF = unit(*(LIGHT + np.array([0.0, 0.0, 1.0])))


def spin(t):
    """The turn angle: lingers face-on (t = 0) and back-on (t = 0.5), quick through edge-on."""
    return TAU * t - 0.3 * math.sin(2 * TAU * t)


def P(x, y):
    return ((x - 2) * DS, (y - 2) * DS)


def B(x0, y0, x1, y1):
    return [(x0 - 2) * DS, (y0 - 2) * DS, (x1 - 2) * DS, (y1 - 2) * DS]


def mask(fn):
    im = Image.new("L", (HI, HI), 0)
    fn(ImageDraw.Draw(im))
    return np.array(im) > 127


def layer(m, mat, level=0.0, bevel=2.5, height=1.2):
    return {"mask": m, "mat": mat, "level": level, "bevel": bevel, "height": height}


def ramp(*cols):
    return [hexc(c) for c in cols]


# ---- the renderer ----------------------------------------------------------------------------------------------------

def surface(layers):
    Hm = np.zeros((HI, HI))
    M = -np.ones((HI, HI), int)
    for i, L in enumerate(layers):
        m = L["mask"]
        if not m.any():
            continue
        d = ndimage.distance_transform_edt(m)
        b = np.sqrt(np.clip(d / (L["bevel"] * SS), 0, 1))
        h = L["level"] * SS + b * L["height"] * SS
        Hm[m] = h[m]
        M[m] = i
    union = M >= 0
    Hs = ndimage.gaussian_filter(Hm, 1.0)
    gy, gx = np.gradient(Hs)
    return Hs, M, union, gx, gy


def render(layers, mats, theta):
    """-> (rgba uint8 EC x EC, layer index per pixel, opaque mask)"""
    Hs, M, union, gx, gy = surface(layers)
    ys, xs = np.nonzero(union)
    ox = xs - HI / 2 + 0.5
    oy = ys - HI / 2 + 0.5
    pts = []
    # front face
    n = np.stack([-gx[ys, xs], -gy[ys, xs], np.ones(len(xs))], 1)
    pts.append((ox, oy, T_HALF + Hs[ys, xs], n, M[ys, xs], np.zeros(len(xs))))
    # back face: the front mirrored, so it reads the right way round from behind
    xm = HI - 1 - xs
    ok = union[ys, xm]
    lm = np.where(ok, M[ys, xm], 0)
    hm = np.where(ok, Hs[ys, xm], 0)
    nb = np.stack([np.where(ok, gx[ys, xm], 0), np.where(ok, -gy[ys, xm], 0), -np.ones(len(xs))], 1)
    pts.append((ox, oy, -(T_HALF + hm), nb, lm, np.zeros(len(xs))))
    # side walls
    edge = union & ~ndimage.binary_erosion(union)
    bu = ndimage.gaussian_filter(union.astype(float), 2.0)
    by, bx = np.gradient(bu)
    ey, ex = np.nonzero(edge)
    en = np.stack([-bx[ey, ex], -by[ey, ex], np.zeros(len(ex))], 1)
    en /= np.maximum(np.linalg.norm(en, axis=1, keepdims=True), 1e-6)
    for z in np.arange(-T_HALF, T_HALF + 0.01, 0.5):
        pts.append((ex - HI / 2 + 0.5, ey - HI / 2 + 0.5, np.full(len(ex), z), en, M[ey, ex], np.ones(len(ex))))
    ox = np.concatenate([p[0] for p in pts])
    oy = np.concatenate([p[1] for p in pts])
    oz = np.concatenate([p[2] for p in pts])
    nn = np.concatenate([p[3] for p in pts])
    nn /= np.maximum(np.linalg.norm(nn, axis=1, keepdims=True), 1e-6)
    li = np.concatenate([p[4] for p in pts])
    side = np.concatenate([p[5] for p in pts])
    c, s = math.cos(theta), math.sin(theta)
    X = ox * c + oz * s
    D = -ox * s + oz * c
    nr = np.stack([nn[:, 0] * c + nn[:, 2] * s, nn[:, 1], -nn[:, 0] * s + nn[:, 2] * c], 1)
    keep = nr[:, 2] > -0.2
    sx = np.floor(X + CH / 2).astype(int)
    sy = np.floor(oy + CH / 2).astype(int)
    keep &= (sx >= 0) & (sx < CH) & (sy >= 0) & (sy < CH)
    sx, sy, D, nr, li, side = sx[keep], sy[keep], D[keep], nr[keep], li[keep], side[keep]
    idx = sy * CH + sx
    order = np.lexsort((D, idx))
    i_s = idx[order]
    last = np.r_[i_s[1:] != i_s[:-1], True]
    win = order[last]
    dif = np.clip(nr[win] @ LIGHT, 0, 1)
    rim = np.clip(nr[win] @ RIM, 0, 1)
    spec = np.clip(nr[win] @ HALF, 0, 1) ** 28
    lw = li[win]
    I = 0.16 + 0.7 * dif + 0.36 * rim ** 2
    I = np.where(side[win] > 0, I * 0.85, I)
    for k, L in enumerate(layers):
        e = mats[L["mat"]].get("emit")
        if e is not None:
            sel = lw == k
            I[sel] = e * (0.72 + 0.28 * dif[sel] + 0.2 * rim[sel])
            spec[sel] *= 0.5
    cov = np.zeros(CH * CH, bool)
    Ib = np.zeros(CH * CH)
    Sb = np.zeros(CH * CH)
    Lb = -np.ones(CH * CH, int)
    cov[idx[win]] = True
    Ib[idx[win]] = I
    Sb[idx[win]] = spec
    Lb[idx[win]] = lw
    cov = cov.reshape(EC, SS, EC, SS)
    count = cov.sum(axis=(1, 3))
    opaque = count >= 7
    Lg = Lb.reshape(EC, SS, EC, SS)
    Ig = Ib.reshape(EC, SS, EC, SS)
    Sg = Sb.reshape(EC, SS, EC, SS)
    best = np.zeros((EC, EC), int)
    bestc = np.zeros((EC, EC), int)
    for k in range(len(layers)):
        ck = (Lg == k).sum(axis=(1, 3))
        upd = ck > bestc
        best[upd] = k
        bestc[upd] = ck[upd]
    sel = Lg == best[:, None, :, None]
    Im = (Ig * sel).sum(axis=(1, 3)) / np.maximum(bestc, 1)
    Sm = (Sg * sel).sum(axis=(1, 3)) / np.maximum(bestc, 1)
    tone = np.digitize(Im, [0.3, 0.48, 0.66, 0.84])
    tone = np.where(Sm > 0.42, 5, tone)
    # dark seams where a lower layer meets a higher one
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        nb_l = np.roll(np.roll(best, dy, 0), dx, 1)
        nb_o = np.roll(np.roll(opaque, dy, 0), dx, 1)
        seam = opaque & nb_o & (nb_l > best)
        tone = np.where(seam, np.maximum(0, np.minimum(tone, 5) - 2), tone)
    out = np.zeros((EC, EC, 4), np.uint8)
    for k, L in enumerate(layers):
        r = mats[L["mat"]]["ramp"]
        for tix in range(6):
            m = opaque & (best == k) & (tone == tix)
            out[m, :3] = np.round(r[tix] * 255).astype(np.uint8)
            out[m, 3] = 255
    body = mats[layers[0]["mat"]]["ramp"][0]
    ol = ndimage.binary_dilation(opaque, structure=[[0, 1, 0], [1, 1, 1], [0, 1, 0]]) & ~opaque
    out[ol, :3] = np.round(body * 0.5 * 255).astype(np.uint8)
    out[ol, 3] = 255
    return out, best, opaque


def project(x, y, level, theta):
    """A design point on the front face -> (px, py, visible) on the canvas; the back face shows it mirrored."""
    c, s = math.cos(theta), math.sin(theta)
    ox, oy = (x - 2) * DS - HI / 2, (y - 2) * DS - HI / 2
    zf = T_HALF + level * SS
    if c > 0.25:
        X = ox * c + zf * s
    elif c < -0.25:
        X = -ox * c - zf * s
    else:
        return 0, 0, False
    return (X + CH / 2) / SS, (oy + CH / 2) / SS, True


def put(out, x, y, col):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < EC and 0 <= y < EC:
        out[y, x, :3] = np.round(hexc(col) * 255).astype(np.uint8)
        out[y, x, 3] = 255


def glint(out, x, y, size, pal):
    if size <= 0:
        return
    put(out, x, y, "#ffffff")
    for d in range(1, size + 1):
        col = pal[4] if d == 1 else pal[3]
        for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
            put(out, x + dx, y + dy, col)
    if size >= 2:
        for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
            put(out, x + dx, y + dy, pal[3])


# ---- the six models: (t) -> layers, materials, touch(out, theta, t, opaque) -------------------------------------------

def model_ruin(t):
    pal = PAL["ruin"]

    def star(d):
        pts = []
        for k in range(24):
            ang = -math.pi / 2 + k * math.pi / 12
            r = 24 if k % 4 == 0 else 17.5 if k % 2 == 0 else 11
            pts.append(P(28 + r * math.cos(ang), 30 + r * math.sin(ang)))
        d.polygon(pts, fill=255)

    def core(d):
        pts = []
        for k in range(16):
            ang = -math.pi / 2 + k * math.pi / 8 + 0.2
            r = 10 if k % 2 == 0 else 5.5
            pts.append(P(28 + r * math.cos(ang), 30 + r * math.sin(ang)))
        d.polygon(pts, fill=255)

    def heart(d):
        d.ellipse(B(24.5, 26.5, 31.5, 33.5), fill=255)

    mats = {
        "body": {"ramp": ramp(pal[0], pal[1], pal[2], pal[3], pal[4], "#fff4d0")},
        "hot": {"ramp": ramp("#962410", "#e8602a", "#ffa83c", "#ffe890", "#fff8d8", "#ffffff"),
                "emit": 0.62 + 0.14 * math.sin(TAU * 3 * t)},
        "white": {"ramp": ramp("#ffa83c", "#ffe890", "#fff8d8", "#ffffff", "#ffffff", "#ffffff"), "emit": 0.9},
    }
    layers = [layer(mask(star), "body", 0, 4, 1.6), layer(mask(core), "hot", 1.0, 2, 0.8),
              layer(mask(heart), "white", 1.8, 1.5, 0.5)]

    def touch(out, theta, t, opaque):
        # flames lick up off every top edge of the burst
        top = opaque & ~np.roll(opaque, 1, 0)
        ys, xs = np.nonzero(top)
        for x, y in zip(xs, ys):
            if y > 44:
                continue
            h = 2.2 * math.sin(TAU * (3 * t + x * 0.31)) + 1.6 * math.sin(TAU * (5 * t - x * 0.17 + 0.3)) + 0.6
            h = int(round(min(5, h)))
            for j in range(1, h + 1):
                yy = y - j
                if yy < 0 or (opaque[yy, x] and j > 0):
                    break
                f = j / max(1, h)
                put(out, x, yy, "#ffe890" if f < 0.34 else "#ffa83c" if f < 0.7 else "#e8602a")
            if h >= 2 and y - h - 1 >= 0 and not opaque[y - h - 1, x]:
                put(out, x, y - h - 1, "#962410")

    return layers, mats, touch


def model_passage(t):
    pal = PAL["passage"]

    def frame(d):
        d.rectangle(B(13, 6, 43, 10), fill=255)
        d.rectangle(B(13, 46, 43, 50), fill=255)
        d.rectangle(B(15, 10, 17.5, 46), fill=255)
        d.rectangle(B(38.5, 10, 41, 46), fill=255)
        d.ellipse(B(12, 5, 16, 11), fill=255)
        d.ellipse(B(40, 5, 44, 11), fill=255)
        d.ellipse(B(12, 45, 16, 51), fill=255)
        d.ellipse(B(40, 45, 44, 51), fill=255)

    def glass(d):
        d.polygon([P(18.5, 10.5), P(37.5, 10.5), P(30, 26.5), P(30, 29.5), P(37.5, 45.5), P(18.5, 45.5), P(26, 29.5),
                   P(26, 26.5)], fill=255)

    def sand(d):
        level = 17.5
        d.polygon([P(20.5 + (level - 11) * 0.45, level), P(35.5 - (level - 11) * 0.45, level), P(28.6, 26.2),
                   P(27.4, 26.2)], fill=255)
        d.polygon([P(28, 35), P(36.5, 45.5), P(19.5, 45.5)], fill=255)
        # the falling stream, its grains running down through the neck
        for k in range(5):
            y = 26 + ((k / 5 + 8 * t) % 1.0) * 10
            d.rectangle(B(27.1, y, 28.9, y + 1.6), fill=255)

    mats = {
        "frame": {"ramp": ramp(pal[0], pal[1], pal[2], pal[3], pal[4], "#ffffff")},
        "glass": {"ramp": ramp("#050f2a", "#0a1c48", "#163a7a", "#2050b0", "#4a90e8", "#cfe8ff")},
        "sand": {"ramp": ramp("#2050b0", "#4a90e8", "#98ccff", "#cfe8ff", "#ffffff", "#ffffff"), "emit": 0.78},
    }
    layers = [layer(mask(glass), "glass", 0, 4, 1.8), layer(mask(sand), "sand", 0.9, 1.2, 0.5),
              layer(mask(frame), "frame", 1.4, 1.5, 1.0)]
    return layers, mats, None


def model_veil(t):
    pal = PAL["veil"]
    i = int(round(t * N_TURN)) % N_TURN
    lid = {1: 0.42, 2: 1.0, 3: 0.42}.get(i, 0.0)

    def lashes(d):
        for k in range(7):
            ang = math.pi + (k + 1) * math.pi / 8
            x0, y0 = 28 + 21 * math.cos(ang), 31 + 16 * math.sin(ang)
            x1, y1 = 28 + 27 * math.cos(ang), 31 + 23 * math.sin(ang)
            d.line([P(x0, y0), P(x1, y1)], fill=255, width=int(2.4 * DS))

    # an almond is where two ellipses, one above the other, overlap
    def alm_a(d):
        d.ellipse(B(1, 15, 55, 53), fill=255)

    def alm_b(d):
        d.ellipse(B(1, 5, 55, 43), fill=255)

    def wh_a(d):
        d.ellipse(B(6, 19, 50, 50), fill=255)

    def wh_b(d):
        d.ellipse(B(6, 8, 50, 39), fill=255)

    def iris(d):
        d.ellipse(B(19, 20, 37, 38), fill=255)

    def pupil(d):
        d.ellipse(B(25.5, 21.5, 30.5, 36.5), fill=255)

    def lid_m(d):
        if lid > 0:
            d.rectangle(B(0, 0, 56, 17 + lid * 25), fill=255)

    m_alm = mask(alm_a) & mask(alm_b)
    m_wh = mask(wh_a) & mask(wh_b)
    mats = {
        "body": {"ramp": ramp(pal[0], pal[1], pal[2], pal[3], pal[4], "#ffffff")},
        "white": {"ramp": ramp("#0a3034", "#5a8c88", "#9cc8c0", "#c4e8e0", "#eafff8", "#ffffff")},
        "iris": {"ramp": ramp("#0a3034", "#156660", "#3ab8a8", "#86eadb", "#dcfff6", "#ffffff"),
                 "emit": 0.56 + 0.12 * math.sin(TAU * 2 * t)},
        "pupil": {"ramp": ramp("#020a0a", "#06181a", "#0a3034", "#156660", "#3ab8a8", "#86eadb")},
    }
    layers = [layer(mask(lashes), "body", 0, 1.5, 0.8), layer(m_alm, "body", 0, 3, 1.2),
              layer(m_wh, "white", 0.4, 3, 1.0), layer(mask(iris) & m_wh, "iris", 0.9, 2.5, 0.9),
              layer(mask(pupil) & m_wh, "pupil", 1.2, 1.2, 0.4), layer(mask(lid_m) & m_alm, "body", 1.6, 2, 0.8)]

    def touch(out, theta, t, opaque):
        if lid == 0:
            x, y, vis = project(24, 25, 1.6, theta)
            if vis:
                put(out, x, y, "#ffffff")
                put(out, x + 1, y, "#ffffff")
                put(out, x, y + 1, "#ffffff")

    return layers, mats, touch


def model_decree(t):
    pal = PAL["decree"]
    phi = 0.13 * math.sin(TAU * t)
    piv = (28.0, 13.5)
    ends = [(piv[0] - 22 * math.cos(phi), piv[1] + 22 * math.sin(phi)),
            (piv[0] + 22 * math.cos(phi), piv[1] - 22 * math.sin(phi))]

    def stand(d):
        d.rectangle(B(26.5, 12, 29.5, 46), fill=255)
        d.polygon([P(19, 51), P(37, 51), P(33, 45), P(23, 45)], fill=255)
        dx, dy = math.cos(phi) * 22, -math.sin(phi) * 22
        nx, ny = math.sin(phi) * 1.9, math.cos(phi) * 1.9
        d.polygon([P(piv[0] - dx - nx, piv[1] - dy - ny), P(piv[0] + dx - nx, piv[1] + dy - ny),
                   P(piv[0] + dx + nx, piv[1] + dy + ny), P(piv[0] - dx + nx, piv[1] - dy + ny)], fill=255)
        for ex, ey in ends:
            d.ellipse(B(ex - 2.6, ey - 2.6, ex + 2.6, ey + 2.6), fill=255)

    def chains(d):
        for ex, ey in ends:
            d.line([P(ex - 0.4, ey), P(ex - 6.5, ey + 19.5)], fill=255, width=int(1.4 * DS))
            d.line([P(ex + 0.4, ey), P(ex + 6.5, ey + 19.5)], fill=255, width=int(1.4 * DS))

    def pans(d):
        for ex, ey in ends:
            d.chord(B(ex - 8.5, ey + 11, ex + 8.5, ey + 28), 0, 180, fill=255)

    def jewel(d):
        d.ellipse(B(24.5, 3.5, 31.5, 10.5), fill=255)

    mats = {
        "gold": {"ramp": ramp(pal[0], pal[1], pal[2], pal[3], pal[4], "#ffffff")},
        "chain": {"ramp": ramp("#3a280c", pal[0], pal[1], pal[2], pal[3], pal[4])},
        "jewel": {"ramp": ramp(pal[1], pal[2], pal[3], pal[4], "#ffffff", "#ffffff"),
                  "emit": 0.7 + 0.15 * math.sin(TAU * 2 * t)},
    }
    layers = [layer(mask(chains), "chain", 0, 1, 0.5), layer(mask(pans), "gold", 0.2, 3, 1.4),
              layer(mask(stand), "gold", 0.6, 1.8, 1.2), layer(mask(jewel), "jewel", 1.2, 2, 0.8)]
    return layers, mats, None


def model_death(t):
    pal = PAL["death"]
    glow = 0.5 + 0.42 * (0.5 + 0.5 * math.sin(TAU * 2 * t - 1.0)) ** 2

    def skull(d):
        d.ellipse(B(10, 4, 46, 38), fill=255)
        d.rectangle(B(17, 30, 39, 42), fill=255)
        d.rectangle(B(19, 40, 37, 51), fill=255)

    def holes(d):
        d.ellipse(B(15.5, 20.5, 26.5, 31.5), fill=255)
        d.ellipse(B(29.5, 20.5, 40.5, 31.5), fill=255)
        d.polygon([P(28, 31), P(25, 37.5), P(31, 37.5)], fill=255)
        d.rectangle(B(17, 42, 39, 43.6), fill=255)
        for x in (22.3, 27.4, 32.5):
            d.rectangle(B(x, 43, x + 1.3, 51), fill=255)
        d.line([P(30, 6), P(31.5, 10), P(29.3, 13.5), P(30.5, 17)], fill=255, width=int(1.2 * DS))

    def eyes(d):
        d.ellipse(B(17.5, 22.5, 24.5, 29.5), fill=255)
        d.ellipse(B(31.5, 22.5, 38.5, 29.5), fill=255)

    def pupils(d):
        d.ellipse(B(19.6, 24.6, 22.4, 27.4), fill=255)
        d.ellipse(B(33.6, 24.6, 36.4, 27.4), fill=255)

    m_sk = mask(skull)
    m_h = mask(holes) & m_sk
    mats = {
        "bone": {"ramp": ramp(pal[0], "#5e7e62", "#86a888", "#bcd8b4", "#dcf0d4", "#f6fff2")},
        "dark": {"ramp": ramp("#050c07", "#0a160d", "#0c1a10", "#142a1a", "#1e3a26", "#2a4a32")},
        "glow": {"ramp": ramp("#367046", "#68b05c", "#98d880", "#c8f8b0", "#eaffe0", "#ffffff"), "emit": glow},
        "core": {"ramp": ramp("#98d880", "#c8f8b0", "#eaffe0", "#ffffff", "#ffffff", "#ffffff"),
                 "emit": min(1.0, glow + 0.3)},
    }
    layers = [layer(m_sk & ~m_h, "bone", 0, 5, 2.0), layer(m_h, "dark", -1.2, 1, 0.2),
              layer(mask(eyes) & m_h, "glow", -0.6, 2, 0.6), layer(mask(pupils) & m_h, "core", -0.3, 1, 0.3)]

    def touch(out, theta, t, opaque):
        # at the top of each pulse a spark leaps from each eye
        if glow > 0.85:
            for ex in (21, 35):
                x, y, vis = project(ex, 26, 0, theta)
                if vis:
                    put(out, x, y - 1, "#ffffff")
                    put(out, x - 1, y, "#eaffe0")
                    put(out, x + 1, y, "#eaffe0")

    return layers, mats, touch


def model_dominion(t):
    pal = PAL["dominion"]

    def crown(d):
        d.polygon([P(8, 41), P(5.5, 17), P(17, 29), P(28, 10), P(39, 29), P(50.5, 17), P(48, 41)], fill=255)
        d.rectangle(B(8, 40, 48, 48), fill=255)

    def orbs(d):
        for (x, y, r) in ((5.5, 14.5, 3.6), (28, 7.5, 4.2), (50.5, 14.5, 3.6)):
            d.ellipse(B(x - r, y - r, x + r, y + r), fill=255)

    def band(d):
        d.rectangle(B(9, 40.5, 47, 47), fill=255)

    def gems(d):
        for x in (16, 28, 40):
            d.polygon([P(x, 40.2), P(x + 3.4, 43.8), P(x, 47.3), P(x - 3.4, 43.8)], fill=255)
        d.polygon([P(28, 21), P(32.5, 28), P(28, 35), P(23.5, 28)], fill=255)

    mats = {
        "body": {"ramp": ramp(pal[0], pal[1], pal[2], pal[3], pal[4], "#ffffff")},
        "band": {"ramp": ramp("#1a0830", "#3a1a6a", "#56289a", "#7a44c0", "#a060e0", "#d0a2ff")},
        "orb": {"ramp": ramp(pal[1], pal[2], pal[3], "#e4c8ff", pal[4], "#ffffff")},
        "gem": {"ramp": ramp("#56289a", "#a060e0", "#d0a2ff", "#f0dcff", "#ffffff", "#ffffff"), "emit": 0.6},
    }
    layers = [layer(mask(crown), "body", 0, 3.5, 1.4), layer(mask(band), "band", 0.8, 1.2, 0.6),
              layer(mask(orbs), "orb", 0.6, 3, 1.4), layer(mask(gems), "gem", 1.4, 2, 0.8)]
    sparkle = [(16, 43.8), (28, 7.5), (40, 43.8), (5.5, 14.5), (28, 28), (50.5, 14.5), (28, 43.8)]
    starts = [0, 3, 7, 10, 14, 17, 20]

    def touch(out, theta, t, opaque):
        i = int(round(t * N_TURN)) % N_TURN
        for (gx, gy), st in zip(sparkle, starts):
            k = (i - st) % N_TURN
            size = {0: 1, 1: 2, 2: 1}.get(k, 0)
            x, y, vis = project(gx, gy, 2.0, theta)
            if vis and size:
                glint(out, x, y, size, pal)

    return layers, mats, touch


MODELS = {"ruin": model_ruin, "passage": model_passage, "veil": model_veil, "decree": model_decree,
          "death": model_death, "dominion": model_dominion}


def turn_frames(god):
    out = []
    for i in range(N_TURN):
        t = i / N_TURN
        layers, mats, touch = MODELS[god](t)
        th = spin(t)
        img, _, opaque = render(layers, mats, th)
        if touch is not None:
            touch(img, th, t, opaque)
        img[img[:, :, 3] == 0] = 0
        out.append(Image.fromarray(img, "RGBA"))
    return out


# ---- entrance flash and sparks ---------------------------------------------------------------------------------------

def flash_frames(god):
    pal = PAL[god]
    frames = []
    c = 48
    for i in range(N_FLASH):
        fr = Frame(None, 96, 96)
        rays = [(k * TAU / 8 + (0.2 if k % 2 else 0)) for k in range(8)]
        if i == 0:
            disc(fr, c, c, 5, pal[4], glow=True)
            disc(fr, c, c, 2.5, "#ffffff")
            for a in rays[::2]:
                for r in range(5, 13):
                    fr.put(c + r * math.cos(a), c + r * math.sin(a), "#ffffff" if r < 9 else pal[4], glow=True)
        elif i == 1:
            disc(fr, c, c, 11, pal[3], glow=True)
            disc(fr, c, c, 8, pal[4])
            disc(fr, c, c, 5, "#ffffff")
            for k, a in enumerate(rays):
                ln = 26 if k % 2 == 0 else 18
                for r in range(10, ln):
                    col = "#ffffff" if r < 16 else pal[4] if r < 21 else pal[3]
                    fr.put(c + r * math.cos(a), c + r * math.sin(a), col, glow=True)
        elif i == 2:
            disc(fr, c, c, 5, pal[4], glow=True)
            disc(fr, c, c, 2.5, "#ffffff")
            ring(fr, c, c, 18, 18, pal[4], back=False, glow=True)
            ring(fr, c, c, 17, 17, "#ffffff", back=False)
            for k, a in enumerate(rays):
                for r in range(20, 34 if k % 2 == 0 else 27):
                    if r % 3 != 2:
                        fr.put(c + r * math.cos(a), c + r * math.sin(a), pal[3], glow=r < 26)
        elif i == 3:
            disc(fr, c, c, 1.5, pal[4], glow=True)
            ring(fr, c, c, 27, 27, pal[3], back=False, keep=fxart.dashes(40, 0.8), glow=True)
            for k, a in enumerate(rays):
                r = 38 if k % 2 == 0 else 31
                fr.put(c + r * math.cos(a), c + r * math.sin(a), pal[4], glow=True)
        elif i == 4:
            ring(fr, c, c, 34, 34, pal[2], back=False, keep=fxart.dashes(40, 0.45))
            for k, a in enumerate(rays[1::2]):
                fr.put(c + 41 * math.cos(a), c + 41 * math.sin(a), pal[3], glow=True)
        else:
            for k, a in enumerate(rays[::2]):
                fr.put(c + 43 * math.cos(a + 0.1), c + 43 * math.sin(a + 0.1), pal[2])
            ring(fr, c, c, 39, 39, pal[1], back=False, keep=fxart.dashes(40, 0.2))
        fr.halo(pal[3], pal[2])
        frames.append(fr.image())
    return frames


def spark_frames(god):
    pal = PAL[god]
    frames = []
    for arm, diag, core in ((1, 0, pal[4]), (2, 1, "#ffffff"), (3, 1, "#ffffff"), (2, 0, pal[4])):
        img = np.zeros((9, 9, 4), np.uint8)
        put9 = lambda x, y, col: img.__setitem__((y, x), list(np.round(hexc(col) * 255).astype(int)) + [255])
        put9(4, 4, core)
        for d in range(1, arm + 1):
            col = pal[4] if d == 1 else pal[3] if d == 2 else pal[2]
            for dx, dy in ((d, 0), (-d, 0), (0, d), (0, -d)):
                put9(4 + dx, 4 + dy, col)
        if diag:
            for dx, dy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
                put9(4 + dx, 4 + dy, pal[2])
        frames.append(Image.fromarray(img, "RGBA"))
    return frames


# ---- mock-ups: what Task 7 will draw (bob, glow, sparks, ring, reflection, entrance) ----------------------------------

def tint_alpha(im, alpha):
    a = np.array(im).astype(float)
    a[:, :, 3] *= alpha
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def hard_disc(base, cx, cy, r, col, alpha, sy=1.0):
    fr = Frame(None, base.width, base.height)
    R = int(r) + 1
    for dy in range(-R, R + 1):
        for dx in range(-R, R + 1):
            if dx * dx + (dy / sy) ** 2 <= r * r:
                fr.put(cx + dx, cy + dy, col, alpha=alpha)
    base.alpha_composite(fr.image())


def compose(god, tsec, turn, flash, sparks, fx_loop, entrance=True):
    pal = PAL[god]
    sel = TYPES.index(god)
    bg = Image.open(os.path.join(ART, "background.png")).convert("RGBA")
    cx, cy = EMBLEM_AT
    bob = int(round(2 * math.sin(TAU * tsec / 2.6)))
    pulse = 0.5 + 0.5 * math.sin(TAU * tsec / 1.4)
    t_in = tsec - 0.08 if entrance else 10.0
    if t_in >= 0:
        scale = 1.0 if t_in > 0.3 else [0.35, 0.6, 0.85, 1.08, 1.12, 1.05, 1.0][min(6, int(t_in / 0.042))]
        # glow behind, pulsing
        for r, a in ((34, 0.08), (28, 0.1), (22, 0.12)):
            hard_disc(bg, cx, cy + bob, r * min(1, scale), pal[2], round((a + 0.05 * pulse) * 32) / 32)
        # ring of light on the pool and the faint reflection under it
        ry = cy + 33
        ringf = Frame(None, 640, 360)
        ring(ringf, cx, ry, 46, 10, pal[3], back=False, keep=fxart.dashes(36, 0.75, tsec * 0.6))
        ring(ringf, cx, ry, 39, 8, pal[2], back=False, keep=fxart.dashes(30, 0.5, -tsec * 0.4))
        bg.alpha_composite(tint_alpha(ringf.image(), 0.55 + 0.3 * pulse))
        k_turn = int(tsec * TURN_FPS) % N_TURN
        em = turn[k_turn]
        if scale != 1.0:
            sz = max(2, int(round(EC * scale)))
            em = em.resize((sz, sz), Image.NEAREST)
        refl = em.transpose(Image.FLIP_TOP_BOTTOM)
        refl = refl.resize((refl.width, max(1, refl.height // 2)), Image.NEAREST)
        bg.alpha_composite(tint_alpha(refl, 0.2), (cx - refl.width // 2, ry + 3))
        # sparks on an ellipse round the emblem: the far half behind it, the near half in front
        orbit = []
        for k in range(6):
            a = TAU * (tsec / 4.0 + k / 6)
            sx = cx + 44 * math.cos(a)
            sy = cy + bob + 14 * math.sin(a) - 4
            orbit.append((math.sin(a), sx, sy, sparks[(int(tsec * 10) + k) % N_SPARK]))
        for sn, sx, sy, sp in orbit:
            if sn < 0:
                bg.alpha_composite(tint_alpha(sp, 0.75), (int(sx) - 4, int(sy) - 4))
        bg.alpha_composite(em, (cx - em.width // 2, cy + bob - em.height // 2))
        for sn, sx, sy, sp in orbit:
            if sn >= 0:
                bg.alpha_composite(sp, (int(sx) - 4, int(sy) - 4))
    if entrance:
        kf = int(tsec * 12)
        if kf < N_FLASH:
            bg.alpha_composite(flash[kf], (cx - 48, cy - 48))
    # the statues, in front of the emblem
    order = sorted(range(6), key=lambda i: FEET[i][1])
    for i in order:
        st = Image.open(os.path.join(ART, "statue_%s.png" % TYPES[i])).convert("RGBA")
        if i != sel:
            a = np.array(st).astype(float)
            a[:, :, :3] *= 0.72
            st = Image.fromarray(a.astype(np.uint8), "RGBA")
        bg.alpha_composite(st, (FEET[i][0] - 32, FEET[i][1] - 79))
        if i == sel and fx_loop:
            fxi = Image.open(os.path.join(ART, "fx_%s_loop_%d.png" % (god, int(tsec * 12) % 16 + 1)))
            bg.alpha_composite(fxi.convert("RGBA"), (FEET[i][0] - 56, FEET[i][1] - 119))
    return bg


def previews(out_dir, turns, flashes, sparks):
    os.makedirs(out_dir, exist_ok=True)
    # contact sheet: every turn frame at 2x on the pool's dark, then the flash and the sparks
    cell = EC + 4
    rows_per = 2
    cols = N_TURN // rows_per
    sheet = Image.new("RGBA", (cell * cols, (cell * rows_per + 100) * 6), (12, 14, 22, 255))
    for g, god in enumerate(TYPES):
        y0 = g * (cell * rows_per + 100)
        for i, im in enumerate(turns[god]):
            sheet.alpha_composite(im, ((i % cols) * cell + 2, y0 + (i // cols) * cell + 2))
        for i, im in enumerate(flashes[god]):
            sheet.alpha_composite(im, (i * 98, y0 + cell * rows_per + 2))
        for i, im in enumerate(sparks[god]):
            sheet.alpha_composite(im, (6 * 98 + 10 + i * 14, y0 + cell * rows_per + 44))
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(out_dir, "r2b_sheet_emblems.png"))
    # the full screen, each god picked, the emblem mid-turn
    grid = Image.new("RGBA", (640 * 3, 360 * 2))
    for g, god in enumerate(TYPES):
        grid.paste(compose(god, 0.06, turns[god], flashes[god], sparks[god], True, entrance=False),
                   ((g % 3) * 640, (g // 3) * 360))
    grid.save(os.path.join(out_dir, "r2b_screen.png"))
    # one GIF per god: the entrance, then one full turn, 25 fps, a 2x crop round the pool
    box = (200, 120, 440, 290)
    for god in TYPES:
        frames = []
        for k in range(int((0.5 + N_TURN / TURN_FPS) * 25)):
            img = compose(god, k / 25.0, turns[god], flashes[god], sparks[god], True).crop(box).convert("RGB")
            frames.append(img.resize((img.width * 2, img.height * 2), Image.NEAREST))
        frames[0].save(os.path.join(out_dir, "r2b_emblem_%s.gif" % god), save_all=True, append_images=frames[1:],
                       duration=40, loop=0)


def main():
    turns, flashes, sparks = {}, {}, {}
    for god in TYPES:
        turns[god] = turn_frames(god)
        flashes[god] = flash_frames(god)
        sparks[god] = spark_frames(god)
        for k, im in enumerate(turns[god]):
            im.save(os.path.join(ART, "emblem_%s_%d.png" % (god, k + 1)))
        for k, im in enumerate(flashes[god]):
            im.save(os.path.join(ART, "emblem_flash_%s_%d.png" % (god, k + 1)))
        for k, im in enumerate(sparks[god]):
            im.save(os.path.join(ART, "emblem_spark_%s_%d.png" % (god, k + 1)))
        print(god, "done")
    if "--preview" in sys.argv:
        previews(sys.argv[sys.argv.index("--preview") + 1], turns, flashes, sparks)


if __name__ == "__main__":
    main()
