"""Procedural SFX synthesizer for the sci-fi VFX proof.

Every cue is built from oscillators, filtered noise, envelopes, saturation and a
Schroeder reverb, with a fixed seed so output is deterministic.

Usage:
    python tools/audio/synth.py                 # generate all cues
    python tools/audio/synth.py --only nova_boom
    python tools/audio/synth.py --verify        # check generated files
    python tools/audio/synth.py --spectrograms OUT_DIR
"""
from __future__ import annotations

import argparse
import sys
import zlib
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
PEAK = 10 ** (-1.0 / 20.0)
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio"


# --------------------------------------------------------------------------
# DSP helpers
# --------------------------------------------------------------------------

def rng_for(name: str) -> np.random.Generator:
    return np.random.default_rng(zlib.crc32(name.encode()))


def times(dur: float) -> np.ndarray:
    return np.arange(int(round(dur * SR))) / SR


def ramp(start: float, end: float, n: int, curve: str = "lin") -> np.ndarray:
    k = np.linspace(0.0, 1.0, n)
    if curve == "exp":
        return start * (end / start) ** k
    return start + (end - start) * k


def phase(freq: np.ndarray | float, n: int) -> np.ndarray:
    f = np.broadcast_to(np.asarray(freq, dtype=np.float64), (n,))
    return 2.0 * np.pi * np.cumsum(f) / SR


def sine(freq, n):
    return np.sin(phase(freq, n))


def saw(freq, n):
    ph = phase(freq, n) / (2.0 * np.pi)
    return 2.0 * (ph - np.floor(ph + 0.5))


def square(freq, n, duty=0.5):
    ph = (phase(freq, n) / (2.0 * np.pi)) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def noise(n, rng):
    return rng.uniform(-1.0, 1.0, n)


def brown(n, rng):
    x = np.cumsum(rng.normal(0.0, 1.0, n))
    x = signal.sosfilt(signal.butter(1, 20, "highpass", fs=SR, output="sos"), x)
    return x / (np.max(np.abs(x)) + 1e-9)


def _sos(kind, freq, order=2):
    nyq = SR * 0.5 * 0.98
    if kind == "bandpass":
        lo, hi = freq
        return signal.butter(order, [max(lo, 20.0), min(hi, nyq)], "bandpass", fs=SR, output="sos")
    return signal.butter(order, min(max(freq, 20.0), nyq), kind, fs=SR, output="sos")


def lowpass(x, f, order=2):
    return signal.sosfilt(_sos("lowpass", f, order), x)


def highpass(x, f, order=2):
    return signal.sosfilt(_sos("highpass", f, order), x)


def bandpass(x, lo, hi, order=2):
    return signal.sosfilt(_sos("bandpass", (lo, hi), order), x)


