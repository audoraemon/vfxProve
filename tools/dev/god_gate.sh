#!/usr/bin/env bash
# The Tier 1 per-type gate over all 30 pairs (god T1R Task 7, rulings D5): each of the five Tier 1 missions x each of the six god types, the
# type playing only its own two Tier 1 powers at level 1 (gate.sh --god=<type>:1). Prints every pair's gate, a 6 x 5 table of wins/median/idle,
# and a last line `god_gate tier=1[ city=<id>] pass=K/N none_lost=M/P PASS|FAIL` (exit 1 on FAIL).
# usage: bash tools/dev/god_gate.sh [--tier=1] [--city=<id>] [--only=<scenario>] [--jobs=N]      (from the project root; G= overrides Godot)
#   --only=<scenario>  one mission only (its six pairs: pass=6/6 none_lost=1/1 on a clean run); a full run is 5 calls of this, each under 10 minutes
#   --jobs=N           passed to gate.sh (its default is 6 runs at once; use 2 when another session runs Godot)
# Binding in Aldermere (D5, D10): wins >= 2/3 and idle <= 45 s on every pair; the median is printed, never judged. The Capital (--city=capital)
# is reported: its table and line print, and the verdict is informational (Tier 1 in the Capital is dev-only), but PASS/FAIL is still honest.
# The none check (doing nothing must lose 3/3) runs once per mission, on the first god type's pair (--with-none), since a none run casts nothing.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TIER=1; CITY=""; ONLY=""; JOBS=""
for a in "$@"; do case "$a" in
  --tier=*) TIER="${a#--tier=}";;
  --city=*) CITY="${a#--city=}";;
  --only=*) ONLY="${a#--only=}";;
  --jobs=*) JOBS="${a#--jobs=}";;
  *) echo "god_gate.sh: unknown option $a" >&2; exit 2;;
esac; done
[ "$TIER" = 1 ] || { echo "god_gate.sh: only --tier=1 is built" >&2; exit 2; }
SCENARIOS="warning tax harvest lamb prayers"
TYPES="ruin death veil passage decree dominion"
if [ -n "$ONLY" ]; then
  case " $SCENARIOS " in *" $ONLY "*) SCENARIOS="$ONLY";; *) echo "god_gate.sh: --only=$ONLY is not one of: $SCENARIOS" >&2; exit 2;; esac
fi
FIRST=${TYPES%% *}
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
pass=0; total=0; none_ok=0; none_total=0; allok=1
for s in $SCENARIOS; do
  for type in $TYPES; do
    args=("$s" "--god=$type:1")
    [ "$s" = warning ] && args+=("--board")
    [ -n "$CITY" ] && args+=("--city=$CITY")
    [ -n "$JOBS" ] && args+=("--jobs=$JOBS")
    [ "$type" = "$FIRST" ] && args+=("--with-none")
    # Two pairs may idle up to 60 s, the user's no-wait limit: Harvest x Decree (ruling D12, The Bell Lies' cooldown) and Prayers x Death
    # (ruling D34, the poor hurry in once no Faithful is left). Every other pair keeps the default 45 s.
    { [ "$s" = harvest ] && [ "$type" = decree ]; } && args+=("--idle-max=60")
    { [ "$s" = prayers ] && [ "$type" = death ]; } && args+=("--idle-max=60")
    bash "$HERE/gate.sh" "${args[@]}" > "$T/out" 2> "$T/err"
    cat "$T/out"; cat "$T/err" >&2
    line=$(grep -a "^gate " "$T/out" | tail -1)
    wins=$(echo "$line" | grep -a -o 'wins=[0-9]*/3' | cut -d= -f2)
    med=$(echo "$line" | grep -a -o 'median=[^ ]*' | cut -d= -f2)
    idle=$(echo "$line" | grep -a -o 'idle_max=[^ ]*' | cut -d= -f2)
    verdict=$(echo "$line" | awk '{print $NF}')
    total=$((total + 1))
    if [ "$verdict" = PASS ]; then pass=$((pass + 1)); else allok=0; fi
    if [ "$type" = "$FIRST" ]; then
      none_total=$((none_total + 1))
      nl=$(echo "$line" | grep -a -o 'none_lost=[0-9]*/3' | cut -d= -f2)
      [ "$nl" = "3/3" ] && none_ok=$((none_ok + 1)) || allok=0
    fi
    echo "${wins:-?} ${med:-?}s ${idle:-?}s" > "$T/cell.$s.$type"
  done
done
echo
printf '%-17s' "wins/median/idle"
for s in $SCENARIOS; do printf ' | %-16s' "$s"; done; echo
for type in $TYPES; do
  printf '%-17s' "$type"
  for s in $SCENARIOS; do printf ' | %-16s' "$(cat "$T/cell.$s.$type")"; done; echo
done
verdict=PASS; [ "$allok" = 1 ] || verdict=FAIL
echo "god_gate tier=$TIER${CITY:+ city=$CITY} pass=$pass/$total none_lost=$none_ok/$none_total $verdict"
[ "$verdict" = PASS ]
