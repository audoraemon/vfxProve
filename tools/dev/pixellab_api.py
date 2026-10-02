"""PixelLab REST helper for the PixelLab structures proof: sends images straight from disk, waits for the job, saves
every image it returns as PNG. The key comes from PIXELLAB_API_KEY, or else the `pixellab` MCP entry in ~/.claude.json;
it is never printed.

Usage (from the project root):
  python tools/dev/pixellab_api.py balance
  python tools/dev/pixellab_api.py generate --desc TEXT --size 84x76 --out DIR [--ref PATH=USAGE ...] [--seed N]
  python tools/dev/pixellab_api.py edit --image PATH --desc TEXT --out DIR [--seed N]
  python tools/dev/pixellab_api.py animate --first PATH [--last PATH] --action TEXT --frames N --out DIR [--seed N]
Each job prints its id, cost and the files it wrote; its raw response goes to DIR/<kind>_job.json (images stripped).
"""
import argparse
import base64
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request

from PIL import Image

BASE = "https://api.pixellab.ai/v2"
POLL_S = 5
TIMEOUT_S = 15 * 60


def _key():
    if os.environ.get("PIXELLAB_API_KEY"):
        return os.environ["PIXELLAB_API_KEY"]
    d = json.load(open(os.path.expanduser("~/.claude.json"), encoding="utf-8"))
    entry = d.get("mcpServers", {}).get("pixellab")
    if entry is None:
        for proj in d.get("projects", {}).values():
            if "pixellab" in proj.get("mcpServers", {}):
                entry = proj["mcpServers"]["pixellab"]
                if proj is d["projects"].get("F:/Godot/Git/vfxProve"):
                    break
    if entry is None:
        sys.exit("No PixelLab key: set PIXELLAB_API_KEY")
    return entry["headers"]["Authorization"].split(" ", 1)[1]


def _call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Authorization": "Bearer " + _key(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, {"error": raw[:500].decode(errors="replace")}


def _b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode()


def _size(path):
    with Image.open(path) as im:
        return im.size


def _image(path):
    return {"type": "base64", "base64": _b64(path), "format": "png"}


def _images_in(obj, found):
    """Every image in a response, in order: base64 dicts, data URLs and plain https URLs."""
    if isinstance(obj, dict):
        if isinstance(obj.get("base64"), str) and len(obj["base64"]) > 100:
            found.append(("b64", obj["base64"]))
            return
        for v in obj.values():
            _images_in(v, found)
    elif isinstance(obj, list):
        for v in obj:
            _images_in(v, found)
    elif isinstance(obj, str):
        if obj.startswith("data:image"):
            found.append(("b64", obj.split(",", 1)[1]))
        elif obj.startswith("https://") and any(obj.split("?")[0].endswith(x) for x in (".png", ".webp", ".jpg")):
            found.append(("url", obj))


def _strip(obj):
    if isinstance(obj, dict):
        return {k: ("<base64>" if k == "base64" and isinstance(v, str) else _strip(v)) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_strip(v) for v in obj]
    return obj


def _balance():
    st, b = _call("GET", "/balance")
    sub = b.get("subscription", {})
    return "%s %s/%s generations, $%.2f credits" % (sub.get("status"), sub.get("generations"), sub.get("total"),
                                                     b.get("credits", {}).get("usd", 0.0))


def _run(kind, path, body, out):
    os.makedirs(out, exist_ok=True)
    before = _balance()
    st, r = _call("POST", path, body)
    job = r.get("background_job_id")
    if st >= 300 or not job:
        sys.exit("%s failed (%d): %s" % (kind, st, json.dumps(r)[:800]))
    print("%s job %s submitted (balance before: %s)" % (kind, job, before))
    t0 = time.time()
    while True:
        time.sleep(POLL_S)
        st, j = _call("GET", "/background-jobs/" + job)
        status = j.get("status")
        if status in ("completed", "failed", "cancelled"):
            break
        if time.time() - t0 > TIMEOUT_S:
            sys.exit("%s job %s still %s after %d s" % (kind, job, status, TIMEOUT_S))
    with open(os.path.join(out, kind + "_job.json"), "w", encoding="utf-8") as f:
        json.dump(_strip(j), f, indent=1)
    if status != "completed":
        sys.exit("%s job %s %s: %s" % (kind, job, status, json.dumps(_strip(j))[:800]))
    found = []
    _images_in(j.get("last_response", j), found)
    written = []
    for i, (how, data) in enumerate(found):
        raw = base64.b64decode(data) if how == "b64" else urllib.request.urlopen(data, timeout=60).read()
        p = os.path.join(out, "%s_%02d.png" % (kind, i))
        Image.open(io.BytesIO(raw)).save(p)
        written.append(p)
    print("%s job %s done in %d s; %d images -> %s" % (kind, job, time.time() - t0, len(written), out))
    print("  usage: %s; balance after: %s" % (json.dumps(j.get("usage")), _balance()))
    return written


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance")
    g = sub.add_parser("generate")
    g.add_argument("--desc", required=True)
    g.add_argument("--size", required=True)
    g.add_argument("--ref", action="append", default=[], help="PATH=how to use it")
    g.add_argument("--seed", type=int)
    g.add_argument("--out", required=True)
    e = sub.add_parser("edit")
    e.add_argument("--image", required=True)
    e.add_argument("--desc", required=True)
    e.add_argument("--seed", type=int)
    e.add_argument("--out", required=True)
    a = sub.add_parser("animate")
    a.add_argument("--first", required=True)
    a.add_argument("--last")
    a.add_argument("--action", required=True)
    a.add_argument("--frames", type=int, default=8)
    a.add_argument("--seed", type=int)
    a.add_argument("--out", required=True)
    args = ap.parse_args()

    if args.cmd == "balance":
        print(_balance())
    elif args.cmd == "generate":
        w, h = (int(v) for v in args.size.lower().split("x"))
        refs = []
        for item in args.ref:
            p, _, usage = item.partition("=")
            rw, rh = _size(p)
            refs.append({"image": _image(p), "size": {"width": rw, "height": rh}, "usage_description": usage or None})
        body = {"description": args.desc, "image_size": {"width": w, "height": h}, "no_background": True,
                "reference_images": refs or None, "seed": args.seed}
        _run("generate", "/generate-image-v2", body, args.out)
    elif args.cmd == "edit":
        w, h = _size(args.image)
        body = {"method": "edit_with_text", "description": args.desc, "no_background": True, "seed": args.seed,
                "image_size": {"width": w, "height": h},
                "edit_images": [{"image": _image(args.image), "width": w, "height": h}]}
        _run("edit", "/edit-images-v2", body, args.out)
    elif args.cmd == "animate":
        body = {"first_frame": _image(args.first), "action": args.action, "frame_count": args.frames,
                "no_background": True, "seed": args.seed}
        if args.last:
            body["last_frame"] = _image(args.last)
        _run("animate", "/animate-with-text-v3", body, args.out)


if __name__ == "__main__":
    main()
