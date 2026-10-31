#!/usr/bin/env bash
# The Lantern Hunts' per-type gate (god P5, MS §7, R37-R38, controller rulings C8 and C9): one Hunt, one god type at a time, then the six judged
# from the saved lines. A Hunt's 21 runs (3 none + 6 types x 3 play seeds) do not fit one foreground command, so a call runs ONE type and a
# second call judges; each foreground command stays under 10 minutes.
# usage: bash tools/dev/hunt_gate.sh --only=<hunt> --type=<type> [--with-none] [--save=<dir>] [--jobs=N]      run one type's gate
#        bash tools/dev/hunt_gate.sh --only=<hunt> --judge=<dir> [--except=<type>,...]                          judge the six saved types
#   (from the project root; G= overrides Godot)
#   --only=<hunt>     required: hide_faithful, silence_witness, expel_inquisitor, break_hunt or face_halcyon (its tier is the --god tier)
#   --type=<type>     ruin, death, veil, passage, decree or dominion: runs `gate.sh <hunt> --god=<type>:<tier> --extra='--dev-tree'` -- that type's
#                     three play seeds (about 3-4 min at --jobs=3); with --with-none the three none runs too (six runs in two waves, about 6-8 min;
#                     give it to one type only: a none run casts nothing)
#   --save=<dir>      with --type: writes the type's gate lines (the per-run lines and the `gate ...` line) to <dir>/<hunt>.<type>.txt
#   --judge=<dir>     runs nothing: reads <dir>/<hunt>.<type>.txt for the six types and prints the 6-row table wins/median/idle and
#                     `hunt_gate <hunt> tier=N pass=K/6 none_lost=K/3 median=S [excepted=<types>] PASS|FAIL`. PASS iff every counted type's gate
#                     PASSed (wins at least 2/3, idle at most 45 s -- the real idle, fillers end no stretch, T1R D38), none_lost is 3/3 (some saved
#                     type ran --with-none), and the median of all winning play runs pooled is 180-240 s (ruling C9). A type's own median is
#                     printed and never judged (T1R D10). A missing type file, or one whose gate line is not `route=god:<that type>`, is FAIL.
#   --except=<type>,... with --judge: those types print `excepted` and do not count (Decree on Hunts 2-4 is a reported gap, MS §9 open issue 1,
#                     ruling C9: the controller judges those three Hunts with --except=decree; never tuned around). Only `decree`, and only on
#                     Hunts 2-4, is accepted; anything else is refused (exit 2)
#   --jobs=N          passed to gate.sh (its default is 6 runs at once; 3 here, or 2 while another session runs Godot)
# A call with neither --type nor --judge is refused (exit 2): there is no 21-run call. Exit 1 on FAIL.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
HUNTS="hide_faithful silence_witness expel_inquisitor break_hunt face_halcyon"
TYPES="ruin death veil passage decree dominion"
ONLY=""; TYPE=""; WITHNONE=0; SAVE=""; JUDGE=""; EXCEPT=""; JOBS=""
for a in "$@"; do case "$a" in
  --only=*) ONLY="${a#--only=}";;
  --type=*) TYPE="${a#--type=}";;
  --with-none) WITHNONE=1;;
  --save=*) SAVE="${a#--save=}";;
  --judge=*) JUDGE="${a#--judge=}";;
  --except=*) EXCEPT="${a#--except=}";;
  --jobs=*) JOBS="${a#--jobs=}";;
  *) echo "hunt_gate.sh: unknown option $a" >&2; exit 2;;
esac; done
[ -n "$ONLY" ] || { echo "hunt_gate.sh: --only=<hunt> is required (one of: $HUNTS)" >&2; exit 2; }
TIER=0; n=0
for h in $HUNTS; do n=$((n + 1)); [ "$h" = "$ONLY" ] && TIER=$n; done
[ "$TIER" != 0 ] || { echo "hunt_gate.sh: --only=$ONLY is not one of: $HUNTS" >&2; exit 2; }
if [ -z "$TYPE" ] && [ -z "$JUDGE" ]; then
  echo "hunt_gate.sh: needs --type=<type> or --judge=<dir>; a Hunt's 21 runs are one type per call, then --judge (got neither --type nor --judge)" >&2; exit 2
fi
if [ -n "$TYPE" ] && [ -n "$JUDGE" ]; then echo "hunt_gate.sh: --type and --judge are separate calls" >&2; exit 2; fi
if [ -n "$EXCEPT" ] && [ -z "$JUDGE" ]; then echo "hunt_gate.sh: --except only goes with --judge" >&2; exit 2; fi
if [ -n "$TYPE" ]; then
  case " $TYPES " in *" $TYPE "*) :;; *) echo "hunt_gate.sh: --type=$TYPE is not one of: $TYPES" >&2; exit 2;; esac
