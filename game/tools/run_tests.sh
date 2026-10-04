#!/usr/bin/env bash
# Runs the whole GUT test suite headless.
# Exit code 0 = all tests passed; non-zero = a test failed, or a script failed to parse/load.
# Usage, from the repo root:  bash game/tools/run_tests.sh
# Extra arguments go straight to GUT, e.g.  bash game/tools/run_tests.sh -gselect=test_sample
set -u
source "$(dirname "${BASH_SOURCE[0]}")/godot_env.sh"

# Import first so class_name caches and imported resources exist (needed on a fresh clone).
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1

log="$(mktemp)"
"$GODOT_BIN" --headless --path "$GAME_DIR" -s res://addons/gut/gut_cmdln.gd -gexit "$@" 2>&1 | tee "$log"
code=${PIPESTATUS[0]}

# GUT skips a test file that does not parse and still reports success. Treat that as a failure.
if [ $code -eq 0 ] && grep -q -E 'Parse Error|Failed to load script' "$log"; then
  echo "A script failed to parse or load (see SCRIPT ERROR above). Treating the run as failed." >&2
  code=3
fi
rm -f "$log"

if [ $code -eq 0 ]; then echo "TESTS PASSED"; else echo "TESTS FAILED (exit $code)" >&2; fi
exit $code
