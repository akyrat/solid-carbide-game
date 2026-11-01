#!/usr/bin/env bash
# Runs the whole GUT test suite headless.
# Exit code 0 = all tests passed; non-zero = a test failed, or a script failed to parse/load.
# Usage, from the repo root:  bash game/tools/run_tests.sh   (GUT_JOBS=N picks the number of parallel processes, default 12)
# Extra arguments go straight to GUT, e.g.  bash game/tools/run_tests.sh -gselect=test_sample
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

# Time limit (task T-137): a run that goes past it is stopped by this script (only the Godot
# process it started) and fails. A normal full run took about 90 s at first, 270 to 306 s on 2026-10-21, and 889 s on 2026-10-31 (T-372's agent), so the default limit is 1500 s (T-437; it was 900 s, which stopped merges with no test failing). GUT_TIME_LIMIT overrides it.
limit="${GUT_TIME_LIMIT:-1500}"

# Import first so class_name caches and imported resources exist (needed on a fresh clone).
timeout -k 5 "$limit" "$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1

# Parallel run (T-487): a plain full run (no extra GUT arguments) splits the test scripts over several
# headless Godot processes (run_tests_parallel.py) and merges the results. GUT_JOBS sets the number of
# processes (default 12; GUT_JOBS=1 gives the old single-process run). Any extra GUT argument
# (-gselect, -gunit_test_name, ...) keeps the single-process run, since those filter inside one GUT run.
jobs="${GUT_JOBS:-12}"
if [ $# -eq 0 ] && [ "$jobs" -gt 1 ] 2>/dev/null; then
  PY=python
  for cand in python python3 py; do
    if "$cand" -c "import sys" >/dev/null 2>&1; then PY="$cand"; break; fi
  done
  timeout -k 5 "$((limit + 30))" "$PY" "$GAME_DIR/tools/run_tests_parallel.py" --jobs "$jobs" --limit "$limit"
  code=$?
  if [ $code -eq 0 ]; then echo "TESTS PASSED"; else echo "TESTS FAILED (exit $code)" >&2; fi
  exit $code
fi

log="$(mktemp)"
timeout -k 5 "$limit" "$GODOT_BIN" --headless --path "$GAME_DIR" -s res://addons/gut/gut_cmdln.gd -gexit "$@" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}

if [ $code -eq 124 ] || [ $code -eq 137 ]; then
  echo "TIME LIMIT: the test run went past $limit seconds and was stopped (set GUT_TIME_LIMIT to change the limit). Treating the run as failed." >&2
  rm -f "$log"
  echo "TESTS FAILED (exit 124)" >&2
  exit 124
fi

# GUT skips a test file that does not parse and still reports success. Treat that as a failure.
if [ $code -eq 0 ] && grep -q -E 'Parse Error|Failed to load script' "$log"; then
  echo "A script failed to parse or load (see SCRIPT ERROR above). Treating the run as failed." >&2
  code=3
fi
rm -f "$log"

if [ $code -eq 0 ]; then echo "TESTS PASSED"; else echo "TESTS FAILED (exit $code)" >&2; fi
exit $code
