#!/usr/bin/env bash
# Records the notebook fall GIF (task T-563): tricks falling into the mission notebook page in a run.
# Usage, from the repo root:  bash game/tools/record_notebook_fall_gif.sh <out.gif> [seconds, default 8] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. Crops to the page's corner of the screen.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-8}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/notebook_fall_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
