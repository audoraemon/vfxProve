#!/usr/bin/env bash
# Landing gates for a KAK milestone, run from the work branch's project root. It never pushes.
# usage: bash tools/dev/land.sh [--bench=BASE_REF] [--pairs="a:b c:c ..."] [--skip-flow]
#   Steps: fetch + trial merge of origin/feat/Develop-Main (reports conflicts and incoming commits; stops on a conflict),
#   import, the suite in parallel, every exact reference (refs_check.sh), FLOW alone (waits for other sessions' Godot to
#   finish), and with --bench a board-version bench of each "A:B" pair: mission A at BASE_REF against mission B here
#   (default pairs: each tier's ★ mission against itself). Writes a summary to $TMPDIR/kak_land/summary.txt and prints it.
#   After it passes: merge origin into the branch if it moved, re-run, then ff feat/Develop-Main, tag and push by hand.
set -u
G=${G:-/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe}
BENCH=""; PAIRS="warning:warning miras_house:miras_house vigil_flame:vigil_flame procession:procession last_judgement:last_judgement"; FLOW=1
for a in "$@"; do case "$a" in --bench=*) BENCH="${a#--bench=}";; --pairs=*) PAIRS="${a#--pairs=}";; --skip-flow) FLOW=0;; esac; done
O=${TMPDIR:-/tmp}/kak_land; mkdir -p "$O"; SUM="$O/summary.txt"; : > "$SUM"
say() { echo "$*" | tee -a "$SUM"; }
busy() { powershell -NoProfile -Command "(@(Get-CimInstance Win32_Process -Filter \"Name like 'Godot%'\" | Where-Object { \$_.CommandLine -match 'behaviour_check|run_all|run_part|flow-test|crowd_check|state_digest|--bench|--import' })).Count" | tr -d '\r'; }
GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git fetch origin >/dev/null 2>&1
say "HEAD $(git rev-parse --short HEAD) $(git rev-parse --abbrev-ref HEAD); origin/feat/Develop-Main $(git rev-parse --short origin/feat/Develop-Main)"
say "incoming commits: $(git log --oneline HEAD..origin/feat/Develop-Main | wc -l)"
git log --oneline HEAD..origin/feat/Develop-Main | head -10 | tee -a "$SUM"
if ! git merge-tree --write-tree --name-only HEAD origin/feat/Develop-Main > "$O/trial.txt" 2>&1; then say "TRIAL MERGE CONFLICTS:"; cat "$O/trial.txt" | tee -a "$SUM"; exit 1; fi
say "trial merge: clean"
timeout 900 "$G" --headless --editor --path . --import > "$O/import.log" 2>&1; say "import exit=$?"
say "== suite"; bash tools/dev/run_suite_parallel.sh 8 2>&1 | tail -1 | tee -a "$SUM"
say "== references"; bash tools/dev/refs_check.sh > "$O/refs.txt" 2>&1; grep -v ' OK$' "$O/refs.txt" | tee -a "$SUM"
if [ "$FLOW" = 1 ]; then
  for i in $(seq 1 120); do [ "$(busy)" = "0" ] && break; sleep 30; done
  say "== FLOW (waited $((i-1))x30 s)"
  for try in 1 2; do
    r=$(timeout 900 "$G" --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep -a "FLOW result")
    [ -n "$r" ] && break
  done
  say "${r:-FLOW: NO RESULT (rerun alone)}"
fi
if [ -n "$BENCH" ]; then
  W="$O/wt-bench"; git worktree remove --force "$W" >/dev/null 2>&1; git worktree add --detach "$W" "$BENCH" >/dev/null 2>&1
  (cd "$W" && timeout 900 "$G" --headless --editor --path . --import >/dev/null 2>&1)
  for i in $(seq 1 60); do [ "$(busy)" = "0" ] && break; sleep 30; done
  say "== bench (board versions, median of 3, fps): A=$BENCH B=HEAD"
  run() { (cd "$1" && timeout 300 "$G" --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --mission=$2 --bench --board 2>&1 | grep -a "^bench\[" | tail -1 | grep -o 'avg_fps=[0-9.]*' | cut -d= -f2); }
  for p in $PAIRS; do a=${p%%:*}; b=${p##*:}; av=(); bv=()
    for k in 1 2 3; do av+=("$(run "$W" "$a")"); bv+=("$(run . "$b")"); done
    med() { printf '%s\n' "$@" | sort -n | sed -n 2p; }
    say "$a/$b: A $(med "${av[@]}") B $(med "${bv[@]}")   (A ${av[*]} | B ${bv[*]})"
  done
  git worktree remove --force "$W" >/dev/null 2>&1
fi
say "== done"
