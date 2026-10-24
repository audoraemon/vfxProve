#!/usr/bin/env python3
"""KAK project board for Discord.

The board lives in one or more Discord messages in the #board channel. Each
update edits those messages in place, so the channel always shows the board
as it is now.

Two halves:

  build / publish  (run locally by Claude after a Dev Ledger update)
      Reads a dump of the Dev Ledger (ArtifactData `list tasks` and `get meta/project`
      with out_dir=DIR) plus every local and remote git branch. Writes
      board/board.json (the data) and board/payload.json (the Discord messages).
      `publish` also commits and pushes the kak-board branch when something changed.

  send  (run by .github/workflows/discord-board.yml on every push)
      Posts payload.json through the DISCORD_BOARD_WEBHOOK secret. It edits the
      messages listed in board/state.json, posts any missing ones, deletes leftovers,
      then rewrites state.json.

Standard library only.
"""

import argparse
import datetime as dt
import glob
import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
BOARD_JSON = os.path.join(HERE, "board.json")
PAYLOAD_JSON = os.path.join(HERE, "payload.json")
STATE_JSON = os.path.join(HERE, "state.json")

MAIN = "feat/Develop-Main"
SKIP_BRANCHES = {"kak-board", "master", "HEAD", "origin"}
ACTIVE_DAYS = 30  # a branch with no commit for this long drops off (unless it has open tasks)
IDLE_DAYS = 7  # a branch shows "quiet" after this many days without a commit
STALE_TASK_DAYS = 14  # an in-progress task shows "quiet since" after this
RECENT_DONE = 8
TITLE_LIMIT = 110

COLOR_SUMMARY = 0xE8B04B
COLOR_ACTIVE = 0x4C8BD9
COLOR_QUIET = 0x6B7280
COLOR_MAIN = 0x3BA55C
COLOR_DONE = 0x9B6BD6

MESSAGE_CHAR_LIMIT = 5800  # Discord allows 6000 across all embeds of one message
EMBEDS_PER_MESSAGE = 10


# ---------- build ----------

def git(repo, *args, check=True):
    r = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, encoding="utf-8")
    if check and r.returncode:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.strip()}")
    return r.stdout.strip()


def load_dump(dump):
    tasks = []
    for path in sorted(glob.glob(os.path.join(dump, "tasks", "*.json"))):
        with open(path, encoding="utf-8") as f:
            row = json.load(f)
        row = row.get("data", row)  # tolerate either dump shape
        row["id"] = os.path.splitext(os.path.basename(path))[0]
        tasks.append(row)
    meta = {}
    meta_path = os.path.join(dump, "meta", "project.json")
    if os.path.exists(meta_path):
        with open(meta_path, encoding="utf-8") as f:
            meta = json.load(f)
        meta = meta.get("data", meta)
    if not tasks:
        sys.exit(f"No tasks found under {dump}/tasks -- dump the Ledger first.")
    return tasks, meta


def branch_refs(repo):
    """name -> ref, preferring the local branch over origin's copy."""
    refs = {}
    for name in git(repo, "for-each-ref", "--format=%(refname:short)", "refs/remotes/origin").splitlines():
        short = name.removeprefix("origin/")
        if short not in SKIP_BRANCHES:
            refs[short] = name
    for name in git(repo, "for-each-ref", "--format=%(refname:short)", "refs/heads").splitlines():
        if name not in SKIP_BRANCHES:
            refs[name] = name
    return refs


def commit_info(repo, ref):
    date, subject = git(repo, "log", "-1", "--no-merges", "--format=%cs%x00%s", ref).split("\x00", 1)
    return date, subject


def days_since(date_str, today):
    try:
        return (today - dt.date.fromisoformat(date_str[:10])).days
    except ValueError:
        return 0


