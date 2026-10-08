"""Style match: a post-process that makes converted sprites (the gpt_* sets) read like the in-game buildings. It runs on
a set's stills (intact, damaged, ruins) or on a strip, and is gpt_convert.py's final step.

The game palette (game_palette.png, build it with --palette): BASE colours by median cut (k-means refined) over the
opaque px of the reference sets' intact stills (style_stats.PALETTE_REFS), leaving out their outline and their lit
windows, cut per material family (FAMILY_N each); then their outline colours (OUTLINE_N dark browns, sampled from the outline px) and their lit-window ramp
(RAMP_N, sampled from their glow_mask px). The outline colours are their outline px darker than luminance 0.16
and redder than blue. Stored as 8 x 8 px swatches, 8 per row, in that order.

The pass, per still (match()):
  1. saturation per material: each material family (style_stats.family: stone/grey, roof red, timber brown, plaster
     cream, green, slate blue) of the intact has its saturation scaled part way (SAT_PULL) toward the references'
     mean for that family,
     then the whole sprite's toward the references' mean for its dominant material (style_stats.ref_material_sat);
  2. brightness lift (per set, see tune());
  3. local contrast: an unsharp mask on luminance (3 x 3 binomial blur, `amount` per set);
  4. lit windows: window_glow.lit() finds the lamp-bright panes (on this full-colour image; the old 64-colour quantize
     merged them into the roof reds; never on roof material, never on ruins) and each is mapped onto the reference ramp
     by luminance;
  5. palette lock: every other opaque px to the nearest BASE colour in CIE Lab, no dithering, the candidates limited to
     the px's own material when its hue is clear (FAMILY_OK), so stone never snaps to a roof red; the material is read
     before steps 2-3, and specks on a roof count as roof (materials());
  6. orphan specks: a px whose colour no 8-neighbour shares, with ORPHAN or more neighbours of one colour, takes that
     colour (not on the outline, not a lit pane);
  7. eaves: a wall px right under a roof px (red or slate) goes one step toward the outline colour: the nearest darker
     palette colour of its material to a blend EAVES of the way to the outline colour;
  8. outline: every opaque px touching transparency becomes the outline colour nearest to it darkened (x OUTLINE_K).
The set's knobs (lift, amount) are tuned on the intact (tune(): a fixed grid, the closest to the reference edge
contrast and luminance) and used on all its stills. A `light` still (ruins borrowed from an approved set, already in
the game's style) gets only the lock, the specks and the outline.

Usage (from anywhere):
  python tools/dev/ref_convert/style_match.py --palette     rebuild game_palette.png from the reference sets
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_stats as ss  # noqa: E402
import window_glow  # noqa: E402

HERE = Path(__file__).resolve().parent
PALETTE = HERE / "game_palette.png"
# Base colours per material family (one median cut each, so a family's bright and dark ends are kept: one cut over
# every px lumped the roofs' bright reds into a dull brick)
FAMILY_N = {ss.GREY: 8, ss.RED: 12, ss.TIMBER: 12, ss.CREAM: 10, ss.GREEN: 4, ss.BLUE: 10}
BASE, OUTLINE_N, RAMP_N = sum(FAMILY_N.values()), 3, 4
SW = 8                  # swatch size in game_palette.png
OUTLINE_K = 0.4         # the outline colour is the nearest to the px darkened this much
EAVES = 0.4             # the eaves step: the blend toward the outline colour it is matched to
ORPHAN = 5              # neighbours of one colour that take over a speck
SAT_PULL = 0.5          # how far toward the reference a family's saturation moves (as a power of the ratio): the
                        # full ratio browned the GPT roof reds and turned the slate garish
SAT_CLAMP = (0.7, 2.2)  # per-family saturation factor bounds
SAT_BAND = 0.07         # the whole sprite's saturation is pulled to within this of its material's reference
SAT_ROUNDS = 3          # tune() re-tunes at most this often to bring the saturation into the band
MIN_SHARE = 0.02        # a family on fewer px of the intact keeps its saturation
EDGE_TARGET = 0.13      # the low end of the references' 0.13-0.15: more contrast was grain, not crispness
LUM_BAND = (0.30, 0.35)
AMOUNTS = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
LIFTS = [0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.25]
# The palette families a px of each family may lock to (a grey px also to the dull swatches: stone is warm-grey).
FAMILY_OK = {ss.GREY: (ss.GREY,), ss.RED: (ss.RED,), ss.TIMBER: (ss.TIMBER, ss.CREAM), ss.CREAM: (ss.CREAM, ss.TIMBER),
             ss.GREEN: (ss.GREEN, ss.TIMBER, ss.GREY), ss.BLUE: (ss.BLUE, ss.GREY)}
DULL = 0.32             # swatches below this saturation are candidates for a grey px
CLEAR_V = 0.2           # a px darker than this has no clear material: any swatch
ROOF_OWN, ROOF_MAJ = 0.4, 0.6  # a roof speck: its own material on fewer of its 5 x 5, the roof's on this many


# --- colour --------------------------------------------------------------------------------------------------------

def lab(rgb):
    """CIE Lab (D65) of a float sRGB array in 0-255, shape (..., 3)."""
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def set_hsv(rgb, s_scale):
    """`rgb` (n x 3, 0-255) with its HSV saturation times s_scale (n,), hue and value kept."""
    mx = rgb.max(1, keepdims=True)
    s = np.where(mx[:, 0] > 0, (mx[:, 0] - rgb.min(1)) / np.maximum(mx[:, 0], 1e-6), 0)
    s2 = np.clip(s * s_scale, 0, 1)
    # each channel sits at mx - s * mx * t, t in [0, 1]: rescale the distance below the max
    k = np.where(s > 0, s2 / np.maximum(s, 1e-6), 1.0)[:, None]
    return mx - (mx - rgb) * k


def outline_ring(al):
    return ss.outline_mask(al)


# --- palette -------------------------------------------------------------------------------------------------------

def build_palette():
    base, outl, glow = [], [], []
    for n in ss.PALETTE_REFS:
        a = ss.load(n)
        al = a[..., 3] > 0
        ring = outline_ring(al)
        gm = np.zeros_like(al)
        gp = ss.B / n / "glow_mask.png"
        if gp.exists():
            gm = np.array(Image.open(gp).convert("RGBA"))[..., 3] > 0
            glow.append(a[..., :3][gm & al])
        outl.append(a[..., :3][ring])
        base.append(a[..., :3][al & ~ring & ~gm])

    def quant(px, n, kmeans=0):
        px = np.concatenate(px).astype(np.uint8)
        im = Image.fromarray(px[None, :, :], "RGB")
        q = im.quantize(colors=n, method=Image.Quantize.MEDIANCUT, kmeans=kmeans, dither=Image.Dither.NONE)
        return np.array(q.getpalette()[:3 * n], np.uint8).reshape(-1, 3)

    o = np.concatenate(outl)
    o = o[(ss.luma(o.astype(float)) < 0.16) & (o[:, 0] > o[:, 2])]     # the dark browns, not the blue-blacks
    bp = np.concatenate(base)
    bf = ss.family(bp.astype(float))
    fam_cols = [quant([bp[bf == k]], FAMILY_N[k], 4) for k in range(6)]
    cols = [np.concatenate(fam_cols), quant([o], OUTLINE_N), quant(glow, RAMP_N)]
    cols[1] = cols[1][np.argsort(ss.luma(cols[1].astype(float)))]
    cols[2] = cols[2][np.argsort(ss.luma(cols[2].astype(float)))]
    pal = np.concatenate(cols)
    n = len(pal)
    rows = (n + 7) // 8
    img = np.zeros((rows * SW, 8 * SW, 4), np.uint8)
    for i, c in enumerate(pal):
        y, x = divmod(i, 8)
        img[y * SW:(y + 1) * SW, x * SW:(x + 1) * SW, :3] = c
        img[y * SW:(y + 1) * SW, x * SW:(x + 1) * SW, 3] = 255
    Image.fromarray(img, "RGBA").save(PALETTE)
    return pal


_PAL = None


def palette():
    """(base, outline, ramp) uint8 colour arrays, read from game_palette.png."""
    global _PAL
    if _PAL is None:
        img = np.array(Image.open(PALETTE).convert("RGBA"))
        cols = []
        for i in range(BASE + OUTLINE_N + RAMP_N):
            y, x = divmod(i, 8)
            cols.append(img[y * SW + SW // 2, x * SW + SW // 2, :3])
        cols = np.array(cols)
        _PAL = (cols[:BASE], cols[BASE:BASE + OUTLINE_N], cols[BASE + OUTLINE_N:])
    return _PAL


_REF = None


def refs():
    """(per-family reference saturation, per-material whole-sprite reference saturation)."""
    global _REF
    if _REF is None:
        _REF = (ss.ref_family_sat(), ss.ref_material_sat())
    return _REF


# --- steps ---------------------------------------------------------------------------------------------------------

def sat_factors(intact):
    """Per-family saturation factors for a set, and the whole-sprite factor after them, measured on its intact."""
    fam_ref, mat_ref = refs()
    al = intact[..., 3] > 0
    rgb = intact[..., :3][al].astype(float)
    f = ss.family(rgb)
    s = ss.hsv(rgb)[1]
    fac = {}
    for k in range(6):
        m = f == k
        if k == ss.GREY or m.mean() < MIN_SHARE or k not in fam_ref:
            fac[k] = 1.0
        else:
            fac[k] = float(np.clip((fam_ref[k] / max(s[m].mean(), 1e-3)) ** SAT_PULL, *SAT_CLAMP))
    s1 = np.clip(s * np.vectorize(fac.get)(f), 0, 1)
    shares = {k: (f == k).mean() for k in range(6)}
    dom = max(shares, key=shares.get)
    ref = mat_ref.get(dom, s1.mean())
    target = np.clip(s1.mean(), ref - SAT_BAND, ref + SAT_BAND)
    return fac, float(target / max(s1.mean(), 1e-3))


def saturate(a, fac, glob):
    out = a.copy()
    al = a[..., 3] > 0
    rgb = a[..., :3][al]
    f = ss.family(rgb)
    out[..., :3][al] = set_hsv(rgb, np.vectorize(fac.get)(f) * glob)
    return out


def unsharp(a, amount):
    """Local contrast on luminance: L + amount (L - blur L), the blur a 3 x 3 binomial over opaque px only."""
    if amount == 0:
        return a
    al = (a[..., 3] > 0).astype(float)
    L = ss.luma(a[..., :3]) * al
    k = np.array([1.0, 2.0, 1.0])

    def blur(x):
        p = np.pad(x, ((0, 0), (1, 1)))
        x = p[:, :-2] * k[0] + p[:, 1:-1] * k[1] + p[:, 2:] * k[2]
        p = np.pad(x, ((1, 1), (0, 0)))
        return p[:-2] * k[0] + p[1:-1] * k[1] + p[2:] * k[2]

    bl = blur(L) / np.maximum(blur(al), 1e-6)
    out = a.copy()
    # scale the channels, not add to them: a lightened px keeps its hue and saturation
    k2 = np.clip(L + (L - bl) * amount, 0, None) / np.maximum(L, 1e-3)
    out[..., :3] = np.clip(a[..., :3] * k2[..., None], 0, 255) * al[..., None]
    return out


def nearest(rgb, cand):
    """Index into `cand` of the nearest colour (Lab) per row of rgb."""
    d = ((lab(rgb.astype(float))[:, None, :] - lab(cand.astype(float))[None, :, :]) ** 2).sum(-1)
    return d.argmin(1)


def materials(a):
    """(family, clear) per px of an RGBA array. Specks on a roof (moss, the painted ridge trim, a lichen dot) take
    the roof's material: a px whose own family is under ROOF_OWN of the opaque px in its 5 x 5, where one roof family
    (red or slate) holds ROOF_MAJ or more, is that roof's. Clear: bright enough (CLEAR_V) for its hue to count."""
    al = a[..., 3] > 0
    f = np.where(al, ss.family(a[..., :3]), -1)
    clear = a[..., :3].max(-1) / 255.0 >= CLEAR_V
    h, w = f.shape
    p = np.pad(f, 2, constant_values=-1)
    win = [p[dy:dy + h, dx:dx + w] for dy in range(5) for dx in range(5)]
    n = sum((q >= 0).astype(int) for q in win)
    own = sum((q == f).astype(int) for q in win)
    out = f.copy()
    for k in (ss.RED, ss.BLUE):
        cnt = sum((q == k).astype(int) for q in win)
        m = al & (f != k) & (own < ROOF_OWN * n) & (cnt >= ROOF_MAJ * n)
        out[m] = k
        clear = clear | m
    return out, clear


