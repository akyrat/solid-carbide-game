# Dot-sourced by the other tools/*.ps1 scripts. Sets $GodotBin, $RepoRoot and $GameDir.
# GODOT_BIN comes from the environment if already set, otherwise from .env at the repo root.

$GameDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoRoot = (Resolve-Path (Join-Path $GameDir '..')).Path
$GodotBin = $env:GODOT_BIN
$envFile = Join-Path $RepoRoot '.env'

if (-not $GodotBin -and (Test-Path $envFile)) {
    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*GODOT_BIN\s*=\s*(.*?)\s*$') {
            $GodotBin = $Matches[1].Trim('"').Trim("'")
        }
    }
}

if (-not $GodotBin) {
    [Console]::Error.WriteLine("GODOT_BIN is not set. Add it to .env at the repo root (see README.md, 'Secrets and API keys').")
    exit 2
}
if (-not (Test-Path -LiteralPath $GodotBin -PathType Leaf)) {
    [Console]::Error.WriteLine("GODOT_BIN points to a file that does not exist: $GodotBin")
    exit 2
}
