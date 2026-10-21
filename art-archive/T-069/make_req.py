"""Builds PixelLab request JSON files for T-069 (usage: make_req.py rot|walk <first_frame.png> <out.json> [direction])."""
import base64, json, sys
kind, png, out = sys.argv[1:4]
b64 = base64.b64encode(open(png, "rb").read()).decode()
ff = {"type": "base64", "base64": b64, "format": "png"}
if kind == "rot":
    req = {"first_frame": ff, "description": "a giant Godzilla-style kaiju monster standing upright on two thick legs, heavy tail, small arms, a row of large pale cyan dorsal plates down its back, dark slate green scaly hide, lighter grey-green belly, glowing yellow eyes, isometric pixel art game sprite, same camera and same size in every direction", "no_background": True, "seed": 69002}
else:
    req = {"first_frame": ff, "action": "a heavy, slow kaiju stride: it walks forward on two thick legs, one foot lifting and planting down at a time, the body swaying slightly, the tail swinging behind, small arms swinging, head forward, keep the same colours and the same size", "frame_count": 6, "no_background": True, "seed": 69003}
json.dump(req, open(out, "w"))
