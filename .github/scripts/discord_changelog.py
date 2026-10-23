#!/usr/bin/env python3
"""Post a KAK changelog summary to a Discord channel through a webhook.

Three kinds of post:
  --tag kak-v0.11.2         release: the tag's message + every change since the previous release tag
  --tag kak-v011-m6         milestone: the tag's message + every change since the previous tag
  --range OLD..NEW          push: a short "landed on Develop-Main" summary of those commits

The webhook URL comes from the DISCORD_WEBHOOK environment variable.
Without it (or with --dry-run) the Discord payload is printed instead of sent.
Standard library only, so it runs on any GitHub runner or a dev machine.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from collections import Counter

REPO_URL = os.environ.get("REPO_URL", "https://github.com/audoraemon/vfxProve")

RELEASE_TAG = re.compile(r"^kak-v\d+\.\d+(\.\d+)?$")  # kak-v0.10, kak-v0.11.2
RELEASE_GLOB = "kak-v[0-9]*.[0-9]*"  # git glob: needs a dot, so milestone tags never match
ANY_TAG_GLOB = "kak-v*"

# Commit prefix -> section heading. Order here is the order in the post.
SECTIONS = [
    ("feat", "New"),
    ("fix", "Fixed"),
    ("assets", "Art & sound"),
    ("perf", "Faster"),
    ("other", "Other"),
]
# Prefixes only counted, never listed: they matter to the code, not to the player.
QUIET = {"docs": "docs", "test": "tests", "refs": "test refs", "chore": "chores",
         "refactor": "refactors", "style": "style", "build": "build", "ci": "CI"}

COLOR_RELEASE = 0xE8B04B
COLOR_MILESTONE = 0x9B6BD6
COLOR_PUSH = 0x4C8BD9

DESC_LIMIT = 4000  # Discord allows 4096 in an embed description
LINE_LIMIT = 170
PUSH_SECTION_CAP = 8  # a push post lists at most this many lines per section

PREFIX = re.compile(r"^(?P<type>[a-zA-Z]+)(\([^)]*\))?!?:\s*(?P<text>.*)$")
VERSION = re.compile(r"\s*\((v\d+\.\d+(?:\.\d+)?)(?: M\d+)?\)\s*$")  # "(v0.11.2)", "(v0.11 M6)"
# "Task 10 review -- ", "Exodus review round 1 -- ", "M6 final review -- "
REVIEW = re.compile(r"^[\w'. ]{0,40}?\breview(?: round \d+)?\s*-+\s*", re.IGNORECASE)
MILESTONE_TAG = re.compile(r"^kak-v(\d)(\d+)-m(\d+)$")  # kak-v011-m6


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True,
                          text=True, encoding="utf-8").stdout.strip()


def subjects(rev_range):
    out = git("log", "--no-merges", "--reverse", "--format=%s", rev_range)
    return [s for s in out.splitlines() if s.strip()]


def previous_tag(tag, glob):
    try:
        return git("describe", "--tags", "--abbrev=0", f"--match={glob}", f"{tag}^")
    except subprocess.CalledProcessError:
        return None  # first tag of its kind


def tag_message(tag):
    msg = git("tag", "-l", "--format=%(contents)", tag)
    # Drop any signature block and keep the first paragraph as the headline.
    msg = msg.split("-----BEGIN", 1)[0].strip()
    return msg or git("log", "-1", "--format=%s", tag)


def pretty(tag):
    """kak-v0.11.2 -> v0.11.2, kak-v011-m6 -> v0.11 M6."""
    m = MILESTONE_TAG.match(tag)
    return f"v{m.group(1)}.{m.group(2)} M{m.group(3)}" if m else tag.removeprefix("kak-")


def short(text, limit):
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def classify(lines):
    """Split commit subjects into listed sections, quiet counts and the versions seen."""
    sections = {key: [] for key, _ in SECTIONS}
    quiet = Counter()
    versions = Counter()
    for subject in lines:
        m = PREFIX.match(subject)
        kind, text = (m.group("type").lower(), m.group("text")) if m else ("other", subject)
        v = VERSION.search(text)
        if v:
            versions[v.group(1)] += 1
            text = text[: v.start()]
        if kind in QUIET:
            quiet[kind] += 1
            continue
        if kind not in sections:
            kind = "other"
        text = REVIEW.sub("", text.strip())
        if text:
            sections[kind].append(text[0].upper() + text[1:])
    return sections, quiet, versions


def render(sections, quiet, cap=None):
    parts = []
    for key, heading in SECTIONS:
        items = sections[key]
        if not items:
            continue
        shown = items if cap is None else items[:cap]
        block = [f"**{heading}**"] + [f"• {short(t, LINE_LIMIT)}" for t in shown]
        if len(items) > len(shown):
            block.append(f"• …and {len(items) - len(shown)} more")
        parts.append("\n".join(block))
    if quiet:
        counts = ", ".join(f"{n} {QUIET[k]}" for k, n in quiet.most_common())
        parts.append(f"_Behind the scenes: {counts}_")
    text = "\n\n".join(parts) or "_No player-facing changes._"
    return fit(text)


def fit(text):
    """Cut whole lines so the description stays under Discord's limit."""
    if len(text) <= DESC_LIMIT:
        return text
    kept, size = [], 0
    lines = text.split("\n")
    for line in lines:
        if size + len(line) + 1 > DESC_LIMIT - 60:
            break
        kept.append(line)
        size += len(line) + 1
    return "\n".join(kept) + f"\n• …and {len(lines) - len(kept)} more lines (see the link above)"


