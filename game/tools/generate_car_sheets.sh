#!/usr/bin/env bash
# Draws the placeholder car sprite sheets (T-013) headless, without PixelLab.
# Writes game/art/placeholders/car/car_flat.png, car_iso.png and a JSON file next to each.
# Running it again gives byte-identical files.
# Usage, from the repo root:  bash game/tools/generate_car_sheets.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

"$GODOT_BIN" --headless --path "$GAME_DIR" --script res://tools/generate_car_sheets.gd
code=$?
# Import the new or changed PNGs so Godot (and git) see up-to-date .import files.
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
exit $code
