#!/usr/bin/env bash
# Records the notebook pulse GIF (task T-606): the mission notebook page pulsing on progress.
# Usage, from the repo root:  bash game/tools/record_notebook_pulse_gif.sh <out.gif> [seconds, default 8] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. Whole screen at 60%.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-8}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/notebook_pulse_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:---crop 1.0 --scale 0.6 --shared}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
