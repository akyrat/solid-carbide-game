#!/usr/bin/env bash
# Draws the kaiju's navigation on a level as a PNG (task T-419; see draw_kaiju_nav.gd).
# Usage, from the repo root:
#   bash game/tools/draw_kaiju_nav.sh <out.png> [level, res:// path] [car x] [car y] [x,y ...]
# Example: bash game/tools/draw_kaiju_nav.sh art-archive/T-419/screenshots/kaiju_nav.png
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

out="${1:?usage: draw_kaiju_nav.sh <out.png> [level] [car x] [car y]}"
shift
case "$out" in /*|[A-Za-z]:*) ;; *) out="$(pwd)/$out" ;; esac
if command -v cygpath >/dev/null 2>&1; then out="$(cygpath -m "$out")"; fi

"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/draw_kaiju_nav.gd -- "$out" "$@"
