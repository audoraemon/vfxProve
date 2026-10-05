"""The town's street torch and lamp post from the reference sheet (concepts/TOWN REF/TownMap_Component2.png, row 5),
converted with convert.py at their plot (0.2 x 0.2) and finished with their states, all locally (no AI):

  torch_post   the standing torch: a wooden post on a flared foot, a rope-bound bowl at the top. Its painted flame is
               cut off at the bowl's rim: the engine's procedural torch flame burns there (keep_flames, flame point).
  lamp_post    the lantern post: a post on a stone foot, an arm to the right, a lantern hanging from it. Its painted
               glass is dark: the engine's procedural lantern glow lights it (keep_flames, glass rect).

States: intact, damaged (a crack down the post, a chip out of the foot; the torch's bowl rim notched, the lamp's top
knob broken off and its arm's end snapped; the flame and glow stay where they were), ruins (the foot left standing
and the post lying on the ground beside it, clean). No idle strip: the procedural flame flickers.

Scale: one scale for both, SCALE sprite px per sheet px, from the sheet's own proportions: a sheet person is about
50 px tall and a game person about 17, so 0.33 keeps the posts at the sheet's height relative to people. It puts the
torch's post (foot to bowl rim) at ~24 px, 1.3x the procedural torch's 18 (post 16 + cup 2), and the lamp at ~38 px
overall, as tall as the procedural lamp (LAMP_H 34 + its arm).

Usage (from anywhere):
  python tools/dev/ref_convert/posts.py [all | torch_post | lamp_post] [--out <scratch dir>]
"""
import argparse
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_fix  # noqa: E402

ROOT = convert.ROOT
B = convert.B
SHEET = ROOT / "concepts" / "TOWN REF" / "TownMap_Component2.png"
OUTLINE = (34, 26, 24)
FP = (0.2, 0.2)
SCALE = 0.33
GLASS = (44, 34, 32)
LENGTH = {"torch_post": 28, "lamp_post": 52}   # room right of the foot for the ruins' fallen post (and lantern), px
LEAN = {"torch_post": 6, "lamp_post": 10}      # damaged: the post leans 1 px right every LEAN rows above its foot        # the unlit lantern glass under the procedural glow

# name: (scan box on the sheet, tag, height, seed, rim: the sheet row the torch's flame is cut above (None: none))
SETS = {
    "torch_post": ((1036, 496, 1084, 624), "", 16, 3, 544),
    "lamp_post": ((1116, 488, 1172, 616), "lamp", 18, 4, None),
}


def hls(a):
    return sprite_fix._hls(a)


def cut(name):
    """The post alone: its main shape (the flame's soft glow is dropped with the semi-opaque pixels), and for the
    torch nothing above the bowl's rim (the painted flame and the stick burning in it)."""
    box, _, _, _, rim = SETS[name]
    a = np.array(Image.open(SHEET).convert("RGBA").crop(box))
    a = convert.keep_shapes(a)
    if rim is not None:
        a[:rim - box[1]] = 0
        a = convert.keep_shapes(a)
    return a


