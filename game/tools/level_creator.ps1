# Opens the level creator (task T-234): a separate app, not reachable from the game's menus.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/level_creator.ps1
. (Join-Path $PSScriptRoot 'godot_env.ps1')

& $GodotBin --path $GameDir res://scenes/level_creator/level_creator.tscn
exit $LASTEXITCODE
