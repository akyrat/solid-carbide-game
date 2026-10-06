# Draws the placeholder car sprite sheets (T-013) headless, without PixelLab.
# Writes game/art/placeholders/car/car_flat.png, car_iso.png and a JSON file next to each.
# Running it again gives byte-identical files.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1
. (Join-Path $PSScriptRoot 'godot_env.ps1')

& $GodotBin --headless --path $GameDir --script res://tools/generate_car_sheets.gd
$code = $LASTEXITCODE
# Import the new or changed PNGs so Godot (and git) see up-to-date .import files.
& $GodotBin --headless --path $GameDir --import *> $null
exit $code
