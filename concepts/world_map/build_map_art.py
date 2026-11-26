"""Builds the World Map's art in res://assets/chamber/ from the Codex CLI paintings in this folder.

  j4/world_map_v4.png  -> map.png              the painting (no road, smoke or ships: the code draws those)
  jfog/fog_sheet.png   -> map/cloud_0..5.png   the cloud banks that lie on what the god cannot reach
  jui/ui_sheet.png     -> map/note.png, seal.png, seal_off.png, tag.png, ship_0.png, ship_1.png, pointer.png
  map.png              -> map/land.png         320 x 180 mask: white on land, black on sea and rivers (the god's faith stays on land)

The sheets are painted on flat magenta; it is keyed out here (a sheet has no real alpha).
"""
import os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "chamber"))
PIECES = os.path.join(OUT, "map")


def keyed(path):
    """The sheet as RGBA with the magenta gone and its fringe pulled back."""
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # how magenta a pixel is: red and blue high, green low
    mag = np.clip((np.minimum(r, b) - g) / 255.0, 0.0, 1.0)
    solid = mag < 0.35
    solid = ndi.binary_opening(solid, iterations=1)
    alpha = ndi.binary_erosion(solid, iterations=1).astype(np.float32)
    alpha = np.maximum(alpha, ndi.gaussian_filter(solid.astype(np.float32), 0.7) * solid)
    out = np.dstack([a, alpha * 255.0]).astype(np.uint8)
    # despill: a fringe pixel leaning magenta takes its green up to the lower of red and blue
    fringe = (mag > 0.08) & solid
    lo = np.minimum(out[..., 0], out[..., 2])
    out[..., 0][fringe] = lo[fringe]
    out[..., 2][fringe] = lo[fringe]
    return Image.fromarray(out, "RGBA"), solid


def pieces(path, min_area=4000):
    """The sheet's separate props, largest area first: (image, box)."""
    im, solid = keyed(path)
    lab, _n = ndi.label(ndi.binary_dilation(solid, iterations=6))
    got = []
    for i, sl in enumerate(ndi.find_objects(lab)):
        area = int((lab[sl] == i + 1).sum())
        if area < min_area:
            continue
        box = (sl[1].start, sl[0].start, sl[1].stop, sl[0].stop)
        piece = im.crop(box)
        px = np.asarray(piece).copy()
        px[..., 3][lab[sl] != i + 1] = 0  # nothing of a neighbour
        got.append((Image.fromarray(px, "RGBA"), box, area))
    return got


def mist(im):
    """The painted cloud pulled toward the map's own palette: most of its violet out, a little candle warmth in."""
    px = np.asarray(im).astype(np.float32)
    rgb = px[..., :3]
    grey = rgb.mean(axis=2, keepdims=True)
    rgb = grey + (rgb - grey) * 0.35
    rgb = rgb * np.array([1.03, 0.99, 0.95], dtype=np.float32)
    px[..., :3] = np.clip(rgb, 0, 255)
    return Image.fromarray(px.astype(np.uint8), "RGBA")


def save(im, name, width=None):
    if width is not None and im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(PIECES, name + ".png"))
    print(name, im.size)


def land_mask(painting):
    a = np.asarray(painting.convert("RGB").resize((640, 360), Image.LANCZOS)).astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    water = (b > r + 18) & (b > 60)
    water = ndi.binary_closing(water, iterations=1)
    land = ~water
    land[:29, :] = False
    land[345:, :] = False
    land[:, :12] = False
    land[:, 628:] = False
    im = Image.fromarray((land * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.6))
    return im.resize((320, 180), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(PIECES, exist_ok=True)
    painting = Image.open(os.path.join(HERE, "j4", "world_map_v4.png")).convert("RGB")
    painting.save(os.path.join(OUT, "map.png"))
    print("map", painting.size)
    land_mask(painting).save(os.path.join(PIECES, "land.png"))
    clouds = sorted(pieces(os.path.join(HERE, "jfog", "fog_sheet.png")), key=lambda p: (p[1][1] // 300, p[1][0]))
    assert len(clouds) == 6, len(clouds)
    for i, (im, _box, _area) in enumerate(clouds):
        save(mist(im), "cloud_%d" % i, 320)
    ui = pieces(os.path.join(HERE, "jui", "ui_sheet.png"))
    assert len(ui) == 7, [p[1] for p in ui]
    by_x = lambda p: p[1][0]
    top = sorted([p for p in ui if p[1][1] < 560 and p[1][3] < 600], key=by_x)   # note, then the two seals (right column)
    low = sorted([p for p in ui if p not in top], key=by_x)                       # tag, ship, ship, pointer
    note = top[0]
    seals = sorted(top[1:], key=lambda p: p[1][1])
    assert len(seals) == 2 and len(low) == 4, (len(seals), len(low))
    save(note[0], "note", 800)
    save(seals[0][0], "seal", 160)
    save(seals[1][0], "seal_off", 160)
    save(low[0][0], "tag", 400)
    save(low[1][0], "ship_0", 120)
    save(low[2][0], "ship_1", 120)
    save(low[3][0], "pointer", 64)
