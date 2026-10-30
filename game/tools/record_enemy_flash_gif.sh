#!/usr/bin/env bash
# Records the enemy red flash GIF (task T-404): a minion hit, the car's blink and the car driving out of a swarm.
# Usage, from the repo root:  bash game/tools/record_hearts_gif.sh <out.gif> [seconds, default 5] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. Frames go to a temp folder (KEEP_FRAMES=<dir> keeps a copy).
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-5}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/enemy_flash_gif_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
