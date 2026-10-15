"""Generate sound effects with Stable Audio Open in the local ComfyUI, for sounds no recording library has.

Running the model means accepting the Stability AI Community License (the checkpoint folder holds a copy):
free under US$1M a year in revenue; commercial use needs a free registration at https://stability.ai/community-license.

Needs ComfyUI running (C:/BURIN_NITRO/ComfyUI/run.bat, http://127.0.0.1:8188) with
models/checkpoints/stable-audio-open-1.0.safetensors and models/text_encoders/t5-base.safetensors.

Prompts are in tools/audio/sao_prompts.json: {"name": {"prompt": ..., "seconds": 3, "takes": 4}}. Each take lands in
the sound library as sao/<name>_<seed>.wav, to audition and then use in a tools/audio/foley recipe as
"lib:sao/<name>_<seed>.wav".

Usage:
    python tools/audio/sao_generate.py              # every prompt
    python tools/audio/sao_generate.py holy_strike  # one
"""
from __future__ import annotations

import json
import os
import shutil
import sys
import time
import urllib.request
from pathlib import Path

import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
SERVER = os.environ.get("COMFYUI", "http://127.0.0.1:8188")
COMFY_OUT = Path(os.environ.get("COMFYUI_OUTPUT", "C:/BURIN_NITRO/ComfyUI/ComfyUI/output"))
LIBRARY = Path(os.environ.get("KAK_SOUND_LIBRARY", "C:/BURIN_NITRO/SoundLibrary"))
NEGATIVE = "music, melody, speech, voice, low quality, distorted, clipping, noise floor"


def workflow(prompt: str, seconds: float, seed: int, prefix: str) -> dict:
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "stable-audio-open-1.0.safetensors"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "t5-base.safetensors", "type": "stable_audio"}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": ["2", 0]}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": NEGATIVE, "clip": ["2", 0]}},
        "5": {"class_type": "ConditioningStableAudio",
              "inputs": {"positive": ["3", 0], "negative": ["4", 0], "seconds_start": 0.0, "seconds_total": seconds}},
        "6": {"class_type": "EmptyLatentAudio", "inputs": {"seconds": seconds, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["5", 0], "negative": ["5", 1],
                                                   "latent_image": ["6", 0], "seed": seed, "steps": 50, "cfg": 5.0,
                                                   "sampler_name": "dpmpp_3m_sde_gpu", "scheduler": "exponential",
                                                   "denoise": 1.0}},
        "8": {"class_type": "VAEDecodeAudio", "inputs": {"samples": ["7", 0], "vae": ["1", 2]}},
        "9": {"class_type": "SaveAudio", "inputs": {"audio": ["8", 0], "filename_prefix": prefix}},
    }


def post(path: str, body: dict) -> dict:
    req = urllib.request.Request(SERVER + path, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())


def get(path: str) -> dict:
    return json.loads(urllib.request.urlopen(SERVER + path, timeout=30).read())


def main() -> None:
    prompts = json.loads((ROOT / "tools" / "audio" / "sao_prompts.json").read_text(encoding="utf-8"))
    args = sys.argv[1:]
    try:
        get("/system_stats")
    except Exception:
        sys.exit(f"ComfyUI is not answering at {SERVER}: start C:/BURIN_NITRO/ComfyUI/run.bat first")
    out_dir = LIBRARY / "sao"
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, spec in prompts.items():
        if name.startswith("_") or (args and name not in args):
            continue
        for take in range(int(spec.get("takes", 4))):
            seed = 1000 + take
            prefix = f"kak_sao/{name}_{seed}"
            pid = post("/prompt", {"prompt": workflow(spec["prompt"], float(spec.get("seconds", 3.0)), seed, prefix)})["prompt_id"]
            while True:
                time.sleep(2)
                hist = get(f"/history/{pid}")
                if pid in hist:
                    break
            files = [f for node in hist[pid]["outputs"].values() for f in node.get("audio", [])]
            if not files:
                print(f"{name} take {take}: no audio ({hist[pid].get('status', {})})")
                continue
            f = files[0]
            src = COMFY_OUT / f.get("subfolder", "") / f["filename"]
            x, sr = sf.read(str(src))
            dest = out_dir / f"{name}_{seed}.wav"
            sf.write(str(dest), x, sr, subtype="PCM_16")
            print(f"{name} take {take}: {dest}")
    manifest = out_dir / "manifest.json"
    data = json.loads(manifest.read_text()) if manifest.exists() else {}
    for name, spec in prompts.items():
        if not name.startswith("_"):
            data[name] = {"title": spec["prompt"], "license": "Stable Audio Open output (Stability AI Community License)",
                          "author": "Stable Audio Open 1.0, generated locally", "url": "https://stability.ai/community-license"}
    manifest.write_text(json.dumps(data, indent=1))


if __name__ == "__main__":
    main()
