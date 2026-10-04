# Imports the project, then checks that every .wav/.ogg/.mp3 under a folder imported
# and loads in Godot as a non-empty AudioStream. Runs headless.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/check_audio.ps1 [res://folder, default res://audio]
# Exit codes: 0 = all load; 1 = bad arguments or no audio files; 2 = a file failed.
param([Parameter(Position = 0)][string]$Dir = 'res://audio')
. (Join-Path $PSScriptRoot 'godot_env.ps1')
& $GodotBin --headless --path $GameDir --import *> $null
& $GodotBin --headless --path $GameDir -s res://tools/check_audio.gd -- "--dir=$Dir"
exit $LASTEXITCODE
