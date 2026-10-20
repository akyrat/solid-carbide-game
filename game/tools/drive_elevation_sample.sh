#!/usr/bin/env bash
# The scripted reachability drive on the elevation sample map (task T-195). Runs headless.
# Drives the real car from the street up a 0-to-3 ramp, up a 3-to-6 ramp and off a
# height-6 edge, and prints the layers reached, the jumps, the maximum height and the airtime.
# Usage, from the repo root:
#   bash game/tools/drive_elevation_sample.sh [--csv=<file.csv>] [--plot=<file.png>]
# Example: bash game/tools/drive_elevation_sample.sh --plot=art-archive/T-195/screenshots/height-over-time.png
# Exit codes: 0 = all three layers reached and the car landed; 1 = not; 2 = bad arguments.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

args=()
for a in "$@"; do
  case "$a" in
    --csv=*|--plot=*)
      key="${a%%=*}"
      p="${a#*=}"
      # Paths are given relative to the current directory; Godot runs in game/.
      case "$p" in /*|[A-Za-z]:*) ;; *) p="$(pwd)/$p" ;; esac
      mkdir -p "$(dirname "$p")"
      if command -v cygpath >/dev/null 2>&1; then p="$(cygpath -m "$p")"; fi
      args+=("$key=$p") ;;
    *) args+=("$a") ;;
  esac
done

"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/drive_elevation_sample.gd -- "${args[@]}"
