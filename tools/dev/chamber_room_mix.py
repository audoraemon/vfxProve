"""Renders a minute of the God's Chamber at rest, offline, for listening (step 7, design section 9).

Reads the minute tools/dev/chamber_sound_probe.gd wrote (--json): the room's bed looped at its catalog level, faded in as the room
opens, and each occasional or state sound at its time, level and pan (constant power, as the game's 2D panning). Writes the room
alone and the room under the Chamber's music (music_theme at Music.DB) as 16-bit stereo WAVs. Bus effects (the master compressor
and limiter) are not applied, so levels are as the catalog sets them.

    python tools/dev/chamber_room_mix.py <minute.json> <out_dir>
"""
import json
import os
import sys

import numpy as np
import soundfile as sf

SR = 44100
SECONDS = 60.0
FADE_IN = 1.5


def stereo(path):
    x, sr = sf.read(path, always_2d=True)
    assert sr == SR, (path, sr)
    return x if x.shape[1] == 2 else np.repeat(x, 2, axis=1)


def db(v):
    return 10 ** (v / 20.0)


def main():
    src, out_dir = sys.argv[1], sys.argv[2]
    m = json.load(open(src, encoding="utf-8"))
    n = int(SECONDS * SR)
    room = np.zeros((n, 2))
    bed = stereo(m["bed"])
    reps = int(np.ceil(n / len(bed))) + 1
    loop = np.tile(bed, (reps, 1))[:n]
    ramp = np.clip(np.arange(n) / (FADE_IN * SR), 0.0, 1.0)[:, None]
    room += loop * ramp * db(m["bed_db"])
    for e in m["events"]:
        x = stereo(e["file"]).mean(axis=1)
        a = (float(e["pan"]) + 1.0) * np.pi / 4.0
        s = np.stack([x * np.cos(a), x * np.sin(a)], axis=1) * np.sqrt(2.0) * db(e["db"])
        at = int(e["t"] * SR)
        end = min(n, at + len(s))
        room[at:end] += s[: end - at]
    music = stereo(m["music"])
    music = np.tile(music, (int(np.ceil(n / len(music))) + 1, 1))[:n] * db(m["music_db"])
    os.makedirs(out_dir, exist_ok=True)
    for name, y in (("chamber_room_60s.wav", room), ("chamber_room_60s_with_music.wav", room + music)):
        peak = np.abs(y).max()
        if peak > 0.98:
            y = y * (0.98 / peak)
        sf.write(os.path.join(out_dir, name), y, SR, subtype="PCM_16")
        print(name, "peak %.1f dB" % (20 * np.log10(np.abs(y).max() + 1e-9)))
    print(len(m["events"]), "sounds:", ", ".join("%.1fs %s" % (e["t"], os.path.basename(e["file"])) for e in m["events"]))


if __name__ == "__main__":
    main()
