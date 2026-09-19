#!/usr/bin/env bash
# Capture the sandbox reference frames (idle, nova, judgement, cinder) into <out_dir> for before/after checks.
# usage: bash tools/dev/sandbox_baseline.sh captures/<name>
set -e
cd "$(dirname "$0")/../.."
OUT="$1"
rm -rf "$OUT"
mkdir -p "$OUT"
rm -f captures/idle.png captures/nova_*.png captures/judgement_*.png captures/cinder_*.png
bash tools/capture.sh --capture-idle
for key in nova judgement cinder; do
	bash tools/capture.sh --capture-all --only=$key
done
cp captures/idle.png captures/nova_*.png captures/judgement_*.png captures/cinder_*.png "$OUT/"
echo "frames: $(ls "$OUT" | wc -l)"
