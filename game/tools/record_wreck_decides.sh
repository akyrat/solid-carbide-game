#!/usr/bin/env bash
# Screenshots of the wreck deciding the loss at its end (task T-413): the wrecked car's
# magnet pulls coins in and the HUD's coins rise, then a kaiju kill during the wreck
# shows the win recap.
# Usage, from the repo root:  bash game/tools/record_wreck_decides.sh [out_dir, default art-archive/T-413/screenshots]
# Needs a real window (not headless).
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-413/screenshots}"
mkdir -p "$out"
scene=res://tests/fixtures/wreck_decides_demo.tscn
fps=30
secs=5
tmp="$(mktemp -d)"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) $scene
# The last heart goes at about 1.5 s (frame 45), the kaiju kill at about 3.3 s (frame 99).
files=("$tmp"/*.png)
echo "${#files[@]} frames recorded"
pick() { local i=$1; [ "$i" -ge "${#files[@]}" ] && i=$((${#files[@]} - 1)); echo "${files[$i]}"; }
cp "$(pick 48)" "$out/1_wreck_starts.png"
cp "$(pick 80)" "$out/2_wreck_coins_pulled.png"
cp "$(pick 140)" "$out/3_kaiju_kill_win_recap.png"
rm -rf "$tmp"
