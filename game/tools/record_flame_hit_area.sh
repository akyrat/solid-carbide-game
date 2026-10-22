#!/usr/bin/env bash
# Records a GIF of the flame hit-area fixture (task T-267): a tier 1 drift through still minions,
# the flame's hit area outlined in green.
# Usage, from the repo root:  bash game/tools/record_flame_hit_area.sh <out.gif> [seconds, default 6] [scene, default flame_hit_area_gif]
# Needs a real window (not headless) and Python with Pillow. Frames go to a temp folder.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-6}"; scene="${3:-flame_hit_area_gif}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) "res://tests/fixtures/weapons/$scene.tscn"
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps 15 --skip 2
rm -rf "$tmp"
