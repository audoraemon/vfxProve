"""PixelLab REST helper for the PixelLab structures proof: sends images straight from disk, waits for the job, saves
every image it returns as PNG. The key comes from PIXELLAB_API_KEY, or else the `pixellab` MCP entry in ~/.claude.json;
it is never printed.

Usage (from the project root):
  python tools/dev/pixellab_api.py balance
  python tools/dev/pixellab_api.py generate --desc TEXT --size 84x76 --out DIR [--ref PATH=USAGE ...] [--seed N]
  python tools/dev/pixellab_api.py edit --image PATH --desc TEXT --out DIR [--seed N]
  python tools/dev/pixellab_api.py animate --first PATH [--last PATH] --action TEXT --frames N --out DIR [--seed N]
  python tools/dev/pixellab_api.py character --desc TEXT --size 32 --out DIR [--seed N]   (8 directions, standard mode)
  python tools/dev/pixellab_api.py char-anim --id CHARACTER --template walking-4-frames --out DIR [--dirs a,b,..]
  python tools/dev/pixellab_api.py char-get --id CHARACTER --out DIR
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
        raw = base64.b64decode(data) if how == "b64" else _fetch_url(data)
        p = os.path.join(out, "%s_%02d.png" % (kind, i))
        Image.open(io.BytesIO(raw)).save(p)
        written.append(p)
    print("%s job %s done in %d s; %d images -> %s" % (kind, job, time.time() - t0, len(written), out))
    print("  usage: %s; balance after: %s" % (json.dumps(j.get("usage")), _balance()))
    return written


def _wait_job(job, label):
    t0 = time.time()
    while True:
        time.sleep(POLL_S)
        st, j = _call("GET", "/background-jobs/" + job)
        status = j.get("status")
        if status in ("completed", "failed", "cancelled"):
            return status, j
        if time.time() - t0 > TIMEOUT_S:
            sys.exit("%s job %s still %s after %d s" % (label, job, status, TIMEOUT_S))


def _fetch_url(url):
    # PixelLab's file host refuses Python's default user agent (403).
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return urllib.request.urlopen(req, timeout=60).read()


def _download(url, path):
    Image.open(io.BytesIO(_fetch_url(url))).save(path)


## Every rotation and animation frame of a character, as <out>/rot_<dir>.png and <out>/<anim>/<dir>_<i>.png.
def _fetch_character(cid, out):
    os.makedirs(out, exist_ok=True)
    st, c = _call("GET", "/characters/" + cid)
    if st >= 300:
        sys.exit("character %s: %d %s" % (cid, st, json.dumps(c)[:400]))
    with open(os.path.join(out, "character.json"), "w", encoding="utf-8") as f:
        json.dump(c, f, indent=1)
    n = 0
    for d, url in (c.get("rotation_urls") or {}).items():
        if url:
            _download(url, os.path.join(out, "rot_%s.png" % d))
            n += 1
    for group in c.get("animations") or []:
        name = group.get("display_name") or group.get("animation_type")
        for dr in group.get("directions", []):
            os.makedirs(os.path.join(out, name), exist_ok=True)
            for i, url in enumerate(dr.get("frames", [])):
                _download(url, os.path.join(out, name, "%s_%02d.png" % (dr["direction"], i)))
                n += 1
    print("character %s (%s): %d images -> %s" % (cid, c.get("status"), n, out))
    return c


def _groups(cid, template, name):
    st, c = _call("GET", "/characters/" + cid)
    return [g for g in (c.get("animations") or [])
            if g.get("animation_type") == template or g.get("display_name") == name]


## The directions of a character's animation (by template or name) that have frames.
def _animated_dirs(cid, template, name):
    return {d["direction"] for g in _groups(cid, template, name) for d in g.get("directions", []) if d.get("frames")}


def _group_of(cid, template, name):
    gs = _groups(cid, template, name)
    return gs[0].get("animation_group_id") if gs else None


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance")
    c = sub.add_parser("character", help="create an 8-direction character (standard mode, 1 generation)")
    c.add_argument("--desc", required=True)
    c.add_argument("--size", type=int, required=True)
    c.add_argument("--seed", type=int)
    c.add_argument("--detail", default="medium detail")
    c.add_argument("--out", required=True)
    an = sub.add_parser("char-anim", help="add a template animation to a character, then download everything")
    an.add_argument("--id", required=True)
    an.add_argument("--template", required=True)
    an.add_argument("--name")
    an.add_argument("--dirs", default="south-east,south-west,north-east,north-west")
    an.add_argument("--out", required=True)
    ip = sub.add_parser("inpaint", help="regenerate the mask's white area of an image, the rest kept as it is")
    ip.add_argument("--image", required=True)
    ip.add_argument("--mask", required=True)
    ip.add_argument("--desc", required=True)
    ip.add_argument("--seed", type=int)
    ip.add_argument("--out", required=True)
    gc = sub.add_parser("char-get", help="download a character's rotations and animations")
    gc.add_argument("--id", required=True)
    gc.add_argument("--out", required=True)
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
    elif args.cmd == "character":
        before = _balance()
        body = {"description": args.desc, "image_size": {"width": args.size, "height": args.size}, "mode": "standard",
                "view": "low top-down", "outline": "single color black outline", "shading": "medium shading",
                "detail": args.detail, "template_id": "mannequin", "seed": args.seed}
        st, r = _call("POST", "/create-character-with-8-directions", body)
        cid = r.get("character_id")
        if st >= 300 or not cid:
            sys.exit("character failed (%d): %s" % (st, json.dumps(_strip(r))[:800]))
        print("character %s submitted (balance before: %s)" % (cid, before))
        if r.get("background_job_id"):
            status, j = _wait_job(r["background_job_id"], "character")
            if status != "completed":
                sys.exit("character job %s: %s" % (status, json.dumps(_strip(j))[:600]))
        _fetch_character(cid, args.out)
        print("  balance after: %s" % _balance())
    elif args.cmd == "char-anim":
        before = _balance()
        wanted = args.dirs.split(",")
        name = args.name or args.template
        group = None
        # PixelLab takes only as many directions as it has free job slots and drops the rest: submit what is missing
        # into the same animation group until every direction has landed.
        for attempt in range(12):
            missing = [d for d in wanted if d not in _animated_dirs(args.id, args.template, name)]
            if not missing:
                break
            body = {"character_id": args.id, "mode": "template", "template_animation_id": args.template,
                    "animation_name": name, "directions": missing}
            if group:
                body["animation_group_id"] = group
            st, r = _call("POST", "/animate-character", body)
            jobs = r.get("background_job_ids") or []
            if st == 429 or (st < 300 and not jobs):
                time.sleep(15)
                continue
            if st >= 300:
                sys.exit("char-anim failed (%d): %s" % (st, json.dumps(_strip(r))[:800]))
            group = r.get("animation_group_id") or group
            print("char-anim %s on %s: %s submitted (%d of %d missing)" % (args.template, args.id, r.get("directions"),
                                                                          len(jobs), len(missing)))
            for job in jobs:
                status, j = _wait_job(job, "char-anim")
                if status != "completed":
                    print("  job %s %s: %s" % (job, status, json.dumps(_strip(j))[:300]))
            if group is None:
                group = _group_of(args.id, args.template, name)
        missing = [d for d in wanted if d not in _animated_dirs(args.id, args.template, name)]
        _fetch_character(args.id, args.out)
        print("  balance before: %s; after: %s%s" % (before, _balance(),
                                                     "; STILL MISSING %s" % missing if missing else ""))
        if missing:
            sys.exit(1)
    elif args.cmd == "inpaint":
        w, h = _size(args.image)
        body = {"description": args.desc, "seed": args.seed, "no_background": True, "crop_to_mask": True,
                "inpainting_image": {"image": _image(args.image), "size": {"width": w, "height": h}},
                "mask_image": {"image": _image(args.mask), "size": {"width": w, "height": h}}}
        _run("inpaint", "/inpaint-v3", body, args.out)
    elif args.cmd == "char-get":
        _fetch_character(args.id, args.out)
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
