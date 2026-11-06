#!/usr/bin/env bash
# Records the T-528 sample video: the Polarized Steering Wheel's cooldown on its HUD slot icon,
# 10 s at tier 1 then 10 s at tier 2, as an AVI written by Godot's movie writer. Usage, from the repo root:
#   bash game/tools/record_wheel_cooldown_video.sh <out.avi> [seconds, default 20]
# Needs a real window (not headless).
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-20}"
fps=30
mkdir -p "$(dirname "$out")"
"$GODOT_BIN" --path "$GAME_DIR" --resolution 1280x720 --write-movie "$(cygpath -m "$out")" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/wheel_cooldown_demo.tscn
