#!/usr/bin/env bash
# Records the T-515 GIF: the car's tier 1 hop over a minion. Usage, from the repo root:
#   bash game/tools/record_jump_minion_gif.sh <out.gif> [seconds, default 4] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-4}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/jump_over_minion_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
