#!/usr/bin/env bash
# Checks that challenge drawings can be driven by the car (task T-021). Runs headless.
# Usage, from the repo root:
#   bash game/tools/check_challenge.sh [--save] [--attempts=<folder>] [--set=<tuning key>=<value>] <drawing.json or folder> ...
# Example: bash game/tools/check_challenge.sh --save docs/level-design
# Exit codes: 0 = all pass; 1 = at least one fails; 2 = bad arguments or unreadable drawing.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

args=()
for a in "$@"; do
  case "$a" in
    --attempts=*)
      d="${a#--attempts=}"
      case "$d" in /*|[A-Za-z]:*) ;; *) d="$(pwd)/$d" ;; esac
      if command -v cygpath >/dev/null 2>&1; then d="$(cygpath -m "$d")"; fi
      args+=("--attempts=$d") ;;
    --*) args+=("$a") ;;
    *)
      # Drawings are given relative to the current directory; Godot runs in game/.
      case "$a" in /*|[A-Za-z]:*) p="$a" ;; *) p="$(pwd)/$a" ;; esac
      if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -m "$p")"; fi
      args+=("$p") ;;
  esac
done

"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/check_challenge.gd -- "${args[@]}"
