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


# id: (effect folder, builder, length seconds, loop)
CUES: dict[str, tuple] = {
    "nova_alarm": ("nova", nova_alarm, 1.5, False),
    "nova_lock": ("nova", nova_lock, 0.3, False),
    "nova_descent": ("nova", nova_descent, 0.8, False),
    "nova_crack": ("nova", nova_crack, 0.4, False),
    "nova_boom": ("nova", nova_boom, 3.0, False),
    "nova_shockwave": ("nova", nova_shockwave, 1.2, False),
    "nova_rumble": ("nova", nova_rumble, 5.0, False),
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
    "laser_scan": ("laser", laser_scan, 1.0, False),
    "laser_thrusters": ("laser", laser_thrusters, 0.6, False),
    "laser_ignite": ("laser", laser_ignite, 0.4, False),
    "laser_hum": ("laser", laser_hum, 1.0, True),
    "laser_powerdown": ("laser", laser_powerdown, 0.8, False),
    "laser_depart": ("laser", laser_depart, 1.5, False),
}
for _v in range(1, 5):
    CUES[f"orb_hit_{_v}"] = ("orbital", lambda rng, dur, v=_v: orb_hit(rng, dur, v), 0.9, False)
for _v in range(1, 4):
    CUES[f"laser_sizzle_{_v}"] = ("laser", lambda rng, dur, v=_v: laser_sizzle(rng, dur, v), 0.3, False)


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
