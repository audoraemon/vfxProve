"""Render the music (and the bugle stinger) with real orchestral samples, in stereo.

Each score in tools/audio/music/<cue>.score.json becomes:
- tools/audio/music/midi/<cue>.mid: a MIDI file, one track per part, to open in any music editor (Reaper, LMMS,
  MuseScore...) and play with other instruments;
- assets/audio/music/<cue>.wav (or the score's "out"): every part rendered on its own sampled instrument, panned,
  balanced, sent to a stereo hall reverb and mixed; a loop's tail is folded back into its start, so it has no seam.

Instruments (tools/audio/music/instruments.json) are SFZ instruments played by sfizz, from the CC0 VS Chamber Orchestra 2
Community Edition ("vsco:...") or Sonatina Symphonic Orchestra ("sso:...", CC Sampling Plus 1.0), or General MIDI
programs played by FluidSynth with the GeneralUser GS soundfont. All of them, and the players, live in the sound library
(KAK_SOUND_LIBRARY, default C:/BURIN_NITRO/SoundLibrary: orchestra/, soundfonts/, tools/).

Score format: as tools/audio/sfxr_bake.gd's (times in beats with "bpm"), plus, per part:
    "instrument": a name in instruments.json (else "voice" is looked up there),
    "level_db": the part's loudness while it plays (RMS dB, its balance in the mix; or "gain_db", a plain gain),
    "pan": -1 (left) .. 1 (right), "send": how much goes to the reverb (0..1),
    "dyn": [[beat, value], ...] the part's dynamics (MIDI CC1, 0..127), joined by straight ramps;
per note "vel" (1..127) sets the MIDI velocity directly. The score may set "reverb": {"rt60": 3.8, "mix": 0.35},
"rms_db" (its level) and "mono".

Usage:
    python tools/audio/music_render.py                # every score
    python tools/audio/music_render.py music_theme    # one
"""
from __future__ import annotations

import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import mido
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools" / "audio" / "music"
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))
FLUIDSYNTH = next(LIBRARY.glob("tools/fluidsynth/*/bin/fluidsynth.exe"), None)
SFIZZ = next(LIBRARY.glob("tools/sfizz/**/sfizz_render.exe"), None)
SOUNDFONT = LIBRARY / "soundfonts" / "GeneralUser-GS.sf2"
ROOTS = {"vsco": LIBRARY / "orchestra" / "VSCO-2-CE-1.1.0",
         "sso": LIBRARY / "orchestra" / "sso-4.0" / "Sonatina Symphonic Orchestra"}
TPB = 480
NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_of(p) -> float:
    if isinstance(p, (int, float)):
        return 69.0 + 12.0 * math.log2(float(p) / 440.0)
    s = str(p)
    semis = NAMES[s[0].upper()] + (1 if s[1:2] == "#" else -1 if s[1:2] == "b" else 0)
    octave = int(s[2:] if s[1:2] in ("#", "b") else s[1:])
    return 12 * (octave + 1) + semis


def part_midi(spec: dict, part: dict, cfg: dict, tail: float) -> mido.MidiFile:
    """One part as a one-track MIDI file: its program (General MIDI), its dynamics curve, its notes."""
    bpm = float(spec.get("bpm", 60))
    sec = 60.0 / bpm
    unit = sec if "bpm" in spec else 1.0
    tick = lambda beats: int(round(beats * unit / sec * TPB))
    mid = mido.MidiFile(ticks_per_beat=TPB)
    track = mido.MidiTrack()
    mid.tracks.append(track)
    ch = 9 if cfg.get("drum") else 0
    events: list[tuple[int, int, mido.Message]] = [(0, 0, mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(bpm)))]
    if "program" in cfg and not cfg.get("drum"):
        events.append((0, 0, mido.Message("program_change", channel=ch, program=cfg["program"])))
    dyn = part.get("dyn") or cfg.get("dyn")
    if dyn:
        pts = sorted((float(t), int(v)) for t, v in dyn)
        events.append((0, 0, mido.Message("control_change", channel=ch, control=1, value=pts[0][1])))
        for (t0, v0), (t1, v1) in zip(pts, pts[1:]):
            steps = max(1, int((t1 - t0) * 8))
            for k in range(1, steps + 1):
                t = t0 + (t1 - t0) * k / steps
                v = int(round(v0 + (v1 - v0) * k / steps))
                events.append((tick(t), 0, mido.Message("control_change", channel=ch, control=1, value=max(0, min(127, v)))))
    taken = set()
    for note in part["notes"]:
        t = float(note.get("t", 0.0))
        if "p" not in note:
            key = cfg["note"]
        else:
            m = midi_of(note["p"])
            if abs(m - round(m)) > 0.05 and cfg.get("skip_detuned", True):
                continue
            key = cfg.get("map", {}).get(str(note["p"]), int(round(m)) + cfg.get("transpose", 0))
        if (t, key) in taken:
            continue
        taken.add((t, key))
        hold = float(note.get("hold", cfg.get("hold", 0.25)))
        length = max((hold + float(note.get("decay", 0.0)) * cfg.get("decay_share", 0.5)) * unit, cfg.get("min_len", 0.06))
        vel = int(note["vel"]) if "vel" in note else int(cfg.get("velocity", 96) * float(note.get("gain", 1.0)))
        vel = max(1, min(127, vel))
        events.append((tick(t), 1, mido.Message("note_on", channel=ch, note=key, velocity=vel)))
        events.append((tick(t) + max(1, int(round(length / sec * TPB))), 0,
                       mido.Message("note_off", channel=ch, note=key, velocity=0)))
    now = 0
    for at, _, msg in sorted(events, key=lambda e: (e[0], e[1])):
        track.append(msg.copy(time=at - now))
        now = at
    end = int(round((float(spec["length"]) + tail) / sec * TPB))
    track.append(mido.MetaMessage("end_of_track", time=max(0, end - now)))
    return mid


