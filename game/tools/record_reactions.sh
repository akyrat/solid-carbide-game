#!/usr/bin/env bash
# Screenshots and GIFs of the reaction icons (task T-351): a moment of the sub goal's
# burst, the floaters at a high viewer count, a GIF of the burst and a GIF of the
# floaters as the viewer count steps up.
# Usage, from the repo root:  bash game/tools/record_reactions.sh [out_dir, default art-archive/T-351/screenshots]
# Needs a real window (not headless) and Python with Pillow.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/godot_env.sh"
out="${1:-art-archive/T-351/screenshots}"
mkdir -p "$out"
scene=res://tests/fixtures/reactions_demo.tscn
for m in burst float; do
  REACTIONS_MODE=${m}_still bash "$here/screenshot.sh" $scene "$out/reactions_${m}.png" 40
done
fps=30
for m in burst float; do
  tmp="$(mktemp -d)"
  secs=4
  [ "$m" = float ] && secs=16
  REACTIONS_MODE=${m}_gif "$GODOT_BIN" --path "$GAME_DIR" --write-movie "$(cygpath -m "$tmp")/f.png" --fixed-fps $fps --quit-after $((secs * fps)) $scene
  # Every third frame (10 fps) keeps the GIF small.
  python - "$tmp" "$out/reactions_${m}.gif" "$here" <<'PY'
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[3])
import likes_spring_gif as g
files = sorted(Path(sys.argv[1]).glob("*.png"))
for i, f in enumerate(files):
    if i % 3:
        f.unlink()
print(g.build(sys.argv[1], sys.argv[2], fps=10, scale=1, colors=48), "frames")
PY
  rm -rf "$tmp"
done
