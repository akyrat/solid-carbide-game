"""Keep the task board page (tools/taskboard/taskboard.html) in step with the task files.

The task files in tasks/ are the source of truth. The page shows them from its own small
database, which the Project Lead fills with this script's output, and the board can drag
tickets between columns there. A drag is a request: it is applied to the task files here,
then the page is refreshed from the files.

Usage, from the repo root:

  python tools/taskboard_sync.py export OUT_DIR [WORKTREES_DIR]
      Writes one JSON document per task to OUT_DIR/<id>.json, plus OUT_DIR/_meta.json.
      With WORKTREES_DIR (normally C:/solid-carbide-worktrees), a task whose branch is open
      in WORKTREES_DIR/<id> is read from there, since its task file is edited on its branch.

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
REVIEW_RE = re.compile(r"^The board's review:\s*(.+)$", re.M)
REVIEW_FILES_RE = re.compile(r"^Board review files:\s*(.+)$", re.M)
NOTES_RE = re.compile(r"^## Result notes[ \t]*\n(.*)\Z", re.S | re.M)
NOTES_PLACEHOLDER = "Written by the agent when it finishes."
NOTES_MAX = 20000


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


def review_parts(text):
    """The board's review line, the files it names, and the result notes, from a task file."""
    text = text.replace("\r\n", "\n")
    review = REVIEW_RE.search(text)
    files = REVIEW_FILES_RE.search(text)
    notes = NOTES_RE.search(text)
    notes_text = notes.group(1).strip() if notes else ""
    if notes_text == NOTES_PLACEHOLDER:
        notes_text = ""
    if len(notes_text) > NOTES_MAX:
        notes_text = notes_text[:NOTES_MAX] + "\n\n(Cut short here; the rest is in the task file.)"
    return (review.group(1).strip() if review else "",
            parse_list(files.group(1)) if files else [],
            notes_text)


def ticket(path, folder=""):
    """The document the page shows for one task file. `folder` is the task's branch folder, if open."""
    text = path.read_text(encoding="utf-8")
    fields = parse_header(text)
    if not fields or "id" not in fields:
        return None
    review, review_files, notes = review_parts(text)
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
        "qa_rounds": int(fields.get("qa_rounds", "0") or 0),
        "review": review,
        "review_files": review_files,
        "result_notes": notes,
        "folder": folder,
    }


def task_files(tasks_dir=TASKS_DIR):
    return sorted(tasks_dir.glob("T-*.md"))


def export(out_dir, tasks_dir=TASKS_DIR, worktrees_dir=None):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    tickets = []
    for path in task_files(tasks_dir):
        folder = Path(worktrees_dir) / path.name[:5] if worktrees_dir else None
        if folder and (folder / "tasks" / path.name).exists():
            t = ticket(folder / "tasks" / path.name, str(folder))
        else:
            t = ticket(path)
        if t:
            tickets.append(t)
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
    if len(argv) in (2, 3) and argv[0] == "export":
        tickets = export(argv[1], worktrees_dir=argv[2] if len(argv) == 3 else None)
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
