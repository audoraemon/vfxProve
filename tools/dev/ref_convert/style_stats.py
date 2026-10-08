"""Style stats of building sets' intact stills (opaque pixels only), the numbers the style match pass is tuned to.

  outline   mean luminance of the outline: opaque px with a transparent 4-neighbour (or on the image edge)
  edge      edge contrast: mean |delta luminance| to the right neighbour, over pairs of opaque px
  colours   distinct opaque RGB colours
  sat       mean HSV saturation
  lum       mean luminance
Luminance is Rec. 601 (0.299 R + 0.587 G + 0.114 B) / 255.

Usage (from anywhere):
  python tools/dev/ref_convert/style_stats.py [<set> ...] [--state intact|damaged|ruins] [--dir <buildings dir>]
  no sets: the reference neighbours and every gpt_* set.
"""
import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
B = ROOT / "assets" / "pixellab" / "buildings"
REFS = ["townhouse_a", "townhouse_b", "tavern", "cottage_red", "workshop", "barracks"]
GPT = ["gpt_townhall", "gpt_armoury", "gpt_jail", "gpt_courthouse", "gpt_watchtower", "gpt_treasury",
       "gpt_chapel", "gpt_monastery", "gpt_graveyard", "gpt_hospital", "gpt_leperhouse", "gpt_bathhouse",
       "gpt_inn", "gpt_shophouse", "gpt_guildhall", "gpt_markethall", "gpt_weighhouse", "gpt_fishmarket",
       "gpt_bakery", "gpt_butcher", "gpt_brewery", "gpt_tannery", "gpt_dyers", "gpt_weavers",
       "gpt_potter", "gpt_cooper", "gpt_masonyard", "gpt_lumberyard", "gpt_charcoal", "gpt_glassworks",
       "gpt_granary", "gpt_warehouse", "gpt_orchard", "gpt_vineyard", "gpt_beehives", "gpt_dovecote",
       "gpt_cistern", "gpt_aqueduct", "gpt_washhouse", "gpt_latrine", "gpt_sluice", "gpt_footbridge",
       "gpt_manor", "gpt_patrician", "gpt_rowhouses", "gpt_tenement", "gpt_shacks", "gpt_hut",
       "gpt_monument", "gpt_noticeboard", "gpt_crierstage", "gpt_grandstand", "gpt_tiltbarrier", "gpt_playstage",
       "gpt_school", "gpt_library", "gpt_pavilion", "gpt_farmhouse", "gpt_fishpond", "gpt_icehouse",
       "gpt_stables", "gpt_wagon", "gpt_handcart", "gpt_crane", "gpt_ferry", "gpt_pens",
       "gpt_barbican", "gpt_drawbridge", "gpt_gallows", "gpt_districtgate",
       "gpt_milestone", "gpt_waysidecross", "gpt_alleysteps"]


def luma(rgb):
    return (rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114) / 255.0


def outline_mask(al):
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    return e


def stats(a):
    """Dict of the five numbers for one RGBA uint8 array."""
    al = a[..., 3] > 0
    rgb = a[..., :3].astype(float)
    L = luma(rgb)
    e = outline_mask(al)
    pair = al[:, :-1] & al[:, 1:]
    edge = np.abs(L[:, 1:] - L[:, :-1])[pair].mean()
    px = a[..., :3][al].astype(np.int64)
    cols = len(np.unique((px[:, 0] << 16) | (px[:, 1] << 8) | px[:, 2]))
    mx, mn = rgb.max(2), rgb.min(2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    return {"outline": float(L[e].mean()), "edge": float(edge), "colours": cols,
            "sat": float(sat[al].mean()), "lum": float(L[al].mean())}


# Material families (hue, saturation, value): what a pixel is painted as.
GREY, RED, TIMBER, CREAM, GREEN, BLUE = range(6)
FAMILY_NAMES = ["stone/grey", "roof red", "timber brown", "plaster cream", "green", "slate blue"]
GREY_SAT = 0.15         # below: stone and greys
CREAM_V = 0.55          # warm hues at or above this value are plaster and pale stone, below it timber


def hsv(rgb):
    """(hue degrees, saturation, value) of a float RGB array in 0-255."""
    c = rgb / 255.0
    mx, mn = c.max(-1), c.min(-1)
    d = mx - mn
    dd = np.maximum(d, 1e-6)
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) * 60.0
    h = np.where(d > 0, h, 0.0)
    s = np.where(mx > 0, d / np.maximum(mx, 1e-6), 0.0)
    return h, s, mx


