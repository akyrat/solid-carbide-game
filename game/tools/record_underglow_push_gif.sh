#!/usr/bin/env bash
# Records the neon underglow swarm GIF (task T-409): minions die on the second tick and are nudged back.
# Usage, from the repo root:  bash game/tools/record_underglow_push_gif.sh <out.gif> [seconds, default 8] [skip, default 2]
# Needs a real window (not headless) and Python with Pillow.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; secs="${2:-8}"; skip="${3:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/weapons/underglow_push_gif.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
rm -rf "$tmp"
