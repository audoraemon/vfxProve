"""Blockout guides for ChatGPT: plain massing models drawn at KAK's exact 2:1 isometric angle and scale.
Ground cell = 64x32 px in game; drawn here at 4x (256x128 per cell), so a painted result can be shrunk 4x straight
into the game. Light from the upper left: left walls light, right walls dark, roofs mid. Roofs are steep gables
like the town's houses (ridge along the building's long side)."""
from PIL import Image, ImageDraw

S = 4                       # 4x game pixels
CX, CY = 32 * S, 16 * S     # half a cell: one ground unit along x goes (+32,+16), along y (-32,+16) on screen
H = S                       # one height unit = 1 game px

WALL_L, WALL_R = (196, 190, 178), (128, 122, 112)
ROOF_L, ROOF_R = (150, 92, 74), (104, 62, 52)
OUT = (40, 30, 26)


def iso(x, y, z=0.0):
    return (x * CX - y * CX, x * CY + y * CY - z * H)


class Canvas:
    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)
        self.ox, self.oy = w / 2, h * 0.55

    def p(self, x, y, z):
        a, b = iso(x, y, z)
        return (self.ox + a, self.oy + b)

    def poly(self, pts, fill):
        self.d.polygon([self.p(*q) for q in pts], fill=fill, outline=OUT)

    def box(self, x0, y0, w, d, z0, h):
        """A box with its back corner at (x0, y0), w along x, d along y; only the two front walls and the top show."""
        x1, y1 = x0 + w, y0 + d
        # left wall faces +y (down-left), right wall faces +x (down-right)
        self.poly([(x0, y1, z0), (x1, y1, z0), (x1, y1, z0 + h), (x0, y1, z0 + h)], WALL_L)
        self.poly([(x1, y0, z0), (x1, y1, z0), (x1, y1, z0 + h), (x1, y0, z0 + h)], WALL_R)
        self.poly([(x0, y0, z0 + h), (x1, y0, z0 + h), (x1, y1, z0 + h), (x0, y1, z0 + h)], WALL_L)

    def gable(self, x0, y0, w, d, z, rise, along_x=True):
        """A gable roof on top of a box: ridge along x (or y), eaves overhanging slightly."""
        o = 0.08
        x0, y0, w, d = x0 - o, y0 - o, w + 2 * o, d + 2 * o
        x1, y1 = x0 + w, y0 + d
        if along_x:
            ym = y0 + d / 2
            self.poly([(x0, ym, z + rise), (x1, ym, z + rise), (x1, y1, z), (x0, y1, z)], ROOF_L)
            self.poly([(x1, y0, z), (x1, ym, z + rise), (x1, y1, z)], WALL_R)
        else:
            xm = x0 + w / 2
            self.poly([(xm, y0, z + rise), (xm, y1, z + rise), (x1, y1, z), (x1, y0, z)], ROOF_R)
            self.poly([(x0, y1, z), (xm, y1, z + rise), (x1, y1, z)], WALL_L)

    def hip(self, x0, y0, w, d, z, rise):
        o = 0.08
        x0, y0, w, d = x0 - o, y0 - o, w + 2 * o, d + 2 * o
        x1, y1 = x0 + w, y0 + d
        t = min(w, d) / 2
        a, b = (x0 + t, y0 + d / 2, z + rise), (x1 - t, y0 + d / 2, z + rise)
        self.poly([a, b, (x1, y1, z), (x0, y1, z)], ROOF_L)
        self.poly([b, (x1, y0, z), (x1, y1, z)], ROOF_R)


def town_hall(c):
    c.box(0, 0, 2.4, 1.5, 0, 34)
    c.gable(0, 0, 2.4, 1.5, 34, 30)
    c.box(1.0, 1.2, 0.5, 0.3, 34, 14)            # clock gable dormer on the front slope
    c.gable(1.0, 1.2, 0.5, 0.3, 48, 8, along_x=False)


def armoury(c):
    c.box(0, 0, 1.6, 1.2, 0, 22)
    c.gable(0, 0, 1.6, 1.2, 22, 24)
    c.box(1.6, 0.2, 0.7, 1.0, 0, 14)             # open weapon shed (lean-to) on the right
    c.gable(1.6, 0.2, 0.7, 1.0, 14, 8)


def jail(c):
    c.box(0, 0, 1.1, 0.9, 0, 20)
    c.gable(0, 0, 1.1, 0.9, 20, 18)
    c.box(0.2, 1.05, 0.5, 0.12, 0, 6)            # stocks beside it


def courthouse(c):
    c.box(0, 0, 2.2, 1.5, 0, 26)
    c.hip(0, 0, 2.2, 1.5, 26, 22)
    c.box(0.7, 1.5, 0.8, 0.4, 0, 22)             # columned porch
    c.gable(0.7, 1.5, 0.8, 0.4, 22, 8, along_x=False)
    c.box(0.6, 1.9, 1.0, 0.2, 0, 3)              # steps


def watchtower(c):
    for (x, y) in ((0, 0), (0.6, 0), (0, 0.6), (0.6, 0.6)):
        c.box(x, y, 0.12, 0.12, 0, 34)           # stilts
    c.box(-0.05, -0.05, 0.82, 0.82, 34, 12)      # lookout cabin
    c.hip(-0.05, -0.05, 0.82, 0.82, 46, 14)


def treasury(c):
    c.box(0, 0, 1.2, 1.2, 0, 18)
    c.hip(0, 0, 1.2, 1.2, 18, 16)


BUILDINGS = [("1 town hall", town_hall), ("2 armoury", armoury), ("3 jail", jail),
             ("4 courthouse", courthouse), ("5 watchtower", watchtower), ("6 treasury", treasury)]

if __name__ == "__main__":
    import os
    here = os.path.dirname(os.path.abspath(__file__))
    tiles = []
    for name, fn in BUILDINGS:
        c = Canvas(1400, 1200)
        fn(c)
        im = c.img.crop(c.img.getbbox())
        tiles.append(im)
    pad = 80
    cols = 3
    cw = max(t.width for t in tiles) + pad
    ch = max(t.height for t in tiles) + pad
    sheet = Image.new("RGBA", (cw * cols + pad, ch * 2 + pad), (255, 255, 255, 255))
    for i, t in enumerate(tiles):
        x = pad + (i % cols) * cw + (cw - pad - t.width) // 2
        y = pad + (i // cols) * ch + (ch - pad - t.height)
        sheet.alpha_composite(t, (x, y))
    sheet.save(os.path.join(here, "blockouts_defence.png"))
    print(sheet.size)
