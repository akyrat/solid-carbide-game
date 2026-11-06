#!/usr/bin/env bash
# Before and after a change to the minions' code, measured in turns under the same load (task
# T-538): the machine's other work moves the crowd benchmark's numbers a lot from one minute to
# the next, so each round measures the old code (game/scripts/enemies/*.gd as they are at
# --before, a git ref) and then the current code, one right after the other, with
# minion_crowd_bench.sh, and adds every measure to one CSV (labels "before" and "after").
# The current files are put back afterwards, also when the run is stopped.
# Usage, from the repo root:
#   bash game/tools/minion_crowd_ab.sh --csv=ABSOLUTE_PATH [--before=master] [--rounds=3] [--window]
#       [--counts=100,200,400] [--seconds=5]
# Then: python game/tools/plot_minion_crowd.py ABSOLUTE_PATH --out art-archive/<task>/screenshots/<name>.png
# Exit codes: 0 = measured; 1 = a measure failed; 2 = bad arguments.
set -u
TOOLS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME="$(cd "$TOOLS/.." && pwd)"
REPO="$(cd "$GAME/.." && pwd)"
before=master
rounds=3
csv=""
bench=()
for a in "$@"; do
  case "$a" in
    --before=*) before="${a#--before=}" ;;
    --rounds=*) rounds="${a#--rounds=}" ;;
    --csv=*) csv="${a#--csv=}"; bench+=("$a") ;;
    --window|--counts=*|--seconds=*|--warmup=*|--seed=*) bench+=("$a") ;;
    *) echo "minion_crowd_ab: unknown argument $a" >&2; exit 2 ;;
  esac
done
if [ -z "$csv" ]; then
  echo "minion_crowd_ab: --csv=ABSOLUTE_PATH is needed" >&2
  exit 2
fi
if ! git -C "$REPO" rev-parse -q --verify "$before^{commit}" >/dev/null; then
  echo "minion_crowd_ab: no such git ref: $before" >&2
  exit 2
fi
keep="$(mktemp -d)"
cp "$GAME"/scripts/enemies/*.gd "$keep/"
restore() {
  cp "$keep"/*.gd "$GAME/scripts/enemies/"
  rm -rf "$keep"
}
trap restore EXIT
use_before() {
  for f in "$keep"/*.gd; do
    local name
    name="$(basename "$f")"
    if git -C "$REPO" cat-file -e "$before:game/scripts/enemies/$name" 2>/dev/null; then
      git -C "$REPO" show "$before:game/scripts/enemies/$name" > "$GAME/scripts/enemies/$name"
    fi
  done
}
status=0
for r in $(seq 1 "$rounds"); do
  use_before
  echo "minion_crowd_ab: round $r, before ($before)"
  bash "$TOOLS/minion_crowd_bench.sh" "${bench[@]}" --label=before | grep "alive" | awk '!seen[$0]++' || status=1
  cp "$keep"/*.gd "$GAME/scripts/enemies/"
  echo "minion_crowd_ab: round $r, after (the current code)"
  bash "$TOOLS/minion_crowd_bench.sh" "${bench[@]}" --label=after | grep "alive" | awk '!seen[$0]++' || status=1
done
exit $status
