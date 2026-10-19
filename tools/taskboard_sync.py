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
UPDATES_RE = re.compile(r"^## Updates[ \t]*\n(.*?)(?=^## |\Z)", re.S | re.M)
UPDATE_HEAD_RE = re.compile(r"^### (\d{4}-\d{2}-\d{2}), (.+?)[ \t]*$", re.M)
NOTES_PLACEHOLDER = "Written by the agent when it finishes."
NOTES_MAX = 20000
NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,29}")   # a Project Lead session's name, also a ticket's lead
# A ticket's screenshots and recordings (T-201): the only file types the board lists and serves.
MEDIA_TYPES = {
    ".png": ("image", "image/png"),
    ".jpg": ("image", "image/jpeg"),
    ".gif": ("image", "image/gif"),
    ".webp": ("image", "image/webp"),
    ".mp4": ("video", "video/mp4"),
    ".webm": ("video", "video/webm"),
}


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


def parse_updates(text):
    """The Project Lead's replies from a task file's `## Updates` section, oldest first (file order):
    [{"date", "change", "text"}]. Each entry starts with a `### <date>, <lane change>` line."""
    section = UPDATES_RE.search(text.replace("\r\n", "\n"))
    if not section:
        return []
    body = section.group(1)
    heads = list(UPDATE_HEAD_RE.finditer(body))
    out = []
    for i, h in enumerate(heads):
        end = heads[i + 1].start() if i + 1 < len(heads) else len(body)
        out.append({"date": h.group(1), "change": h.group(2), "text": body[h.end():end].strip()})
    return out


def media_kind(name):
    """("image" | "video", content type) for a media file name, or None for any other file."""
    return MEDIA_TYPES.get(Path(str(name)).suffix.lower())


def screenshot_files(base, task_id):
    """The media files in <base>/art-archive/<task id>/screenshots/ and its subfolders, sorted."""
    if not re.fullmatch(r"T-\d+", str(task_id)):
        return []
    folder = Path(base) / "art-archive" / task_id / "screenshots"
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.rglob("*") if media_kind(p.name) and p.is_file())


def safe_relative(base, rel):
    """`rel` as a clean relative path ("a/b.png") inside `base`, or None: no absolute paths, drive
    letters or `..`, and the real file (links followed) must stay inside `base`."""
    if not isinstance(rel, str) or not rel or "\0" in rel:
        return None
    rel = rel.strip().replace("\\", "/")
    parts = rel.split("/")
    if rel.startswith("/") or ":" in rel or any(p in ("", ".", "..") for p in parts):
        return None
    try:
        root = Path(base).resolve()
        (root / rel).resolve().relative_to(root)
    except (OSError, ValueError, RuntimeError):
        return None
    return "/".join(parts)


def ticket_media(base, task_id, review_files=()):
    """A ticket's screenshots and recordings, looked up in the checkout it lives in (`base`): every
    media file in art-archive/<id>/screenshots/, then the media named on its `Board review files:`
    line. [{"path" (relative to base, with /), "kind" (image or video), "size" (bytes)}]."""
    base = Path(base)
    found, out = set(), []

    def add(rel):
        rel = safe_relative(base, rel)
        if not rel or rel in found or not media_kind(rel):
            return
        try:
            st = (base / rel).stat()
        except OSError:
            return
        if not (base / rel).is_file():
            return
        found.add(rel)
        out.append({"path": rel, "kind": media_kind(rel)[0], "size": st.st_size})

    for p in screenshot_files(base, task_id):
        add(p.relative_to(base).as_posix())
    for f in review_files:
        f = str(f).strip().replace("\\", "/")
        if re.match(r"^[A-Za-z]:/", f):   # an absolute path is accepted only inside the ticket's checkout
            try:
                f = Path(f).resolve().relative_to(base.resolve()).as_posix()
            except (OSError, ValueError):
                continue
        add(f)
    return out


def ticket(path, folder=""):
    """The document the page shows for one task file. `folder` is the task's branch folder, if open.
    Its media are looked up in the checkout the task file is in (the folder above tasks/)."""
    text = path.read_text(encoding="utf-8")
    fields = parse_header(text)
    if not fields or "id" not in fields:
        return None
    review, review_files, notes = review_parts(text)
    media = ticket_media(Path(path).resolve().parent.parent, fields["id"], review_files)
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
        "updates": parse_updates(text),
        "folder": folder,
        "media": media,
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
