"""The local task board: shows the task files live and moves tasks when the board drags a card.

  python tools/taskboard/server.py            serve the board at http://localhost:8765
  python tools/taskboard/server.py --status   say whether the board is running
  python tools/taskboard/server.py --stop     stop a running board

A SessionStart hook (.claude/hooks/board_gate.py) starts it when a session opens in this repo,
so it is normally already running. BOARD_PORT changes the port.

The task files are the board's only data: every refresh reads tasks/ and the open task
branches (taskboard_sync.tickets_now), so the board can't fall behind. A drag runs
task_status.move() with by="board", so the workflow rules apply to the board too; a refused
move is shown on the page with its reason. Each move the board makes is also appended to
.board/board-inbox.jsonl, which is never emptied: each Project Lead session reads it with its own
cursor (tools/board_inbox.py), through the hooks and its watcher.

A ticket's screenshots and recordings (T-201) are listed with it in /api/tickets ("media") and
served one at a time, read-only, by GET /api/media?id=T-012&path=<relative path>: only image and
video files the ticket lists, from the checkout it lives in.

The goal runner's goals (T-202) come from the main checkout's goals/ (taskboard_sync.goals_now):
GET /api/goals lists each with its tickets and whether its build folder exists, and
GET /api/goal-file?id=G-004 returns one goal file's full text, read-only.

Live activity (T-203): every in-progress or in-QA ticket in /api/tickets has `now`: the latest phrase from
its activity log (.board/activity/<id>.jsonl in the main checkout, written by the goal runner) with its
age and the last 20 phrases, and the free signals: time in its lane (the moves log), commits on its
branch, and its last activity; `quiet` after 10 minutes without any. A building goal in /api/goals has
`now`: the ticket being worked on and its phrase. Logs are read from the end only. BOARD_MAIN_STATE
stands in for the main checkout's .board/ (a second server checked with sample logs).

Out of QA with unmarked criteria (T-212): a drag of an in-qa ticket to In progress or Planning while QA hasn't
marked every acceptance criterion first asks GET /api/move-check?id=T-012&status=in-progress, which returns the
unmarked (and failed) criteria word for word; the page shows them in a warning with an explanation box.
POST /api/move makes that move only with "confirm_unmarked": true (otherwise 409 with the warning, nothing
changed); the explanation is the move's note. It isn't a QA round.

The server listens on 127.0.0.1 only. Writes need the X-Board header (a browser page on
another site can't send it without permission) and a localhost Host header.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import threading
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402

APP = "solid-carbide-board"
PAGE = HERE / "taskboard.html"
DEFAULT_PORT = 8765
MOVE_LOCK = threading.Lock()
TASK_BRANCH_RE = re.compile(r"task/(T-\d+)-")


def port():
    try:
        return int(os.environ.get("BOARD_PORT", DEFAULT_PORT))
    except ValueError:
        return DEFAULT_PORT


def now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def inbox_path():
    return tb.STATE_DIR / "board-inbox.jsonl"


_MAIN = {}


def main_checkout():
    """The main checkout (the first entry of `git worktree list`), where the goal runner commits the
    goal files. Looked up once per served folder: it never moves."""
    if tb.ROOT not in _MAIN:
        _MAIN[tb.ROOT] = Path(worktrees()[0][0])
    return _MAIN[tb.ROOT]


def goals_dir():
    return main_checkout() / "goals"


def version(folders=None):
    """Changes whenever a task file the board shows changes, a task branch opens or closes, a
    screenshot is added to, changed in or removed from a ticket's art-archive/<id>/screenshots/,
    or a goal file in the main checkout's goals/ is added, changed or removed."""
    folders = tb.task_folders() if folders is None else folders
    h = hashlib.sha256()
    for path in tb.goal_files(goals_dir()):
        try:
            st = path.stat()
        except OSError:
            continue
        h.update(f"{path}|{st.st_mtime_ns}|{st.st_size}\n".encode("utf-8"))
    for path in tb.task_files():
        folder = folders.get(path.name[:5])
        real = folder / "tasks" / path.name if folder and (folder / "tasks" / path.name).exists() else path
        try:
            st = real.stat()
        except OSError:
            continue
        h.update(f"{real}|{st.st_mtime_ns}|{st.st_size}\n".encode("utf-8"))
        for shot in tb.screenshot_files(real.parent.parent, path.name[:5]):
            try:
                sst = shot.stat()
            except OSError:
                continue
            h.update(f"{shot}|{sst.st_mtime_ns}|{sst.st_size}\n".encode("utf-8"))
    # T-203: an activity log's new events, at most once per ACTIVITY_TICK seconds, and a new commit in a
    # task folder (its worktree's HEAD log), so the Now lines follow without reading on every check.
    for log_id, path in sorted(activity_files().items()):
        try:
            h.update(f"{log_id}|{int(path.stat().st_mtime // ACTIVITY_TICK)}\n".encode("utf-8"))
        except OSError:
            continue
    for task_id, folder in sorted(folders.items()):
        head_log = worktree_head_log(folder)
        if not head_log:
            continue
        try:
            h.update(f"{task_id}|{head_log.stat().st_mtime_ns}\n".encode("utf-8"))
        except OSError:
            continue
    return h.hexdigest()[:16]


