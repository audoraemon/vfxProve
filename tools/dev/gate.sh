#!/usr/bin/env bash
# One mission's gate (v0.11.1, spec Decision 35): runs the scripted player's six runs (none and play, seeds 1-3; B's three) at once
# and prints one verdict line, so fifty gates need not be read by hand.
# usage: bash tools/dev/gate.sh <scenario> [--route=b] [--board] [--extra='--path=festival ...'] [--jobs=N]
#        [--case=toll]   (v0.11.2, D32: a Lantern night's toll case; see below)
#        [--city=<id>]   (v0.12, D23: appended to every run, e.g. --city=capital; the verdict line then reads `gate <scenario> city=<id> route=...`)
#        [--with-none]   (v0.12, D23: with --route=b also runs the three none cases and judges none_lost 3/3, FAIL otherwise; route a always does)
#        [--god=<type>:<tier>]   (god T1R, spec 9: the per-type gate -- every run plays that god type's own policy with its Tier 1 powers
#                         (behaviour_check --god=, no --route); cases play, plus none with --with-none; the verdict line reads `route=god:<type>`)
#        [--idle-max=N]  (god T1R: the longest idle stretch a play run may have, default 45; Harvest x Decree's per-type gate passes 60, D12,
#                         and so does Prayers x Death, D34)
#   (from the project root; G= overrides the Godot path)
# Per run:   <scenario> <case> seed=N won=.. reason=.. time=.. idle=.. checksum=..
# Last line: gate <scenario> route=<a|b|god:<type>> none_lost=K/3 wins=K/3 median=S idle_max=S PASS|FAIL      (exit 1 on FAIL)
# A --god gate judges wins at least 2/3, the idle stretch (--idle-max, default 45), none_lost 3/3 with --with-none, and a refusal FAILs; its
# median is printed and never judged (rulings D10, either town).
# A route b gate with --with-none prints the none runs as well and none_lost=K/3 (without it none_lost prints -).
# The gate (spec §7 and the plan's Global Constraints): the none runs all lose (route a only; with --route=b they are skipped and
# none_lost prints -); play wins at least 2 of 3; route a: the median of the wins' times is 180-240 s (route b: 150-270 s for a tier mission -- at most 270 s
# for prayers, D34 -- only reported for a ★ --board one,
# D33); no idle stretch over 45 s in a play run. A play run whose result line has no idle= makes idle_max ? and the gate FAIL.
set -u
G=${G:-/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe}
S=""; ROUTE=a; BOARD=""; EXTRA=""; JOBS=6; RARG=""; ONLYCASE=""; CITY=""; CARG=""; WITHNONE=0; GOD=""; GARG=""; IDLE_MAX_OK=45; ROUTE_A=0
for a in "$@"; do case "$a" in
  --route=b) ROUTE=b; RARG="--route=b";;
  --route=a) ROUTE=a; ROUTE_A=1;;
  --god=*) GOD="${a#--god=}"; GARG="--god=$GOD";;
  --idle-max=*) IDLE_MAX_OK="${a#--idle-max=}";;
  --board) BOARD="--board";;
  --extra=*) EXTRA="${a#--extra=}";;
  --jobs=*) JOBS="${a#--jobs=}";;
  --case=toll) ONLYCASE=toll;;
  --city=*) CITY="${a#--city=}"; CARG="--city=$CITY";;
  --with-none) WITHNONE=1;;
  -*) echo "gate.sh: unknown option $a" >&2; exit 2;;
  *) S="$a";;
