"""Paint the procedural powers' icons, in the painted icons' manner -- a dark field with one glowing subject -- at 84x84
for the Prepare cards and 42x42 for the HUD slots: v0.05's quiet powers (Silent Doom, Blight) and v0.06's (Will-o'-Wisp,
Thornwall, Discord, Pestilence).

usage: python tools/dev/make_power_icons.py [key ...]   (all by default; writes assets/pixellab/icons/<key>.png and
       hud/<key>.png)
"""
import math
import os

import numpy as np
from PIL import Image

SIZE = 84
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "pixellab", "icons")


def grid():
    y, x = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    return x - SIZE / 2 + 0.5, y - SIZE / 2 + 0.5


def noise(seed, scale):
    """Smooth value noise: a coarse random grid, bilinearly enlarged."""
    rng = np.random.default_rng(seed)
    n = SIZE // scale + 2
    g = rng.random((n, n))
    img = Image.fromarray((g * 255).astype(np.uint8)).resize((n * scale, n * scale), Image.BICUBIC)
    return np.asarray(img, dtype=np.float64)[:SIZE, :SIZE] / 255.0


def blend(base, col, a):
    a = np.clip(a, 0.0, 1.0)[..., None]
    return base * (1.0 - a) + np.array(col, dtype=np.float64) * a


