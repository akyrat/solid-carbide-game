"""Checks that level_up_texts.gd holds a text task's card table word for word (task T-173).

Usage, from the repo root:
    python game/tools/check_level_up_texts.py [tasks/T-171-text-level-up-cards-for-the.md]

Reads the Markdown table in the task's result notes (| key | title | description |), then
compares every row with the "<key>.title" and "<key>.desc" entries of
game/scripts/ui/level_up_texts.gd. Prints each mismatch or missing key and exits 1 on any.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEXTS_GD = ROOT / "game" / "scripts" / "ui" / "level_up_texts.gd"
DEFAULT_TASK = ROOT / "tasks" / "T-171-text-level-up-cards-for-the.md"

ROW = re.compile(r"^\|\s*([a-z_]+(?:\.tier\d+)?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$")
ENTRY = re.compile(r'^\s*"([^"]+)":\s*"((?:[^"\\]|\\.)*)",?\s*$')


def table_rows(markdown: str) -> dict:
    """{key: (title, desc)} from a | Key | Title | Description | table (header rows skipped)."""
    rows = {}
    for line in markdown.splitlines():
        m = ROW.match(line)
        if m and m.group(1) != "key":
            rows[m.group(1)] = (m.group(2), m.group(3))
    return rows


def gd_texts(source: str) -> dict:
    """{key: text} from the TEXTS dictionary of level_up_texts.gd."""
    out = {}
    for line in source.splitlines():
        m = ENTRY.match(line)
        if m:
            out[m.group(1)] = m.group(2).replace('\\"', '"')
    return out


def compare(rows: dict, texts: dict) -> list:
    problems = []
    for key, (title, desc) in rows.items():
        for suffix, want in ((".title", title), (".desc", desc)):
            got = texts.get(key + suffix)
            if got is None:
                problems.append(f"missing: {key}{suffix}")
            elif got != want:
                problems.append(f"differs: {key}{suffix}: {got!r} != {want!r}")
    return problems


def main(argv) -> int:
    task = Path(argv[1]) if len(argv) > 1 else DEFAULT_TASK
    rows = table_rows(task.read_text(encoding="utf-8"))
    problems = compare(rows, gd_texts(TEXTS_GD.read_text(encoding="utf-8")))
    for p in problems:
        print(p)
    print(f"{len(rows)} rows checked, {len(problems)} problems")
    return 1 if problems or not rows else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