def collect_branches(repo, tasks, today):
    refs = branch_refs(repo)
    base = f"origin/{MAIN}" if git(repo, "rev-parse", "--verify", "-q", f"origin/{MAIN}", check=False) else MAIN
    task_branches = {t.get("branch") for t in tasks if t.get("branch") and t.get("status") != "done"}
    found = {}
    for name, ref in refs.items():
        if name == MAIN:
            continue
        ahead = int(git(repo, "rev-list", "--count", f"{base}..{ref}"))
        date, subject = commit_info(repo, ref)
        has_tasks = name in task_branches
        if not has_tasks and (ahead == 0 or days_since(date, today) > ACTIVE_DAYS):
            continue
        behind = int(git(repo, "rev-list", "--count", f"{ref}..{base}"))
        found[name] = {"name": name, "ref": ref, "ahead": ahead, "behind": behind,
                       "date": date, "subject": subject, "pushed": ref.startswith("origin/")
                       or bool(git(repo, "rev-parse", "--verify", "-q", f"origin/{name}", check=False))}
    # Drop task branches (v012/t3 ...) already merged into another listed branch.
    for name in list(found):
        if name in task_branches:
            continue
        for other in found:
            if other != name and found[other]["ahead"] > found[name]["ahead"] and subprocess.run(
                    ["git", "-C", repo, "merge-base", "--is-ancestor", found[name]["ref"], found[other]["ref"]]
            ).returncode == 0:
                del found[name]
                break
    for b in found.values():
        del b["ref"]
    main_date, main_subject = commit_info(repo, base)
    main = {"name": MAIN, "date": main_date, "subject": main_subject}
    return sorted(found.values(), key=lambda b: (b["date"], b["ahead"]), reverse=True), main


def snapshot(tasks, meta, branches, main):
    keep = ("title", "status", "area", "version", "needs_you", "branch", "updated", "order")
    return {
        "project": {k: meta.get(k) for k in ("version", "tag", "tests", "updated") if meta.get(k) is not None},
        "tasks": {t["id"]: {k: t.get(k) for k in keep if t.get(k) not in (None, "")} for t in tasks},
        "branches": branches,
        "main": main,
    }


def content_hash(snap):
    return hashlib.sha256(json.dumps(snap, sort_keys=True).encode("utf-8")).hexdigest()[:16]


def diff_tasks(old, new):
    """Lines like 'Done: X' for status changes since the previous board."""
    words = {"doing": "Started", "done": "Done", "todo": "Back to to-do"}
    out = []
    for tid, t in new.items():
        before = old.get(tid)
        if before is None:
            out.append(f"New: {t['title']}" + (" (in progress)" if t.get("status") == "doing" else ""))
        elif before.get("status") != t.get("status"):
            out.append(f"{words.get(t.get('status'), t.get('status'))}: {t['title']}")
    for tid, t in old.items():
        if tid not in new:
            out.append(f"Removed: {t['title']}")
    order = {"Done": 0, "Started": 1, "New": 2, "Back to to-do": 3, "Removed": 4}
    return sorted(out, key=lambda s: order.get(s.split(":")[0], 9))


def short(text, limit):
    text = " ".join(str(text).split())
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def task_line(t, today):
    line = f"• {short(t['title'], TITLE_LIMIT)}"
    if t.get("needs_you"):
        line += " — **needs you**"
    if t.get("status") == "doing" and t.get("updated") and days_since(t["updated"], today) > STALE_TASK_DAYS:
        line += f" _(quiet since {t['updated'][5:]})_"
    return line


def task_block(heading, items, today):
    if not items:
        return ""
    items = sorted(items, key=lambda t: (not t.get("needs_you"), -(t.get("order") or 0)))
    return f"**{heading}** ({len(items)})\n" + "\n".join(task_line(t, today) for t in items)


def branch_status(b, today):
    age = days_since(b["date"], today)
    when = "today" if age == 0 else ("yesterday" if age == 1 else f"{age} days ago")
    if b["ahead"]:
        head = f"{b['ahead']} commit{'s' if b['ahead'] != 1 else ''} not in Develop-Main"
    else:
        head = "merged into Develop-Main"
    where = "" if b["pushed"] else " · local only"
    return f"{head} · last commit {when}{where}\n> {short(b['subject'], 150)}"


