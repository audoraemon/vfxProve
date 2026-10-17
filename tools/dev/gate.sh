#!/usr/bin/env bash
# One mission's gate (v0.11.1, spec Decision 35): runs the scripted player's six runs (none and play, seeds 1-3; B's three) at once
# and prints one verdict line, so fifty gates need not be read by hand.
# usage: bash tools/dev/gate.sh <scenario> [--route=b] [--board] [--extra='--path=festival ...'] [--jobs=N]
#   (from the project root; G= overrides the Godot path)
# Per run:   <scenario> <case> seed=N won=.. reason=.. time=.. idle=.. checksum=..
# Last line: gate <scenario> route=<a|b> none_lost=K/3 wins=K/3 median=S idle_max=S PASS|FAIL      (exit 1 on FAIL)
# The gate (spec §7 and the plan's Global Constraints): the none runs all lose (route a only; with --route=b they are skipped and
# none_lost prints -); play wins at least 2 of 3; route a: the median of the wins' times is 180-240 s (route b: 150-270 s for a tier mission, only reported for a ★ --board one,
# D33); no idle stretch over 45 s in a play run. A play run whose result line has no idle= makes idle_max ? and the gate FAIL.
set -u
G=${G:-/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe}
S=""; ROUTE=a; BOARD=""; EXTRA=""; JOBS=6; RARG=""
for a in "$@"; do case "$a" in
  --route=b) ROUTE=b; RARG="--route=b";;
  --route=a) ROUTE=a;;
  --board) BOARD="--board";;
  --extra=*) EXTRA="${a#--extra=}";;
  --jobs=*) JOBS="${a#--jobs=}";;
  -*) echo "gate.sh: unknown option $a" >&2; exit 2;;
  *) S="$a";;
esac; done
[ -z "$S" ] && { echo "usage: gate.sh <scenario> [--route=b] [--board] [--extra='...'] [--jobs=N]" >&2; exit 2; }
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
CASES="none play"; [ "$ROUTE" = b ] && CASES="play"
: > "$T/jobs"
for c in $CASES; do for n in 1 2 3; do echo "$c $n" >> "$T/jobs"; done; done
export G S BOARD RARG EXTRA T
run_one() { # case seed
  local c="$1" n="$2" o
  o=$(timeout 600 "$G" --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- \
    --scenario="$S" --case="$c" --seed="$n" $BOARD $RARG $EXTRA 2>&1)
  echo "$o" > "$T/$c.$n.log"
  echo "$o" | grep -a "BEHAVIOUR" | grep -a -E " (result|end) .*won=" | tail -1 > "$T/$c.$n.res"
  echo "$o" | grep -a -o 'checksum=-\?[0-9]*' | tail -1 > "$T/$c.$n.sum"
}
export -f run_one
xargs -P "$JOBS" -L 1 bash -c 'run_one $0 $1' < "$T/jobs"
wins=0; lost=0; idle_max=0; idle_ok=1; time_ok=1; times=""
for c in $CASES; do for n in 1 2 3; do
  line=$(cat "$T/$c.$n.res" 2>/dev/null); sum=$(cat "$T/$c.$n.sum" 2>/dev/null)
  won=$(echo "$line" | grep -a -o 'won=[a-z]*' | head -1 | cut -d= -f2)
  reason=$(echo "$line" | grep -a -o 'reason=[a-z_]*' | head -1 | cut -d= -f2)
  tm=$(echo "$line" | grep -a -o 'time=[0-9.]*' | head -1 | cut -d= -f2)
  idle=$(echo "$line" | grep -a -o 'idle=[0-9.]*' | tail -1 | cut -d= -f2)
  if [ -z "$line" ]; then  # no result line: a crash or a parse error, not a lost run; show where it stopped
    echo "gate.sh: $c seed=$n printed no result line; the log's last lines:" >&2
    tail -n 8 "$T/$c.$n.log" >&2
  fi
  echo "$S $c seed=$n won=${won:-?} reason=${reason:-?} time=${tm:-?} idle=${idle:-?} ${sum:-checksum=?}"
  if [ "$c" = none ]; then
    [ "$won" = false ] && lost=$((lost+1))
  else
    if [ "$won" = true ]; then
      wins=$((wins+1)); times="$times ${tm:-0}"
      [ -z "$tm" ] && time_ok=0
    fi
    if [ -z "$idle" ]; then idle_ok=0; else idle_max=$(awk -v a="$idle_max" -v b="$idle" 'BEGIN{print (b>a)?b:a}'); fi
  fi
done; done
median="-"
if [ "$wins" -gt 0 ]; then
  median=$(echo $times | tr ' ' '\n' | sort -g | awk '{v[NR]=$1} END{ if (NR%2) printf "%.0f", v[(NR+1)/2]; else printf "%.0f", (v[NR/2]+v[NR/2+1])/2 }')
fi
verdict=PASS
[ "$wins" -lt 2 ] && verdict=FAIL
if [ "$ROUTE" = a ]; then
  [ "$lost" -ne 3 ] && verdict=FAIL
  { [ "$median" = "-" ] || [ "$median" -lt 180 ] || [ "$median" -gt 240 ]; } && verdict=FAIL
fi
# A tier mission's second loadout (no --board): its median may stray a little from A's band, never trivially fast (rulings R6).
if [ "$ROUTE" = b ] && [ -z "$BOARD" ]; then
  { [ "$median" = "-" ] || [ "$median" -lt 150 ] || [ "$median" -gt 270 ]; } && verdict=FAIL
fi
[ "$time_ok" -eq 0 ] && { verdict=FAIL; median="time?"; }  # a win with no time= can not be judged
if [ "$idle_ok" -eq 0 ]; then idle_show="?"; verdict=FAIL; else
  idle_show=$idle_max; awk -v a="$idle_max" 'BEGIN{exit !(a>45)}' && verdict=FAIL
fi
nl="$lost/3"; [ "$ROUTE" = b ] && nl="-"
echo "gate $S route=$ROUTE none_lost=$nl wins=$wins/3 median=$median idle_max=$idle_show $verdict"
[ "$verdict" = PASS ]