def outline(a):
    """convert.py's 1 px dark outline on the opaque shape's edge."""
    al = a[..., 3] > 0
    h, w = al.shape
    p = np.pad(al, 1)
    e = np.zeros_like(al)
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        e |= al & ~p[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    dark = a[..., :3].astype(int).sum(axis=2) < 200
    m = e & ~dark
    a[m, :3] = (a[m, :3] * 0.45 + np.array(OUTLINE) * 0.55).astype(np.uint8)
    return a


def unglow(a):
    """Wood highlights the sprite shader would take for a flame (structure_sprite.gdshader glows()) toned down a
    little: only the procedural flame glows."""
    rgb = a[..., :3].astype(float) / 255
    mx, mn = rgb.max(-1), rgb.min(-1)
    g = (a[..., 3] > 0) & (rgb[..., 0] >= mx) & (mx > 0.93) & ((mx - mn) / np.maximum(mx, 1e-6) > 0.55) & (rgb[..., 1] > 0.45)
    a[g, :3] = (a[g, :3] * 0.9).astype(np.uint8)
    return a


def post_column(a):
    """(x0, x1) of the post's columns: the narrowest run of opaque columns in the middle third of the height."""
    al = a[..., 3] > 0
    ys = np.nonzero(al.any(1))[0]
    top, bot = ys.min(), ys.max()
    best = None
    for y in range(top + (bot - top) // 3, top + 2 * (bot - top) // 3):
        xs = np.nonzero(al[y])[0]
        if len(xs) and (best is None or xs.max() - xs.min() < best[1] - best[0]):
            best = (int(xs.min()), int(xs.max()))
    return best


def glass_rect(a):
    """The lantern's lit glass, darkened in place (its frame bars kept); returns its rect [x, y, w, h]. The glass is the
    lowest run of rows (gaps up to 2 rows: a frame bar) with bright saturated pixels right of the post: the arm's lit
    wood above it is parted from it by the lantern's dark hood."""
    h, l, s = hls(a)
    px0, px1 = post_column(a)
    xx = np.arange(a.shape[1])[None, :].repeat(a.shape[0], 0)
    lit = (a[..., 3] > 0) & (h >= 15) & (h <= 60) & (s >= 0.7) & (l >= 0.33) & (xx > px1 + 1)
    rows = [y for y in range(lit.shape[0]) if lit[y].any()]
    keep = [rows[-1]]
    for y in reversed(rows[:-1]):
        if keep[-1] - y > 2:
            break
        keep.append(y)
    comp = lit & np.isin(np.arange(lit.shape[0]), keep)[:, None]
    ys, xs = np.nonzero(comp)
    x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
    box = a[y0:y1 + 1, x0:x1 + 1]
    bh, bl, bs = h[y0:y1 + 1, x0:x1 + 1], l[y0:y1 + 1, x0:x1 + 1], s[y0:y1 + 1, x0:x1 + 1]
    frame = (bs < 0.5) | (bl < 0.2)
    box[~frame & (box[..., 3] > 0), :3] = GLASS
    return [x0, y0, x1 - x0 + 1, y1 - y0 + 1]


def flame_point(a):
    """The torch's bowl rim: the middle of its top row's run, one row above it (the flame's base)."""
    al = a[..., 3] > 0
    y = int(np.nonzero(al.any(1))[0].min())
    xs = np.nonzero(al[y:y + 2].any(0))[0]
    return [int(round((xs.min() + xs.max()) / 2)), y]


def convert_set(name, tmp):
    """Cut, fit at SCALE and place; writes intact.png and the manifest entry. Returns (intact, anchor, extra)."""
    box, tag, height, seed, rim = SETS[name]
    src = Path(tmp) / ("cut_%s.png" % name)
    im = Image.fromarray(cut(name), "RGBA")
    x0, y0, x1, y1 = im.getchannel("A").getbbox()
    im.crop((x0 - 2, y0 - 2, x1 + 2, y1 + 2)).save(src)
    w, h = Image.open(src).size
    body_w = float(x1 - x0)
    # convert.py scales the bbox width to 32 (W + D) px: pick the footprint that gives SCALE
    k = SCALE * body_w / (32 * (FP[0] + FP[1]))
    c, anchor, info = convert.convert(str(src), (0, 0, w, h), (FP[0] * k, FP[1] * k), colors=32, measure="bbox",
                                      canvas_pad=3)
    c = unglow(c)
    extra = {}
    if tag == "lamp":
        extra["glass"] = glass_rect(c)
    else:
        extra["flame"] = flame_point(c)
        # room above the bowl for the procedural flame (14 px) inside the canvas
        need = 15 - extra["flame"][1]
        if need > 0:
            c = np.concatenate([np.zeros((need, c.shape[1], 4), np.uint8), c], 0)
            anchor = (anchor[0], anchor[1] + need)
            extra["flame"][1] += need
    # room right of and below the foot for the ruins' fallen post (it lies on the ground toward the lower right)
    right = max(0, anchor[0] + LENGTH[name] - (c.shape[1] - 1))
    below = max(0, anchor[1] + 3 - (c.shape[0] - 1))
    c = np.concatenate([c, np.zeros((c.shape[0], right, 4), np.uint8)], 1)
    c = np.concatenate([c, np.zeros((below, c.shape[1], 4), np.uint8)], 0)
    d = B / name
    d.mkdir(parents=True, exist_ok=True)
    Image.fromarray(c, "RGBA").save(d / "intact.png")
    print("%s: body %.0f px, scale %.3f, size %s anchor %s %s" % (name, body_w, info["scale"], [c.shape[1], c.shape[0]],
                                                                 list(anchor), extra))
    entry = {"size": [c.shape[1], c.shape[0]], "footprint": list(FP), "anchor": list(anchor), "height": height,
             "seed": seed, "kind": "TORCH", "role": "decor", "tag": tag, "keep_flames": True}
    entry.update(extra)
    convert.write_manifest(B / "manifest.json", name, entry)
    return c, anchor, extra


# ---- finish: damaged, ruins ----------------------------------------------------------------------------------------
def _pick(px, q):
    order = np.argsort(px.astype(int).sum(1))
    return tuple(int(v) for v in px[order[int(q * (len(order) - 1))]])


def wood_colours(a):
    h, l, s = hls(a)
    wood = (a[..., 3] > 0) & (h >= 12) & (h <= 45) & (s >= 0.3) & (l >= 0.15) & (l <= 0.7)
    px = a[wood][:, :3]
    return {k: _pick(px, q) for k, q in (("light", 0.92), ("lit", 0.75), ("mid", 0.5), ("shade", 0.25),
                                         ("dark", 0.08))}


def foot_rows(a, anchor):
    """The foot's top row: going up from the base, past the foot's wide rows, the row under the first one as narrow as
    the post."""
    px0, px1 = post_column(a)
    al = a[..., 3] > 0
    wide = False
    for y in range(anchor[1], 0, -1):
        xs = np.nonzero(al[y])[0]
        narrow = len(xs) and xs.max() - xs.min() <= (px1 - px0) + 1
        if not narrow:
            wide = True
        elif wide:
            return y + 1
    return anchor[1] - 4


def lean_shift(y, ft, run):
    """How far right the leaning post's row y moves: 0 at the foot's top, 1 px more every `run` rows up."""
    return max(0, (ft - y) // run)


def damaged(a, name, anchor, extra):
    """The post leans right from its foot (1 px every LEAN rows, the foot stays put) with a short crack in it and a
    chip out of the foot's right front corner; the torch's bowl rim is notched, the lamp's top knob broken off. The
    flame's base or the lantern's glass moves with the lean: the shift goes in the manifest (damaged_shift)."""
    wc = wood_colours(a)
    H, W = a.shape[:2]
    px0, px1 = post_column(a)
    ft = foot_rows(a, anchor)
    out = np.zeros_like(a)
    out[ft:] = a[ft:]
    for y in range(ft):
        dx = lean_shift(y, ft, LEAN[name])
        out[y, dx:] = a[y, :W - dx]
    # the joint above the foot, where the lean starts: a dark split on the post's right, its lit edge on the left
    cx = px1 + lean_shift(ft - 6, ft, LEAN[name])
    for y in range(ft - 7, ft - 2):
        if out[y, cx, 3]:
            out[y, cx, :3] = OUTLINE
    # the foot's right front corner chipped: two pixels gone, the break's top lit
    al = out[..., 3] > 0
    right = max(int(np.nonzero(al[y])[0].max()) for y in range(ft, anchor[1] + 1) if al[y].any())
    out[ft + 1:ft + 3, right - 1:right + 1] = 0
    if out[ft + 3, right - 1, 3]:
        out[ft + 3, right - 1, :3] = wc["lit"]
    if name == "torch_post":
        fx, fy = extra["flame"]
        sx = lean_shift(fy, ft, LEAN[name])
        # a notch out of the bowl's rim, right of the flame's base
        for x in range(fx + sx + 2, fx + sx + 4):
            out[fy, x] = 0
        out[fy + 1, fx + sx + 2:fx + sx + 4, :3] = OUTLINE
        shift = [sx, 0]
    else:
        gx, gy, gw, gh = extra["glass"]
        ys = np.nonzero(al.any(1))[0]
        top = int(ys.min())
        # the post's top knob broken off (two rows), its new top lit
        for y in range(top, top + 2):
            xs = np.nonzero(out[y, :, 3] > 0)[0]
            out[y, xs[xs <= px1 + 1 + lean_shift(y, ft, LEAN[name])]] = 0
        xs = np.nonzero(out[top + 2, :, 3] > 0)[0]
        out[top + 2, xs[xs <= px1 + 1 + lean_shift(top + 2, ft, LEAN[name])], :3] = wc["lit"]
        shift = [lean_shift(gy, ft, LEAN[name]), 0]
    out[out[..., 3] == 0] = 0
    return outline(out), shift


def ruins(a, name, anchor, extra):
    """Clean ruins: the foot left standing as a short stub, its broken top lit, and the post fallen to the right of it
    on the ground, the sprite's own post turned a quarter clockwise (its lit left side up, light from the left; the
    top end, the bowl, to the right). The lamp's arm and lantern come off: the lantern stands unlit by the post's end."""
    wc = wood_colours(a)
    H, W = a.shape[:2]
    ft = foot_rows(a, anchor)
    px0, px1 = post_column(a)
    out = np.zeros_like(a)
    stub = ft - 2
    out[stub:] = a[stub:]
    xs = np.nonzero(out[stub, :, 3] > 0)[0]
    out[stub, xs, :3] = wc["light"]
    # the post above the stub (the torch's bowl with it); the lamp's post column only
    piece = a[:stub].copy()
    lantern = None
    if name == "lamp_post":
        gx, gy, gw, gh = extra["glass"]
        # the lantern: its hood and glass, the columns right of the post from the hood's top down
        lx0 = px1 + 2
        lantern = a[:, lx0:].copy()
        hood = gy - 6
        lantern[:hood] = 0
        lantern[gy + gh + 4:] = 0                 # (not the foot's right side)
        piece[:, px1 + 2:] = 0
        piece[:, :px0 - 1] = 0
    al = piece[..., 3] > 0
    ys, xs = np.nonzero(al)
    piece = piece[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    lying = np.rot90(piece, -1).copy()          # clockwise: the top to the right, the left side up
    lh, lw = lying.shape[:2]
    x0 = int(np.nonzero(out[anchor[1], :, 3] > 0)[0].max()) + 1
    y0 = anchor[1] - lh + 1
    region = out[y0:y0 + lh, x0:x0 + lw]
    m = lying[..., 3] > 0
    region[m] = lying[m]
    if lantern is not None:
        al = lantern[..., 3] > 0
        ys, xs = np.nonzero(al)
        lantern = lantern[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        lh2, lw2 = lantern.shape[:2]
        lx, ly = x0 + lw + 1, anchor[1] - lh2 + 2
        reg = out[ly:ly + lh2, lx:lx + lw2]
        m = lantern[..., 3] > 0
        reg[m] = lantern[m]
    return outline(out)


def finish(name, intact, anchor, extra):
    d = B / name
    dmg, shift = damaged(intact, name, anchor, extra)
    Image.fromarray(dmg, "RGBA").save(d / "damaged.png")
    Image.fromarray(ruins(intact, name, anchor, extra), "RGBA").save(d / "ruins.png")
    convert.write_manifest(B / "manifest.json", name, {"damaged_shift": shift})

if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("what", nargs="*", default=["all"])
    p.add_argument("--out", default=str(Path(tempfile.gettempdir()) / "posts"))
    a = p.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for n in (list(SETS) if a.what == ["all"] else a.what):
        c, anchor, extra = convert_set(n, out)
        finish(n, c, anchor, extra)
