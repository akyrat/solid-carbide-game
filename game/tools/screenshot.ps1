# Runs a scene for N frames and saves a PNG screenshot. Opens a window briefly (a real
# renderer is needed, so this cannot run with --headless).
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/screenshot.ps1 <res://scene.tscn> <out.png> [frames, default 60]
# Relative output paths are resolved against the current directory.
# Save screenshots outside game/ (e.g. screenshots/ at the repo root), or Godot will import them.
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Scene,
    [Parameter(Mandatory = $true, Position = 1)][string]$Out,
    [Parameter(Position = 2)][int]$Frames = 60
)
. (Join-Path $PSScriptRoot 'godot_env.ps1')

if (-not [System.IO.Path]::IsPathRooted($Out)) { $Out = Join-Path (Get-Location).Path $Out }
$Out = [System.IO.Path]::GetFullPath($Out).Replace([char]92, [char]47)

& $GodotBin --headless --path $GameDir --import *> $null
& $GodotBin --path $GameDir -s res://tools/screenshot.gd -- "--scene=$Scene" "--frames=$Frames" "--out=$Out"
exit $LASTEXITCODE
