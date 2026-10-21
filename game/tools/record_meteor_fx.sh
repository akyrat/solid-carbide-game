#!/usr/bin/env bash
# Records a GIF of the meteor effects fixture for one version (task T-070).
# Usage, from the repo root:  bash game/tools/record_meteor_fx.sh <pixel|pixellab|particles|off> <out.gif> [seconds, default 7]
# Needs a real window (not headless) and Python with Pillow. Frames go to a temp folder.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
ver="$1"; out="$2"; secs="${3:-7}"
tmp="$(mktemp -d)"
fps=30
export METEOR_FX="$ver"
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/meteor_fx_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps 15 --skip 2
rm -rf "$tmp"