ACTIVITY_TICK = 10


def worktree_head_log(folder):
    """The HEAD log git keeps for a worktree (it changes on every commit there), or None."""
    try:
        text = (Path(folder) / ".git").read_text(encoding="utf-8").strip()
    except OSError:
        return None
    if not text.startswith("gitdir:"):
        return None
    return Path(text[len("gitdir:"):].strip()) / "logs" / "HEAD"


def tickets_payload():
    folders = tb.task_folders()
    stamp = time.time()
    tickets = with_now(tb.tickets_now(folders=folders), stamp)
    return {"version": version(folders), "generated_at": iso(stamp), "tickets": tickets}


def goals_payload():
    """Every goal file with its tickets (from their `goal:` lines, wherever the ticket lives) and
    whether its build folder (the worktree named after the goal's id) exists; a building goal also
    has `now`: the ticket being worked on and its phrase (T-203)."""
    folders = tb.task_folders()
    stamp = time.time()
    builds_by_name = {Path(f).name: Path(f) for f, _ in worktrees()[1:]}
    tickets = with_now(tb.tickets_now(folders=folders), stamp)
    goals = tb.goals_now(goals_dir(), tickets, builds_by_name)
    logs = activity_files()
    for g in goals:
        g["now"] = goal_now(g, tickets, logs, stamp)
    return {"version": version(folders), "generated_at": iso(stamp), "goals": goals}


# --- Live activity (T-203): the Now line on cards, the ticket's timeline, the goal cards' current ticket ---

ACTIVE = ("in-progress", "in-qa")
QUIET_AFTER = 600            # seconds without any activity: the card is marked quiet
MOVES_READ_BYTES = 512_000   # only the end of the moves log is read


