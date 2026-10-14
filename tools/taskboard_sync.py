"""Read the task files the way the task board shows them.

The task files in tasks/ are the source of truth. The local task board
(tools/taskboard/server.py) reads them through tickets_now() on every refresh, including
open tasks from their branch folders (found with `git worktree list`), so it never needs a
sync. tools/task_status.py and the hooks (.claude/hooks/board_gate.py) use the same parsing
helpers. The earlier task board page published on claude.ai, and the export and apply
commands that kept it filled, are gone (2026-10-12).

A library, not a command: import it from tools/ (see tools/taskboard/server.py).
"""

import contextlib
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TASKS_DIR = ROOT / "tasks"
STATE_DIR = ROOT / ".board"   # git-ignored: moves log, board inbox, server log
BRANCH_RE = re.compile(r"refs/heads/task/(T-\d+)-")
STATUSES = ["open", "planning", "in-progress", "in-qa", "needs-playtest", "blocked", "flagged-for-review", "done", "cancelled"]
HEADER_RE = re.compile(r"\A---\n(.*?)\n---\n", re.S)
FIELD_RE = re.compile(r"^(\w+): ?(.*)$", re.M)
LIST_FIELDS = {"depends_on", "documents_affected", "files_to_read_first", "files_expected_to_change"}
REVIEW_RE = re.compile(r"^The board's review:\s*(.+)$", re.M)
REVIEW_FILES_RE = re.compile(r"^Board review files:\s*(.+)$", re.M)
NOTES_RE = re.compile(r"^## Result notes[ \t]*\n(.*)\Z", re.S | re.M)
NOTES_PLACEHOLDER = "Written by the agent when it finishes."
NOTES_MAX = 20000
NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,29}")   # a Project Lead session's name, also a ticket's lead


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
        "lead": fields.get("lead", ""),
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


def task_files(tasks_dir=None):
    return sorted((TASKS_DIR if tasks_dir is None else tasks_dir).glob("T-*.md"))


def no_window():
    """creationflags for subprocess: on Windows, a console program (git) started from the board's
    server, which has no console, would otherwise open a terminal window every time (T-110)."""
    return 0x08000000 if os.name == "nt" else 0   # subprocess.CREATE_NO_WINDOW


def task_folders(root=None):
    """{task id: worktree folder} for every open task branch, from `git worktree list`."""
    try:
        out = subprocess.run(["git", "-C", str(ROOT if root is None else root), "worktree", "list", "--porcelain"],
                             capture_output=True, text=True, check=True, creationflags=no_window()).stdout
    except (OSError, subprocess.CalledProcessError):
        return {}
    folders, path = {}, None
    for line in out.splitlines():
        if line.startswith("worktree "):
            path = Path(line[len("worktree "):])
        match = BRANCH_RE.match(line[len("branch "):]) if line.startswith("branch ") else None
        if match and path:
            folders[match.group(1)] = path
    return folders


def tickets_now(tasks_dir=None, folders=None):
    """Every task as the board shows it, reading open tasks from their branch folders."""
    folders = task_folders() if folders is None else folders
    tickets = []
    for path in task_files(tasks_dir):
        folder = folders.get(path.name[:5])
        if folder and (folder / "tasks" / path.name).exists():
            t = ticket(folder / "tasks" / path.name, str(folder))
        else:
            t = ticket(path)
        if t:
            tickets.append(t)
    return tickets


@contextlib.contextmanager
def file_lock(path, timeout=5.0, stale=30.0):
    """Hold a lock file while a short read-and-write runs, so two processes (hooks, the watcher,
    the status script) never interleave. A lock older than `stale` seconds is left over from a
    crash and is taken over. Raises TimeoutError if the lock stays held for `timeout` seconds."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + timeout
    while True:
        try:
            os.close(os.open(str(path), os.O_CREAT | os.O_EXCL | os.O_WRONLY))
            break
        except (FileExistsError, PermissionError):
            try:
                if time.time() - path.stat().st_mtime > stale:
                    path.unlink()
                    continue
            except OSError:
                continue
            if time.monotonic() > deadline:
                raise TimeoutError(f"{path} is locked")
            time.sleep(0.02)
    try:
        yield
    finally:
        try:
            path.unlink()
        except OSError:
            pass


def utf8_output():
    """Windows consoles default to a code page that can't print arrows; always write UTF-8."""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")