fi
if [ -n "$SAVE" ] && [ -z "$TYPE" ]; then echo "hunt_gate.sh: --save only goes with --type" >&2; exit 2; fi
if [ "$WITHNONE" = 1 ] && [ -z "$TYPE" ]; then echo "hunt_gate.sh: --with-none only goes with --type" >&2; exit 2; fi
for e in $(echo "$EXCEPT" | tr ',' ' '); do
  case " $TYPES " in *" $e "*) :;; *) echo "hunt_gate.sh: --except=$e is not one of: $TYPES" >&2; exit 2;; esac
  # ruling C9: only Decree on Hunts 2-4 is a reported gap; no other type, and no other Hunt, may be excepted
  if [ "$e" != decree ] || [ "$TIER" -lt 2 ] || [ "$TIER" -gt 4 ]; then
    echo "hunt_gate.sh: --except=$e is refused for $ONLY: only decree on Hunts 2-4 (silence_witness, expel_inquisitor, break_hunt) may be excepted" >&2; exit 2
  fi
done

if [ -n "$TYPE" ]; then
  # --- run one type: its gate.sh call (the only one in this script), nothing around it
  args=("$ONLY" "--god=$TYPE:$TIER" "--extra=--dev-tree")
  [ "$WITHNONE" = 1 ] && args+=("--with-none")
  [ -n "$JOBS" ] && args+=("--jobs=$JOBS")
  OUT=$(mktemp)
  trap 'rm -f "$OUT"' EXIT
  bash "$HERE/gate.sh" "${args[@]}" > "$OUT"
  rc=$?
  cat "$OUT"
  if [ -n "$SAVE" ]; then
    mkdir -p "$SAVE" && cp "$OUT" "$SAVE/$ONLY.$TYPE.txt" || { echo "hunt_gate.sh: could not write $SAVE/$ONLY.$TYPE.txt" >&2; exit 2; }
  fi
  exit $rc
fi

# --- judge: runs nothing, reads the saved files
[ -d "$JUDGE" ] || { echo "hunt_gate.sh: --judge=$JUDGE is not a directory" >&2; exit 2; }
pass=0; counted=0; none_lost=""; times=""; excepted=""; allok=1
rows=""
for jt in $TYPES; do
  f="$JUDGE/$ONLY.$jt.txt"
  if echo " $(echo "$EXCEPT" | tr ',' ' ') " | grep -q " $jt "; then
    excepted="${excepted:+$excepted,}$jt"
    rows="$rows$(printf '%-9s %s' "$jt" "excepted")"$'\n'
    continue
  fi
  counted=$((counted + 1))
  # the gate line must say route=god:<this type>: a file saved under the wrong name is not judged as another type (milestone review, M1)
  line=$(grep -a "^gate $ONLY .*route=god:$jt " "$f" 2>/dev/null | tail -1)
  if [ -z "$line" ]; then
    allok=0
    rows="$rows$(printf '%-9s %s' "$jt" "missing ($ONLY.$jt.txt has no gate line with route=god:$jt) FAIL")"$'\n'
    continue
  fi
  wins=$(echo "$line" | grep -a -o 'wins=[0-9]*/3' | cut -d= -f2)
  med=$(echo "$line" | grep -a -o 'median=[^ ]*' | cut -d= -f2)
  idle=$(echo "$line" | grep -a -o 'idle_max=[^ ]*' | cut -d= -f2)
  verdict=$(echo "$line" | awk '{print $NF}')
  nl=$(echo "$line" | grep -a -o 'none_lost=[0-9]*/3' | cut -d= -f2)
  [ -n "$nl" ] && none_lost="$nl"
  if [ "$verdict" = PASS ]; then pass=$((pass + 1)); else allok=0; fi
  # every winning play run's time, pooled (the per-run lines: `<hunt> play seed=N won=true reason=.. time=T ...`)
  t=$(grep -a "^$ONLY play seed=" "$f" | grep -a 'won=true' | grep -a -o 'time=[0-9.]*' | cut -d= -f2)
  times="$times $t"
  case "$med" in ""|*[!0-9]*) medshow="${med:--}";; *) medshow="${med}s";; esac
  rows="$rows$(printf '%-9s %s %s %ss %s' "$jt" "${wins:-?}" "$medshow" "${idle:-?}" "$verdict")"$'\n'
done
median="-"
if [ -n "$(echo $times)" ]; then
  median=$(echo $times | tr ' ' '\n' | sort -g | awk '{v[NR]=$1} END{ if (NR%2) printf "%.0f", v[(NR+1)/2]; else printf "%.0f", (v[NR/2]+v[NR/2+1])/2 }')
fi
echo "wins/median/idle   (hunt $ONLY, tier $TIER)"
printf '%s' "$rows"
[ "$none_lost" = "3/3" ] || allok=0
{ [ "$median" = "-" ] || [ "$median" -lt 180 ] || [ "$median" -gt 240 ]; } && allok=0
verdict=PASS; [ "$allok" = 1 ] || verdict=FAIL
echo "hunt_gate $ONLY tier=$TIER pass=$pass/$counted none_lost=${none_lost:-?/3} median=$median${excepted:+ excepted=$excepted} $verdict"
[ "$verdict" = PASS ]
