#!/usr/bin/env python
"""Loudness of every catalogued sound, and what a player hears (v0.11.2, spec 2.4).

    python tools/audio/loudness.py                write tools/audio/loudness.tsv (cue, file, lufs, peak_dbtp)
    python tools/audio/loudness.py --check        exit 1 if a WAV differs from its row by more than 0.1, or has none
    python tools/audio/loudness.py --table        played level of every power's cues, the loud median and the floor
    python tools/audio/loudness.py --mix CUE...   tools/audio/ab/v0112/mix_<cue>.wav: 4 s of music_theme at Music.DB with the
                                                  cue at its played level at 1.0 s (CUE[@offset] overrides the call offset)

Integrated loudness is ITU-R BS.1770-4 (K-weighting, 400 ms blocks every 100 ms, absolute gate -70 LUFS, relative gate
-10 LU; a file under 0.4 s is measured on 100 ms blocks every 25 ms). True peak is the largest sample of the 4x
oversampled signal. A file with nothing above the absolute gate reads SILENT_LUFS.

Played level = the file's LUFS + the catalog's `db` + the call's offset (a non-literal offset counts as its largest
literal); a cue with variants counts as its loudest variant. tests/test_power_sounds.gd reads the TSV and does the same.
Needs numpy, scipy and soundfile. Run from anywhere; paths are relative to the repo root.
"""
import argparse
import math
import os
import re
import sys

import numpy as np
import soundfile as sf
from scipy.signal import lfilter, resample_poly

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SFX = os.path.join(ROOT, "src", "audio", "sfx.gd")
MUSIC = os.path.join(ROOT, "src", "audio", "music.gd")
POWER_BOOK = os.path.join(ROOT, "src", "game", "power_book.gd")
TSV = os.path.join(ROOT, "tools", "audio", "loudness.tsv")
MIX_DIR = os.path.join(ROOT, "tools", "audio", "ab", "v0112")

SILENT_LUFS = -70.0
TOLERANCE = 0.1
FLOOR_STEP = 0.5  # QUIET_FLOOR is the loud median - 6 LU rounded down to this
FLOOR_BELOW = 6.0
MIX_SECONDS = 4.0
MIX_AT = 1.0


# ---------------------------------------------------------------------------------------------------- measuring

def _biquad(fs, gain_db, q, fc, high_shelf):
    k = math.tan(math.pi * fc / fs)
    vh = 10.0 ** (gain_db / 20.0)
    vb = vh ** 0.4996667741545416
    a0 = 1.0 + k / q + k * k
    a = np.array([1.0, 2.0 * (k * k - 1.0) / a0, (1.0 - k / q + k * k) / a0])
    if high_shelf:
        b = np.array([(vh + vb * k / q + k * k) / a0, 2.0 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0])
    else:
        b = np.array([1.0, -2.0, 1.0])
    return b, a


def k_weight(x, fs):
    """x: (samples, channels). BS.1770-4 stage 1 (high shelf) then stage 2 (high pass)."""
    b1, a1 = _biquad(fs, 3.999843853973347, 0.7071752369554196, 1681.9744509555319, True)
    b2, a2 = _biquad(fs, 0.0, 0.5003270373238773, 38.13547087602444, False)
    return lfilter(b2, a2, lfilter(b1, a1, x, axis=0), axis=0)


def integrated_lufs(x, fs):
    n = x.shape[0]
    if n == 0:
        return SILENT_LUFS
    y = k_weight(x, fs)
    block, step = (0.4, 0.1) if n / fs >= 0.4 else (0.1, 0.025)
    size = min(n, int(round(block * fs)))
    hop = max(1, int(round(step * fs)))
    starts = range(0, max(1, n - size + 1), hop)
    z = np.array([np.mean(y[s:s + size] ** 2, axis=0) for s in starts])  # (blocks, channels), weights all 1.0
    power = z.sum(axis=1)
    with np.errstate(divide="ignore"):
        loud = -0.691 + 10.0 * np.log10(power)
    kept = power[loud > -70.0]
    if kept.size == 0:
        return SILENT_LUFS
    relative = -0.691 + 10.0 * math.log10(kept.mean()) - 10.0
    kept = power[(loud > -70.0) & (loud > relative)]
    if kept.size == 0:
        return SILENT_LUFS
    return -0.691 + 10.0 * math.log10(kept.mean())


def true_peak_db(x):
    peak = float(np.max(np.abs(resample_poly(x, 4, 1, axis=0)))) if x.shape[0] else 0.0
    return 20.0 * math.log10(peak) if peak > 0.0 else -120.0


