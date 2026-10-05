"""The bell tower's waving flag: an idle strip (assets/pixellab/buildings/bell_tower/idle.png) of FRAMES copies of the
intact sprite where each column of the flag cloth moves up/down on a travelling wave. The wave grows with the
distance from the pole (the edge at the pole stays put), and whole columns move, so the cloth never tears.
Usage (from the project root): python tools/dev/ref_convert/bell_flag_wave.py
"""
import math
import numpy as np
from PIL import Image

D = "assets/pixellab/buildings/bell_tower/"
FRAMES = 6
POLE_X = 72                    # the pole's left column; the flag hangs to its left
FLAG = (52, 18, 71, 39)        # x0, y0, x1, y1 (inclusive) of the cloth, above the roof
AMP = 2.5                      # px at the free end
WAVELEN = 9.0                  # px of cloth per wave

base = np.array(Image.open(D + "intact.png").convert("RGBA"))
h, w = base.shape[:2]
x0, y0, x1, y1 = FLAG
cloth = np.zeros_like(base)
cloth[y0:y1 + 1, x0:x1 + 1] = base[y0:y1 + 1, x0:x1 + 1]
still = base.copy()
still[y0:y1 + 1, x0:x1 + 1] = 0
still[y0:y1 + 1, POLE_X:] = base[y0:y1 + 1, POLE_X:]          # keep the pole

strip = np.zeros((h, w * FRAMES, 4), np.uint8)
for f in range(FRAMES):
    frame = still.copy()
    phase = 2 * math.pi * f / FRAMES
    for x in range(x0, x1 + 1):
        u = POLE_X - x
        amp = AMP * min(1.0, u / 12.0)
        dy = int(round(amp * math.sin(phase + 2 * math.pi * u / WAVELEN)))
        col = cloth[y0:y1 + 1, x]
        for i in range(col.shape[0]):
            if col[i, 3] > 0:
                frame[y0 + i + dy, x] = col[i]
    strip[:, f * w:(f + 1) * w] = frame
Image.fromarray(strip, "RGBA").save(D + "idle.png")
print("idle strip", strip.shape[1], "x", strip.shape[0], "frames", FRAMES)
