#!/usr/bin/env bash
# Screenshot and GIF of the wreck (task T-360): the car at speed loses its last heart,
# slides on with dead controls, smokes and burns for 3 seconds, then the main menu.
# Usage, from the repo root:  bash game/tools/record_wreck.sh [out_dir, default art-archive/T-360/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-360/screenshots}"
mkdir -p "$out"
scene=res://tests/fixtures/wreck_demo.tscn
fps=30
secs=6
tmp="$(mktemp -d)"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) $scene
# The last heart goes at 1.5 s (frame 45); the wreck runs to 4.5 s, then the menu.
# Screenshot: 1.2 s into the wreck. GIF: from 1.0 s to 5.0 s, every second frame (15 fps).
python - "$tmp" "$out" "$here" <<'PY'
import shutil, sys
from pathlib import Path
sys.path.insert(0, sys.argv[3])
import likes_spring_gif as g
src = Path(sys.argv[1]); out = Path(sys.argv[2])
files = sorted(src.glob("*.png"))
print(len(files), "frames recorded")
shutil.copy(files[81], out / "wreck.png")
keep = Path(src / "gif"); keep.mkdir()
for i, f in enumerate(files[30:150]):
    if i % 2 == 0:
        shutil.copy(f, keep / f.name)
print(g.build(str(keep), str(out / "wreck.gif"), fps=15, scale=1, colors=64), "GIF frames")
PY
rm -rf "$tmp"