def measure(path):
    x, fs = sf.read(path, dtype="float64", always_2d=True)
    return round(integrated_lufs(x, fs), 2), round(true_peak_db(x), 2)


# ---------------------------------------------------------------------------------------------------- the sources

def catalog():
    """[(cue, res_path, db, loop)] for every file of every cue, variants expanded, in catalog order."""
    rows = []
    cues = {}
    with open(SFX, encoding="utf-8") as f:
        for line in f:
            m = re.match(r'\s*&"(\w+)":\s*\{(.*)\},?\s*$', line)
            if not m:
                continue
            body = m.group(2)
            path = re.search(r'"path":\s*"([^"]+)"', body).group(1)
            variants = re.search(r'"variants":\s*(\d+)', body)
            db = re.search(r'"db":\s*(-?[0-9.]+)', body)
            cues[m.group(1)] = float(db.group(1)) if db else 0.0
            n = int(variants.group(1)) if variants else 0
            for p in ([path % i for i in range(1, n + 1)] if n else [path]):
                rows.append((m.group(1), p, cues[m.group(1)]))
    return rows


def music_db():
    with open(MUSIC, encoding="utf-8") as f:
        return float(re.search(r"^const DB\s*:?=\s*(-?[0-9.]+)", f.read(), re.M).group(1))


def res_to_file(res):
    return os.path.join(ROOT, res.replace("res://", "").replace("/", os.sep))


def read_tsv():
    rows = []
    if not os.path.exists(TSV):
        return rows
    with open(TSV, encoding="utf-8") as f:
        for line in f.read().splitlines()[1:]:
            cue, file, lufs, peak = line.split("\t")
            rows.append((cue, file, float(lufs), float(peak)))
    return rows


def write_tsv():
    rows = ["cue\tfile\tlufs\tpeak_dbtp"]
    for cue, res, _db in catalog():
        lufs, peak = measure(res_to_file(res))
        rows.append("%s\t%s\t%.2f\t%.2f" % (cue, res, lufs, peak))
    with open(TSV, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(rows) + "\n")
    print("wrote %d rows to %s" % (len(rows) - 1, os.path.relpath(TSV, ROOT)))


def check():
    have = {file: (lufs, peak) for _cue, file, lufs, peak in read_tsv()}
    bad = 0
    wanted = set()
    for cue, res, _db in catalog():
        wanted.add(res)
        if res not in have:
            print("MISSING row: %s (%s)" % (res, cue))
            bad += 1
            continue
        lufs, peak = measure(res_to_file(res))
        if abs(lufs - have[res][0]) > TOLERANCE or abs(peak - have[res][1]) > TOLERANCE:
            print("DIFFERS: %s  file %.2f / %.2f  row %.2f / %.2f" % (res, lufs, peak, have[res][0], have[res][1]))
            bad += 1
    for res in have:
        if res not in wanted:
            print("note: row for a file the catalog no longer plays: %s" % res)
    print("loudness check: %d files, %d bad" % (len(wanted), bad))
    return 1 if bad else 0


# ---------------------------------------------------------------------------------------------------- the powers

def _split_args(text):
    """The top-level comma-separated arguments of a call whose '(' has just been consumed; returns (args, end)."""
    args, depth, cur = [], 0, ""
    i = 0
    while i < len(text):
        c = text[i]
        if c in "([{":
            depth += 1
        elif c in ")]}":
            if depth == 0:
                args.append(cur.strip())
                return args, i
            depth -= 1
        if c == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
        else:
            cur += c
        i += 1
    return args, len(text)


def script_plays(path):
    """[(cue, offset)] for every `.play(&"cue", pos, offset)` in a script; offset = its largest literal, else 0."""
    with open(res_to_file(path), encoding="utf-8") as f:
        src = f.read()
    out = []
    for m in re.finditer(r'\.play\(\s*&"(\w+)"', src):
        args, _ = _split_args(src[m.end():])
        offset = 0.0
        if len(args) >= 3 and args[2] != "":
            lits = [float(v) for v in re.findall(r"(?<![\w.])-?\d+\.\d+", args[2])]
            offset = max(lits) if lits else 0.0
        out.append((m.group(1), offset))
    return out


def powers():
    """[(key, path, quiet)] in book order."""
    with open(POWER_BOOK, encoding="utf-8") as f:
        src = f.read()
    src = src[src.index("const POWERS"):src.index("const ICON_DIR")]
    starts = [m for m in re.finditer(r'\{"key": "(\w+)", "name": "[^"]*", "path": "([^"]+)"', src)]
    out = []
    for i, m in enumerate(starts):
        end = starts[i + 1].start() if i + 1 < len(starts) else len(src)
        out.append((m.group(1), m.group(2), '"quiet": true' in src[m.end():end]))
    return out


