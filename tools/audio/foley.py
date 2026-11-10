"""Build game sounds from recordings: layer, trim, pitch, filter, fade and reverb sound files, per recipe.

Recipes live in tools/audio/foley/<category>[/<group>]/<cue>.json and write the same path under assets/audio/ (16-bit mono, or stereo with "stereo": true,
44.1 kHz). Recordings come from the sound library outside the repo (KAK_SOUND_LIBRARY, default
C:/BURIN_NITRO/SoundLibrary), which keeps each source's licence in its manifest; see tools/audio/foley/SOURCES.md.

Usage:
    python tools/audio/foley.py                    # every recipe
    python tools/audio/foley.py collapse_stone_1   # one cue (or a category name)
    python tools/audio/foley.py --credits          # rewrite assets/audio/CREDITS.md from the recipes in use
    python tools/audio/foley.py --recordings-only DIR ability   # the same cues without their synth.py base, into DIR

Recipe:
    {"length": 1.6, "loop": false, "peak_db": -1.0,          # or "rms_db": -14 (never above peak -0.3 dB)
     "reverb": {"rt60": 1.4, "mix": 0.18, "predelay_ms": 12, "damp": 6000},   # optional; or {"ir": "lib:...", "mix": ..}
     "eq": [["lowshelf", 120, -4], ["peak", 3000, 3, 0.8]],   # optional: the finished mix's EQ, [kind, Hz, dB, Q]
     "layers": [
       {"src": "lib:oga/breaking-rock/rock_break.ogg",       # lib: the library; repo: this repo (e.g. a synth.py WAV)
        "at": 0.0,            # where it starts in the output, seconds
        "from": 0.2,          # where to start reading the source, seconds; or "onset": true to start at its first sound
        "dur": 1.0,           # how much of the source to take (after pitch), seconds; default all
        "pitch": -3,          # semitones, tape-style (lower is also longer)
        "gain_db": -6, "normalize": true,    # normalize the layer's peak to 0 dB before its gain (default true)
        "hp": 80, "lp": 6000,  # high- and low-pass, Hz
        "fade_in": 5, "fade_out": 120,      # ms
        "reverse": false, "dry": false,      # "dry": keep this layer out of the reverb
        "pan": 0.0}]}         # -1 left .. 1 right, in a recipe with "stereo": true (its sources keep their own channels)
A layer can instead be {"scatter": {...}}: many short one-shots (footsteps) spread over runners, expanded by scatter().
A looped recipe wraps what runs past its end back to its start, and the reverb tail with it, so the loop has no seam.
"""
from __future__ import annotations

import functools
import json
import os
import sys
from fractions import Fraction
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dsp import eq  # noqa: E402

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
RECIPES = ROOT / "tools" / "audio" / "foley"
OUT = ROOT / "assets" / "audio"
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))


@functools.lru_cache(maxsize=64)
def load(src: str, ch: int | None = None) -> np.ndarray:
    """A source as mono (ch None), or its channel ch (a mono source gives the same signal to every channel). Cached, so
    the result is read-only."""
    kind, _, rel = src.partition(":")
    path = (LIBRARY if kind == "lib" else ROOT) / rel
    x, sr = sf.read(str(path), always_2d=True)
    x = x[:, ch] if ch is not None and ch < x.shape[1] else x.mean(axis=1)
    if sr != SR:
        r = Fraction(SR, sr).limit_denominator(1000)
        x = signal.resample_poly(x, r.numerator, r.denominator)
    x = np.ascontiguousarray(x)
    x.setflags(write=False)
    return x