def family(rgb):
    """Material family per pixel of a float RGB array (0-255)."""
    h, s, v = hsv(rgb)
    f = np.full(h.shape, GREY, int)
    col = s >= GREY_SAT
    f[col & ((h < 18) | (h >= 330))] = RED
    warm = col & (h >= 18) & (h < 55)
    f[warm & (v < CREAM_V)] = TIMBER
    f[warm & (v >= CREAM_V)] = CREAM
    f[col & (h >= 55) & (h < 170)] = GREEN
    f[col & (h >= 170) & (h < 330)] = BLUE
    return f


def family_sat(a):
    """{family: (share of opaque px, mean saturation)} of an RGBA array."""
    al = a[..., 3] > 0
    rgb = a[..., :3].astype(float)[al]
    f = family(rgb)
    s = hsv(rgb)[1]
    return {k: (float((f == k).mean()), float(s[f == k].mean()) if (f == k).any() else 0.0) for k in range(6)}


PALETTE_REFS = ["townhouse_a", "townhouse_b", "tavern", "cottage_red", "cottage_blue", "workshop", "smithy",
                "barracks", "carpenter", "barn", "town_tower"]


def ref_family_sat(base=B):
    """Mean saturation per family over every reference set's opaque px (PALETTE_REFS)."""
    rgb = np.concatenate([a[..., :3][a[..., 3] > 0] for a in (load(n, "intact", base) for n in PALETTE_REFS)])
    rgb = rgb.astype(float)
    f = family(rgb)
    s = hsv(rgb)[1]
    return {k: float(s[f == k].mean()) for k in range(6) if (f == k).any()}


def dominant(a):
    fs = family_sat(a)
    return max(fs, key=lambda q: fs[q][0])


def ref_material_sat(base=B):
    """{material: mean of the whole-sprite saturation of the PALETTE_REFS sets that material dominates}."""
    groups = {}
    for n in PALETTE_REFS:
        a = load(n, "intact", base)
        groups.setdefault(dominant(a), []).append(stats(a)["sat"])
    return {k: float(np.mean(v)) for k, v in groups.items()}


def materials(names, state="intact", base=B):
    """Each set's dominant material (most opaque px), its whole-sprite mean saturation and the reference mean for that
    material: the mean saturation of the reference sets (PALETTE_REFS) that material dominates. Target: within 0.08."""
    ref = ref_material_sat()
    rows = ["%-16s %-14s %6s %6s %6s %5s" % ("set", "dominant", "share", "sat", "ref", "ok")]
    for n in names:
        a = load(n, state, base)
        fs = family_sat(a)
        k = max(fs, key=lambda q: fs[q][0])
        sat = stats(a)["sat"]
        r = ref.get(k, float("nan"))
        rows.append("%-16s %-14s %6.2f %6.3f %6.3f %5s" % (n, FAMILY_NAMES[k], fs[k][0], sat, r,
                                                           "yes" if abs(sat - r) <= 0.08 else "NO"))
    return "\n".join(rows)


def load(name, state="intact", base=B):
    return np.array(Image.open(Path(base) / name / (state + ".png")).convert("RGBA"))


def table(names, state="intact", base=B):
    rows = ["%-16s %8s %6s %8s %6s %6s" % ("set", "outline", "edge", "colours", "sat", "lum")]
    for n in names:
        s = stats(load(n, state, base))
        rows.append("%-16s %8.3f %6.3f %8d %6.3f %6.3f" % (n, s["outline"], s["edge"], s["colours"], s["sat"],
                                                          s["lum"]))
    return "\n".join(rows)


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sets", nargs="*")
    ap.add_argument("--state", default="intact")
    ap.add_argument("--dir", default=str(B))
    a = ap.parse_args()
    print(table(a.sets or REFS + GPT, a.state, a.dir))
    print()
    print(materials(a.sets or REFS + GPT, a.state, a.dir))
