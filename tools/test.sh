#!/usr/bin/env bash
# Re-import project (refreshes class_name cache) and run headless tests.
set -o pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-/f/Godot/Godot_v4.7.2-stable_win64_console.exe}"
timeout 180 "$G" --headless --editor --path . --import >/dev/null 2>&1
timeout 120 "$G" --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:'
exit ${PIPESTATUS[0]}
