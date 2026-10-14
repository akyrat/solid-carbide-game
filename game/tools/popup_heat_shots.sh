#!/usr/bin/env bash
# The trick popups' combo heat steps (task T-133):
# - <out>/T-133_popups_heat.png: a run with one row of popups per step
#   (tests/fixtures/popups_heat_demo.tscn), and T-133_popups_heat_zoom.png,
#   its popups enlarged 2x (nearest neighbour);
# - <out>/T-133_popups_heat_sheet.png and ..._sheet_f3.png: the baked popups
#   alone, a column per step, on dark and light, enlarged 3x (two flame frames);
# - <out>/T-133_combo_heat_<step>.png: T-131's four combo fixtures (the real
#   combo path), where the popups at the car match the HUD counter's step.
# Usage, from the repo root:  bash game/tools/popup_heat_shots.sh [out_dir, default screenshots]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-screenshots}"
mkdir -p "$out"
abs="$(cd "$out" && pwd)"
if command -v cygpath >/dev/null 2>&1; then abs="$(cygpath -m "$abs")"; fi
bash "$here/screenshot.sh" res://tests/fixtures/popups_heat_demo.tscn "$out/T-133_popups_heat.png" 10
python -c "
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB')
c = im.crop((200, 60, 900, 440))
c.resize((c.width * 2, c.height * 2), Image.NEAREST).save(sys.argv[2])
" "$out/T-133_popups_heat.png" "$out/T-133_popups_heat_zoom.png"
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/popup_heat_sheet.gd -- --out="$abs/T-133_popups_heat_sheet.png"
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/popup_heat_sheet.gd -- --out="$abs/T-133_popups_heat_sheet_f3.png" --frame=3
for step in base step1 step2 step3; do
  bash "$here/screenshot.sh" "res://tests/fixtures/combo_heat_$step.tscn" "$out/T-133_combo_heat_$step.png" 30
done
