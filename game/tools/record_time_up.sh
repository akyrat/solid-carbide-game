#!/usr/bin/env bash
# Screenshot and GIF of the time's up screen (task T-317): a run whose clock runs out
# at about 2 s freezes at 0:00, the time's up screen plays for 3 seconds, then the recap (T-320).
# Usage, from the repo root:  bash game/tools/record_time_up.sh [out_dir, default art-archive/T-317/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-317/screenshots}"
mkdir -p "$out"
scene=res://tests/fixtures/time_up_demo.tscn
fps=30
secs=6
tmp="$(mktemp -d)"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) $scene
# The clock runs out at about 2 s (frame 61); the screen plays to about 5 s (frame 151), then the recap.
# Screenshot: 1.5 s into the screen, the crack open. GIF: from 1.9 s to 5.4 s (the whole 3 seconds and the recap
# after), every second frame (15 fps).
python - "$tmp" "$out" "$here" <<'PY'
import shutil, sys
from pathlib import Path
sys.path.insert(0, sys.argv[3])
import likes_spring_gif as g
src = Path(sys.argv[1]); out = Path(sys.argv[2])
files = sorted(src.glob("*.png"))
print(len(files), "frames recorded")
shutil.copy(files[106], out / "time_up.png")
keep = Path(src / "gif"); keep.mkdir()
for i, f in enumerate(files[57:162]):
    if i % 2 == 0:
        shutil.copy(f, keep / f.name)
print(g.build(str(keep), str(out / "time_up.gif"), fps=15, scale=1, colors=64), "GIF frames")
PY
rm -rf "$tmp"
