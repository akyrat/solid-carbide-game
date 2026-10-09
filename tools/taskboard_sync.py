"""Keep the task board page (tools/taskboard/taskboard.html) in step with the task files.

The task files in tasks/ are the source of truth. The page shows them from its own small
database, which the Project Lead fills with this script's output, and the board can drag
tickets between columns there. A drag is a request: it is applied to the task files here,
then the page is refreshed from the files.

Usage, from the repo root:

  python tools/taskboard_sync.py export OUT_DIR
      Writes one JSON document per task to OUT_DIR/<id>.json, plus OUT_DIR/_meta.json.

  python tools/taskboard_sync.py apply MOVES_JSON
      MOVES_JSON is a list of {"id": "T-012", "status": "in-progress"} objects (the
      tickets the board moved). Sets each task file's status line and prints what changed.
"""

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TASKS_DIR = ROOT / "tasks"
STATUSES = ["open", "in-progress", "in-qa", "needs-playtest", "blocked", "flagged-for-review", "done", "cancelled"]
HEADER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
FIELD_RE = re.compile(r"^(\w+): ?(.*)$", re.M)
LIST_FIELDS = {"depends_on", "documents_affected", "files_to_read_first", "files_expected_to_change"}


def parse_list(value):
    value = value.strip()
    if not (value.startswith("[") and value.endswith("]")):
        return [value] if value else []
    return [item.strip() for item in value[1:-1].split(",") if item.strip()]


def parse_header(text):
    """The task file's header fields; list fields become lists. None if there is no header."""
    match = HEADER_RE.match(text.replace("\r\n", "\n"))
    if not match:
        return None
    fields = {}
    for key, value in FIELD_RE.findall(match.group(1)):
        fields[key] = parse_list(value) if key in LIST_FIELDS else value.strip()
    return fields


def ticket(path):
    """The document the page shows for one task file."""
    fields = parse_header(path.read_text(encoding="utf-8"))
    if not fields or "id" not in fields:
        return None
    return {
        "id": fields["id"],
        "title": fields.get("title", ""),
        "status": fields.get("status", "open"),
        "to": fields.get("to", ""),
        "epic": fields.get("epic", ""),
        "milestone": fields.get("milestone", ""),
        "depends_on": fields.get("depends_on", []),
        "file": f"tasks/{path.name}",
        "model": fields.get("model", ""),
        "file_status": fields.get("status", "open"),   # the page marks a ticket as moved when status differs
    }


def task_files(tasks_dir=TASKS_DIR):
    return sorted(tasks_dir.glob("T-*.md"))


def export(out_dir, tasks_dir=TASKS_DIR):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    tickets = [t for t in (ticket(p) for p in task_files(tasks_dir)) if t]
    for t in tickets:
        (out_dir / f"{t['id']}.json").write_text(json.dumps(t, indent=2), encoding="utf-8")
    meta = {"synced_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "count": len(tickets)}
    (out_dir / "_meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    return tickets


def set_status(text, status):
    """The task file's text with its header's status line set to `status`."""
    if status not in STATUSES:
        raise ValueError(f"unknown status: {status}")
    newline = "\r\n" if "\r\n" in text else "\n"
    match = HEADER_RE.match(text.replace("\r\n", "\n"))
    if not match:
        raise ValueError("no header")
    header = re.sub(r"^status: .*$", f"status: {status}", match.group(1), count=1, flags=re.M)
    body = text.replace("\r\n", "\n")[match.end():]
    return f"---\n{header}\n---\n{body}".replace("\n", newline)


def apply_moves(moves, tasks_dir=TASKS_DIR):
    """Apply the board's moves to the task files; returns (id, old, new) for each change."""
    by_id = {}
    for path in task_files(tasks_dir):
        fields = parse_header(path.read_text(encoding="utf-8"))
        if fields and "id" in fields:
            by_id[fields["id"]] = (path, fields.get("status"))
    changed = []
    for move in moves:
        path, old = by_id[move["id"]]
        if old == move["status"]:
            continue
        text = path.read_bytes().decode("utf-8")   # keeps CRLF line endings as they are
        path.write_bytes(set_status(text, move["status"]).encode("utf-8"))
        changed.append((move["id"], old, move["status"]))
    return changed


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) == 2 and argv[0] == "export":
        tickets = export(argv[1])
        print(f"exported {len(tickets)} tickets to {argv[1]}")
        return 0
    if len(argv) == 2 and argv[0] == "apply":
        moves = json.loads(Path(argv[1]).read_text(encoding="utf-8"))
        for tid, old, new in apply_moves(moves):
            print(f"{tid}: {old} -> {new}")
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
