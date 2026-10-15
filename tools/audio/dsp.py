"""Shared DSP for the audio tools: RBJ-cookbook biquads and an EQ chain, on mono or (frames, channels) arrays."""
from __future__ import annotations

import math

import numpy as np
from scipy import signal

SR = 44100


def biquad(kind: str, f0: float, gain_db: float = 0.0, q: float = 0.707) -> np.ndarray:
    """One RBJ-cookbook biquad as a second-order section: "peak", "highshelf", "lowshelf", "hp" or "lp"."""
    a_ = 10 ** (gain_db / 40.0)
    w0 = 2 * math.pi * f0 / SR
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2 * q)
    if kind == "peak":
        b = [1 + alpha * a_, -2 * cw, 1 - alpha * a_]
        a = [1 + alpha / a_, -2 * cw, 1 - alpha / a_]
    elif kind in ("highshelf", "lowshelf"):
        s = 1 if kind == "highshelf" else -1
        r = 2 * math.sqrt(a_) * alpha
        b = [a_ * ((a_ + 1) + s * (a_ - 1) * cw + r), -2 * s * a_ * ((a_ - 1) + s * (a_ + 1) * cw),
             a_ * ((a_ + 1) + s * (a_ - 1) * cw - r)]
        a = [(a_ + 1) - s * (a_ - 1) * cw + r, 2 * s * ((a_ - 1) - s * (a_ + 1) * cw), (a_ + 1) - s * (a_ - 1) * cw - r]
    elif kind == "hp":
        b = [(1 + cw) / 2, -(1 + cw), (1 + cw) / 2]
        a = [1 + alpha, -2 * cw, 1 - alpha]
    else:
        b = [(1 - cw) / 2, 1 - cw, (1 - cw) / 2]
        a = [1 + alpha, -2 * cw, 1 - alpha]
    return np.array([[b[0] / a[0], b[1] / a[0], b[2] / a[0], 1.0, a[1] / a[0], a[2] / a[0]]])


def eq(x: np.ndarray, bands: list) -> np.ndarray:
    """Run x (samples, or frames x channels) through bands: [kind, Hz, dB, Q] each (dB and Q may be left out)."""
    for band in bands:
        kind, f0 = band[0], float(band[1])
        g = float(band[2]) if len(band) > 2 else 0.0
        q = float(band[3]) if len(band) > 3 else 0.707
        x = signal.sosfilt(biquad(kind, f0, g, q), x, axis=0)
    return x
