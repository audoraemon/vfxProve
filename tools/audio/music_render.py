"""Render the music (and the bugle stinger) with real instrument samples.

Each score in tools/audio/music/<cue>.score.json (the same note format as tools/audio/sfxr_bake.gd) becomes:
- tools/audio/music/midi/<cue>.mid: a General MIDI file to open in any music editor (Reaper, LMMS, MuseScore...) and
  play with better instruments, e.g. Spitfire LABS or BBC Symphony Orchestra Discover;
- assets/audio/music/<cue>.wav (or the score's "out"): that MIDI played by FluidSynth with the GeneralUser GS
  soundfont, its reverb tail folded back into the start of a loop so the loop has no seam, at the score's level.

Which instrument plays each part is set in tools/audio/music/instruments.json. FluidSynth and the soundfont live in
the sound library (KAK_SOUND_LIBRARY, default C:/BURIN_NITRO/SoundLibrary: tools/fluidsynth, soundfonts).

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

SR = 44100
ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools" / "audio" / "music"
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))
FLUIDSYNTH = next(LIBRARY.glob("tools/fluidsynth/*/bin/fluidsynth.exe"), None)
SOUNDFONT = LIBRARY / "soundfonts" / "GeneralUser-GS.sf2"
TPB = 480
NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_of(p) -> float:
    if isinstance(p, (int, float)):
        return 69.0 + 12.0 * math.log2(float(p) / 440.0)
    s = str(p)
    semis = NAMES[s[0].upper()] + (1 if s[1:2] == "#" else -1 if s[1:2] == "b" else 0)
    octave = int(s[2:] if s[1:2] in ("#", "b") else s[1:])
    return 12 * (octave + 1) + semis


def to_midi(spec: dict, inst: dict, tail: float) -> tuple[mido.MidiFile, float]:
    bpm = float(spec.get("bpm", 60))
    sec = 60.0 / bpm
    mid = mido.MidiFile(ticks_per_beat=TPB)
    meta = mido.MidiTrack()
    mid.tracks.append(meta)
    meta.append(mido.MetaMessage("set_tempo", tempo=mido.bpm2tempo(bpm), time=0))
    events: list[tuple[int, int, mido.Message]] = []
    channel = 0
    for part in spec["parts"]:
        cfg = inst.get(part.get("instrument", part["voice"]))
        if cfg is None or cfg.get("skip"):
            continue
        drum = cfg.get("drum", False)
        ch = 9 if drum else channel
        if not drum:
            channel = channel + 1 if channel + 1 != 9 else 10
            events.append((0, 0, mido.Message("program_change", channel=ch, program=cfg["program"])))
        volume = int(max(0, min(127, 127 * float(part.get("gain", 1.0)) * cfg.get("level", 1.0))))
        events.append((0, 0, mido.Message("control_change", channel=ch, control=7, value=volume)))
        events.append((0, 0, mido.Message("control_change", channel=ch, control=91, value=cfg.get("reverb", 70))))
        unit = sec if "bpm" in spec else 1.0
        taken = set()
        for note in part["notes"]:
            t = float(note.get("t", 0.0))
            if "p" not in note:
                key = cfg["note"]
            else:
                m = midi_of(note["p"])
                if abs(m - round(m)) > 0.05 and cfg.get("skip_detuned", True):
                    continue  # the sfxr score's detuned doubles were a chorus; a real section has its own
                key = cfg.get("map", {}).get(str(note["p"]), int(round(m)) + cfg.get("transpose", 0))
            if (t, key) in taken:
                continue
            taken.add((t, key))
            hold = float(note.get("hold", cfg.get("hold", 0.25)))
            length = max((hold + float(note.get("decay", 0.0)) * cfg.get("decay_share", 0.5)) * unit,
                         cfg.get("min_len", 0.06))
            vel = int(max(15, min(127, cfg.get("velocity", 96) * float(note.get("gain", 1.0)))))
            on = int(round(t * unit / sec * TPB))
            off = int(round((t * unit + length) / sec * TPB))
            events.append((on, 1, mido.Message("note_on", channel=ch, note=key, velocity=vel)))
            events.append((off, 0, mido.Message("note_off", channel=ch, note=key, velocity=0)))
    track = mido.MidiTrack()
    mid.tracks.append(track)
    now = 0
    for tick, _, msg in sorted(events, key=lambda e: (e[0], e[1])):
        track.append(msg.copy(time=tick - now))
        now = tick
    end = int(round((float(spec["length"]) + tail) / sec * TPB))
    track.append(mido.MetaMessage("marker", text="end", time=max(0, end - now)))
    return mid, float(spec["length"])


def render(mid_path: Path, wav_path: Path) -> np.ndarray:
    if FLUIDSYNTH is None or not SOUNDFONT.exists():
        sys.exit(f"FluidSynth or {SOUNDFONT} missing from {LIBRARY}")
    subprocess.run([str(FLUIDSYNTH), "-ni", "-q", "-g", "0.5", "-r", str(SR), "-F", str(wav_path),
                    "-o", "synth.reverb.room-size=0.75", "-o", "synth.reverb.level=0.6", "-o", "synth.chorus.active=0",
                    str(SOUNDFONT), str(mid_path)], check=True, stdout=subprocess.DEVNULL)
    x, sr = sf.read(str(wav_path), always_2d=True)
    return x.mean(axis=1)


def main() -> None:
    inst = json.loads((SRC / "instruments.json").read_text(encoding="utf-8"))
    args = sys.argv[1:]
    for p in sorted(SRC.glob("*.score.json")):
        cue = p.name.removesuffix(".score.json")
        if args and cue not in args:
            continue
        spec = json.loads(p.read_text(encoding="utf-8"))
        loop = spec.get("loop", False)
        tail = 4.0 if loop else 2.5
        mid, length = to_midi(spec, inst, tail)
        (SRC / "midi").mkdir(exist_ok=True)
        mid_path = SRC / "midi" / f"{cue}.mid"
        mid.save(str(mid_path))
        with tempfile.TemporaryDirectory() as tmp:
            x = render(mid_path, Path(tmp) / "out.wav")
        n = int(round(length * SR))
        if loop:
            y = x[:n].copy()
            rest = x[n:]
            while len(rest):  # what rang on past the end belongs to the start of the next time round
                m = min(n, len(rest))
                y[:m] += rest[:m]
                rest = rest[m:]
        else:
            y = x[: int(round(float(spec.get("out_length", length)) * SR))]
            f = int(0.03 * SR)
            y[-f:] *= np.linspace(1, 0, f)
        y = y - np.mean(y)
        peak, rms = np.abs(y).max(), np.sqrt(np.mean(y ** 2))
        scale = 10 ** (spec.get("peak_db", -1.0) / 20.0) / peak
        if "rms_db" in spec:
            scale = min(10 ** (spec["rms_db"] / 20.0) / rms, 10 ** (-0.3 / 20.0) / peak)
        y *= scale
        out = ROOT / spec["out"] if "out" in spec else ROOT / "assets" / "audio" / "music" / f"{cue}.wav"
        out.parent.mkdir(parents=True, exist_ok=True)
        sf.write(str(out), y, SR, subtype="PCM_16")
        print(f"{cue:20s} {len(y) / SR:6.2f} s  peak {20 * np.log10(np.abs(y).max()):5.1f} dB  "
              f"rms {20 * np.log10(np.sqrt(np.mean(y ** 2))):6.1f} dB  -> {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
