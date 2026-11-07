#!/usr/bin/env bash
# Records the running totals GIF (task T-565): the drift slide's total of drift seconds growing to
# 3 s, then a run's airtime mission total growing as landings add their seconds.
# Usage, from the repo root:  bash game/tools/record_running_total_gif.sh <out.gif> [seconds, default 14] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. GIF_ARGS passes more frames_to_gif.py
# arguments (default: the whole screen at 60%).
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-14}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/running_total_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:---crop 1.0 --scale 0.6 --shared}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
