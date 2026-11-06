"""Builds the /animate-with-text-v3 request for T-532 (minion death, SE). Usage: python build_req.py <out.json> <seed>"""
import base64, json, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ACTION = (
    "death animation: the lizard is hit and jolts back with its head thrown up, then collapses sideways "
    "onto its belly and side, legs curling and going limp, tail dropping flat, jaw hanging slack, eye closing; "
    "it ends lying still on the ground as a motionless corpse, the last two frames identical and still. "
    "The feet stay in place, it does not slide or move away. No blood, no liquid, no splatter, no particles, no shadow"
)

def main():
    out, seed = sys.argv[1], int(sys.argv[2])
    b64 = base64.b64encode((HERE / "reference_frame0.png").read_bytes()).decode()
    req = {
        "first_frame": {"type": "base64", "base64": b64, "format": "png"},
        "action": ACTION,
        "frame_count": 8,
        "no_background": True,
        "seed": seed,
    }
    Path(out).write_text(json.dumps(req), encoding="utf-8")
    print(out)

if __name__ == "__main__":
    main()
