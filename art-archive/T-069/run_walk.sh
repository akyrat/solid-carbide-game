#!/bin/sh
# usage: run_walk.sh <dir> <rotation index> ; one paid call, never run twice at once
cd /c/solid-carbide-worktrees/T-069
python art-archive/T-069/make_req.py walk art-archive/T-069/rotations/kaiju_rot8_$2.png art-archive/T-069/walk_$1_req.json
python game/tools/pixellab_client.py generate --endpoint animate-with-text-v3 --params-file art-archive/T-069/walk_$1_req.json --out-dir art-archive/T-069/walk_$1 --name kaiju_walk_$1 --task T-069 --consulted art-archive/T-069/rotations/kaiju_rot8_$2.png --consulted docs/visual-style.md --notes "T-069 full set: 6-frame walk, direction $1, from rotation $2" > art-archive/T-069/walk_$1_call.log 2>&1
echo "EXIT $?" >> art-archive/T-069/walk_$1_call.log
