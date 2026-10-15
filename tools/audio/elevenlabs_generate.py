"""Generate sound effects with the ElevenLabs Sound Effects API from the same prompts as sao_generate.py.

Needs your own ElevenLabs API key in the ELEVENLABS_API_KEY environment variable (commercial use of the results needs
a paid plan). Each take lands in the sound library as elevenlabs/<name>_<n>.mp3, to audition and then use in a
tools/audio/foley recipe as "lib:elevenlabs/<name>_<n>.mp3".

Usage:
    set ELEVENLABS_API_KEY=...            (PowerShell: $env:ELEVENLABS_API_KEY = "...")
    python tools/audio/elevenlabs_generate.py holy_strike
"""
from __future__ import annotations

import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))
API = "https://api.elevenlabs.io/v1/sound-generation"


def main() -> None:
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("Set ELEVENLABS_API_KEY to your ElevenLabs API key first.")
    prompts = json.loads((ROOT / "tools" / "audio" / "sao_prompts.json").read_text(encoding="utf-8"))
    args = sys.argv[1:]
    out_dir = LIBRARY / "elevenlabs"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, spec in prompts.items():
        if name.startswith("_") or (args and name not in args):
            continue
        for take in range(int(spec.get("takes", 2))):
            body = json.dumps({"text": spec["prompt"], "duration_seconds": float(spec.get("seconds", 3.0)),
                               "prompt_influence": 0.4}).encode()
            req = urllib.request.Request(API, data=body, headers={"xi-api-key": key, "Content-Type": "application/json"})
            data = urllib.request.urlopen(req, timeout=120).read()
            dest = out_dir / f"{name}_{take + 1}.mp3"
            dest.write_bytes(data)
            print(dest)


if __name__ == "__main__":
    main()
