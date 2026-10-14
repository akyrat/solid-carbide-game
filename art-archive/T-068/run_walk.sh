#!/bin/sh
# usage: run_walk.sh s|se|ne|n ; one paid call, never run twice at once
cd /c/solid-carbide-worktrees/T-068
rot=$(case $1 in s) echo 1;; se) echo 2;; ne) echo 4;; n) echo 5;; esac)
python game/tools/pixellab_client.py generate --endpoint animate-with-text-v3 --params-file art-archive/T-068/walk_$1_req.json --out-dir art-archive/T-068/walk_$1 --name minion_walk_$1 --task T-068 --consulted art-archive/T-068/rotations/minion_rot8_$rot.png --consulted art-archive/T-068/walk2_req.json --consulted https://api.pixellab.ai/v2/openapi.json --notes "T-068 round 4: low-stride walk, direction $1, from rotation $rot" > art-archive/T-068/walk_$1_call.log 2>&1
echo "EXIT $?" >> art-archive/T-068/walk_$1_call.log
