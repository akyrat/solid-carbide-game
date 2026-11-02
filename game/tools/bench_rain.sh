#!/usr/bin/env bash
# T-507: the rain's cost per frame, headless (bench_rain.gd): the game's run with the rain on
# and off in alternating blocks, mean and median frame times for each, and the rain's own time.
# Usage, from the repo root:
#   bash game/tools/bench_rain.sh [--blocks=6] [--frames=300]
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/bench_rain.gd -- "$@"
