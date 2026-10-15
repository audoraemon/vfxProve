"""Build game sounds from recordings: layer, trim, pitch, filter, fade and reverb sound files, per recipe.

Recipes live in tools/audio/foley/<category>[/<group>]/<cue>.json and write the same path under assets/audio/ (16-bit mono,
44.1 kHz). Recordings come from the sound library outside the repo (KAK_SOUND_LIBRARY, default
C:/BURIN_NITRO/SoundLibrary), which keeps each source's licence in its manifest; see tools/audio/foley/SOURCES.md.

Usage:
    python tools/audio/foley.py                    # every recipe
    python tools/audio/foley.py collapse_stone_1   # one cue (or a category name)
    python tools/audio/foley.py --credits          # rewrite assets/audio/CREDITS.md from the recipes in use

Recipe:
    {"length": 1.6, "loop": false, "peak_db": -1.0,          # or "rms_db": -14 (never above peak -0.3 dB)
     "reverb": {"rt60": 1.4, "mix": 0.18, "predelay_ms": 12, "damp": 6000},   # optional; or {"ir": "lib:...", "mix": ..}
     "layers": [
       {"src": "lib:oga/breaking-rock/rock_break.ogg",       # lib: the library; repo: this repo (e.g. a synth.py WAV)
        "at": 0.0,            # where it starts in the output, seconds
        "from": 0.2,          # where to start reading the source, seconds; or "onset": true to start at its first sound
        "dur": 1.0,           # how much of the source to take (after pitch), seconds; default all
        "pitch": -3,          # semitones, tape-style (lower is also longer)
        "gain_db": -6, "normalize": true,    # normalize the layer's peak to 0 dB before its gain (default true)
        "hp": 80, "lp": 6000,  # high- and low-pass, Hz
        "fade_in": 5, "fade_out": 120,      # ms
        "reverse": false, "dry": false}]}   # "dry": keep this layer out of the reverb
A looped recipe wraps what runs past its end back to its start, and the reverb tail with it, so the loop has no seam.
"""
from __future__ import annotations

import json
import os
import sys
from fractions import Fraction
from pathlib import Path

import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
RECIPES = ROOT / "tools" / "audio" / "foley"
OUT = ROOT / "assets" / "audio"
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))


def load(src: str) -> np.ndarray:
    kind, _, rel = src.partition(":")
    path = (LIBRARY if kind == "lib" else ROOT) / rel
    x, sr = sf.read(str(path), always_2d=True)
    x = x.mean(axis=1)
    if sr != SR:
        r = Fraction(SR, sr).limit_denominator(1000)
        x = signal.resample_poly(x, r.numerator, r.denominator)
    return x


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


def layer(spec: dict) -> np.ndarray:
    x = load(spec["src"])
    start = onset(x) if spec.get("onset") else int(spec.get("from", 0.0) * SR)
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
        peak = np.abs(x).max()
        x = x / peak if peak > 0 else x
    return x * 10 ** (spec.get("gain_db", 0.0) / 20.0)


def impulse(spec: dict) -> np.ndarray:
    """A reverb's impulse: a recorded one, or decaying noise with an RT60 and some high-frequency damping."""
    if "ir" in spec:
        ir = load(spec["ir"])
    else:
        rng = np.random.default_rng(7)
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


def build(recipe: dict) -> np.ndarray:
    n = int(round(recipe["length"] * SR))
    loop = recipe.get("loop", False)
    wet_in = np.zeros(n)
    dry = np.zeros(n)
    for spec in recipe["layers"]:
        x = layer(spec)
        at = int(round(spec.get("at", 0.0) * SR))
        place(dry, x, at, loop)
        if not spec.get("dry"):
            place(wet_in, x, at, loop)
    out = dry
    if "reverb" in recipe:
        rv = recipe["reverb"]
        wet = signal.fftconvolve(wet_in, impulse(rv))
        wet_out = np.zeros(n)
        place(wet_out, wet, 0, loop)
        mix = rv.get("mix", 0.2)
        out = dry * (1.0 - mix) + wet_out * mix * 3.0
    if not loop:
        f = int(0.008 * SR)
        out[-f:] *= np.linspace(1, 0, f)
    out = out - np.mean(out)
    peak = np.abs(out).max()
    rms = np.sqrt(np.mean(out ** 2))
    scale = 10 ** (recipe.get("peak_db", -1.0) / 20.0) / peak
    if "rms_db" in recipe:
        scale = min(10 ** (recipe["rms_db"] / 20.0) / rms, 10 ** (-0.3 / 20.0) / peak)
    return out * scale


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
        for spec in json.loads(p.read_text(encoding="utf-8"))["layers"]:
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
    done = 0
    for p in recipes():
        rel = p.relative_to(RECIPES)
        if args and p.stem not in args and not set(rel.parts[:-1]) & set(args):
            continue
        recipe = json.loads(p.read_text(encoding="utf-8"))
        y = build(recipe)
        dest = OUT / rel.with_suffix(".wav")
        dest.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(dest), y, SR, subtype="PCM_16")
        rms = 20 * np.log10(np.sqrt(np.mean(y ** 2)) + 1e-9)
        print(f"{p.stem:22s} {len(y) / SR:6.2f} s  peak {20 * np.log10(np.abs(y).max()):5.1f} dB  rms {rms:6.1f} dB")
        done += 1
    if not done:
        sys.exit("no recipe matched " + " ".join(args))


if __name__ == "__main__":
    main()
