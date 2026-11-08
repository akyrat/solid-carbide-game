# Runs the whole GUT test suite headless.
# Exit code 0 = all tests passed; non-zero = a test failed, or a script failed to parse/load.
# Usage, from the repo root:
#   powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1
# Extra arguments go straight to GUT, e.g.  ... run_tests.ps1 -gselect=test_sample
# A plain full run is split over $env:GUT_JOBS parallel Godot processes (default 12; 1 = one process),
# the same as run_tests.sh (T-487, T-588). Any extra argument keeps the single-process run.
. (Join-Path $PSScriptRoot 'godot_env.ps1')

# Time limit (task T-137): a run that goes past it is stopped by this script (only the process tree
# it started) and fails. The real length of the latest full run is in game/tools/test_run_record.json
# (see game/docs/setup/tests.md, "The parallel run"). $env:GUT_TIME_LIMIT overrides it.
$limit = 1500
if ($env:GUT_TIME_LIMIT) { $limit = [int]$env:GUT_TIME_LIMIT }

# Runs one Godot command line through cmd (so stderr is plain text), with the time limit.
# Returns @{ Code; Output; TimedOut }.
function Invoke-Limited([string]$godotArgs) {
    $out = [System.IO.Path]::GetTempFileName()
    $cmdLine = "/d /c `"`"$GodotBin`" $godotArgs > `"$out`" 2>&1`""
    $p = Start-Process -FilePath cmd.exe -ArgumentList $cmdLine -PassThru -WindowStyle Hidden
    $done = $p.WaitForExit($limit * 1000)
    if (-not $done) {
        & taskkill.exe /PID $p.Id /T /F *> $null
        $p.WaitForExit(10000) | Out-Null
    }
    $text = @(Get-Content -LiteralPath $out -ErrorAction SilentlyContinue)
    Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
    $exit = 124
    if ($done) { $exit = $p.ExitCode }
    return @{ Code = $exit; Output = $text; TimedOut = (-not $done) }
}

# Import first so class_name caches and imported resources exist (needed on a fresh clone).
Invoke-Limited "--headless --path `"$GameDir`" --import" | Out-Null

$jobs = 12
if ($env:GUT_JOBS) { $jobs = [int]$env:GUT_JOBS }

if ($args.Count -eq 0 -and $jobs -gt 1) {
    # Parallel run: run_tests_parallel.py prints the summary and the final TESTS PASSED / TESTS FAILED line.
    $py = $null
    foreach ($cand in @('python', 'python3', 'py')) {
        if (Get-Command $cand -ErrorAction SilentlyContinue) {
            & $cand -c "import sys" *> $null
            if ($LASTEXITCODE -eq 0) { $py = $cand; break }
        }
    }
    if (-not $py) {
        [Console]::Error.WriteLine("Python was not found (needed for the parallel run). Set GUT_JOBS=1 for the single-process run.")
        [Console]::Error.WriteLine("TESTS FAILED (exit 2)")
        exit 2
    }
    $env:GODOT_BIN = $GodotBin
    & $py (Join-Path $PSScriptRoot 'run_tests_parallel.py') --jobs $jobs --limit $limit
    exit $LASTEXITCODE
}

$gutArgs = ($args | ForEach-Object { "`"$_`"" }) -join ' '
$r = Invoke-Limited "--headless --path `"$GameDir`" -s res://addons/gut/gut_cmdln.gd -gexit $gutArgs"
$output = $r.Output
$code = $r.Code
$output | ForEach-Object { Write-Output $_ }

if ($r.TimedOut) {
    [Console]::Error.WriteLine("TIME LIMIT: the test run went past $limit seconds and was stopped (set GUT_TIME_LIMIT to change the limit). Treating the run as failed.")
    [Console]::Error.WriteLine("TESTS FAILED (exit 124)")
    exit 124
}

# GUT skips a test file that does not parse and still reports success. Treat that as a failure.
if ($code -eq 0 -and ($output | Select-String -Pattern 'Parse Error|Failed to load script' -Quiet)) {
    [Console]::Error.WriteLine("A script failed to parse or load (see SCRIPT ERROR above). Treating the run as failed.")
    $code = 3
}

if ($code -eq 0) { Write-Output "TESTS PASSED" } else { [Console]::Error.WriteLine("TESTS FAILED (exit $code)") }
exit $code
