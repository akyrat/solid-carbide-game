#!/usr/bin/env bash
# Records one README GIF of the run (task T-217).
# Usage, from the repo root:  bash game/tools/record_readme_gif.sh <street|jump|trick|kaiju|magnet|drop> <out.gif> [seconds, default 6] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. Frames go to a temp folder.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
mode="$1"; out="$2"; secs="${3:-6}"; skip="${4:-2}"
tmp="$(mktemp -d)"
fps=30
export README_GIF="$mode"
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/readme_gif_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
