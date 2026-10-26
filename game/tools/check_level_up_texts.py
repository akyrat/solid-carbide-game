"""Checks that level_up_texts.gd holds a text task's card table word for word (task T-173).

Usage, from the repo root:
    python game/tools/check_level_up_texts.py [tasks/T-171-text-level-up-cards-for-the.md]

With no argument, T-171's table is used with the newer texts of T-301 (the Greenbull texts,
task T-302) put over the ones they replaced.

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
# Later text tasks that replaced some of T-171's texts; their "New (final)" column wins.
NEWER_TASKS = [ROOT / "tasks" / "T-301-text-the-level-up-screen-its.md"]

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


def newer_texts(markdown: str) -> dict:
    """{key: new text} from a later text task's | Key | File | Old | New (final) | ... | table.

    Keys are full text keys ("upgrade_molotov.tier2.desc"); rows whose key has no
    .title/.desc suffix (garage keys) are kept too and simply match no card row.
    """
    out = {}
    for line in markdown.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 4 and line.lstrip().startswith("|") and cells[0] not in ("Key", "") \
                and not set(cells[0]) <= set("-:"):
            out[cells[0]] = cells[3]
    return out


def apply_newer(rows: dict, newer: dict) -> dict:
    """The card table with a later task's texts put over the old ones it replaced."""
    rows = dict(rows)
    for full_key, text in newer.items():
        base, _, suffix = full_key.rpartition(".")
        if base in rows and suffix in ("title", "desc"):
            title, desc = rows[base]
            rows[base] = (text, desc) if suffix == "title" else (title, text)
    return rows


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


def expected_rows(task: Path = DEFAULT_TASK, newer_tasks=NEWER_TASKS) -> dict:
    """T-171's card table with every later text task's replacements applied, in order."""
    rows = table_rows(task.read_text(encoding="utf-8"))
    for newer in newer_tasks:
        rows = apply_newer(rows, newer_texts(newer.read_text(encoding="utf-8")))
    return rows


def main(argv) -> int:
    if len(argv) > 1:
        rows = table_rows(Path(argv[1]).read_text(encoding="utf-8"))
    else:
        rows = expected_rows()
    problems = compare(rows, gd_texts(TEXTS_GD.read_text(encoding="utf-8")))
    for p in problems:
        print(p)
    print(f"{len(rows)} rows checked, {len(problems)} problems")
    return 1 if problems or not rows else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
