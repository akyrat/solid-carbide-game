#!/usr/bin/env bash
# Opens the level creator (task T-234): a separate app, not reachable from the game's menus.
# Usage, from the repo root:
#   bash game/tools/level_creator.sh
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

"$GODOT_BIN" --path "$GAME_DIR" res://scenes/level_creator/level_creator.tscn
