#!/usr/bin/env bash
# Runs the whole test suite as N Godot processes at once (default 8) and sums them.
# usage: bash tools/dev/run_suite_parallel.sh [N]      (from the project root; G= overrides the Godot path)
# Prints each part's line, then "checks=C failures=F"; exits 1 on any failure. Logs: a fresh $TMPDIR/kak_suite.XXXX/part_N.log per run (parallel worktrees never share one)
set -u
N=${1:-8}
G=${G:-/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe}
LOG=$(mktemp -d "${TMPDIR:-/tmp}/kak_suite.XXXX")
for i in $(seq 1 "$N"); do
  ( timeout 1800 "$G" --headless --path . --script res://tests/run_part.gd -- --part=$i --of=$N > "$LOG/part_$i.log" 2>&1 ) &
done
wait
total=0; fails=0; bad=0
for i in $(seq 1 "$N"); do
  line=$(grep -a "^part=" "$LOG/part_$i.log" | tail -1)
  if [ -z "$line" ]; then echo "part $i: NO RESULT (see $LOG/part_$i.log)"; bad=1; continue; fi
  echo "$line"
  c=$(echo "$line" | sed 's/.*checks=\([0-9]*\).*/\1/'); f=$(echo "$line" | sed 's/.*failures=\([0-9]*\).*/\1/')
  total=$((total + c)); fails=$((fails + f))
done
grep -a -h "FAIL:\|SCRIPT ERROR\|Parse Error" "$LOG"/part_*.log | head -20
echo "checks=$total failures=$fails"
[ "$fails" -eq 0 ] && [ "$bad" -eq 0 ]
