#!/usr/bin/env bash
# Records the T-612 GIFs: the kaiju's walk, windup or death in a run (fixture
# tests/fixtures/kaiju_anim_demo.tscn). Usage, from the repo root:
#   bash game/tools/record_kaiju_anim_gif.sh <walk|windup|death> <out.gif> [seconds, default 3] [skip, default 2]
# KEEP_FRAMES=<folder> keeps the raw frames. Needs a real window (not headless) and Python with Pillow.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
mode="$1"; out="$2"; secs="${3:-3}"; skip="${4:-2}"
tmp="$(mktemp -d)"
fps=30
KAIJU_ANIM="$mode" "$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/kaiju_anim_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
