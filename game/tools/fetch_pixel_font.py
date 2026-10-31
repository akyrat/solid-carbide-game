"""Downloads Press Start 2P (SIL OFL 1.1) into game/fonts/press_start_2p/ and writes its record.

Usage, from the repo root: python game/tools/fetch_pixel_font.py
"""
import hashlib
import json
import sys
import urllib.request
from pathlib import Path

COMMIT = "main"
BASE = "https://raw.githubusercontent.com/google/fonts/%s/ofl/pressstart2p/" % COMMIT
FILES = ["PressStart2P-Regular.ttf", "OFL.txt"]


def fetch(name: str) -> bytes:
    with urllib.request.urlopen(BASE + name, timeout=120) as r:
        return r.read()


def main() -> int:
    out = Path(__file__).resolve().parent.parent / "fonts" / "press_start_2p"
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    for name in FILES:
        data = fetch(name)
        if name.endswith(".ttf") and data[:4] != b"\x00\x01\x00\x00":
            print("not a TrueType file:", name)
            return 1
        if name == "OFL.txt" and b"SIL OPEN FONT LICENSE" not in data.upper():
            print("not the OFL text")
            return 1
        (out / name).write_bytes(data)
        files[name] = {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
    record = {
        "what": "Press Start 2P, the pixel-art font for the main menu title and its work in progress line (task T-432). Downloaded unmodified.",
        "font": "Press Start 2P",
        "designer": "CodeMan38",
        "licence": "SIL Open Font License, Version 1.1 (OFL.txt in this folder). Allows use, bundling and selling with software, commercial games included; the licence text ships with the font; a modified font may not use the reserved name.",
        "source": BASE,
        "downloaded": "2026-10-30",
        "files": files,
    }
    (out / "press_start_2p.json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
    print("ok", files)
    return 0


if __name__ == "__main__":
    sys.exit(main())