def iso(stamp):
    return datetime.fromtimestamp(stamp, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ") if stamp is not None else None


def main_state():
    """The main checkout's .board/ (where the runner writes the activity logs and the status script its moves
    log). BOARD_MAIN_STATE points somewhere else, for a second board server checked with sample logs."""
    env = os.environ.get("BOARD_MAIN_STATE")
    return Path(env) if env else main_checkout() / ".board"


def activity_files():
    """{ticket or goal id: its activity log} for every log there is."""
    try:
        return {p.stem: p for p in (main_state() / "activity").glob("*.jsonl") if tb.ACTIVITY_ID_RE.fullmatch(p.stem)}
    except OSError:
        return {}


def lane_times():
    """{ticket id: (status, time)} of each ticket's newest move in the moves log (its end only)."""
    path, out = main_state() / "moves.log", {}
    try:
        with path.open("rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - MOVES_READ_BYTES))
            lines = f.read().decode("utf-8", errors="replace").split("\n")
    except OSError:
        return out
    if size > MOVES_READ_BYTES:
        lines = lines[1:]
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if isinstance(entry, dict) and entry.get("id") and entry.get("at"):
            out[entry["id"]] = (entry.get("to"), entry["at"])
    return out


def branch_signals(folder, branch):
    """(commits only on this branch, the newest one's time in seconds or None) for a ticket's folder."""
    if not folder or not branch or branch == "(detached)":
        return 0, None
    try:
        out = subprocess.run(["git", "-C", str(folder), "log", "--format=%ct", "HEAD", "--not",
                              f"--exclude={branch}", "--branches"], capture_output=True, text=True,
                             check=True, creationflags=tb.no_window(), timeout=10).stdout.split()
    except (OSError, subprocess.SubprocessError):
        return 0, None
    return len(out), (int(out[0]) if out and out[0].isdigit() else None)


def age(stamp, at):
    t = tb.parse_time(at) if isinstance(at, str) else at
    return None if t is None else max(0, int(stamp - t))


def ticket_now(t, log, lane, branch, stamp):
    """What the board shows of one in-progress or in-QA ticket: the activity log's latest phrase and its
    last TIMELINE_MAX phrases, and the free signals: time in its lane, commits on its branch, last activity."""
    summary = tb.activity_summary(tb.read_activity(log)) if log else None
    commits, last_commit = branch_signals(t.get("folder"), branch)
    task_file = Path(t["folder"]) / t["file"] if t.get("folder") else tb.ROOT / t["file"]
    try:
        changed = task_file.stat().st_mtime
    except OSError:
        changed = None
    since = lane[1] if lane and lane[0] == t["status"] else None
    times = [x for x in (tb.parse_time(summary["last_at"]) if summary else None, last_commit, changed) if x is not None]
    last = max(times) if times else None
    out = {"phrase": summary["phrase"] if summary else "", "phrase_since": summary["since"] if summary else None,
           "phrase_age_s": age(stamp, summary["since"]) if summary else None, "step": summary["step"] if summary else "",
           "timeline": summary["timeline"] if summary else [],
           "in_lane_since": since, "in_lane_s": age(stamp, since) if since else None,
           "commits": commits, "last_commit_at": iso(last_commit), "file_changed_at": iso(changed),
           "last_activity_at": iso(last), "last_activity_s": age(stamp, last) if last is not None else None}
    out["quiet"] = out["last_activity_s"] is not None and out["last_activity_s"] >= QUIET_AFTER
    return out


def with_now(tickets, stamp=None):
    """The tickets, each in progress or in QA with its `now` (the others: None)."""
    stamp = time.time() if stamp is None else stamp
    active = [t for t in tickets if t["status"] in ACTIVE]
    logs = activity_files() if active else {}
    lanes = lane_times() if active else {}
    branches = {str(Path(f)): b for f, b in worktrees()} if any(t.get("folder") for t in active) else {}
    for t in tickets:
        t["now"] = (ticket_now(t, logs.get(t["id"]), lanes.get(t["id"]), branches.get(str(Path(t["folder"])))
                               if t.get("folder") else None, stamp) if t["status"] in ACTIVE else None)
    return tickets


def goal_now(g, tickets, logs, stamp):
    """For a building goal: the ticket being worked on (its newest active one), "ticket N of M", the
    iteration, and the phrase; the goal check's phrase when the goal's own log is newer. None otherwise."""
    if g.get("status") != "building":
        return None
    by_id = {t["id"]: t for t in tickets}
    mine = [by_id[i] for i in g["tickets"] if by_id.get(i, {}).get("now")]
    pick = max(mine, key=lambda t: (t["now"]["last_activity_s"] is not None, -(t["now"]["last_activity_s"] or 0)),
               default=None)
    out = {"ticket": "", "ticket_index": 0, "tickets_total": g["tickets_total"], "iteration": g["iteration"],
           "phrase": "", "phrase_since": None, "phrase_age_s": None, "last_activity_at": None, "quiet": False}
    if pick:
        n = pick["now"]
        out.update(ticket=pick["id"], ticket_index=g["tickets"].index(pick["id"]) + 1, phrase=n["phrase"],
                   phrase_since=n["phrase_since"], phrase_age_s=n["phrase_age_s"],
                   last_activity_at=n["last_activity_at"], quiet=n["quiet"])
    own = tb.activity_summary(tb.read_activity(logs[g["id"]])) if g["id"] in logs else None
    if own and own["step"] == "goal-check" and (out["last_activity_at"] is None
                                                or (tb.parse_time(own["last_at"]) or 0) > (tb.parse_time(out["last_activity_at"]) or 0)):
        out.update(ticket="", ticket_index=0, phrase=own["phrase"], phrase_since=own["since"],
                   phrase_age_s=age(stamp, own["since"]), last_activity_at=own["last_at"],
                   quiet=(age(stamp, own["last_at"]) or 0) >= QUIET_AFTER)
    return out


def goal_file_text(goal_id):
    """One goal file's full text, read-only. Returns (http status, text or error body)."""
    if not isinstance(goal_id, str) or not tb.GOAL_ID_RE.fullmatch(goal_id):
        return 400, {"error": "A goal file request needs a goal id like G-004."}
    for path in tb.goal_files(goals_dir()):
        if path.name.startswith(goal_id + "-"):
            try:
                return 200, path.read_bytes().decode("utf-8", errors="replace")
            except OSError:
                break
    return 404, {"error": "No such goal file."}


def media_file(task_id, rel, folders=None):
    """The file the media endpoint may serve for one ticket. Returns (http status, Path or error body).
    Only a file the ticket lists as its media (tb.ticket_media: its screenshots folder and media on its
    `Board review files:` line, in the checkout the ticket lives in) is served; anything else is refused."""
    if not isinstance(task_id, str) or not re.fullmatch(r"T-\d+", task_id):
        return 400, {"error": "A media request needs a ticket id like T-012."}
    if not isinstance(rel, str) or not rel:
        return 400, {"error": "A media request needs a path."}
    clean = rel.replace("\\", "/")
    if ".." in clean.split("/") or clean.startswith("/") or ":" in clean or "\0" in clean:
        return 400, {"error": "That path is not allowed."}
    if not tb.media_kind(clean):
        return 415, {"error": "Only images and recordings (png, jpg, gif, webp, mp4, webm) are served."}
    folders = tb.task_folders() if folders is None else folders
    files = sorted(tb.TASKS_DIR.glob(f"{task_id}-*.md"))
    if not files:
        return 404, {"error": "No such ticket."}
    name = files[0].name
    folder = folders.get(task_id)
    task_file = folder / "tasks" / name if folder and (folder / "tasks" / name).exists() else files[0]
    t = tb.ticket(task_file)
    base = task_file.resolve().parent.parent
    listed = {m["path"] for m in (t or {}).get("media", [])}
    safe = tb.safe_relative(base, clean)
    if not safe or safe not in listed:
        return 404, {"error": "That file is not one of this ticket's screenshots or recordings."}
    return 200, base / safe


def godot_bin(root=None):
    """GODOT_BIN from .env in the folder served. Nothing else is read from .env."""
    env = (tb.ROOT if root is None else Path(root)) / ".env"
    try:
        lines = env.read_text(encoding="utf-8").splitlines()
    except OSError:
        return ""
    for line in lines:
        key, sep, value = line.strip().partition("=")
        if sep and key.strip() == "GODOT_BIN":
            return value.strip().strip("\"'")
    return ""


def worktrees(root=None):
    """[(folder, branch)] from `git worktree list`; the first is the main repo."""
    root = tb.ROOT if root is None else Path(root)
    try:
        out = subprocess.run(["git", "-C", str(root), "worktree", "list", "--porcelain"],
                             capture_output=True, text=True, check=True, creationflags=tb.no_window()).stdout
    except (OSError, subprocess.CalledProcessError):
        return [(root, "master")]
    found, path, branch = [], None, ""
    for line in out.splitlines() + [""]:
        if line.startswith("worktree "):
            path, branch = Path(line[len("worktree "):]), ""
        elif line.startswith("branch "):
            branch = line[len("branch "):].replace("refs/heads/", "", 1)
        elif line == "" and path is not None:
            found.append((path, branch or "(detached)"))
            path = None
    return found or [(root, "master")]


def builds(root=None):
    """One entry per worktree for the Builds tab. The first entry is master."""
    root = tb.ROOT if root is None else Path(root)
    entries = []
    for i, (folder, branch) in enumerate(worktrees(root)):
        match = TASK_BRANCH_RE.match(branch)
        task_id = match.group(1) if match else ""
        t = None
        if task_id:
            for base in (folder / "tasks", root / "tasks"):
                for f in sorted(base.glob(f"{task_id}-*.md")):
                    t = tb.ticket(f)
                    if t:
                        break
                if t:
                    break
        project = folder / "game" / "project.godot"
        entries.append({
            "id": "master" if i == 0 else folder.name,
            "folder": str(folder),
            "branch": branch,
            "ticket_id": task_id,
            "ticket_title": t["title"] if t else "",
            "ticket_status": t["status"] if t else "",
            "lead": t["lead"] if t else "",
            "has_project": project.is_file(),
        })
    return entries


def launcher_args(gbin, folder, mode):
    game = str(Path(folder) / "game")
    return [gbin, "--path", game] if mode == "play" else [gbin, "--editor", "--path", game]


def start_detached(args):
    """Start Godot on its own: no console window on Windows (T-110), not tied to the server."""
    kw = {"stdin": subprocess.DEVNULL, "stdout": subprocess.DEVNULL, "stderr": subprocess.DEVNULL}
    if os.name == "nt":
        kw["creationflags"] = tb.no_window() | 0x00000200   # CREATE_NO_WINDOW | CREATE_NEW_PROCESS_GROUP
    else:
        kw["start_new_session"] = True
    subprocess.Popen(args, **kw)


def launch(entry_id, mode, root=None):
    """Start Godot for one entry of the worktree list. Returns (http status, body)."""
    if mode not in ("play", "editor"):
        return 400, {"error": "Mode must be play or editor."}
    entry = next((e for e in builds(root) if e["id"] == entry_id), None)
    if entry is None:
        return 404, {"error": "That build is not in the worktree list."}
    if not entry["has_project"]:
        return 409, {"error": "That folder has no game/project.godot."}
    gbin = godot_bin(root)
    if not gbin:
        return 500, {"error": "GODOT_BIN is not set in .env. See .env.example."}
    if not Path(gbin).is_file():
        return 500, {"error": f"GODOT_BIN points to a file that does not exist: {gbin}"}
    try:
        start_detached(launcher_args(gbin, entry["folder"], mode))
    except OSError as e:
        return 500, {"error": f"Godot could not be started: {e}"}
    return 200, {"ok": True}


def move_warning(task_id, status, folders=None):
    """The warning the page shows before the board's drag takes an in-qa ticket with unmarked acceptance
    criteria back to in-progress or planning (T-212): {"unmarked": [...], "failed": [...]}, or None.
    Raises ts.Refused when there is no such ticket."""
    folders = tb.task_folders() if folders is None else folders
    path = ts.find(task_id, folders)[0]
    text = path.read_bytes().decode("utf-8")
    return ts.unmarked_warning(tb.parse_header(text) or {}, text, status, "board")


def move_check(task_id, status):
    """GET /api/move-check: whether a drag needs the warning first. Returns (http status, body)."""
    if not isinstance(task_id, str) or not re.fullmatch(r"T-\d+", task_id) or status not in tb.STATUSES:
        return 400, {"error": "A move check needs a ticket id like T-012 and a status."}
    try:
        return 200, {"warning": move_warning(task_id, status)}
    except ts.Refused as e:
        return 404, {"error": str(e)}


def board_move(task_id, status, note=None, confirmed=False):
    """Move a task for the board. Returns (http status, body). A move that needs the warning (move_warning)
    happens only with confirmed=True, after the board went ahead in the page's pop-up; until then it is
    answered 409 with the warning, and nothing changes."""
    with MOVE_LOCK:
        folders = tb.task_folders()
        try:
            old = ts.header(ts.find(task_id, folders)[0]).get("status")
            warning = move_warning(task_id, status, folders)
            if warning and not confirmed:
                n = len(warning["unmarked"])
                return 409, {"error": f"QA hasn't marked {n} acceptance criteria of {task_id}: confirm the move "
                                      "in the warning first.", "warning": warning}
            lines = ts.move(task_id, status, note or None, folders=folders, by="board")
        except ts.Refused as e:
            return 409, {"error": str(e).replace("--note", "a note")}
        tb.STATE_DIR.mkdir(exist_ok=True)
        with inbox_path().open("a", encoding="utf-8") as f:
            f.write(json.dumps({"id": task_id, "from": old, "to": status, "note": note or "", "at": now()}) + "\n")
        return 200, {"ok": True, "lines": lines}


class Handler(BaseHTTPRequestHandler):
    server_version = "SolidCarbideBoard/1"

    def log_message(self, fmt, *args):
        try:
            tb.STATE_DIR.mkdir(exist_ok=True)
            with (tb.STATE_DIR / "server.log").open("a", encoding="utf-8") as f:
                f.write(f"{now()} {self.address_string()} {fmt % args}\n")
        except OSError:
            pass

    def send(self, code, body, content_type="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def local_host(self):
        host = (self.headers.get("Host") or "").split(":")[0]
        return host in ("localhost", "127.0.0.1")

    def do_GET(self):
        if not self.local_host():
            return self.send(403, {"error": "The board only answers on localhost."})
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            return self.send(200, PAGE.read_bytes(), "text/html; charset=utf-8")
        if path == "/api/health":
            return self.send(200, {"app": APP, "root": str(tb.ROOT), "pid": os.getpid()})
        if path == "/api/version":
            return self.send(200, {"version": version()})
        if path == "/api/builds":
            return self.send(200, {"builds": builds()})
        if path == "/api/tickets":
            return self.send(200, tickets_payload())
        if path == "/api/goals":
            return self.send(200, goals_payload())
        if path == "/api/move-check":
            query = urllib.parse.parse_qs(self.path.partition("?")[2])
            code, out = move_check((query.get("id") or [""])[0], (query.get("status") or [""])[0])
            return self.send(code, out)
        if path == "/api/goal-file":
            query = urllib.parse.parse_qs(self.path.partition("?")[2])
            code, out = goal_file_text((query.get("id") or [""])[0])
            if code != 200:
                return self.send(code, out)
            return self.send(200, out.encode("utf-8"), "text/plain; charset=utf-8")
        if path == "/api/media":
            query = urllib.parse.parse_qs(self.path.partition("?")[2])
            code, out = media_file((query.get("id") or [""])[0], (query.get("path") or [""])[0])
            if code != 200:
                return self.send(code, out)
            return self.send_media(out)
        return self.send(404, {"error": "Not found."})

    def send_media(self, file):
        """Stream one media file with its content type; a single `Range: bytes=a-b` gets a 206,
        so recordings can be scrubbed. The file is read only now, in chunks."""
        try:
            size = file.stat().st_size
            f = file.open("rb")
        except OSError:
            return self.send(404, {"error": "That file can't be read."})
        with f:
            start, end, code = 0, size - 1, 200
            match = re.fullmatch(r"bytes=(\d*)-(\d*)", (self.headers.get("Range") or "").strip())
            if match and (match.group(1) or match.group(2)):
                if match.group(1):
                    start = int(match.group(1))
                    end = min(int(match.group(2)), size - 1) if match.group(2) else size - 1
                else:
                    start = max(0, size - int(match.group(2)))
                if start > end or start >= size:
                    self.send_response(416)
                    self.send_header("Content-Range", f"bytes */{size}")
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return None
                code = 206
            self.send_response(code)
            self.send_header("Content-Type", tb.media_kind(file.name)[1])
            self.send_header("Content-Length", str(end - start + 1 if size else 0))
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("X-Content-Type-Options", "nosniff")
            if code == 206:
                self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.end_headers()
            f.seek(start)
            left = end - start + 1 if size else 0
            try:
                while left > 0:
                    chunk = f.read(min(65536, left))
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    left -= len(chunk)
            except (ConnectionError, OSError):
                pass   # the browser stopped a video download half way: normal
        return None

    def do_POST(self):
        if not self.local_host() or self.headers.get("X-Board") != "1":
            return self.send(403, {"error": "Moves come from the board page only."})
        try:
            length = int(self.headers.get("Content-Length") or 0)
            body = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            return self.send(400, {"error": "Send JSON."})
        path = self.path.split("?")[0]
        if path == "/api/move":
            task_id, status = body.get("id"), body.get("status")
            if not isinstance(task_id, str) or not isinstance(status, str):
                return self.send(400, {"error": "A move needs an id and a status."})
            code, out = board_move(task_id, status, body.get("note"), body.get("confirm_unmarked") is True)
            return self.send(code, out)
        if path == "/api/launch":
            entry_id, mode = body.get("id"), body.get("mode")
            if not isinstance(entry_id, str) or not isinstance(mode, str):
                return self.send(400, {"error": "A launch needs an id and a mode."})
            code, out = launch(entry_id, mode)
            return self.send(code, out)
        if path == "/api/stop":
            self.send(200, {"ok": True})
            threading.Thread(target=self.server.shutdown, daemon=True).start()
            return None
        return self.send(404, {"error": "Not found."})


def health(p=None, timeout=1.0):
    """The running board's health answer, or None when nothing answers on the port."""
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{p or port()}/api/health", timeout=timeout) as r:
            data = json.loads(r.read())
        return data if data.get("app") == APP else None
    except (OSError, ValueError):
        return None


def stop(p=None):
    req = urllib.request.Request(f"http://127.0.0.1:{p or port()}/api/stop", data=b"{}", method="POST",
                                 headers={"X-Board": "1", "Content-Type": "application/json"})
    try:
        urllib.request.urlopen(req, timeout=2).read()
        return True
    except OSError:
        return False


def make_server(p=None):
    return ThreadingHTTPServer(("127.0.0.1", port() if p is None else p), Handler)


def main(argv=None):
    tb.utf8_output()
    args = argparse.ArgumentParser(description="The local task board.")
    args.add_argument("--status", action="store_true")
    args.add_argument("--stop", action="store_true")
    opts = args.parse_args(argv)
    running = health()
    if opts.status:
        print(f"Running at http://localhost:{port()} for {running['root']}" if running else "Not running.")
        return 0 if running else 1
    if opts.stop:
        print("Stopped." if running and stop() else "Not running.")
        return 0
    if running:
        print(f"Already running at http://localhost:{port()} for {running['root']}.")
        return 0
    server = make_server()
    print(f"Task board at http://localhost:{port()} (Ctrl+C to stop)", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
