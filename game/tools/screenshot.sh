#!/usr/bin/env bash
# Runs a scene for N frames and saves a PNG screenshot. Opens a window briefly (a real
# renderer is needed, so this cannot run with --headless).
# Usage, from the repo root:
#   bash game/tools/screenshot.sh <res://scene.tscn> <out.png> [frames, default 60]
# Relative output paths are resolved against the current directory.
# Save screenshots outside game/ (e.g. screenshots/ at the repo root), or Godot will import them.
set -u
if [ $# -lt 2 ]; then
  echo "Usage: bash game/tools/screenshot.sh <res://scene.tscn> <out.png> [frames]" >&2
  exit 1
fi
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

scene="$1"
out="$2"
frames="${3:-60}"
case "$out" in
  /*|[A-Za-z]:*) ;;
  *) out="$(pwd)/$out" ;;
esac
# Convert a Git Bash path (/c/...) to a Windows path Godot understands.
if command -v cygpath >/dev/null 2>&1; then out="$(cygpath -m "$out")"; fi

"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" -s res://tools/screenshot.gd -- \
  --scene="$scene" --frames="$frames" --out="$out"