def lock(rgb, base, fam_px, clear):
    """Each row of rgb (n x 3) to its nearest base colour within its material fam_px (FAMILY_OK) where `clear`, else
    to the nearest of all."""
    fam_pal = ss.family(base.astype(float))
    sat_pal = ss.hsv(base.astype(float))[1]
    out = np.zeros_like(rgb)
    groups = {}
    for k in range(6):
        ok = np.isin(fam_pal, FAMILY_OK[k])
        if k == ss.GREY:
            ok |= sat_pal < DULL
        groups[k] = np.nonzero(ok)[0] if ok.sum() >= 2 else np.arange(len(base))
    for k in range(6):
        m = clear & (fam_px == k)
        if m.any():
            out[m] = base[groups[k][nearest(rgb[m], base[groups[k]])]]
    m = ~clear
    if m.any():
        out[m] = base[nearest(rgb[m], base)]
    return out


def despeckle(img, skip):
    """Orphan px (no 8-neighbour of its colour, ORPHAN or more of one colour) take the neighbours' colour."""
    h, w = img.shape[:2]
    al = img[..., 3] > 0
    key = (img[..., 0].astype(np.int64) << 16) | (img[..., 1].astype(np.int64) << 8) | img[..., 2]
    key = np.where(al, key, -1)
    p = np.pad(key, 1, constant_values=-1)
    nb = [p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
    same = sum((n == key) for n in nb)
    cand = al & ~skip & (same == 0)
    out = img.copy()
    for y, x in zip(*np.nonzero(cand)):
        vals = [int(n[y, x]) for n in nb if n[y, x] >= 0]
        if not vals:
            continue
        u, c = np.unique(vals, return_counts=True)
        if c.max() >= ORPHAN:
            v = int(u[c.argmax()])
            out[y, x, :3] = ((v >> 16) & 255, (v >> 8) & 255, v & 255)
    return out


def eaves(img, ring, skip, base, outl):
    """A wall px right under a roof px goes one step toward the outline colour (see the module doc)."""
    al = img[..., 3] > 0
    f = ss.family(img[..., :3].astype(float))
    roof = al & ((f == ss.RED) | (f == ss.BLUE))
    under = np.zeros_like(al)
    under[1:] = roof[:-1]
    m = under & al & ~roof & ~ring & ~skip
    out = img.copy()
    if not m.any():
        return out
    cand_all = np.concatenate([base, outl]).astype(float)
    lc = ss.luma(cand_all)
    for y, x in zip(*np.nonzero(m)):
        c = img[y, x, :3].astype(float)
        dark = cand_all[lc < ss.luma(c) * 0.92]
        if len(dark) == 0:
            continue
        o = outl[nearest(c[None] * OUTLINE_K, outl)[0]].astype(float)
        goal = c * (1 - EAVES) + o * EAVES
        out[y, x, :3] = dark[nearest(goal[None], dark)[0]]
    return out


def redraw_outline(img, ring, outl):
    out = img.copy()
    if ring.any():
        out[..., :3][ring] = outl[nearest(img[..., :3][ring].astype(float) * OUTLINE_K, outl)]
    return out


def glow_ramp(rgb, ramp):
    """Lit-window px onto the reference ramp: their luminance rank within the still picks the step."""
    if len(rgb) == 0:
        return rgb
    L = ss.luma(rgb.astype(float))
    rl = ss.luma(ramp.astype(float))
    # stretch the panes' own range over the ramp's, so the brightest pane px is the ramp's top
    lo, hi = L.min(), L.max()
    t = (L - lo) / max(hi - lo, 1e-6) * (rl.max() - rl.min()) + rl.min()
    return ramp[np.abs(t[:, None] - rl[None, :]).argmin(1)]


def match(a, knobs, light=False, glow=True):
    """One still (float or uint8 RGBA) through the pass. Returns (uint8 RGBA, lit-window mask). glow=False: no lit
    windows (a ruin's fallen lamp is not lit)."""
    base, outl, ramp = palette()
    a = np.where(a[..., 3:] > 0, np.clip(np.asarray(a, float), 0, 255), 0)
    al = a[..., 3] > 0
    lit = np.zeros(al.shape, bool)
    if not light:
        a = saturate(a, knobs["fac"], knobs["glob"])
        fam, clear = materials(a)       # before the lift and the contrast, which move hue families
        a[..., :3] = np.clip(a[..., :3] * knobs["lift"], 0, 255)
        a = unsharp(a, knobs["amount"])
        if glow:
            # never on a roof: its eave highlights next to a dark tile line pass the finder's test
            lit = window_glow.lit([np.clip(a, 0, 255).astype(int)])[0] & al & ~np.isin(fam, (ss.RED, ss.BLUE))
    ring = outline_ring(al)
    lit &= ~ring
    out = np.zeros(a.shape, np.uint8)
    out[..., 3] = np.where(al, 255, 0)
    body = al & ~lit
    if light:
        fam, clear = materials(a)
    out[..., :3][body] = lock(a[..., :3][body], base, fam[body], clear[body])
    out[..., :3][lit] = glow_ramp(a[..., :3][lit], ramp)
    out = despeckle(out, ring | lit)
    if not light:
        out = eaves(out, ring, lit, base, outl)
    out = redraw_outline(out, ring, outl)
    out[~al] = 0
    return out, lit


def score(img):
    st = ss.stats(img)
    lo, hi = LUM_BAND
    return abs(st["edge"] - EDGE_TARGET) + 2.0 * max(0.0, lo - st["lum"], st["lum"] - hi), st


def tune(intact):
    """The set's knobs: saturation factors from the intact, then (lift, amount) off the fixed grid that lands its
    edge contrast nearest EDGE_TARGET with its mean luminance in LUM_BAND (ties: the smaller change)."""
    fac, glob = sat_factors(intact)
    mat_ref = refs()[1]
    for _ in range(SAT_ROUNDS):
        best = None
        for lift in LIFTS:
            for amount in AMOUNTS:
                k = {"fac": fac, "glob": glob, "lift": lift, "amount": amount}
                img, _ = match(intact, k)
                c, st = score(img)
                c += 0.01 * abs(lift - 1.0) + 0.002 * amount
                if best is None or c < best[0] - 1e-12:
                    best = (c, k, st, img)
        # the lock and the lift move the saturation, and the dominant material is the one after the pass: if the
        # result is off its material's reference by more than SAT_BAND, scale toward it and tune again
        ref = mat_ref.get(ss.dominant(best[3]))
        sat = best[2]["sat"]
        if ref is None or abs(sat - ref) <= SAT_BAND:
            break
        glob *= float(np.clip(sat, ref - SAT_BAND * 0.5, ref + SAT_BAND * 0.5) / sat)
    return best[1], best[2]


def match_strip(strip, frame_w, knobs, light=False):
    """A strip of frames, frame by frame with one set's knobs."""
    outs = [match(strip[:, i:i + frame_w], knobs, light)[0] for i in range(0, strip.shape[1], frame_w)]
    return np.concatenate(outs, 1)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--palette", action="store_true")
    args = ap.parse_args()
    if args.palette:
        p = build_palette()
        print("game_palette.png: %d colours (%d base, %d outline, %d ramp)" % (len(p), BASE, OUTLINE_N, RAMP_N))
        print("outline", p[BASE:BASE + OUTLINE_N].tolist())
        print("ramp", p[BASE + OUTLINE_N:].tolist())