def sweep_filter(x, kind, f_curve, q=0.25, blocks=96):
    """Time-varying filter: re-designed per block, state carried across blocks."""
    n = len(x)
    edges = np.linspace(0, n, blocks + 1).astype(int)
    out = np.zeros(n)
    zi = None
    for b in range(blocks):
        a, e = edges[b], edges[b + 1]
        if e <= a:
            continue
        f = float(f_curve[min((a + e) // 2, n - 1)])
        if kind == "bandpass":
            sos = _sos("bandpass", (f * (1 - q), f * (1 + q)))
        else:
            sos = _sos(kind, f)
        if zi is None:
            zi = np.zeros((sos.shape[0], 2))
        out[a:e], zi = signal.sosfilt(sos, x[a:e], zi=zi)
    return out


def decay(n, tau, delay=0.0):
    t = np.arange(n) / SR
    env = np.exp(-np.maximum(t - delay, 0.0) / tau)
    env[t < delay] = 1.0
    return env


def attack(n, seconds):
    k = int(seconds * SR)
    env = np.ones(n)
    if k > 0:
        env[:k] = np.linspace(0.0, 1.0, k)
    return env


def adsr(n, a, d, s, r):
    env = np.full(n, s)
    ai, di, ri = int(a * SR), int(d * SR), int(r * SR)
    env[:ai] = np.linspace(0, 1, ai)
    env[ai:ai + di] = np.linspace(1, s, len(env[ai:ai + di]))
    if ri > 0:
        env[-ri:] *= np.linspace(1, 0, ri)
    return env


def saturate(x, drive):
    return np.tanh(drive * x) / np.tanh(drive)


def reverb(x, size=1.0, feedback=0.78, mix=0.25, tail=0.0, damp=5000.0):
    """Schroeder reverb: 4 parallel combs + 2 series allpasses (via lfilter)."""
    if tail > 0:
        x = np.concatenate([x, np.zeros(int(tail * SR))])
    wet = np.zeros_like(x)
    for d in (1557, 1617, 1491, 1422):
        d = int(d * size)
        a = np.zeros(d + 1)
        a[0], a[-1] = 1.0, -feedback
        wet += signal.lfilter([1.0], a, x)
    wet /= 4.0
    for d, g in ((225, 0.5), (556, 0.5)):
        d = int(d * size)
        b = np.zeros(d + 1)
        a = np.zeros(d + 1)
        b[0], b[-1] = -g, 1.0
        a[0], a[-1] = 1.0, -g
        wet = signal.lfilter(b, a, wet)
    wet = lowpass(wet, damp)
    return x * (1.0 - mix) + wet * mix


def place(buf, x, at):
    i = int(at * SR)
    if i >= len(buf):
        return
    m = min(len(x), len(buf) - i)
    buf[i:i + m] += x[:m]


def fit(x, n):
    if len(x) >= n:
        return x[:n]
    return np.concatenate([x, np.zeros(n - len(x))])


def fade(x, ms=5.0):
    k = min(int(ms * SR / 1000), len(x) // 2)
    x = x.copy()
    x[:k] *= np.linspace(0, 1, k)
    x[-k:] *= np.linspace(1, 0, k)
    return x


def loopify(x, n, xfade_ms=60.0):
    """Take n samples and crossfade the overflow tail into the head for a seamless loop."""
    k = int(xfade_ms * SR / 1000)
    x = fit(x, n + k)
    y = x[:n].copy()
    w = np.linspace(0.0, 1.0, k)
    y[:k] = y[:k] * w + x[n:n + k] * (1.0 - w)
    return y


def normalize(x):
    peak = np.max(np.abs(x))
    return x * (PEAK / peak) if peak > 0 else x


def clicks(n, rate, rng, length_s=0.002, hp=2000.0, amp=(0.3, 1.0), density=None):
    """Random short pops. density: optional per-sample rate multiplier curve."""
    buf = np.zeros(n)
    count = int(rate * n / SR)
    pos = rng.integers(0, n, count * 2)
    if density is not None:
        keep = rng.uniform(0, 1, len(pos)) < density[pos]
        pos = pos[keep][:count]
    else:
        pos = pos[:count]
    k = max(int(length_s * SR), 4)
    shape = np.exp(-np.arange(k) / (k / 4.0)) * rng.choice([-1.0, 1.0], k)
    for p in pos:
        m = min(k, n - p)
        buf[p:p + m] += shape[:m] * rng.uniform(*amp)
    return highpass(buf, hp)


# --------------------------------------------------------------------------
# Cues
# --------------------------------------------------------------------------

def nova_alarm(rng, dur):
    n = int(dur * SR)
    buf = np.zeros(n)
    t, interval, i = 0.0, 0.26, 0
    while t < dur - 0.08:
        f = 880.0 if i % 2 == 0 else 660.0
        bn = int(0.075 * SR)
        tone = saw(f, bn) * 0.6 + square(f * 0.5, bn) * 0.3
        tone = lowpass(tone, 3500) * adsr(bn, 0.003, 0.02, 0.7, 0.02)
        place(buf, tone, t)
        t += interval
        interval = max(interval * 0.84, 0.085)
        i += 1
    return reverb(buf, size=0.6, mix=0.18)[:n]


def nova_lock(rng, dur):
    n = int(dur * SR)
    f = np.concatenate([ramp(600, 1800, int(n * 0.6), "exp"), np.full(n - int(n * 0.6), 1800.0)])
    x = sine(f, n) + 0.35 * sine(f * 2.0, n) + 0.15 * square(f, n)
    return lowpass(x, 6000) * adsr(n, 0.005, 0.05, 0.8, 0.06)


def nova_descent(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    f = ramp(2600, 420, n, "exp") * (1.0 + 0.012 * np.sin(2 * np.pi * 9 * t))
    whistle = sine(f, n) * 0.5 + 0.2 * sine(f * 1.5, n)
    air = sweep_filter(noise(n, rng), "bandpass", ramp(3000, 500, n, "exp"), q=0.5)
    env = ramp(0.15, 1.0, n) ** 2
    x = (whistle * 0.6 + air * 1.4) * env
    return fade(x, 3)


def nova_crack(rng, dur):
    n = int(dur * SR)
    burst = highpass(noise(n, rng), 1200) * decay(n, 0.025)
    click = np.zeros(n)
    click[:40] = np.linspace(1.0, 0.0, 40)
    crackle = clicks(n, 60, rng, 0.003, 1500, density=decay(n, 0.12)) * 0.6
    x = saturate(burst * 1.5 + click + crackle, 2.5)
    return reverb(x, size=0.8, mix=0.2)[:n]


def nova_boom(rng, dur):
    n = int(dur * SR)
    sub = sine(ramp(95, 28, n, "exp"), n) * decay(n, 0.9)
    body = sweep_filter(noise(n, rng), "lowpass", ramp(900, 70, n, "exp")) * decay(n, 0.7) * 2.5
    x = saturate(sub * 1.2 + body, 3.0) * attack(n, 0.004)
    return reverb(x, size=1.3, feedback=0.82, mix=0.22, damp=1800)[:n]


def nova_shockwave(rng, dur):
    n = int(dur * SR)
    x = sweep_filter(noise(n, rng), "bandpass", ramp(4000, 150, n, "exp"), q=0.6)
    env = attack(n, 0.03) * decay(n, 0.45)
    return reverb(x * env * 2.0, size=1.1, mix=0.3)[:n]


def nova_rumble(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    base = lowpass(brown(n, rng), 160, 4)
    mod = 0.7 + 0.3 * np.sin(2 * np.pi * 0.7 * t + 1.0) * np.sin(2 * np.pi * 0.23 * t)
    fade_out = np.linspace(1.0, 0.0, n) ** 1.5
    debris = clicks(n, 45, rng, 0.004, 1800, amp=(0.1, 0.6), density=np.linspace(1.0, 0.05, n)) * 0.5
    return (base * mod * 1.4 + debris) * fade_out * attack(n, 0.2)


def nova_geiger(rng, dur):
    n = int(dur * SR)
    extra = int(0.06 * SR)
    total = n + extra
    density = 0.35 + 0.65 * (np.abs(np.sin(np.linspace(0, 3 * np.pi, total))) > 0.5)
    tick = clicks(total, 16, rng, 0.0015, 2500, amp=(0.5, 1.0), density=density)
    hiss = highpass(noise(total, rng), 4000) * 0.04
    return loopify(tick + hiss, n)


def nova_swell(rng, dur):
    """Core gathering power: rising roar and sub pitch that slams into the blast."""
    n = int(dur * SR)
    roar = sweep_filter(noise(n, rng), "bandpass", ramp(150, 2200, n, "exp"), q=0.6)
    sub = sine(ramp(30, 90, n, "exp"), n) + 0.4 * saw(ramp(45, 120, n, "exp"), n)
    env = ramp(0.05, 1.0, n) ** 2.2
    x = saturate((roar * 1.4 + lowpass(sub, 400) * 0.9) * env, 2.0)
    return fade(x, 2)


def orb_target(rng, dur):
    n = int(dur * SR)
    buf = np.zeros(n)
    for i, at in enumerate((0.0, 0.14, 0.28, 0.42)):
        cn = int(0.06 * SR)
        chirp = sine(ramp(1100 + i * 120, 2300 + i * 120, cn, "exp"), cn) * adsr(cn, 0.002, 0.01, 0.8, 0.02)
        place(buf, chirp, at)
    for at in (0.6, 0.68):
        bn = int(0.05 * SR)
        place(buf, square(1760, bn, 0.3) * 0.4 * adsr(bn, 0.002, 0.01, 0.8, 0.01), at)
    return reverb(lowpass(buf, 7000), size=0.5, mix=0.2)[:n]


def orb_charge(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    f = ramp(280, 1700, n, "exp")
    trem = 0.75 + 0.25 * np.sin(phase(ramp(10, 40, n), n))
    x = sweep_filter(saw(f, n), "lowpass", ramp(800, 6000, n, "exp")) * trem
    x += sine(f * 2.0, n) * 0.25
    return x * ramp(0.2, 1.0, n) ** 1.5 * attack(n, 0.01)


def orb_hit(rng, dur, variant):
    n = int(dur * SR)
    j = rng.uniform(0.85, 1.15)
    zn = int(0.09 * SR)
    zap = sine(ramp(3200 * j, 180, zn, "exp"), zn) * decay(zn, 0.04)
    zap += highpass(noise(zn, rng), 3000) * decay(zn, 0.02) * 0.6
    thud = sine(ramp(80 * j, 38, n, "exp"), n) * decay(n, 0.18)
    boom = sweep_filter(noise(n, rng), "lowpass", ramp(2400 * j, 90, n, "exp")) * decay(n, 0.3) * 1.8
    debris = clicks(n, 30, rng, 0.003, 2000, amp=(0.1, 0.5), density=decay(n, 0.25)) * 0.4
    buf = thud * 1.2 + boom + debris
    place(buf, zap * 0.9, 0.0)
    x = saturate(buf, 2.2 + variant * 0.3)
    return reverb(x, size=0.9, mix=0.18, damp=3500)[:n]


def orb_embers(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    pops = clicks(total, 28, rng, 0.004, 900, amp=(0.1, 1.0))
    hiss = lowpass(highpass(noise(total, rng), 500), 3000) * 0.06
    return loopify(pops + hiss, n)


def grav_field(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    vib = 1.0 + ramp(0.0, 0.06, n) * np.sin(2 * np.pi * 7 * t)
    f = ramp(260, 110, n, "exp") * vib
    x = sine(f, n) + sine(f * 1.007, n) * 0.8 + saw(f * 0.5, n) * 0.2
    swell = sweep_filter(noise(n, rng), "bandpass", ramp(300, 1500, n, "exp"), q=0.4) * 0.6
    return reverb(lowpass(x, 2000) * adsr(n, 0.1, 0.2, 0.8, 0.25) + swell * ramp(0, 1, n), size=1.2, mix=0.3)[:n]


def grav_drone(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    lfo = 0.75 + 0.25 * np.sin(2 * np.pi * 0.5 * t)
    x = saw(55.0, total) + saw(55.5, total) + 0.6 * saw(82.5, total) + 0.8 * sine(27.5, total)
    x = lowpass(x, 320, 4) * lfo
    return loopify(x, n)


def grav_suction(rng, dur):
    n = int(dur * SR)
    # Build a decaying whoosh with reverb, then reverse it so it swells toward the core.
    whoosh = sweep_filter(noise(n, rng), "bandpass", ramp(2600, 180, n, "exp"), q=0.5) * decay(n, 0.7)
    wet = reverb(whoosh, size=1.4, feedback=0.84, mix=0.45)[:n]
    rising = sine(ramp(70, 320, n, "exp"), n) * ramp(0.0, 0.5, n) ** 2
    return fade(wet[::-1] * 1.4 + rising, 10)


def grav_compress(rng, dur):
    n = int(dur * SR)
    am = 0.5 + 0.5 * np.sin(phase(ramp(8, 45, n, "exp"), n))
    f = ramp(140, 420, n, "exp")
    x = (sine(f, n) + 0.5 * saw(f * 0.5, n)) * am
    flutter = bandpass(noise(n, rng), 300, 2000) * am * 0.5
    return lowpass(x + flutter, 3000) * ramp(0.4, 1.0, n) * attack(n, 0.01)


def grav_implode(rng, dur):
    n = int(dur * SR)
    buf = np.zeros(n)
    sn = int(0.12 * SR)
    snap = highpass(noise(sn, rng), 800) * decay(sn, 0.03)
    place(buf, snap[::-1] * 0.8, 0.0)
    bn = n - int(0.1 * SR)
    sub = sine(ramp(70, 24, bn, "exp"), bn) * decay(bn, 1.0)
    body = sweep_filter(noise(bn, rng), "lowpass", ramp(1500, 60, bn, "exp")) * decay(bn, 0.6) * 2.2
    place(buf, saturate(sub * 1.3 + body, 3.0) * attack(bn, 0.003), 0.1)
    return reverb(buf, size=1.5, feedback=0.84, mix=0.25, damp=2500)[:n]


def grav_arc(rng, dur):
    """Short electric crack for a lightning arc."""
    n = int(dur * SR)
    gate = (rng.uniform(0, 1, n // 120 + 1) > 0.45).repeat(120)[:n]
    buzz = highpass(saw(ramp(180, 90, n), n) + noise(n, rng) * 0.8, 1200) * gate
    snap = highpass(noise(n, rng), 3000) * decay(n, 0.008)
    return (buzz * decay(n, 0.05) + snap * 1.5) * attack(n, 0.001)


def grav_shimmer(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    x = np.zeros(n)
    for _ in range(9):
        f = rng.uniform(1800, 6500)
        am = 0.5 + 0.5 * np.sin(2 * np.pi * rng.uniform(1.5, 6.0) * t + rng.uniform(0, 6.28))
        x += sine(f, n) * am * rng.uniform(0.3, 1.0)
    air = bandpass(noise(n, rng), 5000, 11000) * 0.4
    x = (x / 9.0 + air) * decay(n, 0.8) * attack(n, 0.08)
    return reverb(x, size=1.3, feedback=0.85, mix=0.45)[:n]


def _chimes(n, rng, count, lo, hi, tau):
    x = np.zeros(n)
    for _ in range(count):
        f = rng.uniform(lo, hi)
        k = int(rng.uniform(0, 0.7) * n)
        m = n - k
        env = decay(m, tau * rng.uniform(0.6, 1.4)) * attack(m, 0.01)
        x[k:] += (sine(f, m) + 0.35 * sine(f * 2.76, m)) * env * rng.uniform(0.4, 1.0)
    return x


def glac_rune(rng, dur):
    """Frost rune forming: shimmering crystal chimes over a thin cold wind."""
    n = int(dur * SR)
    chimes = _chimes(n, rng, 14, 1800, 5200, 0.35)
    wind = sweep_filter(noise(n, rng), "bandpass", ramp(600, 1800, n, "exp"), q=0.4) * 0.35
    x = chimes * 0.5 + wind * ramp(0.2, 1.0, n)
    return reverb(x * attack(n, 0.15), size=1.3, feedback=0.84, mix=0.4)[:n]


def glac_erupt(rng, dur):
    """Ice spikes bursting: crystalline crunch, many cracks, deep thud."""
    n = int(dur * SR)
    thud = sine(ramp(90, 35, n, "exp"), n) * decay(n, 0.25)
    body = sweep_filter(noise(n, rng), "lowpass", ramp(2500, 120, n, "exp")) * decay(n, 0.35) * 1.4
    crunch = clicks(n, 260, rng, 0.004, 2500, amp=(0.2, 1.0), density=decay(n, 0.45)) * 0.9
    ping = _chimes(n, rng, 10, 2500, 7000, 0.12) * 0.35
    x = saturate(thud * 1.3 + body + crunch + ping, 2.2)
    return reverb(x, size=1.1, mix=0.25, damp=6000)[:n]


def glac_freeze(rng, dur):
    """Freeze wave: rushing air with crackling frost racing outward."""
    n = int(dur * SR)
    air = sweep_filter(noise(n, rng), "highpass", ramp(800, 4000, n, "exp")) * decay(n, 0.6) * 0.8
    crackle = clicks(n, 400, rng, 0.002, 3500, amp=(0.1, 0.8), density=np.sin(np.linspace(0, np.pi, n)) ** 0.6)
    x = air + crackle * 0.7
    return reverb(x * attack(n, 0.02), size=1.0, mix=0.25)[:n]


def glac_peak(rng, dur):
    """Crystal mountain peaks: resonant glassy chord and a deep boom."""
    n = int(dur * SR)
    chord = np.zeros(n)
    for f in (523.25, 659.25, 783.99, 1046.5, 1318.5):
        chord += (sine(f * rng.uniform(0.997, 1.003), n) + 0.3 * sine(f * 2.76, n)) * decay(n, 1.2)
    boom = saturate(sine(ramp(70, 28, n, "exp"), n) * decay(n, 0.7) * 1.4
                    + lowpass(noise(n, rng), 300) * decay(n, 0.4), 2.5)
    shimmer = highpass(noise(n, rng), 6000) * decay(n, 0.5) * 0.25
    x = chord * 0.22 + boom + shimmer
    return reverb(x * attack(n, 0.003), size=1.5, feedback=0.86, mix=0.35)[:n]


def glac_wind(rng, dur):
    """Cold wind loop."""
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 0.5 * t)
    wind = sweep_filter(noise(total, rng), "bandpass", 500 + 900 * lfo, q=0.35)
    whistle = sine(1400 + 300 * np.sin(2 * np.pi * 0.25 * t), total) * 0.04 * lfo
    return loopify(wind * (0.6 + 0.4 * lfo) + whistle, n)


def glac_shatter(rng, dur, variant):
    """Ice breaking like glass."""
    n = int(dur * SR)
    burst = highpass(noise(n, rng), 3000 + variant * 400) * decay(n, 0.03)
    pings = _chimes(n, rng, 8 + variant * 2, 2500, 8000, 0.06)
    tinkle = clicks(n, 120, rng, 0.002, 4000, amp=(0.1, 0.6), density=decay(n, 0.15))
    return (burst * 1.2 + pings * 0.5 + tinkle * 0.6) * attack(n, 0.001)


# --- Set2: shared building blocks ---------------------------------------------

def _boom(n, rng, f0=80.0, f1=28.0, tau=0.6, body=1.5, cutoff=1500.0, drive=2.5):
    sub = sine(ramp(f0, f1, n, "exp"), n) * decay(n, tau)
    rumble = sweep_filter(noise(n, rng), "lowpass", ramp(cutoff, 60, n, "exp")) * decay(n, tau * 0.7) * body
    return saturate(sub * 1.2 + rumble, drive) * attack(n, 0.003)


def _thunder_crack(n, rng):
    crack = highpass(noise(n, rng), 1500) * decay(n, 0.02) * 1.5
    tail = clicks(n, 300, rng, 0.003, 1200, amp=(0.2, 1.0), density=decay(n, 0.25)) * 0.8
    return crack + tail


def _crackle(n, rng, rate=40, hp=900):
    return clicks(n, rate, rng, 0.004, hp, amp=(0.1, 1.0))


def _whoosh(n, rng, f0, f1, q=0.5):
    return sweep_filter(noise(n, rng), "bandpass", ramp(f0, f1, n, "exp"), q=q)


# --- Heaven Splitter ------------------------------------------------------------

def hs_charge(rng, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    hum = sweep_filter(saw(ramp(60, 180, n, "exp"), n), "lowpass", ramp(300, 3000, n, "exp"))
    buzz = highpass(noise(n, rng), 3000) * (0.5 + 0.5 * np.sin(2 * np.pi * ramp(8, 40, n) * t)) * 0.25
    zaps = clicks(n, 50, rng, 0.006, 2000, amp=(0.2, 1.0), density=ramp(0.1, 1.0, n)) * 0.5
    return (hum * 0.6 + buzz + zaps) * ramp(0.1, 1.0, n) ** 1.5


def hs_strike(rng, dur):
    n = int(dur * SR)
    x = _thunder_crack(n, rng) + _boom(n, rng, 90, 30, 0.9, 2.0, 2500, 3.0)
    return reverb(x, size=1.5, feedback=0.85, mix=0.3, damp=4000)[:n]


def hs_fissure(rng, dur):
    n = int(dur * SR)
    grind = sweep_filter(noise(n, rng), "lowpass", ramp(900, 200, n, "exp")) * decay(n, 0.5) * 1.5
    cracks = clicks(n, 120, rng, 0.006, 400, amp=(0.2, 1.0), density=decay(n, 0.4))
    return saturate(grind + cracks + sine(ramp(60, 30, n, "exp"), n) * decay(n, 0.4), 2.0)


def hs_erupt(rng, dur):
    n = int(dur * SR)
    x = _thunder_crack(n, rng) * 0.8 + _boom(n, rng, 120, 50, 0.25, 0.8, 3000, 2.0) * 0.7
    return reverb(x, size=0.9, mix=0.2)[:n]


def hs_static(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    gate = (rng.uniform(0, 1, total // 300 + 1) > 0.7).repeat(300)[:total]
    x = highpass(noise(total, rng), 2500) * gate * 0.6 + clicks(total, 40, rng, 0.002, 3000) * 0.5
    return loopify(x, n)


def hs_rumble(rng, dur):
    n = int(dur * SR)
    return lowpass(brown(n, rng), 140, 4) * np.linspace(1.0, 0.0, n) ** 1.3 * attack(n, 0.1) * 1.5


# --- Cinderfall Barrage ---------------------------------------------------------------

def cf_rumble(rng, dur):
    n = int(dur * SR)
    return lowpass(brown(n, rng), 120, 4) * ramp(0.3, 1.0, n) * attack(n, 0.2) * 1.6


def cf_rise(rng, dur):
    n = int(dur * SR)
    grind = sweep_filter(noise(n, rng), "lowpass", ramp(300, 1200, n, "exp")) * 1.4
    cracks = clicks(n, 80, rng, 0.008, 300, amp=(0.2, 1.0))
    sub = sine(ramp(35, 70, n, "exp"), n) * 0.8
    return saturate((grind + cracks + sub) * adsr(n, 0.1, 0.2, 0.8, 0.4), 2.0)


def cf_erupt(rng, dur):
    n = int(dur * SR)
    blast = _boom(n, rng, 70, 25, 0.9, 2.0, 1200, 3.0)
    hiss = _whoosh(n, rng, 800, 3000, 0.6) * decay(n, 0.8) * 0.8
    return reverb(blast + hiss + _crackle(n, rng, 60) * decay(n, 1.0) * 0.6, size=1.3, mix=0.25, damp=2500)[:n]


def cf_lava(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    bubble = np.zeros(total)
    for k in range(10):
        pos = int(rng.uniform(0, total - 4000))
        m = 4000
        bubble[pos:pos + m] += sine(ramp(rng.uniform(80, 160), rng.uniform(200, 400), m, "exp"), m) * decay(m, 0.03) * 0.5
    roar = lowpass(noise(total, rng), 400) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.8 * t))
    return loopify(roar + bubble + _crackle(total, rng, 20) * 0.5, n)


def cf_fall(rng, dur):
    n = int(dur * SR)
    return _whoosh(n, rng, 3000, 500, 0.5) * ramp(0.1, 1.0, n) ** 2 * 1.4


def cf_impact(rng, dur):
    n = int(dur * SR)
    return reverb(_boom(n, rng, 110, 40, 0.3, 1.3, 2000, 2.5) + _crackle(n, rng, 80) * decay(n, 0.4) * 0.6,
                  size=0.9, mix=0.18)[:n]


# --- Tsunami Breaker ----------------------------------------------------------------

def ts_surge(rng, dur):
    n = int(dur * SR)
    return _whoosh(n, rng, 200, 1200, 0.8) * ramp(0.1, 1.0, n) ** 1.5 * 1.3


def ts_rise(rng, dur):
    n = int(dur * SR)
    water = lowpass(noise(n, rng), 1500) * adsr(n, 0.2, 0.3, 0.8, 0.3)
    swell = sine(ramp(40, 90, n, "exp"), n) * adsr(n, 0.3, 0.2, 0.7, 0.3) * 0.8
    return reverb(water + swell, size=1.2, mix=0.3)[:n]


def ts_roar(rng, dur):
    n = int(dur * SR)
    t = times(dur)
    surf = bandpass(noise(n, rng), 150, 2500) * (0.75 + 0.25 * np.sin(2 * np.pi * 1.7 * t))
    low = lowpass(brown(n, rng), 200) * 1.2
    fizz = highpass(noise(n, rng), 5000) * 0.15
    return (surf + low + fizz) * adsr(n, 0.05, 0.2, 0.9, 0.3)


def ts_crash(rng, dur):
    n = int(dur * SR)
    splash = highpass(noise(n, rng), 600) * decay(n, 0.35) * 1.6
    boom = _boom(n, rng, 70, 30, 0.6, 1.5, 1000, 2.5)
    return reverb(splash + boom, size=1.4, feedback=0.84, mix=0.3)[:n]


def ts_drip(rng, dur):
    n = int(dur * SR)
    x = np.zeros(n)
    for k in range(28):
        pos = int(rng.uniform(0, n - 3000))
        m = 3000
        x[pos:pos + m] += sine(ramp(rng.uniform(900, 1600), rng.uniform(1800, 3000), m, "exp"), m) * decay(m, 0.012) * rng.uniform(0.3, 1.0)
    trickle = bandpass(noise(n, rng), 1500, 5000) * 0.1 * np.linspace(1.0, 0.3, n)
    return reverb(x + trickle, size=1.1, mix=0.3)[:n]


# --- Tornado Tempest ----------------------------------------------------------------

def tn_gust(rng, dur):
    n = int(dur * SR)
    return _whoosh(n, rng, 300, 1400, 0.6) * np.sin(np.linspace(0, np.pi, n)) ** 1.5 * 1.3


def tn_form(rng, dur):
    n = int(dur * SR)
    swirl = sweep_filter(noise(n, rng), "bandpass", 400 + 300 * np.sin(np.linspace(0, 14, n)) + ramp(0, 800, n), q=0.4)
    low = lowpass(brown(n, rng), 180) * 1.2
    return (swirl * 1.2 + low) * adsr(n, 0.3, 0.2, 0.9, 0.3)


def tn_wind(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    lfo = 0.5 + 0.5 * np.sin(2 * np.pi * 1.0 * t)
    howl = sweep_filter(noise(total, rng), "bandpass", 300 + 700 * lfo, q=0.3)
    low = lowpass(brown(total, rng), 150) * 1.4
    debris = clicks(total, 25, rng, 0.006, 600, amp=(0.1, 0.6)) * 0.5
    return loopify(howl * (0.7 + 0.3 * lfo) + low + debris, n)


def tn_dissipate(rng, dur):
    n = int(dur * SR)
    fall = _whoosh(n, rng, 1400, 200, 0.5) * decay(n, 0.6) * 1.3
    thuds = clicks(n, 30, rng, 0.02, 80, amp=(0.2, 1.0), density=decay(n, 0.8)) * 0.8
    return reverb(fall + thuds, size=1.0, mix=0.25)[:n]


# --- Judgement of the Ancients -----------------------------------------------------------

def jg_rumble(rng, dur):
    n = int(dur * SR)
    choir = sum(sine(f, n) for f in (110.0, 164.8, 220.0)) * 0.12 * ramp(0.0, 1.0, n)
    return (lowpass(brown(n, rng), 130, 4) * 1.5 + choir) * attack(n, 0.3)


def jg_hands(rng, dur):
    n = int(dur * SR)
    return reverb(_boom(n, rng, 90, 35, 0.4, 1.4, 900, 2.5) + clicks(n, 100, rng, 0.01, 200, density=decay(n, 0.5)) * 0.7,
                  size=1.1, mix=0.22)[:n]


def jg_rise(rng, dur):
    n = int(dur * SR)
    grind = sweep_filter(noise(n, rng), "lowpass", ramp(200, 900, n, "exp")) * 1.5
    chord = sum(sine(f, n) for f in (130.8, 196.0, 261.6)) * 0.15 * adsr(n, 0.4, 0.3, 0.8, 0.5)
    return saturate((grind + chord + clicks(n, 60, rng, 0.01, 200) * 0.6) * adsr(n, 0.1, 0.2, 0.9, 0.3), 2.0)


def jg_punch(rng, dur, variant):
    n = int(dur * SR)
    x = _boom(n, rng, 100 + variant * 10, 40, 0.28, 1.4, 1400, 3.0)
    x += clicks(n, 90, rng, 0.008, 300, amp=(0.2, 1.0), density=decay(n, 0.2)) * 0.7
    return reverb(x, size=1.0, mix=0.2)[:n]


def jg_windup(rng, dur):
    n = int(dur * SR)
    rise = sweep_filter(noise(n, rng), "bandpass", ramp(200, 2000, n, "exp"), q=0.5) * ramp(0.1, 1.0, n) ** 2
    tone = sine(ramp(110, 440, n, "exp"), n) * ramp(0.0, 0.5, n) ** 2
    return (rise * 1.2 + tone) * attack(n, 0.05)


def jg_slam(rng, dur):
    n = int(dur * SR)
    x = _boom(n, rng, 70, 22, 1.1, 2.4, 1500, 3.5) + clicks(n, 150, rng, 0.01, 250, density=decay(n, 0.6)) * 0.9
    return reverb(x, size=1.6, feedback=0.86, mix=0.3, damp=2500)[:n]


def jg_crumble(rng, dur):
    n = int(dur * SR)
    rocks = clicks(n, 70, rng, 0.02, 120, amp=(0.2, 1.0), density=np.linspace(1.0, 0.1, n)) * 1.2
    slide = lowpass(noise(n, rng), 500) * np.linspace(1.0, 0.0, n) * 0.8
    return reverb(rocks + slide, size=1.1, mix=0.25)[:n]


# --- Dragonfire Parade ----------------------------------------------------------------

def dr_rumble(rng, dur):
    n = int(dur * SR)
    return (lowpass(brown(n, rng), 140, 4) * 1.4 + _crackle(n, rng, 15, 700) * 0.3) * ramp(0.3, 1.0, n) * attack(n, 0.2)


def dr_erupt(rng, dur):
    n = int(dur * SR)
    return reverb(_boom(n, rng, 80, 28, 0.7, 1.8, 1500, 3.0) + _whoosh(n, rng, 600, 2500) * decay(n, 0.5) * 0.7,
                  size=1.2, mix=0.25)[:n]


def dr_roar(rng, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = ramp(95, 70, n, "exp") * (1.0 + 0.04 * np.sin(2 * np.pi * 7 * t))
    growl = saw(f, n) + 0.7 * saw(f * 1.51, n) + 0.5 * square(f * 0.5, n)
    growl = sweep_filter(growl, "lowpass", ramp(1800, 700, n, "exp")) * (0.8 + 0.2 * np.sin(2 * np.pi * 23 * t))
    breath = bandpass(noise(n, rng), 300, 2500) * 0.6
    x = saturate((growl * 0.7 + breath) * adsr(n, 0.15, 0.3, 0.85, 0.6), 2.5)
    return reverb(x, size=1.5, feedback=0.85, mix=0.3)[:n]


def dr_inhale(rng, dur):
    n = int(dur * SR)
    return _whoosh(n, rng, 2000, 400, 0.5)[::-1] * ramp(0.2, 1.0, n) * 1.3


def dr_ignite(rng, dur):
    n = int(dur * SR)
    whump = sine(ramp(160, 50, n, "exp"), n) * decay(n, 0.15) * 1.2
    flare = highpass(noise(n, rng), 1200) * decay(n, 0.25)
    return saturate(whump + flare, 2.0) * attack(n, 0.004)


def dr_breath(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    roar = bandpass(noise(total, rng), 150, 3000) * (0.8 + 0.2 * np.sin(2 * np.pi * 3 * t))
    low = lowpass(brown(total, rng), 220) * 1.2
    return loopify(roar + low + _crackle(total, rng, 60, 1500) * 0.5, n)


def dr_sink(rng, dur):
    n = int(dur * SR)
    fall = sweep_filter(noise(n, rng), "lowpass", ramp(2000, 200, n, "exp")) * decay(n, 0.7) * 1.3
    hiss = highpass(noise(n, rng), 3000) * decay(n, 0.5) * 0.4
    return reverb(fall + hiss + _crackle(n, rng, 40) * decay(n, 0.8) * 0.5, size=1.2, mix=0.25)[:n]


def laser_scan(rng, dur):
    n = int(dur * SR)
    tri = 1.0 - np.abs(np.linspace(-1, 1, n))
    x = sweep_filter(saw(120, n) + 0.5 * saw(180, n), "bandpass", 400 * (8 ** tri), q=0.35)
    buf = x * adsr(n, 0.05, 0.1, 0.8, 0.15)
    bn = int(0.04 * SR)
    for at in (0.0, 0.08):
        place(buf, sine(2000, bn) * 0.5 * adsr(bn, 0.002, 0.01, 0.7, 0.01), at)
    return buf


def laser_thrusters(rng, dur):
    n = int(dur * SR)
    jet = sweep_filter(noise(n, rng), "bandpass", ramp(1600, 700, n, "exp"), q=0.5)
    rumble = lowpass(noise(n, rng), 200) * 1.5
    x = (jet + rumble) * adsr(n, 0.05, 0.1, 0.8, 0.12)
    cn = int(0.12 * SR)
    clunk = sum(sine(f, cn) * decay(cn, 0.03 + i * 0.01) for i, f in enumerate((320.0, 587.0, 911.0)))
    place(x, clunk * 0.8, 0.46)
    return x


def laser_ignite(rng, dur):
    n = int(dur * SR)
    f = ramp(55, 110, n, "exp")
    cutoff = np.concatenate([ramp(200, 5000, int(n * 0.35), "exp"), ramp(5000, 1600, n - int(n * 0.35), "exp")])
    x = sweep_filter(saw(f, n) + saw(f * 1.01, n), "lowpass", cutoff)
    x += bandpass(noise(n, rng), 2000, 6000) * decay(n, 0.05) * 0.8
    return saturate(x * adsr(n, 0.005, 0.1, 0.7, 0.1), 1.8)


def laser_hum(rng, dur):
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    wob = 1.0 + 0.004 * np.sin(2 * np.pi * 4.0 * t)
    x = saw(100.0 * wob, total) + 0.6 * square(200.0, total, 0.4) + 0.3 * saw(300.0, total)
    buzz = highpass(noise(total, rng), 3000) * (0.6 + 0.4 * np.sin(2 * np.pi * 100 * t)) * 0.15
    return loopify(lowpass(x, 2800) + buzz, n)


def laser_sizzle(rng, dur, variant):
    n = int(dur * SR)
    gate = (rng.uniform(0, 1, n // 200 + 1) > 0.35).repeat(200)[:n]
    fizz = highpass(noise(n, rng), 2800 + variant * 500) * gate
    zap = sine(ramp(1400 - variant * 150, 280, n, "exp"), n) * decay(n, 0.05) * 0.6
    return (fizz * decay(n, 0.09) + zap) * attack(n, 0.002)


def laser_fire(rng, dur):
    """Molten ground burning: low roar with crackles, loopable."""
    n = int(dur * SR)
    total = n + int(0.06 * SR)
    t = np.arange(total) / SR
    roar = lowpass(bandpass(noise(total, rng), 120, 900), 700) * (0.8 + 0.2 * np.sin(2 * np.pi * 1.5 * t))
    pops = clicks(total, 22, rng, 0.005, 700, amp=(0.2, 0.9))
    hiss = highpass(noise(total, rng), 4000) * 0.05
    return loopify(roar * 1.2 + pops * 0.7 + hiss, n)


def laser_powerdown(rng, dur):
    n = int(dur * SR)
    f = ramp(220, 28, n, "exp")
    x = sweep_filter(saw(f, n) + 0.5 * square(f * 0.5, n), "lowpass", ramp(3500, 150, n, "exp"))
    return x * ramp(1.0, 0.0, n) ** 1.3 * attack(n, 0.005)


def laser_depart(rng, dur):
    n = int(dur * SR)
    jet = sweep_filter(noise(n, rng), "bandpass", ramp(600, 2600, n, "exp"), q=0.4)
    whine = sine(ramp(500, 1400, n, "exp"), n) * 0.2
    env = np.sin(np.linspace(0, np.pi, n)) ** 1.5 * np.linspace(1.0, 0.5, n)
    return (jet * 1.5 + whine) * env


# --------------------------------------------------------------------------
# Interface (KAK milestone 5): short, dry, and plainly not part of the world.
# --------------------------------------------------------------------------

def ui_hover(rng, dur):
    n = int(round(dur * SR))
    return sine(1800.0, n) * decay(n, 0.012) * attack(n, 0.002) * 0.5


def ui_click(rng, dur):
    n = int(round(dur * SR))
    body = sine(ramp(900.0, 520.0, n, "exp"), n) * decay(n, 0.03)
    tick = highpass(noise(n, rng), 3000.0) * decay(n, 0.004)
    return (body + tick * 0.4) * attack(n, 0.001)


def ui_focus(rng, dur):
    n = int(round(dur * SR))
    tone = sine(ramp(700.0, 1400.0, n, "exp"), n) + 0.3 * sine(ramp(1400.0, 2800.0, n, "exp"), n)
    return tone * adsr(n, 0.004, 0.03, 0.4, 0.04)


def ui_buzz(rng, dur):
    n = int(round(dur * SR))
    tone = lowpass(square(110.0, n, 0.3) + 0.5 * square(116.0, n, 0.3), 1800.0)
    return saturate(tone * 0.6, 2.0) * adsr(n, 0.005, 0.05, 0.7, 0.06)


def ui_pause(rng, dur):
    n = int(round(dur * SR))
    out = sine(660.0, n) * decay(n, 0.05)
    place(out, sine(440.0, n) * decay(n, 0.06), 0.07)
    return out * attack(n, 0.002)


def ui_manifest(rng, dur):
    n = int(round(dur * SR))
    rise = ramp(0.0, 1.0, n) ** 2
    drift = ramp(0.98, 1.0, n)
    chord = sum(saw(f * drift, n) for f in (110.0, 164.8, 220.0, 329.6))
    chord = sweep_filter(chord, "lowpass", ramp(300.0, 4000.0, n, "exp"))
    hit = int(dur * 0.55 * SR)
    boom = np.zeros(n)
    boom[hit:] = sine(ramp(90.0, 40.0, n - hit, "exp"), n - hit) * decay(n - hit, 0.35)
    return reverb(chord * rise * 0.25 + boom * 0.8, size=1.2, mix=0.3)


def ui_win(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n)
    for i, f in enumerate((261.6, 329.6, 392.0, 523.3)):
        m = int(0.9 * SR)
        note = lowpass(saw(f, m) * 0.5 + sine(f * 2.0, m) * 0.3, 2600.0) * adsr(m, 0.01, 0.1, 0.6, 0.3)
        place(out, note, 0.13 * i)
    m = n - int(0.55 * SR)
    chord = lowpass(sum(saw(f, m) for f in (261.6, 329.6, 392.0, 523.3)) * 0.18, 3000.0)
    place(out, chord * adsr(m, 0.02, 0.3, 0.5, 0.8), 0.55)
    return reverb(out, size=1.3, mix=0.28)


def ui_lose(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n)
    for i, f in enumerate((392.0, 349.2, 311.1, 261.6)):
        m = int(0.7 * SR)
        note = lowpass(saw(f, m) * 0.5 + sine(f * 0.5, m) * 0.4, 1600.0) * adsr(m, 0.01, 0.12, 0.5, 0.35)
        place(out, note, 0.3 * i)
    return reverb(out, size=1.4, mix=0.32)


# --------------------------------------------------------------------------
# The crowd (KAK milestone 5): crude voices -- a buzzy source through a few vowel formants. Stylized on
# purpose: heard in a crowd under a volcano, they need to read as people, not to fool anyone.
# --------------------------------------------------------------------------

VOWELS = (
    ((800.0, 1.0), (1150.0, 0.7), (2800.0, 0.3)),   # ah
    ((400.0, 1.0), (2000.0, 0.6), (2800.0, 0.3)),   # eh
    ((700.0, 1.0), (1800.0, 0.6), (2600.0, 0.3)),   # ae
    ((500.0, 1.0), (900.0, 0.7), (2500.0, 0.25)),   # oh
)


def _voice(rng, n, f0, vowel, breath=0.15):
    src = saw(f0, n) + 0.3 * square(f0, n, 0.2)
    out = np.zeros(n)
    for fc, gain in vowel:
        out += bandpass(src, fc * 0.85, fc * 1.15) * gain
    return out + bandpass(noise(n, rng), 1500.0, 5000.0) * breath


def cit_yelp(rng, dur, v):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    base = (380.0, 460.0, 330.0, 520.0)[v - 1]
    f0 = base * (1.0 + 0.55 * np.sin(np.pi * np.minimum(k * 1.4, 1.0)))
    f0 = f0 * (1.0 + 0.03 * np.sin(2.0 * np.pi * 7.0 * k * dur))
    return saturate(_voice(rng, n, f0, VOWELS[v - 1]) * adsr(n, 0.02, 0.1, 0.7, 0.18), 1.5)


def cit_shout(rng, dur, v):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    f0 = (210.0, 260.0, 180.0)[v - 1] * (1.15 - 0.25 * k)
    return saturate(_voice(rng, n, f0, VOWELS[v % 4], breath=0.25) * adsr(n, 0.01, 0.08, 0.8, 0.2), 2.0)


def sol_rally(rng, dur):
    n = int(round(dur * SR))
    k = np.linspace(0.0, 1.0, n)
    f0 = 146.8 * (1.0 + 0.06 * np.minimum(k * 6.0, 1.0)) * (1.0 + 0.008 * np.sin(2.0 * np.pi * 5.0 * k * dur))
    horn = saw(f0, n) + 0.5 * saw(f0 * 2.0, n) + 0.25 * saw(f0 * 3.0, n)
    horn = lowpass(horn, 1400.0) * adsr(n, 0.12, 0.2, 0.8, 0.45)
    return reverb(saturate(horn * 0.5, 1.5), size=1.4, mix=0.3)


def crowd_panic(rng, dur):
    """A town running for its life: a formant-shaped murmur and dozens of voices crying out across the loop."""
    n = int(round(dur * SR))
    total = n + int(0.06 * SR)                   # loopify's crossfade takes the overflow
    out = np.zeros(total)
    murmur = brown(total, rng)
    for fc, gain in VOWELS[0]:
        out += bandpass(murmur, fc * 0.8, fc * 1.2) * gain * 0.35
    for _ in range(38):
        m = int(rng.uniform(0.25, 0.55) * SR)
        k = np.linspace(0.0, 1.0, m)
        f0 = rng.uniform(260.0, 560.0) * (1.0 + 0.4 * np.sin(np.pi * np.minimum(k * 1.3, 1.0)))
        voice = _voice(rng, m, f0, VOWELS[int(rng.integers(0, 4))], breath=0.2) * adsr(m, 0.02, 0.08, 0.6, 0.12)
        place(out, voice * rng.uniform(0.15, 0.45), rng.uniform(0.0, dur))
    return loopify(reverb(out, size=1.6, mix=0.35), n)


# --------------------------------------------------------------------------
# Music (KAK milestone 6), synthesized like everything else. A brooding theme for the title and the draft; a battle
# loop in three stems -- base, drums, lead -- that the game layers in as the city falls. All loops, all built with
# loopify, so they pass verify()'s seam check.
# --------------------------------------------------------------------------

def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


BEAT = 0.5                                   # 120 bpm
BAR = BEAT * 4.0
BATTLE_BARS = 8
# Two bars each: D minor, B flat, C, and A -- the dominant that pulls the loop back to its start.
BATTLE_CHORDS = ((38, 41, 45), (34, 38, 41), (36, 40, 43), (33, 37, 40))
THEME_CHORDS = ((50, 53, 57), (46, 50, 53), (41, 45, 48), (48, 52, 55))
# (midi, beats) at 60 bpm: 24 beats, the whole 24 s loop.
THEME_MELODY = ((74, 2), (72, 1), (69, 3), (70, 2), (69, 1), (65, 3),
                (69, 2), (67, 1), (65, 3), (64, 2), (65, 1), (62, 3))


def _note(freq, m, cutoff, a, d, s, r):
    return lowpass(saw(freq, m), cutoff) * adsr(m, a, d, s, r)


def music_theme(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    seg = dur / len(THEME_CHORDS)
    for i in range(len(THEME_CHORDS) + 1):   # one extra chord feeds the loop's crossfade
        chord = THEME_CHORDS[i % len(THEME_CHORDS)]
        m = int(seg * 1.15 * SR)
        pad = sum(lowpass(saw(hz(p), m) + saw(hz(p) * 1.004, m), 900.0) for p in chord)
        place(out, pad * adsr(m, 1.2, 0.5, 0.7, 1.5) * 0.12, i * seg)
        place(out, sine(hz(chord[0] - 12), m) * adsr(m, 0.6, 0.4, 0.8, 1.2) * 0.35, i * seg)
    at = 0.0
    for midi, beats in THEME_MELODY:
        m = int(beats * SR)
        vib = hz(midi) * (1.0 + 0.006 * np.sin(2.0 * np.pi * 5.0 * np.arange(m) / SR))
        place(out, (sine(vib, m) + 0.3 * sine(vib * 2.0, m)) * adsr(m, 0.08, 0.3, 0.6, 0.4) * 0.28, at)
        at += beats
    return loopify(reverb(out, size=1.8, mix=0.4), n)


def music_battle_base(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    step = BEAT / 2.0                        # eighth notes
    pattern = (0, 0, 0, 2, 0, 0, 1, 0)       # root, root, root, fifth, root, root, third, root
    for bar in range(BATTLE_BARS + 1):
        chord = BATTLE_CHORDS[(bar // 2) % len(BATTLE_CHORDS)]
        for i, idx in enumerate(pattern):
            m = int(step * 0.9 * SR)
            place(out, _note(hz(chord[idx] - 12), m, 700.0, 0.005, 0.05, 0.5, 0.05) * 0.5, bar * BAR + i * step)
        if bar % 2 == 0:
            m = int(BAR * 2.0 * SR)
            root = hz(chord[0] - 12)
            drone = lowpass(saw(root, m) + saw(root * 1.005, m), 300.0) * adsr(m, 0.2, 0.3, 0.8, 0.3)
            place(out, drone * 0.3, bar * BAR)
    return loopify(out, n)


def _taiko(rng, m, pitch):
    body = sine(ramp(pitch * 1.8, pitch, m, "exp"), m) * decay(m, 0.18)
    skin = lowpass(noise(m, rng), 900.0) * decay(m, 0.03)
    return saturate(body + skin * 0.5, 1.5)


def _snare(rng, m):
    return bandpass(noise(m, rng), 1500.0, 6000.0) * decay(m, 0.07) + sine(190.0, m) * decay(m, 0.04) * 0.4


def music_battle_drums(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    for bar in range(BATTLE_BARS + 1):
        start = bar * BAR
        for beat in (0.0, 1.5, 2.0):         # taiko on 1, the and of 2, and 3
            place(out, _taiko(rng, int(0.5 * SR), 62.0) * 0.9, start + beat * BEAT)
        for beat in (1.0, 3.0):              # snare on 2 and 4
            place(out, _snare(rng, int(0.25 * SR)) * 0.5, start + beat * BEAT)
        if bar % 4 == 3:                     # a roll into the end of every fourth bar
            for i in range(4):
                place(out, _taiko(rng, int(0.3 * SR), 90.0) * 0.5, start + (3.0 + i * 0.25) * BEAT)
    return loopify(reverb(out, size=1.1, mix=0.18), n)


def music_battle_lead(rng, dur):
    n = int(round(dur * SR))
    out = np.zeros(n + int(0.06 * SR))
    for bar in range(BATTLE_BARS + 1):
        chord = BATTLE_CHORDS[(bar // 2) % len(BATTLE_CHORDS)]
        for beat, length in ((0.0, 1.2), (1.5, 0.4), (2.0, 1.8)):
            m = int(length * BEAT * SR)
            stab = sum(_note(hz(p + 12), m, 1800.0, 0.02, 0.15, 0.5, 0.15) for p in chord)
            place(out, stab * 0.25, bar * BAR + beat * BEAT)
    return loopify(reverb(out, size=1.3, mix=0.25), n)


# id: (effect folder, builder, length seconds, loop)
CUES: dict[str, tuple] = {
    "nova_alarm": ("nova", nova_alarm, 1.5, False),
    "nova_lock": ("nova", nova_lock, 0.3, False),
    "nova_descent": ("nova", nova_descent, 0.8, False),
    "nova_crack": ("nova", nova_crack, 0.4, False),
    "nova_boom": ("nova", nova_boom, 3.0, False),
    "nova_shockwave": ("nova", nova_shockwave, 1.2, False),
    "nova_rumble": ("nova", nova_rumble, 5.0, False),
    "nova_swell": ("nova", nova_swell, 0.6, False),
    "nova_geiger": ("nova", nova_geiger, 2.0, True),
    "orb_target": ("orbital", orb_target, 0.8, False),
    "orb_charge": ("orbital", orb_charge, 0.4, False),
    "orb_embers": ("orbital", orb_embers, 2.0, True),
    "grav_field": ("gravity", grav_field, 0.8, False),
    "grav_drone": ("gravity", grav_drone, 2.0, True),
    "grav_suction": ("gravity", grav_suction, 2.7, False),
    "grav_compress": ("gravity", grav_compress, 0.6, False),
    "grav_implode": ("gravity", grav_implode, 2.5, False),
    "grav_shimmer": ("gravity", grav_shimmer, 2.4, False),
    "grav_arc": ("gravity", grav_arc, 0.15, False),
    "laser_scan": ("laser", laser_scan, 1.0, False),
    "laser_thrusters": ("laser", laser_thrusters, 0.6, False),
    "laser_ignite": ("laser", laser_ignite, 0.4, False),
    "laser_hum": ("laser", laser_hum, 1.0, True),
    "laser_fire": ("laser", laser_fire, 2.0, True),
    "laser_powerdown": ("laser", laser_powerdown, 0.8, False),
    "laser_depart": ("laser", laser_depart, 1.5, False),
    "glac_rune": ("glacial", glac_rune, 1.2, False),
    "glac_erupt": ("glacial", glac_erupt, 2.0, False),
    "glac_freeze": ("glacial", glac_freeze, 1.2, False),
    "glac_peak": ("glacial", glac_peak, 3.0, False),
    "glac_wind": ("glacial", glac_wind, 2.0, True),
    "hs_charge": ("heaven", hs_charge, 1.4, False),
    "hs_strike": ("heaven", hs_strike, 3.0, False),
    "hs_fissure": ("heaven", hs_fissure, 1.2, False),
    "hs_erupt": ("heaven", hs_erupt, 0.9, False),
    "hs_static": ("heaven", hs_static, 2.0, True),
    "hs_rumble": ("heaven", hs_rumble, 3.5, False),
    "cf_rumble": ("cinder", cf_rumble, 1.3, False),
    "cf_rise": ("cinder", cf_rise, 1.6, False),
    "cf_erupt": ("cinder", cf_erupt, 3.0, False),
    "cf_lava": ("cinder", cf_lava, 2.0, True),
    "cf_fall": ("cinder", cf_fall, 0.5, False),
    "cf_impact": ("cinder", cf_impact, 1.2, False),
    "ts_surge": ("tsunami", ts_surge, 1.1, False),
    "ts_rise": ("tsunami", ts_rise, 1.4, False),
    "ts_roar": ("tsunami", ts_roar, 3.2, False),
    "ts_crash": ("tsunami", ts_crash, 3.0, False),
    "ts_drip": ("tsunami", ts_drip, 3.5, False),
    "tn_gust": ("tornado", tn_gust, 1.0, False),
    "tn_form": ("tornado", tn_form, 1.6, False),
    "tn_wind": ("tornado", tn_wind, 2.0, True),
    "tn_dissipate": ("tornado", tn_dissipate, 2.0, False),
    "jg_rumble": ("judgement", jg_rumble, 1.5, False),
    "jg_hands": ("judgement", jg_hands, 1.5, False),
    "jg_rise": ("judgement", jg_rise, 1.6, False),
    "jg_windup": ("judgement", jg_windup, 0.6, False),
    "jg_slam": ("judgement", jg_slam, 3.5, False),
    "jg_crumble": ("judgement", jg_crumble, 2.5, False),
    "dr_rumble": ("dragon", dr_rumble, 1.3, False),
    "dr_erupt": ("dragon", dr_erupt, 2.5, False),
    "dr_roar": ("dragon", dr_roar, 2.2, False),
    "dr_inhale": ("dragon", dr_inhale, 0.6, False),
    "dr_ignite": ("dragon", dr_ignite, 0.7, False),
    "dr_breath": ("dragon", dr_breath, 2.0, True),
    "dr_sink": ("dragon", dr_sink, 2.0, False),
}
for _v in range(1, 5):
    CUES[f"orb_hit_{_v}"] = ("orbital", lambda rng, dur, v=_v: orb_hit(rng, dur, v), 0.9, False)
for _v in range(1, 4):
    CUES[f"jg_punch_{_v}"] = ("judgement", lambda rng, dur, v=_v: jg_punch(rng, dur, v), 1.2, False)
for _v in range(1, 4):
    CUES[f"glac_shatter_{_v}"] = ("glacial", lambda rng, dur, v=_v: glac_shatter(rng, dur, v), 0.5, False)
for _v in range(1, 4):
    CUES[f"laser_sizzle_{_v}"] = ("laser", lambda rng, dur, v=_v: laser_sizzle(rng, dur, v), 0.3, False)
for _name, _fn, _dur in (
    ("ui_hover", ui_hover, 0.06), ("ui_click", ui_click, 0.12), ("ui_focus", ui_focus, 0.1),
    ("ui_buzz", ui_buzz, 0.25), ("ui_pause", ui_pause, 0.25), ("ui_manifest", ui_manifest, 1.6),
    ("ui_win", ui_win, 2.4), ("ui_lose", ui_lose, 2.2),
):
    CUES[_name] = ("ui", _fn, _dur, False)
CUES["sol_rally"] = ("crowd", sol_rally, 1.4, False)
CUES["crowd_panic"] = ("crowd", crowd_panic, 6.0, True)
for _v in range(1, 5):
    CUES[f"cit_yelp_{_v}"] = ("crowd", lambda rng, dur, v=_v: cit_yelp(rng, dur, v), 0.45, False)
for _v in range(1, 4):
    CUES[f"cit_shout_{_v}"] = ("crowd", lambda rng, dur, v=_v: cit_shout(rng, dur, v), 0.55, False)
for _name, _fn, _dur in (
    ("music_theme", music_theme, 24.0),
    ("music_battle_base", music_battle_base, BAR * BATTLE_BARS),
    ("music_battle_drums", music_battle_drums, BAR * BATTLE_BARS),
    ("music_battle_lead", music_battle_lead, BAR * BATTLE_BARS),
):
    CUES[_name] = ("music", _fn, _dur, True)


def cue_path(cue: str) -> Path:
    return OUT / CUES[cue][0] / f"{cue}.wav"


def render(cue: str) -> np.ndarray:
    _, fn, dur, loop = CUES[cue]
    x = fit(np.asarray(fn(rng_for(cue), dur), dtype=np.float64), int(round(dur * SR)))
    x = x - np.mean(x)
    if not loop:
        x = fade(x, 5.0)
    return normalize(x)


def generate(only: str | None) -> None:
    for cue in CUES:
        if only and cue != only:
            continue
        x = render(cue)
        path = cue_path(cue)
        path.parent.mkdir(parents=True, exist_ok=True)
        wavfile.write(path, SR, np.round(x * 32767).astype(np.int16))
        print(f"wrote {path.relative_to(ROOT)} ({len(x) / SR:.2f}s)")


def verify() -> int:
    problems = []
    for cue, (_, _, dur, loop) in CUES.items():
        path = cue_path(cue)
        if not path.exists():
            problems.append(f"{cue}: missing {path}")
            continue
        sr, data = wavfile.read(path)
        if sr != SR or data.dtype != np.int16 or data.ndim != 1:
            problems.append(f"{cue}: format sr={sr} dtype={data.dtype} ndim={data.ndim}")
            continue
        x = data.astype(np.float64) / 32767.0
        length = len(x) / SR
        if abs(length - dur) > dur * 0.05:
            problems.append(f"{cue}: length {length:.3f}s expected {dur}s")
        peak_db = 20 * np.log10(np.max(np.abs(x)) + 1e-12)
        if peak_db > -1.0 + 0.05:
            problems.append(f"{cue}: peak {peak_db:.2f} dBFS")
        if peak_db < -30:
            problems.append(f"{cue}: nearly silent ({peak_db:.1f} dBFS)")
        if not np.all(np.isfinite(x)):
            problems.append(f"{cue}: non-finite samples")
        if abs(np.mean(x)) > 0.01:
            problems.append(f"{cue}: DC offset {np.mean(x):.4f}")
        if loop:
            # The wrap-around step must not be a click louder than the signal's own roughness.
            seam = abs(x[0] - x[-1])
            rough = np.percentile(np.abs(np.diff(x)), 99.9)
            if seam > max(rough, 0.02):
                problems.append(f"{cue}: loop seam jump {seam:.3f} > signal step {rough:.3f}")
        elif abs(x[0]) > 0.02 or abs(x[-1]) > 0.02:
            problems.append(f"{cue}: one-shot not faded (start {x[0]:.3f}, end {x[-1]:.3f})")
    for p in problems:
        print("PROBLEM:", p)
    print(f"audio verify: {len(CUES)} cues, {len(problems)} problems")
    return 1 if problems else 0


def spectrograms(out_dir: Path) -> None:
    from PIL import Image, ImageDraw

    out_dir.mkdir(parents=True, exist_ok=True)
    tiles = []
    for cue in CUES:
        sr, data = wavfile.read(cue_path(cue))
        f, t, s = signal.spectrogram(data.astype(np.float64), sr, nperseg=1024, noverlap=768)
        keep = f <= 12000
        img = 10 * np.log10(s[keep] + 1e-9)
        img = np.clip((img - img.max() + 70) / 70, 0, 1)
        im = Image.fromarray((img[::-1] * 255).astype(np.uint8)).resize((300, 120))
        wave = Image.new("L", (300, 40))
        d = ImageDraw.Draw(wave)
        env = np.abs(data.astype(np.float64)) / 32767.0
        cols = np.array_split(env, 300)
        for i, c in enumerate(cols):
            h = int(np.max(c) * 19) if len(c) else 0
            d.line([(i, 20 - h), (i, 20 + h)], fill=200)
        tile = Image.new("L", (300, 175))
        tile.paste(im, (0, 15))
        tile.paste(wave, (0, 135))
        ImageDraw.Draw(tile).text((2, 1), cue, fill=255)
        tiles.append(tile)
    cols = 4
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("L", (300 * cols, 175 * rows))
    for i, tile in enumerate(tiles):
        sheet.paste(tile, ((i % cols) * 300, (i // cols) * 175))
    sheet.save(out_dir / "spectrograms.png")
    print(out_dir / "spectrograms.png")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--verify", action="store_true")
    ap.add_argument("--spectrograms", type=Path)
    args = ap.parse_args()
    if args.verify:
        return verify()
    if args.spectrograms:
        spectrograms(args.spectrograms)
        return 0
    if args.only and args.only not in CUES:
        print(f"unknown cue {args.only}")
        return 1
    generate(args.only)
    return 0


if __name__ == "__main__":
    sys.exit(main())
