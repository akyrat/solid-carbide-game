#!/usr/bin/env bash
# Screenshots of the combo's four heat steps (task T-131): base (x1.5), step 1
# (x2.0), step 2 (x3.0) and step 3 (x4.5, the likes bar on fire), each a run
# started from the main menu, plus one image with the bottom of the four
# screens side by side (stacked, enlarged 2x, nearest neighbour).
# Usage, from the repo root:  bash game/tools/combo_heat_shots.sh [out_dir, default screenshots]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-screenshots}"
mkdir -p "$out"
for step in base step1 step2 step3; do
  bash "$here/screenshot.sh" "res://tests/fixtures/combo_heat_$step.tscn" "$out/combo_heat_$step.png" 30
done
python "$here/combo_heat_strip.py" "$out"