def scatter(spec: dict) -> list[dict]:
    """A crowd of runners as plain layers. Each runner has its own distance (gain and low-pass), pitch, pace and a pan
    that drifts as they cross the street, and runs in bursts with short stops. Seeded, so a recipe always builds the
    same. Keys: srcs, seed, runners, length, rate (steps/s) [lo, hi], gain_db [lo, hi] (far .. near), lp [lo, hi]
    (far .. near, Hz), hp, pitch [lo, hi], pan [lo, hi], run [lo, hi] and stop [lo, hi] seconds, step_db, step_pitch,
    jitter (fraction of a step)."""
    rng = np.random.default_rng(spec.get("seed", 1))
    lo_hi = lambda k, d: tuple(spec.get(k, d))  # noqa: E731
    out = []
    for _ in range(int(spec["runners"])):
        near = rng.random()   # 0 far .. 1 near
        g0, g1 = lo_hi("gain_db", (-16.0, -4.0))
        f0, f1 = lo_hi("lp", (2000.0, 8000.0))
        gain = g0 + (g1 - g0) * near
        lp = f0 * (f1 / f0) ** near
        pitch = rng.uniform(*lo_hi("pitch", (-2.0, 1.0)))
        step = 1.0 / rng.uniform(*lo_hi("rate", (2.6, 3.4)))
        p0, p1 = lo_hi("pan", (-0.9, 0.9))
        t = rng.uniform(0.0, spec["length"])
        end = t + spec["length"]
        foot = rng.integers(2)
        while t < end:
            run = rng.uniform(*lo_hi("run", (5.0, 14.0)))
            a, b = rng.uniform(p0, p1, 2)
            stop_at = min(t + run, end)
            t0 = t
            while t < stop_at:
                pan = a + (b - a) * (t - t0) / run
                out.append({"src": spec["srcs"][rng.integers(len(spec["srcs"]))], "at": round(t % spec["length"], 4),
                            "pitch": round(pitch + rng.normal(0.0, spec.get("step_pitch", 0.4)), 2),
                            "gain_db": round(gain + rng.normal(0.0, spec.get("step_db", 2.0)) - 1.5 * foot, 2),
                            "hp": spec.get("hp", 50), "lp": round(lp), "pan": round(float(np.clip(pan, -1, 1)), 3),
                            "fade_in": 1, "fade_out": 30, "dry": spec.get("dry", False)})
                foot = 1 - foot
                t += step * (1.0 + rng.normal(0.0, spec.get("jitter", 0.06)))
            t += rng.uniform(*lo_hi("stop", (0.5, 3.0)))
    return out


def layers(recipe: dict) -> list[dict]:
    """A recipe's layers with every scatter expanded."""
    return [x for spec in recipe["layers"] for x in (scatter(spec["scatter"]) if "scatter" in spec else [spec])]


def onset(x: np.ndarray, floor_db: float = -30.0) -> int:
    env = np.abs(x)
    thresh = env.max() * 10 ** (floor_db / 20.0)
    i = int(np.argmax(env > thresh))
    return max(0, i - int(0.005 * SR))


def repitch(x: np.ndarray, semis: float) -> np.ndarray:
    if not semis:
        return x
    r = Fraction(2 ** (-semis / 12.0)).limit_denominator(400)   # resample to more samples = lower pitch
    return signal.resample_poly(x, r.numerator, r.denominator)


def filt(x: np.ndarray, hp: float | None, lp: float | None) -> np.ndarray:
    if hp:
        x = signal.sosfilt(signal.butter(2, hp, "highpass", fs=SR, output="sos"), x)
    if lp:
        x = signal.sosfilt(signal.butter(2, lp, "lowpass", fs=SR, output="sos"), x)
    return x


def fades(x: np.ndarray, fin_ms: float, fout_ms: float) -> np.ndarray:
    x = x.copy()
    a = min(len(x), int(fin_ms * SR / 1000))
    b = min(len(x), int(fout_ms * SR / 1000))
    if a:
        x[:a] *= np.linspace(0, 1, a) ** 2
    if b:
        x[-b:] *= np.linspace(1, 0, b) ** 2
    return x


def layer(spec: dict, ch: int | None = None) -> np.ndarray:
    x = load(spec["src"], ch)
    start = onset(load(spec["src"]) if ch is not None else x) if spec.get("onset") else int(spec.get("from", 0.0) * SR)
    x = x[start:]
    if spec.get("reverse"):
        x = x[::-1]
    x = repitch(x, spec.get("pitch", 0.0))
    if "dur" in spec:
        x = x[: int(spec["dur"] * SR)]
    x = x - np.mean(x)
    x = filt(x, spec.get("hp"), spec.get("lp"))
    x = fades(x, spec.get("fade_in", 3.0), spec.get("fade_out", 20.0))
    if spec.get("normalize", True):
        # A stereo recipe normalizes each layer by its mono peak, so its two channels keep their balance.
        peak = np.abs(x).max() if ch is None else _layer_peak(spec)
        x = x / peak if peak > 0 else x
    if ch is not None and "pan" in spec:
        a = (float(spec["pan"]) + 1.0) * np.pi / 4.0
        x = x * (np.cos(a) if ch == 0 else np.sin(a)) * np.sqrt(2.0)
    return x * 10 ** (spec.get("gain_db", 0.0) / 20.0)


