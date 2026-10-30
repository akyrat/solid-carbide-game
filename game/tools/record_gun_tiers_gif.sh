#!/usr/bin/env bash
# Records the gun's tiers GIF (task T-408): a swarm of minions shot at tier 1, tier 6 and tier 11, 5 s each.
# Usage, from the repo root:  bash game/tools/record_gun_tiers_gif.sh <out.gif> [skip, default 2]
# Needs a real window (not headless) and Python with Pillow. Frames go to a temp folder (KEEP_FRAMES=<dir> keeps a copy).
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
out="$1"; skip="${2:-2}"
tmp="$(mktemp -d)"
fps=30
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((15 * fps)) res://tests/fixtures/gun_tiers_gif_demo.tscn
python "$GAME_DIR/tools/frames_to_gif.py" "$tmp" "$out" --fps $((fps / skip)) --skip "$skip" ${GIF_ARGS:-}
if [ -n "${KEEP_FRAMES:-}" ]; then cp -r "$tmp" "$KEEP_FRAMES"; fi
rm -rf "$tmp"
