#!/usr/bin/env bash
# GIF of a wreck revived by a health pickup (task T-406): the car at speed loses its
# last heart, slides on smoking, picks up a health pickup ahead and drives again.
# Usage, from the repo root:  bash game/tools/record_revive.sh [out_dir, default art-archive/T-406/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-406/screenshots}"
mkdir -p "$out"
scene=res://tests/fixtures/revive_demo.tscn
fps=30
secs=5
tmp="$(mktemp -d)"
"$GODOT_BIN" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) $scene
# The last heart goes at 1.5 s (frame 45). Screenshot: 2.6 s (after the pickup). GIF: 1.2 s to 4.2 s, every second frame.
python - "$tmp" "$out" "$here" <<'PY'
import shutil, sys
from pathlib import Path
sys.path.insert(0, sys.argv[3])
import likes_spring_gif as g
src = Path(sys.argv[1]); out = Path(sys.argv[2])
files = sorted(src.glob("*.png"))
print(len(files), "frames recorded")
shutil.copy(files[min(78, len(files) - 1)], out / "revive.png")
keep = Path(src / "gif"); keep.mkdir()
for i, f in enumerate(files[36:126]):
    if i % 2 == 0:
        shutil.copy(f, keep / f.name)
print(g.build(str(keep), str(out / "revive.gif"), fps=15, scale=1, colors=64), "GIF frames")
PY
rm -rf "$tmp"
