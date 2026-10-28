#!/usr/bin/env bash
# Screenshots and a GIF of the sub goal square (task T-337): part-filled with
# the grey gift, the goal reached (lit, glowing), and a GIF of subs coming in,
# reaching the goal, the celebration and the restart.
# Usage, from the repo root:  bash game/tools/record_sub_goal.sh [out_dir, default art-archive/T-337/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-337/screenshots}"
mkdir -p "$out"
for m in part lit; do
  SUB_GOAL_MODE=$m bash "$here/screenshot.sh" res://tests/fixtures/sub_goal_demo.tscn "$out/sub_goal_$m.png" 40
done
tmp="$(mktemp -d)"
fps=30
SUB_GOAL_MODE=gif "$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((6 * fps)) res://tests/fixtures/sub_goal_demo.tscn
# The right edge at 1152 x 648: the square (x988 y340, 128 x 180) with room for the glow and flames.
python "$here/likes_spring_gif.py" "$tmp" "$out/sub_goal_reaching_goal.gif" --box 900 290 1152 540 --scale 2
rm -rf "$tmp"