_PEAKS: dict = {}


def _layer_peak(spec: dict) -> float:
    """The peak of a layer's channels together, so both sides of a stereo layer scale by one number."""
    key = json.dumps(spec, sort_keys=True)
    if key not in _PEAKS:
        _PEAKS[key] = max(np.abs(layer(dict(spec, normalize=False, gain_db=0.0), c)).max() for c in (0, 1)) or 1.0
    return _PEAKS[key]


def impulse(spec: dict, ch: int | None = None) -> np.ndarray:
    """A reverb's impulse: a recorded one, or decaying noise with an RT60 and some high-frequency damping. Each channel
    of a stereo recipe gets its own noise, so the reverb is wide."""
    if "ir" in spec:
        ir = load(spec["ir"], ch)
    else:
        rng = np.random.default_rng(7 + (ch or 0) * 101)
        rt60 = spec.get("rt60", 1.2)
        n = int(rt60 * 1.2 * SR)
        t = np.arange(n) / SR
        ir = rng.standard_normal(n) * 10 ** (-3.0 * t / rt60)
        ir = signal.sosfilt(signal.butter(1, spec.get("damp", 6000), "lowpass", fs=SR, output="sos"), ir)
        ir[: int(0.004 * SR)] *= np.linspace(0, 1, int(0.004 * SR))
    pre = np.zeros(int(spec.get("predelay_ms", 10) * SR / 1000))
    ir = np.concatenate([pre, ir])
    return ir / np.sqrt(np.sum(ir ** 2))


def place(buf: np.ndarray, x: np.ndarray, at: int, loop: bool) -> None:
    n = len(buf)
    end = at + len(x)
    if end <= n:
        buf[at:end] += x
        return
    keep = n - at
    buf[at:] += x[:keep]
    rest = x[keep:]
    if loop:
        while len(rest):
            m = min(n, len(rest))
            buf[:m] += rest[:m]
            rest = rest[m:]


def build(recipe: dict, skip_base: bool = False) -> np.ndarray:
    """The finished cue: mono, or (frames, 2) for a recipe with "stereo": true."""
    if recipe.get("stereo"):
        out = np.stack([_build_channel(recipe, skip_base, c) for c in (0, 1)], axis=1)
    else:
        out = _build_channel(recipe, skip_base, None)
    out = out - np.mean(out, axis=0)
    peak = np.abs(out).max()
    rms = np.sqrt(np.mean(out ** 2))
    scale = 10 ** (recipe.get("peak_db", -1.0) / 20.0) / peak
    if "rms_db" in recipe:
        scale = min(10 ** (recipe["rms_db"] / 20.0) / rms, 10 ** (-0.3 / 20.0) / peak)
    return out * scale


def _build_channel(recipe: dict, skip_base: bool, ch: int | None) -> np.ndarray:
    n = int(round(recipe["length"] * SR))
    loop = recipe.get("loop", False)
    wet_in = np.zeros(n)
    dry = np.zeros(n)
    for spec in layers(recipe):
        if skip_base and spec["src"].startswith("lib:synth/"):
            continue
        x = layer(spec, ch)
        at = int(round(spec.get("at", 0.0) * SR))
        place(dry, x, at, loop)
        if not spec.get("dry"):
            place(wet_in, x, at, loop)
    out = dry
    if "reverb" in recipe:
        rv = recipe["reverb"]
        wet = signal.fftconvolve(wet_in, impulse(rv, ch))
        wet_out = np.zeros(n)
        place(wet_out, wet, 0, loop)
        mix = rv.get("mix", 0.2)
        out = dry * (1.0 - mix) + wet_out * mix * 3.0
    if "eq" in recipe:
        out = eq(out, recipe["eq"])
    if not loop:
        f = int(0.008 * SR)
        out[-f:] *= np.linspace(1, 0, f)
    return out


def recipes() -> list[Path]:
    return sorted(p for p in RECIPES.rglob("*.json")
                  if not any(part.startswith("_") for part in p.relative_to(RECIPES).parts))


