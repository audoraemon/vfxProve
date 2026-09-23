#!/usr/bin/env bash
# Run a scene windowed with a capture/bench flag. Usage: tools/capture.sh --capture-all [--only=nova]
# Another scene: SCENE=res://scenes/town_debug.tscn tools/capture.sh --capture-town
cd "$(dirname "$0")/.."
G="${GODOT:-/f/Godot/Godot_v4.7.2-stable_win64_console.exe}"
EXTRA=()
if [[ "$*" == *--capture* || "$*" == *--citadel-test* ]]; then EXTRA=(--fixed-fps 60); fi
if [[ -n "$SCENE" ]]; then EXTRA+=(--scene "$SCENE"); fi
timeout 300 "$G" --path . --audio-driver Dummy "${EXTRA[@]}" -- "$@" 2>&1 | grep -v '^\s*at:'
exit ${PIPESTATUS[0]}
