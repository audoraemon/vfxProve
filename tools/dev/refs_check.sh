#!/usr/bin/env bash
# Checks KAK's exact references against every tools/dev/refs/*.tsv (references.tsv and, from v0.11.1, one routes_t<N>.tsv per tier).
# usage: bash tools/dev/refs_check.sh [--only=REGEX] [--jobs=N]     (from the project root; G= overrides the Godot path)
#   --only=REGEX   check only references whose name matches (e.g. --only='^(bread|hunt)_' for the missions a task touched)
#   --jobs=N       parallel headless scenario runs (default 6; fixed-fps headless runs are deterministic under load)
# The digest, crowd_check and the global behaviour rows run one at a time, rendered, as they were recorded (casts there
# use hit-stop, which is wall-clock). Board-mission scenario rows (<scenario>_<none|play>_<seed>) run in parallel, headless.
# Prints one line per reference with OK or MISMATCH(want ...); last line "refs ok=K bad=B"; exits 1 if any is bad.
set -u
G=${G:-/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe}
ONLY=""; JOBS=6
for a in "$@"; do case "$a" in --only=*) ONLY="${a#--only=}";; --jobs=*) JOBS="${a#--jobs=}";; esac; done
T=$(mktemp -d)
for f in tools/dev/refs/*.tsv; do cat "$f"; echo; done | tr -d '\r' | grep -v '^#' | awk -F'\t' 'NF>=3' > "$T/rows"
[ -n "$ONLY" ] && { awk -F'	' -v re="$ONLY" '$1 ~ re' "$T/rows" > "$T/r2"; mv "$T/r2" "$T/rows"; }
run_row() { # name how expected outfile mode
  local name="$1" how="$2" want="$3" out="$4" mode="$5" o got
  case "$how" in
    state_digest) o=$(timeout 600 "$G" --headless --path . -s tools/dev/state_digest.gd 2>&1); got=$(echo "$o" | grep -a '^digest=' | tail -1 | cut -d= -f2);;
    crowd_check) o=$(timeout 600 "$G" --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd 2>&1); got=$(echo "$o" | grep -a -o 'checksum=-\?[0-9]*' | tail -1 | cut -d= -f2);;
    *) if [ "$mode" = par ]; then o=$(timeout 600 "$G" --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- $how 2>&1)
       else o=$(timeout 600 "$G" --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- $how 2>&1); fi
       got=$(echo "$o" | grep -a -o 'checksum=-\?[0-9]*' | tail -1 | cut -d= -f2);;
  esac
  local res; res=$(echo "$o" | grep -a -o 'won=[a-z]* reason=[a-z_]* time=[0-9.]*' | tail -1)
  local st=OK
  if [ "${want#outcome:}" != "$want" ]; then echo "$o" | grep -a -q -- "${want#outcome:}" || st="MISMATCH(want ${want#outcome:})"
  elif [ "$got" != "$want" ]; then st="MISMATCH(want $want)"; fi
  echo "$name: ${got:-?} $res $st" > "$out"
}
export -f run_row; export G
i=0
while IFS=$'\t' read -r name how want; do
  i=$((i+1)); if echo "$name" | grep -q -E '_(none|play)_[0-9]+$'; then echo "$i	$name	$how	$want" >> "$T/par"; else run_row "$name" "$how" "$want" "$T/$i.out" seq; fi
done < "$T/rows"
if [ -f "$T/par" ]; then
  awk -F'\t' -v d="$T" '{printf "%s\t%s\t%s\t%s/%s.out\n", $2, $3, $4, d, $1}' "$T/par" | \
    xargs -P "$JOBS" -d '\n' -n 1 bash -c 'IFS=$'"'"'\t'"'"' read -r n h w f <<< "$0"; run_row "$n" "$h" "$w" "$f" par'
fi
ok=0; bad=0
for f in $(ls -v "$T"/*.out 2>/dev/null); do cat "$f"; if grep -q ' OK$' "$f"; then ok=$((ok+1)); else bad=$((bad+1)); fi; done
echo "refs ok=$ok bad=$bad"
rm -rf "$T"
[ "$bad" -eq 0 ]
