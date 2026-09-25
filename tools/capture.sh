#!/usr/bin/env bash
# Run a scene windowed with a capture/bench flag. Usage: tools/capture.sh --capture-all [--only=nova]
# No SCENE= means the sandbox. Another scene: SCENE=res://scenes/town_debug.tscn tools/capture.sh --capture-town
cd "$(dirname "$0")/.."
G="${GODOT:-/f/Godot/Godot_v4.7.2-stable_win64_console.exe}"
EXTRA=()
if [[ "$*" == *--capture* || "$*" == *--citadel-test* || "$*" == *--crowd-test* || "$*" == *--mission-test* ]]; then EXTRA=(--fixed-fps 60); fi
# The project's main scene is the game; every capture and bench written before milestone 4 means the sandbox.
EXTRA+=(--scene "${SCENE:-res://scenes/sandbox.tscn}")
timeout 300 "$G" --path . --audio-driver Dummy "${EXTRA[@]}" -- "$@" 2>&1 | grep -v '^\s*at:'
exit ${PIPESTATUS[0]}