def cue_lufs():
    """cue -> loudest variant's LUFS, from the TSV."""
    best = {}
    for cue, _file, lufs, _peak in read_tsv():
        best[cue] = max(lufs, best.get(cue, -999.0))
    return best


def played(cue, db, offset, lufs):
    return lufs[cue] + db[cue] + offset


def table():
    lufs = cue_lufs()
    db = {}
    for cue, _res, d in catalog():
        db[cue] = d
    mains = []
    print("%-12s %-5s %-18s %8s   cues (played dB)" % ("power", "kind", "main cue", "played"))
    for key, path, quiet in powers():
        plays = [(c, o) for c, o in script_plays(path) if c in db and c in lufs]
        if not plays:
            print("%-12s %-5s %s" % (key, "quiet" if quiet else "loud", "(no catalogued cue)"))
            continue
        levels = sorted(((played(c, db, o, lufs), c) for c, o in plays), reverse=True)
        if not quiet:
            mains.append(levels[0][0])
        print("%-12s %-5s %-18s %8.1f   %s" % (key, "quiet" if quiet else "loud", levels[0][1], levels[0][0],
              ", ".join("%s %.1f" % (c, v) for v, c in levels)))
    median = float(np.median(mains))
    floor = math.floor((median - FLOOR_BELOW) / FLOOR_STEP) * FLOOR_STEP
    print("\nloud powers: %d   median main-cue played level %.2f   QUIET_FLOOR %.1f (median - %.0f, rounded down to %.1f)" % (
        len(mains), median, floor, FLOOR_BELOW, FLOOR_STEP))
    print("death targets: cit_death / sol_death %.1f +-2, cit_fall %.1f +-2, crowd_death_wave <= %.1f" % (
        median - 4, median - 9, median))
    for cue in ("cit_death", "cit_fall", "sol_death", "crowd_death_wave"):
        if cue in lufs:
            print("  %-17s file %.2f LUFS, catalog %.1f dB -> played %.1f" % (cue, lufs[cue], db[cue], lufs[cue] + db[cue]))
    return 0


# ---------------------------------------------------------------------------------------------------- the sheet's mixes

def mix(specs):
    lufs = cue_lufs()
    plays = {}
    for key, path, _quiet in powers():
        for c, o in script_plays(path):
            plays[c] = max(o, plays.get(c, -999.0))
    rows = {}
    for cue, res, d in catalog():
        rows.setdefault(cue, []).append((res, d))
    os.makedirs(MIX_DIR, exist_ok=True)
    theme, fs = sf.read(res_to_file("res://assets/audio/music/music_theme.wav"), dtype="float64", always_2d=True)
    n = int(MIX_SECONDS * fs)
    bed = theme[:n, :1] * 10.0 ** (music_db() / 20.0)
    for spec in specs:
        cue, _, off = spec.partition("@")
        if cue not in rows:
            print("unknown cue: " + cue)
            return 1
        offset = float(off) if off else plays.get(cue, 0.0)
        # The loudest variant stands for the cue (the same rule as the played level the floor test reads).
        files = [(measure(res_to_file(res))[0], res, d) for res, d in rows[cue]]
        _l, res, d = max(files)
        x, xfs = sf.read(res_to_file(res), dtype="float64", always_2d=True)
        x = x[:, :1]
        if xfs != fs:
            x = resample_poly(x, int(fs), int(xfs), axis=0)
        out = bed.copy()
        at = int(MIX_AT * fs)
        end = min(n, at + x.shape[0])
        out[at:end] += x[:end - at] * 10.0 ** ((d + offset) / 20.0)
        peak = float(np.max(np.abs(out)))
        if peak > 1.0:
            print("note: %s clips by %.1f dB in the mix (the game's limiter would take it)" % (cue, 20.0 * math.log10(peak)))
            out = out / peak
        dest = os.path.join(MIX_DIR, "mix_%s.wav" % cue)
        sf.write(dest, out, int(fs), subtype="PCM_16")
        print("wrote %s  (%s at catalog %+.1f dB, call offset %+.1f)" % (os.path.relpath(dest, ROOT), os.path.basename(res), d, offset))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--table", action="store_true")
    ap.add_argument("--mix", nargs="+", metavar="CUE")
    a = ap.parse_args()
    if a.check:
        return check()
    if a.table:
        return table()
    if a.mix:
        return mix(a.mix)
    write_tsv()
    return 0


if __name__ == "__main__":
    sys.exit(main())
