#!/usr/bin/env bash
# Screenshots of the likes bar's level-up animation (task T-139): the bar just
# before the level-up, then the key frames (0, 1, 2, 4, 5, 6 of 9), each a run
# started from the main menu with a combo showing, plus one image with the
# bottom of all of them one under the other (enlarged 2x, nearest neighbour).
# Usage, from the repo root:  bash game/tools/level_up_flash_shots.sh [out_dir, default screenshots]
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-screenshots}"
mkdir -p "$out"
for f in before f0 f1 f2 f4 f5 f6; do
  bash "$here/screenshot.sh" "res://tests/fixtures/level_up_flash_$f.tscn" "$out/level_up_flash_$f.png" 30
done
python "$here/level_up_flash_strip.py" "$out"