def tag_post(tag):
    is_release = bool(RELEASE_TAG.match(tag))
    prev = previous_tag(tag, RELEASE_GLOB if is_release else ANY_TAG_GLOB)
    rev_range = f"{prev}..{tag}" if prev else tag
    lines = subjects(rev_range)
    sections, quiet, _ = classify(lines)
    headline = tag_message(tag)
    title = f"Released {pretty(tag)}" if is_release else f"Milestone {pretty(tag)}"
    body = f"{short(headline, 600)}\n\n{render(sections, quiet)}"
    url = f"{REPO_URL}/compare/{prev}...{tag}" if prev else f"{REPO_URL}/releases/tag/{tag}"
    footer = f"{len(lines)} changes" + (f" since {pretty(prev)}" if prev else "")
    return embed(title, body, url, footer, COLOR_RELEASE if is_release else COLOR_MILESTONE,
                 git("log", "-1", "--format=%cI", tag))


def push_post(rev_range, branch):
    lines = subjects(rev_range)
    if not lines:
        return None
    sections, quiet, versions = classify(lines)
    if not any(sections.values()):
        return None  # only docs/tests/chores: not worth a post
    version = versions.most_common(1)[0][0] if versions else None
    title = f"{version} in progress" if version else f"New on {branch}"
    title += f": {len(lines)} change" + ("s" if len(lines) != 1 else "")
    old, new = (git("rev-parse", "--short=7", f"{r}^{{commit}}") for r in rev_range.split(".."))
    url = f"{REPO_URL}/compare/{old}...{new}"
    footer = f"{branch} · {old}..{new}"
    return embed(title, render(sections, quiet, cap=PUSH_SECTION_CAP), url, footer, COLOR_PUSH,
                 git("log", "-1", "--format=%cI", new))


def embed(title, description, url, footer, color, timestamp):
    return {
        "username": "KAK Changelog",
        "allowed_mentions": {"parse": []},  # commit text never pings anyone
        "embeds": [{
            "title": short(title, 256),
            "url": url,
            "description": description,
            "color": color,
            "footer": {"text": short(footer, 2048)},
            "timestamp": timestamp,
        }],
    }


def send(payload, webhook):
    req = urllib.request.Request(
        webhook + ("&" if "?" in webhook else "?") + "wait=true",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "User-Agent": "KAK-changelog (github.com/audoraemon/vfxProve, 1.0)"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            print(f"Posted to Discord (HTTP {resp.status}).")
    except urllib.error.HTTPError as err:
        # Print Discord's reason, never the webhook URL.
        sys.exit(f"Discord refused the post: HTTP {err.code} {err.read().decode('utf-8', 'replace')[:500]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    what = ap.add_mutually_exclusive_group(required=True)
    what.add_argument("--tag", help="post a release or milestone tag, e.g. kak-v0.11.2")
    what.add_argument("--range", help="post a push summary for OLD..NEW")
    ap.add_argument("--branch", default="feat/Develop-Main", help="branch name shown on push posts")
    ap.add_argument("--dry-run", action="store_true", help="print the payload, send nothing")
    args = ap.parse_args()

    payload = tag_post(args.tag) if args.tag else push_post(args.range, args.branch)
    if payload is None:
        print("Nothing player-facing in these commits; no post.")
        return
    webhook = os.environ.get("DISCORD_WEBHOOK", "").strip()
    if args.dry_run or not webhook:
        if not webhook and not args.dry_run:
            print("DISCORD_WEBHOOK is not set; printing the post instead of sending it.")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return
    send(payload, webhook)


if __name__ == "__main__":
    main()
