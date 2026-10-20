"""Read the task files the way the task board shows them.

The task files in tasks/ are the source of truth. The local task board
(tools/taskboard/server.py) reads them through tickets_now() on every refresh, including
open tasks from their branch folders (found with `git worktree list`), so it never needs a
sync. tools/task_status.py and the hooks (.claude/hooks/board_gate.py) use the same parsing
helpers. goals_now() reads the goal runner's goal files for the board's Goals strip (T-202).
The activity logs (T-203): append_activity() is how the goal runner writes them, read_activity() reads
the end of one, and event_phrase() / activity_summary() turn events into plain phrases by fixed rules.
The earlier task board page published on claude.ai, and the export and apply
commands that kept it filled, are gone (2026-10-12).

A library, not a command: import it from tools/ (see tools/taskboard/server.py).
"""

import calendar
import contextlib
import json
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
        "goal": fields.get("goal", ""),
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


# --- Goals (T-202): the goal runner's goal files (goals/G-NNN-*.md), as the board shows them ---

GOAL_ID_RE = re.compile(r"G-\d{3,}")
GOAL_NAME_RE = re.compile(r"^(G-\d{3,})-.*\.md$")
GOAL_NUMBERS = ("art_cap", "art_used", "iteration", "max_iterations")
PAUSE_ENTRY_RE = re.compile(r"^- (\d{4}-\d{2}-\d{2})(?: \[([a-z-]+)\])?:[ \t]?(.*)$")
PAUSE_REASON_MAX = 4000
FINISHED = ("done", "cancelled")


def goal_files(goals_dir):
    """Every goal file in goals_dir (G-NNN-short-title.md), sorted by name."""
    folder = Path(goals_dir)
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.glob("G-*.md") if GOAL_NAME_RE.match(p.name) and p.is_file())


def goal_pauses(section):
    """The entries of a goal file's `## Pauses` section, oldest first (file order):
    [{"date", "kind" ("stop" when it has none, as goal_file.last_pause_kind), "reason"}].
    A line that doesn't start a new entry continues the one before it."""
    out = []
    for line in (section or "").replace("\r\n", "\n").split("\n"):
        match = PAUSE_ENTRY_RE.match(line)
        if match:
            out.append({"date": match.group(1), "kind": match.group(2) or "stop", "reason": match.group(3).strip()})
        elif out and line.strip():
            out[-1]["reason"] = (out[-1]["reason"] + "\n" + line.strip()).strip()
    for p in out:
        if len(p["reason"]) > PAUSE_REASON_MAX:
            p["reason"] = p["reason"][:PAUSE_REASON_MAX] + " (cut short here; the rest is in the goal file)"
    return out


def ticket_number(task_id):
    digits = re.sub(r"\D", "", str(task_id))
    return int(digits) if digits else 0


def goal(path, tickets=(), build_folders=None):
    """The document the board shows for one goal file, read with the goal runner's own reader
    (tools/goal_agent/goal_file.py). `tickets`: every ticket as tickets_now() returns them; the goal's
    tickets are those whose `goal:` line names it. `build_folders`: {folder name: folder} of the
    worktrees, from `git worktree list`; the goal's build folder is the one named after its id.
    None for a file that can't be read."""
    from goal_agent import goal_file   # imported here: the hooks import this module and never need it

    try:
        g = goal_file.GoalFile.load(path)
    except (OSError, ValueError, UnicodeDecodeError):
        return None
    gid = g.get("id") or GOAL_NAME_RE.match(Path(path).name).group(1)
    mine = sorted((t for t in tickets if t.get("goal") == gid), key=lambda t: ticket_number(t["id"]))
    counts = {}
    for t in mine:
        counts[t["status"]] = counts.get(t["status"], 0) + 1
    pauses = goal_pauses(g.section("Pauses"))
    status = g.get("status") or ""
    folder = (build_folders or {}).get(gid)
    doc = {
        "id": gid,
        "title": g.get("title") or "",
        "status": status,
        "created": g.get("created") or "",
        "lead": g.get("lead") or "",
        "file": f"goals/{Path(path).name}",
        "goal_text": g.section("Goal") or "",
        "pauses": pauses,
        "latest_pause": pauses[-1] if status == "paused" and pauses else None,
        "tickets": [t["id"] for t in mine],
        "ticket_counts": counts,
        "tickets_total": len(mine),
        "tickets_finished": sum(n for s, n in counts.items() if s in FINISHED),
        "build_folder": str(folder) if folder else "",
        "has_build": bool(folder),
    }
    for key in GOAL_NUMBERS:
        doc[key] = g.number(key)
    return doc