esac; done
[ -z "$S" ] && { echo "usage: gate.sh <scenario> [--route=b] [--board] [--case=toll] [--city=<id>] [--with-none] [--god=<type>:<tier>] [--idle-max=N] [--extra='...'] [--jobs=N]" >&2; exit 2; }
GODTYPE=""
if [ -n "$GOD" ] && [ -z "$RARG" ] && [ "$ROUTE_A" = 0 ]; then ROUTE=god; GODTYPE="${GOD%%:*}"; fi  # the per-type gate (no route given)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
CASES="none play"; { [ "$ROUTE" = b ] || [ "$ROUTE" = god ]; } && [ "$WITHNONE" = 0 ] && CASES="play"
[ -n "$ONLYCASE" ] && CASES="$ONLYCASE"  # --case=toll: the three toll runs only
: > "$T/jobs"
for c in $CASES; do for n in 1 2 3; do echo "$c $n" >> "$T/jobs"; done; done
export G S BOARD RARG EXTRA CARG GARG T
run_one() { # case seed
  local c="$1" n="$2" o
  o=$(timeout 600 "$G" --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- \
    --scenario="$S" --case="$c" --seed="$n" $BOARD $RARG $GARG $CARG $EXTRA 2>&1)
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
refused=0
for f in "$T"/*.log; do grep -a -q "^BEHAVIOUR refused scenario=" "$f" && refused=1; done
[ "$refused" = 1 ] && echo "gate.sh: a run was refused (the town cannot host this mission); the verdict is FAIL" >&2
median="-"
if [ "$wins" -gt 0 ]; then
  median=$(echo $times | tr ' ' '\n' | sort -g | awk '{v[NR]=$1} END{ if (NR%2) printf "%.0f", v[(NR+1)/2]; else printf "%.0f", (v[NR/2]+v[NR/2+1])/2 }')
fi
verdict=PASS
[ "$wins" -lt 2 ] && verdict=FAIL
[ "$refused" = 1 ] && verdict=FAIL
if [ "$ROUTE" = a ] || [ "$WITHNONE" = 1 ]; then
  [ "$lost" -ne 3 ] && verdict=FAIL
fi
if [ "$ROUTE" = a ]; then
  { [ "$median" = "-" ] || [ "$median" -lt 180 ] || [ "$median" -gt 240 ]; } && verdict=FAIL
fi
# A tier mission's second loadout (no --board): its median may stray a little from A's band, never trivially fast (rulings R6).
# (god T1R, D34) First Prayers only: B's 150 s floor is relaxed -- once no Faithful is left the poor hurry in and pray together, and B takes every
# Faithful -- so its median is judged only against the 270 s ceiling there; its wins (and with --with-none, none_lost) are judged as before.
B_FLOOR=150; [ "$S" = prayers ] && B_FLOOR=0
if [ "$ROUTE" = b ] && [ -z "$BOARD" ]; then
  { [ "$median" = "-" ] || [ "$median" -lt "$B_FLOOR" ] || [ "$median" -gt 270 ]; } && verdict=FAIL
fi
[ "$time_ok" -eq 0 ] && { verdict=FAIL; median="time?"; }  # a win with no time= can not be judged
if [ "$idle_ok" -eq 0 ]; then idle_show="?"; verdict=FAIL; else
  idle_show=$idle_max; awk -v a="$idle_max" -v m="$IDLE_MAX_OK" 'BEGIN{exit !(a>m)}' && verdict=FAIL
fi
# The toll case (v0.11.2, D32): the policy waits for the toll on purpose, so only the wins are judged (at least 2 of 3); the idle stretch and the
# median are reported, not judged.
if [ -n "$ONLYCASE" ]; then
  verdict=PASS; [ "$wins" -lt 2 ] && verdict=FAIL
  [ "$refused" = 1 ] && verdict=FAIL
  [ "$time_ok" -eq 0 ] && median="time?"
  [ "$idle_ok" -eq 0 ] && idle_show="?" || idle_show=$idle_max
  echo "gate $S${CITY:+ city=$CITY} case=$ONLYCASE wins=$wins/3 median=$median idle_max=$idle_show $verdict"
  [ "$verdict" = PASS ]
  exit
fi
nl="$lost/3"; { [ "$ROUTE" = b ] || [ "$ROUTE" = god ]; } && [ "$WITHNONE" = 0 ] && nl="-"
cl=""; [ -n "$CITY" ] && cl=" city=$CITY"
rl="$ROUTE"; [ "$ROUTE" = god ] && rl="god:$GODTYPE"
echo "gate $S${cl} route=$rl none_lost=$nl wins=$wins/3 median=$median idle_max=$idle_show $verdict"
[ "$verdict" = PASS ]
