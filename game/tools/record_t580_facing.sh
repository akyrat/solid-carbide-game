#!/usr/bin/env bash
# Task T-580 (investigation): records the facing-versus-travel fixture for each case, one physics
# step per frame, and makes a GIF and a few stills per case in art-archive/T-580/screenshots/.
# Usage, from the repo root:  bash game/tools/record_t580_facing.sh [case ...]
# Frames go to a temporary folder outside game/ (removed at the end). Needs a window (not headless).
set -eu
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
OUT="$REPO_ROOT/art-archive/T-580/screenshots"
mkdir -p "$OUT"
cases=("$@")
if [ ${#cases[@]} -eq 0 ]; then
  cases=(coast_turn_onto_screen_up_right turn_onto_screen_up_right coast_then_throttle drift_turn_onto_diagonal straight_screen_315 straight_screen_45)
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for c in "${cases[@]}"; do
  mkdir -p "$TMP/$c"
  T580_CASE="$c" timeout 180 "$GODOT_BIN" --path "$GAME_DIR" --fixed-fps 50 \
    --write-movie "$(cygpath -m "$TMP/$c" 2>/dev/null || echo "$TMP/$c")/f.png" \
    res://tests/fixtures/t580_facing_demo.tscn >/dev/null 2>&1
  python "$GAME_DIR/tools/t580_pick_stills.py" "$TMP/$c" "$OUT" "$c"
done
