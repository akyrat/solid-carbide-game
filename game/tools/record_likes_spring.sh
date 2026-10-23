#!/usr/bin/env bash
# Screenshots and a GIF of the likes bar (task T-273): the plain HUD, the bar
# burning at x4 and the bar springing as likes come in, with a level-up.
# Usage, from the repo root:  bash game/tools/record_likes_spring.sh [out_dir, default art-archive/T-273/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-273/screenshots}"
mkdir -p "$out"
for m in plain burning; do
  LIKES_SPRING_MODE=$m bash "$here/screenshot.sh" res://tests/fixtures/likes_spring_demo.tscn "$out/likes_bar_$m.png" 40
done
tmp="$(mktemp -d)"
fps=30
LIKES_SPRING_MODE=gif "$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((6 * fps)) res://tests/fixtures/likes_spring_demo.tscn
python "$here/likes_spring_gif.py" "$tmp" "$out/likes_bar_spring.gif"
rm -rf "$tmp"