def render_part(mid: mido.MidiFile, cfg: dict, frames: int, tmp: Path) -> np.ndarray:
    mid_path, wav_path = tmp / "part.mid", tmp / "part.wav"
    mid.save(str(mid_path))
    if "sfz" in cfg:
        lib, _, rel = cfg["sfz"].partition(":")
        subprocess.run([str(SFIZZ), "--sfz", str(ROOTS[lib] / rel), "--midi", str(mid_path), "--wav", str(wav_path),
                        "-s", str(SR), "-q", "3", "--use-eot"], check=True, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
    else:
        subprocess.run([str(FLUIDSYNTH), "-ni", "-q", "-g", "0.6", "-r", str(SR), "-F", str(wav_path), "-o",
                        "synth.reverb.active=0", "-o", "synth.chorus.active=0", str(SOUNDFONT), str(mid_path)],
                       check=True, stdout=subprocess.DEVNULL)
    x, _ = sf.read(str(wav_path), always_2d=True)
    if x.shape[1] == 1:
        x = np.repeat(x, 2, axis=1)
    out = np.zeros((frames, 2))
    m = min(frames, len(x))
    out[:m] = x[:m, :2]
    return out


def active_rms(x: np.ndarray) -> float:
    """A part's loudness while it plays: the RMS of the stretches within 40 dB of its loudest moment."""
    env = np.convolve(np.abs(x).mean(axis=1), np.ones(2205) / 2205, "same")
    on = env > env.max() * 0.01
    return float(np.sqrt(np.mean(x[on] ** 2))) if on.any() else 1.0


def hall_ir(rt60: float, seed: int = 11) -> np.ndarray:
    """A stereo hall: early reflections, then a decorrelated tail that dies away faster in the highs."""
    n = int(rt60 * 1.4 * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(seed)
    ir = np.zeros((n, 2))
    bands = [(None, 400, rt60 * 1.15), (400, 3000, rt60), (3000, None, rt60 * 0.45)]
    for ch in range(2):
        noise = rng.standard_normal(n)
        tail = np.zeros(n)
        for lo, hi, rt in bands:
            if lo and hi:
                sos = signal.butter(2, [lo, hi], "bandpass", fs=SR, output="sos")
            elif hi:
                sos = signal.butter(2, hi, "lowpass", fs=SR, output="sos")
            else:
                sos = signal.butter(2, lo, "highpass", fs=SR, output="sos")
            tail += signal.sosfilt(sos, noise) * 10 ** (-3.0 * t / rt)
        onset = int(0.03 * SR)
        tail[:onset] *= np.linspace(0, 1, onset) ** 2
        for _ in range(14):
            d = int(rng.uniform(0.008, 0.07) * SR)
            tail[d] += rng.uniform(0.3, 1.0) * (1 - d / (0.09 * SR)) * 6.0
        ir[:, ch] = tail / np.sqrt(np.sum(tail ** 2))
    return ir


def fold(x: np.ndarray, n: int) -> np.ndarray:
    """A loop's first n frames, with everything that rang on past them added back in from the start."""
    y = x[:n].copy()
    rest = x[n:]
    while len(rest):
        m = min(n, len(rest))
        y[:m] += rest[:m]
        rest = rest[m:]
    return y


def main() -> None:
    inst = json.loads((SRC / "instruments.json").read_text(encoding="utf-8"))
    args = sys.argv[1:]
    for p in sorted(SRC.glob("*.score.json")):
        cue = p.name.removesuffix(".score.json")
        if args and cue not in args:
            continue
        spec = json.loads(p.read_text(encoding="utf-8"))
        loop = spec.get("loop", False)
        rv = spec.get("reverb", {"rt60": 3.2, "mix": 0.3})
        tail = rv["rt60"] * 1.5 + 2.0
        n = int(round(float(spec["length"]) * SR))
        frames = n + int(tail * SR)
        dry = np.zeros((frames, 2))
        send = np.zeros((frames, 2))
        full = mido.MidiFile(ticks_per_beat=TPB)
        with tempfile.TemporaryDirectory() as tmp:
            for part in spec["parts"]:
                cfg = inst.get(part.get("instrument", part.get("voice", "")))
                if cfg is None or cfg.get("skip"):
                    continue
                mid = part_midi(spec, part, cfg, tail)
                full.tracks.append(mid.tracks[0])
                x = render_part(mid, cfg, frames, Path(tmp))
                if "level_db" in part:
                    gain = 10 ** (float(part["level_db"]) / 20.0) / active_rms(x)
                else:
                    gain = 10 ** ((float(part.get("gain_db", 0.0)) + cfg.get("gain_db", 0.0)) / 20.0)
                    if "gain" in part:
                        gain *= float(part["gain"]) * cfg.get("level", 1.0)
                pan = float(part.get("pan", cfg.get("pan", 0.0)))
                a = (pan + 1.0) * math.pi / 4.0
                x = x * gain * np.array([math.cos(a), math.sin(a)]) * math.sqrt(2.0)
                if os.environ.get("KAK_MUSIC_DEBUG"):
                    lvl = 20 * math.log10(np.sqrt(np.mean(x[:n] ** 2)) + 1e-12)
                    print(f"    {part.get('instrument', part.get('voice')):14s} {len(part['notes']):3d} notes  {lvl:6.1f} dB")
                dry += x
                send += x * float(part.get("send", cfg.get("send", 0.3)))
        (SRC / "midi").mkdir(exist_ok=True)
        full.save(str(SRC / "midi" / f"{cue}.mid"))
        ir = hall_ir(rv["rt60"])
        wet = np.stack([signal.fftconvolve(send[:, c], ir[:, c])[:frames] for c in range(2)], axis=1)
        mix = dry + wet * rv["mix"] * 2.5
        if loop:
            y = fold(mix, n)
        else:
            y = mix[: int(round(float(spec.get("out_length", spec["length"])) * SR))]
            f = int(0.05 * SR)
            y[-f:] *= np.linspace(1, 0, f)[:, None]
        y = y - y.mean(axis=0)
        rms = np.sqrt(np.mean(y ** 2))
        if "rms_db" in spec:
            y = y * (10 ** (spec["rms_db"] / 20.0) / rms)
        else:
            y = y * (10 ** (spec.get("peak_db", -1.0) / 20.0) / np.abs(y).max())
        # A gentle limiter: anything over -3 dBFS bends smoothly toward -0.3 dBFS instead of clipping.
        knee, ceil = 10 ** (-3 / 20), 10 ** (-0.3 / 20)
        over = np.abs(y) > knee
        y[over] = np.sign(y[over]) * (knee + (ceil - knee) * np.tanh((np.abs(y[over]) - knee) / (ceil - knee)))
        if spec.get("mono"):
            y = y.mean(axis=1)
        out = ROOT / spec["out"] if "out" in spec else ROOT / "assets" / "audio" / "music" / f"{cue}.wav"
        out.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(out), y, SR, subtype="PCM_16")
        print(f"{cue:20s} {len(y) / SR:6.2f} s  peak {20 * np.log10(np.abs(y).max()):5.1f} dB  "
              f"rms {20 * np.log10(np.sqrt(np.mean(y ** 2))):6.1f} dB  -> {out.relative_to(ROOT)}")


if __name__ == "__main__":
    if SFIZZ is None or FLUIDSYNTH is None:
        sys.exit(f"sfizz_render or fluidsynth missing from {LIBRARY / 'tools'}")
    main()
