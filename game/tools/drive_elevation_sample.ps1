# The scripted reachability drive on the elevation sample map (task T-195). Runs headless.
# Drives the real car from the street up a 0-to-3 ramp, up a 3-to-6 ramp and off a
# height-6 edge, and prints the layers reached, the jumps, the maximum height and the airtime.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/drive_elevation_sample.ps1 [--csv=<file.csv>] [--plot=<file.png>]
# Exit codes: 0 = all three layers reached and the car landed; 1 = not; 2 = bad arguments.
. (Join-Path $PSScriptRoot 'godot_env.ps1')

# Godot runs in game/, so relative paths are made absolute from the current directory.
function ConvertTo-GodotPath([string]$p) {
    if (-not [System.IO.Path]::IsPathRooted($p)) { $p = Join-Path (Get-Location).Path $p }
    $dir = Split-Path -Parent $p
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    return $p.Replace([char]92, [char]47)
}

$argsOut = @()
foreach ($a in $args) {
    if ($a -like '--csv=*') { $argsOut += ('--csv=' + (ConvertTo-GodotPath $a.Substring(6))) }
    elseif ($a -like '--plot=*') { $argsOut += ('--plot=' + (ConvertTo-GodotPath $a.Substring(7))) }
    else { $argsOut += $a }
}
& $GodotBin --headless --path $GameDir --import *> $null
& $GodotBin --headless --path $GameDir -s res://tools/drive_elevation_sample.gd -- @argsOut
exit $LASTEXITCODE
