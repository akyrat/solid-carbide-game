#!/usr/bin/env bash
# GIF of T-443's timer spawning: a run played live with the car parked, minions walking in from
# the screen's edges early in the run (clock at 0:05, one every ~1.2 s) and late (clock at 6:40,
# one every ~0.3 s), 8 s each, joined into one GIF.
# Usage, from the repo root:  bash game/tools/record_minions_timer_gif.sh [out_dir, default art-archive/T-443/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-443/screenshots}"
mkdir -p "$out"
fps=30
secs=8
tmp="$(mktemp -d)"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
mkdir -p "$tmp/early" "$tmp/late" "$tmp/gif"
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/early/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/minions_timer_early_gif.tscn
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/late/f.png" --fixed-fps $fps --quit-after $((secs * fps)) res://tests/fixtures/minions_timer_late_gif.tscn
# Every second frame (15 fps), early then late, into one folder in order.
python - "$tmp" <<'PY'
import shutil, sys
from pathlib import Path
src = Path(sys.argv[1])
n = 0
for part in ("early", "late"):
    files = sorted((src / part).glob("*.png"))
    print(part, len(files), "frames recorded")
    for i, f in enumerate(files[5:]):
        if i % 2 == 0:
            shutil.copy(f, src / "gif" / ("%05d.png" % n)); n += 1
PY
python "$here/frames_to_gif.py" "$tmp/gif" "$out/minions_timer_early_and_late.gif" --fps 15 --skip 1 --scale 0.5 --crop 1.0 --colors 64 --shared
rm -rf "$tmp"
