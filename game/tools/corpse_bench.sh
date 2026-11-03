#!/usr/bin/env bash
# Cost of the minions corpses and green spills (task T-531): kills a crowd in bursts with the corpses off and on and prints frame times. Headless.
# Usage, from the repo root: bash game/tools/corpse_bench.sh [--seconds=8] [--kills=40] [--every=0.5] [--crowd=60]
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --fixed-fps 50 --path "$GAME_DIR" -s res://tools/corpse_bench.gd -- "$@"
