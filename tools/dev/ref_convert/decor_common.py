"""Shared writer for the decor sets (decor batch 4): each set is one still, assets/pixellab/decor/<name>/intact.png, with
a line in assets/pixellab/decor/manifest.json (DecorSprites reads it): {"size": [w, h], "anchor": [x, y]} plus
"segment" (ground units) for a run kind's set. The manifest keeps one entry per line, tab indent, LF newlines; writing
an existing name replaces its line in place, new names are appended.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import convert  # noqa: E402

ROOT = convert.ROOT
DECOR = ROOT / "assets" / "pixellab" / "decor"
MANIFEST = DECOR / "manifest.json"


def write_set(name, img, anchor, segment=None):
    """Save `img` (PIL RGBA image) as DECOR/<name>/intact.png and insert or replace its manifest line."""
    out = DECOR / name
    out.mkdir(parents=True, exist_ok=True)
    img.save(out / "intact.png")
    entry = {"size": [img.width, img.height], "anchor": [int(anchor[0]), int(anchor[1])]}
    if segment is not None:
        entry["segment"] = segment
    man = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    man[name] = entry   # dicts keep insertion order: an existing name stays on its line, a new one goes last
    text = "{\n" + ",\n".join("\t" + json.dumps(k) + ": " + json.dumps(v) for k, v in man.items()) + "\n}\n"
    MANIFEST.write_text(text, encoding="utf-8", newline="\n")
    return out / "intact.png"
