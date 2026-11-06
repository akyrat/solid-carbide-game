#!/usr/bin/env bash
# Records the T-531 sample video of the minion deaths (tests/fixtures/minion_deaths_demo.tscn):
# a crowd dies to the car's weapons, the green spill, the car and the weapons shoving the corpses,
# then the corpses fading. Writes an AVI directly. Needs a real window (not headless).
# Usage, from the repo root:
#   bash game/tools/record_minion_deaths_video.sh <out.avi> [seconds, default 28]
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-28}"
fps=30
mkdir -p "$(dirname "$out")"
"$GODOT_BIN" --path "$GAME_DIR" --resolution 1280x720 --write-movie "$(cygpath -m "$out")" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/minion_deaths_demo.tscn
# Also a GIF for a phone (set GIF=<out.gif>): the frames as PNGs, then frames_to_gif.py at 640x360, 15 fps.
if [ -n "${GIF:-}" ]; then
  tmp="$(mktemp -d)"
  "$GODOT_BIN" --path "$GAME_DIR" --resolution 1280x720 --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/minion_deaths_demo.tscn
  python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$GIF" --fps 15 --skip 2 --scale 0.5 --crop 1.0 --colors 64 --shared
  rm -rf "$tmp"
fi
