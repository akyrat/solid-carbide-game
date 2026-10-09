# Checks that challenge drawings can be driven by the car (task T-021). Runs headless.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/check_challenge.ps1 [--save] [--attempts=<folder>] [--set=<tuning key>=<value>] <drawing.json or folder> ...
# Exit codes: 0 = all pass; 1 = at least one fails; 2 = bad arguments or unreadable drawing.
. (Join-Path $PSScriptRoot 'godot_env.ps1')

# Godot runs in game/, so relative paths are made absolute from the current directory.
function ConvertTo-GodotPath([string]$p) {
    if (-not [System.IO.Path]::IsPathRooted($p)) { $p = Join-Path (Get-Location).Path $p }
    return $p.Replace([char]92, [char]47)
}

$argsOut = @()
foreach ($a in $args) {
    if ($a -like '--attempts=*') { $argsOut += ('--attempts=' + (ConvertTo-GodotPath $a.Substring(11))) }
    elseif ($a -like '--*') { $argsOut += $a }
    else { $argsOut += (ConvertTo-GodotPath $a) }
}
& $GodotBin --headless --path $GameDir --import *> $null
& $GodotBin --headless --path $GameDir -s res://tools/check_challenge.gd -- @argsOut
exit $LASTEXITCODE