def goals_now(goals_dir, tickets=(), build_folders=None):
    """Every goal as the board shows it, newest (highest id) first."""
    out = [d for d in (goal(p, tickets, build_folders) for p in goal_files(goals_dir)) if d]
    return sorted(out, key=lambda d: ticket_number(d["id"]), reverse=True)


# --- Live activity (T-203): what the goal runner's headless sessions are doing, in plain words ---
#
# The runner (tools/goal_agent/claude_call.py) appends every stream-json event of a headless session to
# .board/activity/<ticket or goal id>.jsonl in the main checkout, one line per event:
#   {"at": "2026-10-19T12:00:00Z", "step": "agent" | "qa" | "goal-check", "event": {...}}
# Events are cut down first (long strings shortened, tool results reduced to their type), and a log that
# grows past ACTIVITY_MAX_BYTES keeps only its last ACTIVITY_KEEP_BYTES. The board reads only the end of a
# log (ACTIVITY_READ_BYTES), so a log of any size costs the same; a log can be deleted at any time.

ACTIVITY_ID_RE = re.compile(r"[TG]-\d+")
ACTIVITY_MAX_BYTES = 2_000_000
ACTIVITY_KEEP_BYTES = 500_000
ACTIVITY_READ_BYTES = 256_000
ACTIVITY_STRING_MAX = 400
TIMELINE_MAX = 20
STEP_LABELS = {"qa": "QA checking", "goal-check": "Goal check"}


def activity_path(activity_dir, log_id):
    """The activity log of one ticket or goal, or None for an id that isn't T-NNN or G-NNN."""
    if not isinstance(log_id, str) or not ACTIVITY_ID_RE.fullmatch(log_id):
        return None
    return Path(activity_dir) / f"{log_id}.jsonl"


def compact_event(event, depth=0):
    """An event cut down for the log: strings past ACTIVITY_STRING_MAX shortened, long lists cut, and a
    tool result's content dropped (only its type and error flag are kept)."""
    if isinstance(event, str):
        return event if len(event) <= ACTIVITY_STRING_MAX else event[:ACTIVITY_STRING_MAX] + "…"
    if depth > 8:
        return None
    if isinstance(event, list):
        return [compact_event(x, depth + 1) for x in event[:30]]
    if isinstance(event, dict):
        if event.get("type") == "tool_result":
            return {"type": "tool_result", "is_error": bool(event.get("is_error"))}
        return {k: compact_event(v, depth + 1) for k, v in event.items() if k != "signature"}
    return event


def append_activity(activity_dir, log_id, step, event, at=None):
    """Append one event to an activity log (made if missing); trims a log grown past ACTIVITY_MAX_BYTES.
    Never raises: the log is a convenience, and a run never stops for it."""
    path = activity_path(activity_dir, log_id)
    if path is None:
        return None
    at = at or time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    line = json.dumps({"at": at, "step": step, "event": compact_event(event)}, ensure_ascii=False)
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8", newline="\n") as f:
            f.write(line + "\n")
        if path.stat().st_size > ACTIVITY_MAX_BYTES:
            trim_activity(path)
    except OSError:
        return None
    return path


def trim_activity(path, keep=None):
    """Keep only the last `keep` bytes of a log, from a line start. Skipped (no error) if the file is busy."""
    keep = ACTIVITY_KEEP_BYTES if keep is None else keep
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - keep))
            tail = f.read()
        if size > keep:
            tail = tail.split(b"\n", 1)[1] if b"\n" in tail else b""
        tmp = Path(str(path) + ".trim")
        tmp.write_bytes(tail)
        os.replace(tmp, path)
    except OSError:
        pass


