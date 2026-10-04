#!/usr/bin/env bash
# Imports the project, then checks that every .wav/.ogg/.mp3 under a folder imported
# and loads in Godot as a non-empty AudioStream. Runs headless.
# Usage, from the repo root:
#   bash game/tools/check_audio.sh [res://folder, default res://audio]
# Exit codes: 0 = all load; 1 = bad arguments or no audio files; 2 = a file failed.
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"
dir="${1:-res://audio}"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://tools/check_audio.gd -- "--dir=$dir"