def credits() -> None:
    """assets/audio/CREDITS.md: every library file a recipe uses, with its licence, author and source."""
    manifests = {}
    for m in LIBRARY.rglob("manifest.json"):
        data = json.loads(m.read_text(encoding="utf-8"))
        base = m.parent.relative_to(LIBRARY).as_posix()
        for key, info in data.items():
            manifests[f"{base}/{key}"] = info
    used: dict[str, set] = {}
    for p in recipes():
        for spec in layers(json.loads(p.read_text(encoding="utf-8"))):
            if spec["src"].startswith("lib:"):
                used.setdefault(spec["src"][4:], set()).add(p.relative_to(RECIPES).with_suffix("").as_posix())
    lines = ["# Sound credits", "", "Recordings used by tools/audio/foley.py recipes, from the sound library outside the "
             "repo. CC0 and public-domain sources need no credit; they are listed so each sound can be traced.", "",
             "| Source | Licence | Author | Used by |", "|---|---|---|---|"]
    for rel in sorted(used):
        stem = rel.rsplit(".", 1)[0]
        info = next((v for k, v in manifests.items() if rel.startswith(k) or stem == k.rsplit(".", 1)[0]), None)
        if rel.startswith("synth/"):
            continue  # tools/audio/synth.py's own render, made in this repo
        if rel.startswith("kenney/"):
            info = {"title": "Kenney " + rel.split("/")[1], "license": "CC0", "author": "Kenney", "url": "https://kenney.nl"}
        if rel.startswith("orchestra/VSCO-2-CE"):
            info = {"title": "VS Chamber Orchestra 2 Community Edition", "license": "CC0", "author": "Versilian Studios",
                    "url": "https://github.com/sgossner/VSCO-2-CE"}
        if rel.startswith("orchestra/sso-4.0"):
            info = {"title": "Sonatina Symphonic Orchestra 4.0", "license": "CC Sampling Plus 1.0 (credit requested)",
                    "author": "Mattias Westlund and contributors", "url": "https://github.com/peastman/sso"}
        if info is None:
            info = {"title": rel, "license": "?", "author": "?", "url": ""}
        lines.append(f"| [{info['title']}]({info['url']}) `{rel.rsplit('/', 1)[-1]}` | {info['license']} | "
                     f"{info['author']} | {', '.join(sorted(used[rel]))} |")
    lines += ["", "## Music", "", "The music (`tools/audio/music_render.py`) is played on sampled instruments:", "",
              "| Library | Licence | Used for |", "|---|---|---|",
              "| [Sonatina Symphonic Orchestra](https://github.com/peastman/sso) 4.0, by Mattias Westlund and contributors "
              "| [CC Sampling Plus 1.0](https://creativecommons.org/licenses/sampling+/1.0/) (credit requested) "
              "| choir, strings, brass, organ, harp, chimes, timpani, drums, cymbals, tam-tam, the bugle |",
              "| [VS Chamber Orchestra 2 Community Edition](https://github.com/sgossner/VSCO-2-CE), Versilian Studios "
              "| CC0 | the low drum |"]
    (OUT / "CREDITS.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print("wrote", (OUT / "CREDITS.md").relative_to(ROOT), len(used), "sources")


def main() -> None:
    args = sys.argv[1:]
    if "--credits" in args:
        credits()
        return
    alt = None
    if "--recordings-only" in args:
        i = args.index("--recordings-only")
        alt = Path(args[i + 1])
        args = args[:i] + args[i + 2:]
    done = 0
    for p in recipes():
        rel = p.relative_to(RECIPES)
        if args and p.stem not in args and not set(rel.parts[:-1]) & set(args):
            continue
        recipe = json.loads(p.read_text(encoding="utf-8"))
        if alt is not None and (not any(l["src"].startswith("lib:synth/") for l in layers(recipe))
                                or all(l["src"].startswith("lib:synth/") for l in layers(recipe))):
            continue  # only cues that have both a synth base and recordings
        y = build(recipe, skip_base=alt is not None)
        dest = (alt if alt is not None else OUT) / rel.with_suffix(".wav")
        dest.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(dest), y, SR, subtype="PCM_16")
        rms = 20 * np.log10(np.sqrt(np.mean(y ** 2)) + 1e-9)
        print(f"{p.stem:22s} {len(y) / SR:6.2f} s  peak {20 * np.log10(np.abs(y).max()):5.1f} dB  rms {rms:6.1f} dB")
        done += 1
    if not done:
        sys.exit("no recipe matched " + " ".join(args))


if __name__ == "__main__":
    main()
