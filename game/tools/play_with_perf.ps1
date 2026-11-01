# Plays the game with the performance recorder on (task T-468; game/docs/game-loop/perf-recorder.md).
# Every run played in this session writes a recording to game/perf/<date-time>/.
# Usage, from the repo root (PowerShell):
#   powershell -ExecutionPolicy Bypass -File game/tools/play_with_perf.ps1
# Then tell the Project Lead, who runs:  python game/tools/analyse_perf.py
$ErrorActionPreference = "Stop"
. "$PSScriptRoot/godot_env.ps1"
& $GodotBin --path $GameDir -- --record-perf
