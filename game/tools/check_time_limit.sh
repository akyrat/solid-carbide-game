#!/usr/bin/env bash
# Checks the test runner's time limit (task T-137): runs GUT on a test that hangs forever, with a
# short limit, and confirms the runner stops it, exits 124 with a message naming the limit, and
# leaves no Godot process of this project behind.
# Usage, from the repo root:  bash game/tools/check_time_limit.sh [seconds, default 10]
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
secs="${1:-10}"
# Godot processes started for the hang fixture (other task folders may run Godot too; ignore them).
count() { powershell -NoProfile -Command "@(Get-CimInstance Win32_Process | Where-Object { \$_.CommandLine -like '*hang_fixture*' -and \$_.Name -like '*odot*' }).Count" | tr -dc '0-9'; }
out="$(GUT_TIME_LIMIT=$secs bash "$here/run_tests.sh" -gdir=res://tools/hang_fixture -gprefix=test_ 2>&1)"
code=$?
echo "$out" | tail -5
fail=0
[ "$code" -eq 124 ] || { echo "FAIL: exit code $code, expected 124"; fail=1; }
echo "$out" | grep -q "went past $secs seconds" || { echo "FAIL: message does not name the limit"; fail=1; }
sleep 2
after=$(count)
[ "$after" -eq 0 ] || { echo "FAIL: $after Godot process(es) of the fixture still running"; fail=1; }
[ $fail -eq 0 ] && echo "TIME LIMIT CHECK PASSED"
exit $fail