def render(snap, changes, updated_at, today):
    tasks = list(snap["tasks"].values())
    open_tasks = [t for t in tasks if t.get("status") in ("doing", "todo")]
    counts = {s: sum(1 for t in tasks if t.get("status") == s) for s in ("doing", "todo", "done")}
    shown_branches = {b["name"] for b in snap["branches"]}

    proj = snap["project"]
    head = f"**{proj.get('version', '?')}** is the latest release" + (f" (`{proj['tag']}`)" if proj.get("tag") else "")
    summary = [head,
               f"**{counts['doing']}** in progress · **{counts['todo']}** to do · **{counts['done']}** done",
               f"**{len(shown_branches)}** active branch{'es' if len(shown_branches) != 1 else ''} besides Develop-Main"]
    if changes["items"]:
        summary.append(f"\n**Since the last update** ({changes['date']})")
        summary += [f"• {short(c, 140)}" for c in changes["items"][:12]]
        if len(changes["items"]) > 12:
            summary.append(f"• …and {len(changes['items']) - 12} more")
    embeds = [{
        "title": "KAK project board",
        "description": "\n".join(summary),
        "color": COLOR_SUMMARY,
        "footer": {"text": "Updated"},
        "timestamp": updated_at,
    }]

    for b in snap["branches"]:
        mine = [t for t in open_tasks if t.get("branch") == b["name"]]
        parts = [branch_status(b, today),
                 task_block("In progress", [t for t in mine if t.get("status") == "doing"], today),
                 task_block("To do", [t for t in mine if t.get("status") == "todo"], today)]
        if not mine:
            parts.append("_No Ledger task points at this branch._")
        quiet = days_since(b["date"], today) > IDLE_DAYS
        embeds.append({"title": b["name"], "description": "\n\n".join(p for p in parts if p),
                       "color": COLOR_QUIET if quiet else COLOR_ACTIVE})

    main_tasks = [t for t in open_tasks if t.get("branch") not in shown_branches]
    m = snap["main"]
    parts = [f"Main line · last commit {m['date']}\n> {short(m['subject'], 150)}",
             task_block("In progress", [t for t in main_tasks if t.get("status") == "doing"], today),
             task_block("To do", [t for t in main_tasks if t.get("status") == "todo"], today)]
    embeds.append({"title": MAIN, "description": fit("\n\n".join(p for p in parts if p)), "color": COLOR_MAIN})

    done = sorted([t for t in tasks if t.get("status") == "done"],
                  key=lambda t: (t.get("updated") or "", t.get("order") or 0), reverse=True)[:RECENT_DONE]
    if done:
        lines = [f"• {short(t['title'], TITLE_LIMIT)} _({(t.get('updated') or '')[5:]})_" for t in done]
        embeds.append({"title": "Recently done", "description": "\n".join(lines), "color": COLOR_DONE})

    for e in embeds:
        e["description"] = fit(e["description"])
    return chunk(embeds)


def fit(text, limit=4000):
    if len(text) <= limit:
        return text
    lines, kept, size = text.split("\n"), [], 0
    for line in lines:
        if size + len(line) + 1 > limit - 40:
            break
        kept.append(line)
        size += len(line) + 1
    return "\n".join(kept) + f"\n• …and {len(lines) - len(kept)} more lines"


def embed_size(e):
    return len(e.get("title", "")) + len(e.get("description", "")) + len(e.get("footer", {}).get("text", ""))


def chunk(embeds):
    messages, current, size = [], [], 0
    for e in embeds:
        s = embed_size(e)
        if current and (len(current) == EMBEDS_PER_MESSAGE or size + s > MESSAGE_CHAR_LIMIT):
            messages.append(current)
            current, size = [], 0
        current.append(e)
        size += s
    if current:
        messages.append(current)
    return [{"allowed_mentions": {"parse": []}, "embeds": m} for m in messages]


def build(dump, repo):
    tasks, meta = load_dump(dump)
    now = dt.datetime.now().astimezone()
    today = now.date()
    branches, main = collect_branches(repo, tasks, today)
    snap = snapshot(tasks, meta, branches, main)
    digest = content_hash(snap)

    previous = {}
    if os.path.exists(BOARD_JSON):
        with open(BOARD_JSON, encoding="utf-8") as f:
            previous = json.load(f)
    if previous.get("hash") == digest:
        print("Board unchanged; nothing to write.")
        return False

    items = diff_tasks(previous.get("snapshot", {}).get("tasks", {}), snap["tasks"]) if previous else []
    changes = {"date": f"<t:{int(now.timestamp())}:f>", "items": items}  # Discord shows it in local time if items else previous.get("changes", {"date": "", "items": []})
    updated_at = now.isoformat(timespec="seconds")
    messages = render(snap, changes, updated_at, today)

    with open(BOARD_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"hash": digest, "updated": updated_at, "changes": changes, "snapshot": snap},
                  f, indent=1, ensure_ascii=False)
        f.write("\n")
    with open(PAYLOAD_JSON, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"messages": messages}, f, indent=1, ensure_ascii=False)
        f.write("\n")
    print(f"Board written: {len(snap['tasks'])} tasks, {len(branches)} branches, "
          f"{len(messages)} message(s), {len(items)} change(s).")
    for c in items:
        print("  " + c)
    return True


