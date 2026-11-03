#!/usr/bin/env bash
# The speed-stacking bot (task T-527). Runs headless; see speed_bot.gd.
# Usage, from the repo root:  bash game/tools/speed_bot.sh [--csv=<file.csv>] [--seconds=60]
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
args=()
for a in "$@"; do
  case "$a" in
    --csv=*)
      p="${a#*=}"
      case "$p" in /*|[A-Za-z]:*) ;; *) p="$(pwd)/$p" ;; esac
      mkdir -p "$(dirname "$p")"
      if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -m "$p")"; fi
      args+=("--csv=$p") ;;
    *) args+=("$a") ;;
  esac
done
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/speed_bot.gd -- "${args[@]}"
