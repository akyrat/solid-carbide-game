#!/usr/bin/env bash
# A scripted run for the performance recorder (task T-468; game/docs/game-loop/perf-recorder.md).
# Opens a game window, drives a fixed pattern of drifts for a set time, and prints its frame times.
# Usage, from the repo root:
#   bash game/tools/perf_sample_run.sh [--record-perf] [--seconds=150] [--start-at=300] [--all-weapons]
# With --record-perf the recording goes to game/perf/<date-time>/; then:
#   python game/tools/analyse_perf.py
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" -s res://tools/perf_sample_run.gd -- "$@"