def publish(dump, repo):
    if not build(dump, repo):
        return
    wt = os.path.dirname(HERE)
    git(wt, "add", "board/board.json", "board/payload.json")
    if not git(wt, "diff", "--cached", "--name-only"):
        print("Nothing staged.")
        return
    git(wt, "commit", "-q", "-m", "board: update from the Dev Ledger")
    if git(wt, "ls-remote", "--heads", "origin", "kak-board", check=False):
        git(wt, "pull", "-q", "--rebase", "origin", "kak-board")
    git(wt, "push", "-q", "-u", "origin", "HEAD:kak-board")
    print("Pushed kak-board; the Action will refresh #board.")


# ---------- send ----------

def call(method, url, payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    for attempt in range(5):
        req = urllib.request.Request(url, data=data, method=method, headers={
            "Content-Type": "application/json",
            "User-Agent": "KAK-board (github.com/audoraemon/vfxProve, 1.0)"})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode("utf-8")
                return resp.status, (json.loads(body) if body else {})
        except urllib.error.HTTPError as err:
            body = err.read().decode("utf-8", "replace")
            if err.code == 429 and attempt < 4:
                wait = float(json.loads(body or "{}").get("retry_after", 2))
                time.sleep(min(wait, 30) + 0.5)
                continue
            return err.code, {"error": body[:400]}
    return 429, {"error": "rate limited"}


def hook_url(base, suffix="", **query):
    parts = urllib.parse.urlsplit(base)
    q = dict(urllib.parse.parse_qsl(parts.query))
    q.update({k: v for k, v in query.items() if v is not None})
    return urllib.parse.urlunsplit((parts.scheme, parts.netloc, parts.path.rstrip("/") + suffix,
                                    urllib.parse.urlencode(q), ""))


def send(dry_run=False):
    with open(PAYLOAD_JSON, encoding="utf-8") as f:
        messages = json.load(f)["messages"]
    state = {"message_ids": []}
    if os.path.exists(STATE_JSON):
        with open(STATE_JSON, encoding="utf-8") as f:
            state = json.load(f)
    webhook = os.environ.get("DISCORD_BOARD_WEBHOOK", "").strip()
    if dry_run or not webhook:
        if not webhook:
            print("DISCORD_BOARD_WEBHOOK is not set; printing the board instead of sending it.")
        print(json.dumps(messages, indent=1, ensure_ascii=False)[:20000])
        return

    old_ids = list(state.get("message_ids", []))
    new_ids = []
    for i, msg in enumerate(messages):
        mid = old_ids[i] if i < len(old_ids) else None
        if mid:
            code, _ = call("PATCH", hook_url(webhook, f"/messages/{mid}"), msg)
            if code == 200:
                new_ids.append(mid)
                print(f"Edited board message {i + 1}.")
                continue
            print(f"Board message {i + 1} could not be edited (HTTP {code}); posting it again.")
        code, body = call("POST", hook_url(webhook, wait="true"), {"username": "KAK Board", **msg})
        if code not in (200, 204):
            sys.exit(f"Discord refused the board: HTTP {code} {body.get('error', '')}")
        new_ids.append(body["id"])
        print(f"Posted board message {i + 1}.")
    for mid in old_ids[len(messages):]:
        code, _ = call("DELETE", hook_url(webhook, f"/messages/{mid}"))
        print(f"Deleted an extra board message (HTTP {code}).")

    if new_ids != old_ids:
        with open(STATE_JSON, "w", encoding="utf-8", newline="\n") as f:
            json.dump({"message_ids": new_ids}, f, indent=1)
            f.write("\n")
        print("state.json updated.")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("build", "publish"):
        p = sub.add_parser(name)
        p.add_argument("--dump", required=True, help="ArtifactData out_dir holding tasks/ and meta/")
        p.add_argument("--repo", default=os.path.dirname(HERE), help="any checkout of the KAK repo")
    s = sub.add_parser("send")
    s.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if args.cmd == "build":
        build(args.dump, args.repo)
    elif args.cmd == "publish":
        publish(args.dump, args.repo)
    else:
        send(args.dry_run)


if __name__ == "__main__":
    main()
