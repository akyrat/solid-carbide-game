#!/usr/bin/env python3
"""T-300: copy Greenbull's approved emblem (T-294, run 2) and wordmark (T-295, run 1) from the
art archive into game/art/logo/ byte for byte, each with a json record beside it, and move the
old Redgull logo files with git mv into art-archive/T-300/ (done by hand, not here).
Usage: copy_greenbull_logo.py [repo root]; prints the SHA-256 of every copy."""
import hashlib
import json
import shutil
import sys
from pathlib import Path

FILES = [
    ("T-294", "run 2", "greenbull_emblem_128.png", "Greenbull emblem (the bull's head alone), 128 px."),
    ("T-294", "run 2", "greenbull_emblem_64.png", "Greenbull emblem (the bull's head alone), 64 px."),
    ("T-294", "run 2", "greenbull_emblem_32.png", "Greenbull emblem (the bull's head alone), 32 px."),
    ("T-295", "run 1", "greenbull_wordmark.png", "Greenbull wordmark (the head with GREENBULL in pixel letters)."),
]


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def copy_all(root):
    root = Path(root)
    out = root / "game" / "art" / "logo"
    out.mkdir(parents=True, exist_ok=True)
    result = {}
    for ticket, run, name, what in FILES:
        src = root / "art-archive" / ticket / name
        dst = out / name
        shutil.copyfile(src, dst)
        record = {
            "task": "T-300",
            "what": what + " Approved by the board; copied unchanged, no generation, no edit.",
            "source_file": f"art-archive/{ticket}/{name}",
            "source_ticket": ticket,
            "source_run": run,
            "sha256": sha256(dst),
            "prompt": None,
        }
        dst.with_name(name + ".json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
        result[name] = record["sha256"]
    return result


if __name__ == "__main__":
    for n, h in copy_all(sys.argv[1] if len(sys.argv) > 1 else ".").items():
        print(h, n)
