"""How much of each building sprite and decor set (assets/pixellab/decor/*/intact.png) the sprite shader treats as
glowing (lit windows, fires): those pixels skip the dim, the effects' light and the char. The rule is
structure_sprite.gdshader's glows(); change both together.
Exits 1 if a sprite glows over MAX_SHARE, which means the rule is catching its walls, not its windows.
Usage (from the project root): python tools/dev/check_sprite_glow.py [--masks DIR]   (--masks: a PNG per sprite, glow in magenta)
"""
import glob
import os
import sys

from PIL import Image

MAX_SHARE = 0.05


def glows(r, g, b):
    mx = max(r, g, b)
    mn = min(r, g, b)
    return r >= mx and mx > 0.93 and (mx - mn) / mx > 0.55 and g > 0.45


def main():
    masks = sys.argv[sys.argv.index("--masks") + 1] if "--masks" in sys.argv else None
    bad = 0
    paths = sorted(glob.glob("assets/pixellab/buildings/*/*.png"))
    paths += sorted(glob.glob("assets/pixellab/decor/*/intact.png"))
    for path in paths:
        name = "/".join(path.replace("\\", "/").split("/")[-2:])
        if name.endswith(("reference.png", "style_ref.png")):
            continue
        im = Image.open(path).convert("RGBA")
        px = im.load()
        opaque = lit = 0
        mask = Image.new("RGBA", im.size, (0, 0, 0, 0)) if masks else None
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                opaque += 1
                if glows(r / 255, g / 255, b / 255):
                    lit += 1
                    if mask:
                        mask.putpixel((x, y), (255, 0, 255, 255))
        share = lit / max(opaque, 1)
        flag = "  TOO MUCH" if share > MAX_SHARE else ""
        bad += 1 if flag else 0
        print("%-32s %5.1f%% glow%s" % (name, share * 100.0, flag))
        if mask:
            os.makedirs(masks, exist_ok=True)
            view = Image.new("RGBA", im.size, (40, 40, 40, 255))
            view.alpha_composite(im)
            view.alpha_composite(mask)
            view.save(os.path.join(masks, name.replace("/", "_")))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
