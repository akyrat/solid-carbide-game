#!/usr/bin/env bash
# Screenshots of the hearts row (task T-338): full, after a hit, with a garage heart.
# Usage, from the repo root:  bash game/tools/record_heart_row.sh [out_dir, default art-archive/T-338/screenshots]
# Needs a real window (not headless).
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out="${1:-art-archive/T-338/screenshots}"
mkdir -p "$out"
for m in full hit garage; do
  HEART_MODE=$m bash "$here/screenshot.sh" res://tests/fixtures/heart_row_demo.tscn "$out/hearts_$m.png" 40
done
