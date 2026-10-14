"""The local task board: shows the task files live and moves tasks when the board drags a card.

  python tools/taskboard/server.py            serve the board at http://localhost:8765
  python tools/taskboard/server.py --status   say whether the board is running
  python tools/taskboard/server.py --stop     stop a running board

A SessionStart hook (.claude/hooks/board_gate.py) starts it when a session opens in this repo,
so it is normally already running. BOARD_PORT changes the port.

The task files are the board's only data: every refresh reads tasks/ and the open task
branches (taskboard_sync.tickets_now), so the board can't fall behind. A drag runs
task_status.move() with by="board", so the workflow rules apply to the board too; a refused
move is shown on the page with its reason. Each move the board makes is also written to
.board/board-inbox.jsonl, which the hooks hand to the Project Lead.

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


def version(folders=None):
    """Changes whenever a task file the board shows changes, or a task branch opens or closes."""
    folders = tb.task_folders() if folders is None else folders
    h = hashlib.sha256()
    for path in tb.task_files():
        folder = folders.get(path.name[:5])
        real = folder / "tasks" / path.name if folder and (folder / "tasks" / path.name).exists() else path
        try:
            st = real.stat()
        except OSError:
            continue
        h.update(f"{real}|{st.st_mtime_ns}|{st.st_size}\n".encode("utf-8"))
    return h.hexdigest()[:16]


def tickets_payload():
    folders = tb.task_folders()
    return {"version": version(folders), "generated_at": now(), "tickets": tb.tickets_now(folders=folders)}


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


def board_move(task_id, status, note=None):
    """Move a task for the board. Returns (http status, body)."""
    with MOVE_LOCK:
        folders = tb.task_folders()
        try:
            old = ts.header(ts.find(task_id, folders)[0]).get("status")
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
        return self.send(404, {"error": "Not found."})

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
            code, out = board_move(task_id, status, body.get("note"))
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
