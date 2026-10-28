#!/usr/bin/env bash
# Screenshots and GIFs of the live viewers counter (task T-336): stills of each look
# (base, the three heat steps, on fire), a GIF of tricks' "+viewers" flying into the
# counter and a GIF of a crash.
# Usage, from the repo root:  bash game/tools/record_viewers_counter.sh [out_dir, default art-archive/T-336/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-336/screenshots}"
mkdir -p "$out"
out_abs="$(cd "$out" && pwd)"
if command -v cygpath >/dev/null 2>&1; then out_abs="$(cygpath -m "$out_abs")"; fi
scene=res://tests/fixtures/viewers_counter_demo.tscn
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
VIEWERS_DEMO_MODE=stills VIEWERS_PNG_PREFIX="$out_abs/counter" "$GODOT_BIN" --path "$GAME_DIR" "$scene"
fps=30
for mode in trick crash; do
  tmp="$(mktemp -d)"
  secs=4
  [ "$mode" = crash ] && secs=3
  VIEWERS_DEMO_MODE=$mode "$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) "$scene"
  python "$here/viewers_counter_gif.py" "$tmp" "$out/viewers_$mode.gif"
  rm -rf "$tmp"
done