def read_activity(path, max_bytes=None):
    """The events at the end of an activity log, oldest first: only its last `max_bytes` are read, a cut
    first line and any line that isn't JSON are skipped. [] when the log is missing."""
    max_bytes = ACTIVITY_READ_BYTES if max_bytes is None else max_bytes
    try:
        with open(path, "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - max_bytes))
            data = f.read(max_bytes)
    except OSError:
        return []
    lines = data.decode("utf-8", errors="replace").split("\n")
    if size > max_bytes:
        lines = lines[1:]
    out = []
    for line in lines:
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if isinstance(entry, dict) and isinstance(entry.get("event"), dict):
            out.append(entry)
    return out


def short_path(path):
    """A file path as the board shows it: relative to its checkout when it is inside one (a task or goal
    folder, or the main checkout), else its name; a long one becomes its name."""
    p = str(path or "").replace("\\", "/")
    m = re.search(r"/(?:solid-carbide-worktrees/[^/]+|solid-carbide-game)/(.+)$", p)
    rel = m.group(1) if m else p
    if len(rel) > 40 or re.match(r"^[A-Za-z]:/|^/", rel):
        rel = rel.rsplit("/", 1)[-1]
    return rel or "a file"


def command_phrase(command):
    """A shell command in plain words."""
    c = str(command or "").lower()
    if "pixellab" in c:
        return "Calling PixelLab"
    if re.search(r"\bgit\b[^|;&]*\bcommit\b", c):
        return "Committing"
    if "screenshot" in c or "--write-movie" in c:
        return "Taking screenshots"
    if "run_tests" in c or ("godot" in c and "gut" in c):
        return "Running the game's tests"
    if "unittest" in c or "pytest" in c or re.search(r"\btest_\w+\.py\b", c):
        return "Running the tools' tests"
    if re.search(r"\bgit\b", c):
        return "Using git"
    if "godot" in c:
        return "Running the game"
    return "Running a command"


def tool_phrase(name, args):
    """One tool call in plain words. Unknown tools get a generic phrase."""
    name, args = str(name or ""), args if isinstance(args, dict) else {}
    path = args.get("file_path") or args.get("notebook_path") or args.get("path") or ""
    if "pixellab" in name.lower():
        return "Calling PixelLab"
    if name in ("Read", "NotebookRead"):
        return f"Reading `{short_path(path)}`"
    if name in ("Edit", "MultiEdit", "NotebookEdit"):
        return f"Editing `{short_path(path)}`"
    if name == "Write":
        return f"Writing `{short_path(path)}`"
    if name in ("Grep", "Glob"):
        return "Searching the files"
    if name in ("Bash", "PowerShell"):
        return command_phrase(args.get("command"))
    if name in ("Task", "Agent"):
        return "Asking a helper agent"
    if name in ("WebFetch", "WebSearch"):
        return "Looking something up online"
    if name == "TodoWrite":
        return "Planning its steps"
    if name == "Skill":
        return "Using a skill"
    short = name.rsplit("__", 1)[-1] if name.startswith("mcp__") else name
    return f"Using {short}" if short else "Working"


def event_phrase(event):
    """The plain phrase for one stream-json event, or None for an event that doesn't change what the
    session is doing (a tool's result, a stream chunk)."""
    if not isinstance(event, dict):
        return None
    kind = event.get("type")
    if kind == "system":
        return "Starting" if event.get("subtype") == "init" else None
    if kind == "result":
        return "Stopped with an error" if event.get("is_error") else "Finished"
    if kind != "assistant":
        return None
    content = (event.get("message") or {}).get("content") or []
    tools = [c for c in content if isinstance(c, dict) and c.get("type") == "tool_use"]
    if tools:
        return tool_phrase(tools[-1].get("name"), tools[-1].get("input"))
    if any(isinstance(c, dict) and c.get("type") in ("thinking", "text", "redacted_thinking") for c in content):
        return "Thinking"
    return None


def step_phrase(step, phrase):
    """A phrase with its step: the agent's as it is; QA's and the goal check's prefixed ("QA checking")."""
    label = STEP_LABELS.get(step)
    if not label:
        return phrase
    if phrase in ("Starting", "Thinking"):
        return label
    return f"{label}: {phrase[0].lower()}{phrase[1:]}"


def parse_time(at):
    """Seconds since the epoch from a "2026-10-19T12:00:00Z" time, or None."""
    try:
        return calendar.timegm(time.strptime(str(at), "%Y-%m-%dT%H:%M:%SZ"))
    except (ValueError, TypeError):
        return None


def activity_summary(entries):
    """What the latest events say: {"phrase", "since" (when that phrase began), "step", "last_at" (the newest
    event), "timeline": the last TIMELINE_MAX phrases, oldest first, each {"at", "phrase", "step"}}; a run of
    the same phrase counts once. None when there is nothing to say."""
    timeline, last_at = [], None
    for e in entries:
        at = e.get("at")
        if parse_time(at) is None:
            continue
        last_at = at
        p = event_phrase(e["event"])
        if p is None:
            continue
        p = step_phrase(e.get("step"), p)
        if timeline and timeline[-1]["phrase"] == p:
            continue
        timeline.append({"at": at, "phrase": p, "step": e.get("step") or ""})
    if not timeline:
        return None
    timeline = timeline[-TIMELINE_MAX:]
    cur = timeline[-1]
    return {"phrase": cur["phrase"], "since": cur["at"], "step": cur["step"], "last_at": last_at, "timeline": timeline}


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
