#!/usr/bin/env bash
# How fast the game runs with a crowd of minions on Kaiju City (task T-444, T-538). Holds each
# count of minions alive round the parked car and prints the average, 99th percentile and worst
# frame, physics and minion-step times (game/docs/enemies/minions.md, "Performance").
# --fixed-fps 50 makes every frame exactly one of the game's physics steps.
# Usage, from the repo root:
#   bash game/tools/minion_crowd_bench.sh [--window] [--counts=50,100,200,300] [--seconds=6] [--warmup=1]
#       [--seed=444] [--breakdown] [--csv=ABSOLUTE_PATH] [--label=TEXT]
# Headless by default (no drawing). T-538: --window opens the game's window (1152 x 648, vsync
# off) so the frame time also holds drawing the crowd; --csv adds the numbers to a CSV file
# (tools/plot_minion_crowd.py plots it).
# Exit codes: 0 = measured; 1 = the run did not start; 2 = bad arguments or no Godot.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
mode=(--headless)
args=()
for a in "$@"; do
  if [ "$a" = "--window" ]; then
    mode=(--disable-vsync --resolution 1152x648)
  else
    args+=("$a")
  fi
done
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" "${mode[@]}" --fixed-fps 50 --path "$GAME_DIR" -s res://tools/minion_crowd_bench.gd -- "${args[@]}"
