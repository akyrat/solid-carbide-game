# Runs the whole GUT test suite headless.
# Exit code 0 = all tests passed; non-zero = a test failed, or a script failed to parse/load.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1
# Extra arguments go straight to GUT, e.g.  ... run_tests.ps1 -gselect=test_sample
. (Join-Path $PSScriptRoot 'godot_env.ps1')

# Import first so class_name caches and imported resources exist (needed on a fresh clone).
& $GodotBin --headless --path $GameDir --import *> $null

# Run through cmd so Godot's stderr is captured as plain text (PowerShell 5.1 wraps it otherwise).
$gutArgs = ($args | ForEach-Object { "`"$_`"" }) -join ' '
$cmdLine = "`"`"$GodotBin`" --headless --path `"$GameDir`" -s res://addons/gut/gut_cmdln.gd -gexit $gutArgs 2>&1`""
$output = & cmd.exe /d /c $cmdLine
$code = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }

# GUT skips a test file that does not parse and still reports success. Treat that as a failure.
if ($code -eq 0 -and ($output | Select-String -Pattern 'Parse Error|Failed to load script' -Quiet)) {
    [Console]::Error.WriteLine("A script failed to parse or load (see SCRIPT ERROR above). Treating the run as failed.")
    $code = 3
}

if ($code -eq 0) { Write-Output "TESTS PASSED" } else { [Console]::Error.WriteLine("TESTS FAILED (exit $code)") }
exit $code
