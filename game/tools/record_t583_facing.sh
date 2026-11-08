#!/usr/bin/env bash
# Task T-583: records the facing fixture (tests/fixtures/t580_facing_demo.tscn) for each case twice,
# with no fix (T583_COMBO=none) and with the fixes (T583_COMBO, default AC), and writes a side-by-side
# BEFORE / AFTER GIF and stills per case into art-archive/T-583/screenshots/.
# Usage, from the repo root:  bash game/tools/record_t583_facing.sh [case ...]   (AFTER=A, C or AC)
# Frames go to a temporary folder outside game/ (removed at the end). Needs a window (not headless).
set -eu
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
OUT="$REPO_ROOT/art-archive/T-583/screenshots"
AFTER="${AFTER:-AC}"
mkdir -p "$OUT"
cases=("$@")
if [ ${#cases[@]} -eq 0 ]; then
  cases=(straight_screen_315 coast_turn_onto_screen_up_right turn_onto_screen_up_right drift_turn_onto_diagonal)
fi
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for c in "${cases[@]}"; do
  for combo in none "$AFTER"; do
    mkdir -p "$TMP/$c/$combo"
    T580_CASE="$c" T583_COMBO="$combo" timeout 180 "$GODOT_BIN" --path "$GAME_DIR" --fixed-fps 50 \
      --write-movie "$(cygpath -m "$TMP/$c/$combo" 2>/dev/null || echo "$TMP/$c/$combo")/f.png" \
      res://tests/fixtures/t580_facing_demo.tscn >/dev/null 2>&1
  done
  python "$GAME_DIR/tools/t583_before_after.py" "$TMP/$c/none" "$TMP/$c/$AFTER" "$OUT" "$c"
done