def finish(rgb, name):
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")
    # Down to a pixel-art palette, as the painted icons are.
    img = img.quantize(colors=48, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    img.save(os.path.join(OUT, name + ".png"))
    img.resize((42, 42), Image.LANCZOS).save(os.path.join(OUT, "hud", name + ".png"))


def doom():
    """A hooded death: a dark cowl with two cold green eyes, wisps of smoke curling round it, a violet-teal glow."""
    x, y = grid()
    r = np.hypot(x, y)
    n = noise(7, 6)
    n2 = noise(9, 3)
    rgb = np.zeros((SIZE, SIZE, 3))
    rgb[:] = (12, 8, 20)
    rgb = blend(rgb, (70, 40, 120), np.exp(-(r / 34.0) ** 2) * (0.75 + 0.35 * n))
    rgb = blend(rgb, (40, 150, 140), np.exp(-((x) ** 2 + (y + 4) ** 2) / 300.0) * 0.6)
    # Smoke wisps: light ribbons curling round the figure.
    for k, (ph, rad, ycen) in enumerate([(0.0, 30.0, -6.0), (2.1, 25.0, 4.0), (4.2, 34.0, 10.0)]):
        ang = np.arctan2(y - ycen, x)
        rr = np.hypot(x, (y - ycen) * 1.6)
        band = np.exp(-((rr - rad - 3.0 * np.sin(ang * 3 + ph)) ** 2) / 6.0) * (0.5 + 0.5 * np.sin(ang + ph))
        rgb = blend(rgb, (150, 140, 190), band * (0.35 + 0.4 * n2))
    # The cowl: a pointed arch, flaring to shoulders at the bottom.
    t = np.clip((y + 32.0) / 64.0, 0.0, 1.0)
    half = 6.0 + 20.0 * t ** 0.55 + np.where(y > 18, (y - 18) * 1.4, 0.0)
    cowl = (np.abs(x) < half) & (y > -32) & (y < 42)
    cowl_soft = np.clip((half - np.abs(x)) / 2.0, 0.0, 1.0) * (y > -32)
    shade = 0.6 + 0.4 * np.clip(-x / 26.0, -1, 1)
    rgb = blend(rgb, (26, 22, 40), cowl_soft)
    rgb = blend(rgb, (60, 52, 84), cowl_soft * np.clip(shade - 0.8, 0, 1) * 1.6)
    # A teal rim of light down the cowl's edges.
    rim = np.clip(1.0 - np.abs(np.abs(x) - half) / 1.6, 0.0, 1.0) * (y > -30) * (y < 30)
    rgb = blend(rgb, (110, 220, 200), rim * 0.65)
    # The face: a black hollow, and two eyes.
    face = np.exp(-((x / 9.5) ** 2 + ((y + 1.0) / 12.0) ** 2) ** 2)
    rgb = blend(rgb, (2, 2, 4), np.clip(face * 1.5, 0, 1))
    for ex in (-4.5, 4.5):
        eye = np.exp(-((x - ex) ** 2 + ((y + 3.0) * 1.6) ** 2) / 2.2)
        halo = np.exp(-((x - ex) ** 2 + (y + 3.0) ** 2) / 18.0)
        rgb = blend(rgb, (90, 255, 170), halo * 0.45)
        rgb = blend(rgb, (220, 255, 230), eye)
    rgb *= np.clip(1.3 - (r / 50.0) ** 2, 0.3, 1.0)[..., None]
    finish(rgb, "doom")


def blight():
    """A bronze bell split by a crack and eaten by green rot dripping from its lip, spores rising in a sickly glow."""
    x, y = grid()
    r = np.hypot(x, y)
    n = noise(11, 5)
    n2 = noise(13, 3)
    rgb = np.zeros((SIZE, SIZE, 3))
    rgb[:] = (14, 16, 8)
    rgb = blend(rgb, (110, 130, 40), np.exp(-(r / 30.0) ** 2) * (0.7 + 0.4 * n))
    # The bell: a dome flaring to a lip.
    t = np.clip((y + 26.0) / 46.0, 0.0, 1.0)
    half = 8.0 + 15.0 * t ** 2.0 + np.where(y > 16, 3.0, 0.0)
    bell = (np.abs(x) < half) & (y > -26) & (y < 22)
    top = np.exp(-((x / 8.5) ** 2 + ((y + 26) / 4.5) ** 2) ** 3) * (y <= -24)
    body = np.clip((half - np.abs(x)) / 1.5, 0.0, 1.0) * (y > -26) * (y < 22)
    body = np.maximum(body, np.clip(top * 2, 0, 1))
    # Bronze, lit from the left.
    u = np.clip((x / np.maximum(half, 1.0) + 1.0) * 0.5, 0.0, 1.0)
    lit = np.exp(-((u - 0.28) / 0.16) ** 2)
    bronze = np.stack([120 + 110 * lit, 80 + 80 * lit, 30 + 40 * lit], axis=-1) * (0.65 + 0.35 * (1 - u))[..., None]
    rgb = rgb * (1 - body[..., None]) + bronze * body[..., None]
    # The crown loop.
    loop = np.abs(np.hypot(x, (y + 31) * 1.2) - 5.0) < 1.6
    rgb = blend(rgb, (150, 110, 50), loop.astype(float) * (y < -26))
    # The lip's band and a dark mouth under it.
    rgb = blend(rgb, (70, 48, 20), (bell & (y > 15) & (y < 18)).astype(float))
    mouth = np.exp(-((x / 20.0) ** 2 + ((y - 22) / 2.5) ** 2) ** 2)
    rgb = blend(rgb, (8, 8, 4), mouth)
    # A jagged crack down from the shoulder.
    cx = 4.0 + 3.0 * np.sin(y * 0.55) + 2.0 * np.sign(np.sin(y * 1.3))
    crack = (np.abs(x - cx) < 0.9) & (y > -18) & (y < 17)
    rgb = blend(rgb, (10, 6, 2), crack.astype(float))
    # Rot: green creeping up from the lip, with drips below it.
    creep = np.clip((y - 2.0 + 14.0 * (n2 - 0.5)) / 14.0, 0.0, 1.0) * body
    rgb = blend(rgb, (60, 110, 30), creep * 0.85)
    rgb = blend(rgb, (150, 210, 70), np.clip(creep - 0.7, 0, 1) * 1.5 * (n2 > 0.55))
    rng = np.random.default_rng(3)
    for _ in range(7):
        dx = rng.uniform(-20, 20)
        ln = rng.uniform(4, 12)
        drip = (np.abs(x - dx) < 1.0) & (y > 20) & (y < 20 + ln)
        rgb = blend(rgb, (110, 170, 50), drip.astype(float))
        rgb = blend(rgb, (150, 210, 70), np.exp(-((x - dx) ** 2 + (y - 20 - ln) ** 2) / 2.0))
    # Spores.
    for _ in range(22):
        sx = rng.normal(0, 14)
        sy = rng.uniform(-38, 10)
        rad = rng.uniform(0.7, 1.6)
        glow = np.exp(-((x - sx) ** 2 + (y - sy) ** 2) / (rad * rad))
        rgb = blend(rgb, (200, 240, 110), glow * rng.uniform(0.5, 1.0))
    rgb *= np.clip(1.3 - (r / 50.0) ** 2, 0.3, 1.0)[..., None]
    finish(rgb, "blight")


def wisp():
    """A pale will-o'-wisp: a bright core in a soft green halo over a dark marsh, motes drifting up from it."""
    x, y = grid()
    r = np.hypot(x, y)
    n = noise(17, 6)
    rgb = np.zeros((SIZE, SIZE, 3))
    rgb[:] = (6, 14, 16)
    # Marsh mist low down, and reeds.
    rgb = blend(rgb, (18, 44, 44), np.clip((y + 6) / 40.0, 0, 1) * (0.6 + 0.4 * n))
    for k in range(-38, 40, 7):
        reed = (np.abs(x - k - 2 * np.sin(y * 0.2 + k)) < 0.8) & (y > 18 + (k * 7 % 9))
        rgb = blend(rgb, (8, 22, 18), reed.astype(float))
    cy = -4.0
    rc = np.hypot(x, (y - cy))
    rgb = blend(rgb, (40, 140, 120), np.exp(-(rc / 22.0) ** 2) * 0.8)
    rgb = blend(rgb, (150, 240, 210), np.exp(-(rc / 10.0) ** 2) * 0.9)
    rgb = blend(rgb, (240, 255, 248), np.exp(-(rc / 4.5) ** 2))
    # Its reflection on the water.
    rgb = blend(rgb, (90, 200, 180), np.exp(-((x / 6.0) ** 2 + ((y - 30) / 2.0) ** 2)) * 0.6)
    rng = np.random.default_rng(21)
    for _ in range(18):
        sx = rng.normal(0, 10)
        sy = rng.uniform(-36, 8)
        rad = rng.uniform(0.6, 1.4)
        rgb = blend(rgb, (200, 255, 230), np.exp(-((x - sx) ** 2 + (y - sy) ** 2) / (rad * rad)) * rng.uniform(0.5, 1.0))
    rgb *= np.clip(1.3 - (r / 50.0) ** 2, 0.3, 1.0)[..., None]
    finish(rgb, "wisp")


def thorns():
    """A wall of brambles: dark arching stems with pale thorns and red berries, against a dusk sky."""
    x, y = grid()
    r = np.hypot(x, y)
    rgb = np.zeros((SIZE, SIZE, 3))
    sky = np.clip((y + 42) / 84.0, 0, 1)[..., None]
    rgb[:] = 0
    rgb = rgb + np.array([70, 40, 70]) * (1 - sky) + np.array([150, 80, 50]) * sky
    rgb = blend(rgb, (20, 14, 22), np.clip((y - 18) / 6.0, 0, 1))
    rng = np.random.default_rng(31)
    stems = np.zeros((SIZE, SIZE))
    thorn_pts = []
    for k in range(11):
        x0 = rng.uniform(-44, 44)
        x1 = x0 + rng.uniform(-30, 30)
        h = rng.uniform(26, 46)
        w = rng.uniform(1.6, 2.6)
        for i in range(60):
            u = i / 59.0
            cx = x0 + (x1 - x0) * u
            cy = 30 - h * 4 * u * (1 - u)
            stems = np.maximum(stems, np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (w * w)))
            if i % 9 == 4:
                thorn_pts.append((cx, cy, 1 if k % 2 else -1))
    rgb = blend(rgb, (26, 30, 14), stems * 1.2)
    rgb = blend(rgb, (70, 84, 36), np.clip(stems - 0.75, 0, 1) * 2.5)
    for (cx, cy, sgn) in thorn_pts:
        t = np.exp(-(((x - cx - sgn * 2.0) ** 2) / 0.5 + ((y - cy + 1.2) ** 2) / 0.5))
        rgb = blend(rgb, (190, 170, 120), t * 0.8)
    for _ in range(9):
        bx, by = rng.uniform(-36, 36), rng.uniform(-14, 26)
        rgb = blend(rgb, (150, 20, 50), np.exp(-((x - bx) ** 2 + (y - by) ** 2) / 3.0))
    rgb *= np.clip(1.3 - (r / 52.0) ** 2, 0.35, 1.0)[..., None]
    finish(rgb, "thorns")


PAINTERS = {"doom": None, "blight": None, "wisp": wisp, "thorns": thorns}


if __name__ == "__main__":
    import sys
    PAINTERS["doom"] = doom
    PAINTERS["blight"] = blight
    for key in sys.argv[1:] or list(PAINTERS):
        PAINTERS[key]()
    print("wrote", os.path.abspath(OUT))
