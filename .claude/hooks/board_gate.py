"""Claude Code hook: keeps the local task board and the Project Lead connected.

Wired in .claude/settings.json. One script for every event; it reads the hook's JSON from stdin.

- SessionStart: starts the local task board (tools/taskboard/server.py) if it isn't running,
  and tells the board and the Project Lead its address.
- PreToolUse Edit/Write/MultiEdit: refuses changes to a task file's status or qa_rounds line.
  Moves go through tools/task_status.py, which checks the workflow rules.
- PreToolUse Bash/PowerShell: refuses shell commands that rewrite those lines.
- UserPromptSubmit, PostToolUse Agent: hands the Project Lead the moves the board made on the
  task board since it last heard (.board/board-inbox.jsonl), so it acts on them.
- Stop: if the board moved something while the Project Lead was working, it gets one more turn
  to act on it before finishing.

The task board reads the task files directly, so it is never behind: an agent's move shows up
on the page within a couple of seconds, and the board's drags are real status changes.
"""

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "taskboard"))
import taskboard_sync as tb  # noqa: E402

TASK_FILE_RE = re.compile(r"[\\/]tasks[\\/](T-\d+)[^\\/]*\.md$")
GUARDED = ("status", "qa_rounds")
STATUS_SCRIPT = "python tools/task_status.py"
SERVER = ROOT / "tools" / "taskboard" / "server.py"


def out(obj):
    print(json.dumps(obj))
    return 0


def deny(reason):
    return out({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                       "permissionDecision": "deny", "permissionDecisionReason": reason}})


# --- Status lines change only through task_status.py ---

def guarded_fields(text):
    fields = tb.parse_header(text) or {}
    return {k: fields.get(k) for k in GUARDED}


def edited_text(tool, tool_input, current):
    if tool == "Write":
        return tool_input.get("content", "")
    edits = tool_input.get("edits") if tool == "MultiEdit" else [tool_input]
    text = current.replace("\r\n", "\n")   # the Edit tool matches LF text in CRLF files too
    for e in edits or []:
        old, new = e.get("old_string", "").replace("\r\n", "\n"), e.get("new_string", "").replace("\r\n", "\n")
        text = text.replace(old, new) if e.get("replace_all") else text.replace(old, new, 1)
    return text


def pre_edit(tool, tool_input):
    path = tool_input.get("file_path") or ""
    match = TASK_FILE_RE.search(path)
    if not match:
        return 0
    file = Path(path)
    if not file.exists():
        fields = guarded_fields(tool_input.get("content", ""))
        if fields["status"] in (None, "open", "blocked") and fields["qa_rounds"] in (None, "0"):
            return 0
        return deny("A new task starts as open (or blocked, when it depends on unfinished tasks) with qa_rounds: 0.")
    current = file.read_bytes().decode("utf-8")
    before, after = guarded_fields(current), guarded_fields(edited_text(tool, tool_input, current))
    changed = [k for k in GUARDED if before[k] != after[k]]
    if not changed:
        return 0
    task = match.group(1)
    target = after["status"] or "<status>"
    return deny(f"A task's {' and '.join(changed)} line changes only through the status script, which checks "
                f"the workflow rules. Run: {STATUS_SCRIPT} {task} {target} "
                f"(from a task's branch folder, use the main repo's copy: python {ROOT / 'tools' / 'task_status.py'}). "
                f"Run it with just the task id to see the allowed moves.")


def pre_shell(tool_input):
    cmd = tool_input.get("command") or ""
    if "task_status.py" in cmd or "taskboard_sync.py" in cmd:
        return 0
    if re.search(r"tasks[\\/]+T-\d+", cmd) and re.search(r"\b(status|qa_rounds)\s*:", cmd):
        return deny(f"Task statuses change only through the status script: {STATUS_SCRIPT} <T-id> <status>.")
    return 0


# --- The local task board ---

def board_url():
    import server
    return f"http://localhost:{server.port()}"


def ensure_server():
    """(url, note) with the board running; starts it in the background when needed."""
    import server
    running = server.health()
    if running and Path(running["root"]) == ROOT:
        return board_url(), "already running"
    if running:
        return None, (f"port {server.port()} is taken by a board for {running['root']}; "
                      "set BOARD_PORT to run this repo's board on another port")
    tb.STATE_DIR.mkdir(exist_ok=True)
    log = (tb.STATE_DIR / "server.out").open("a", encoding="utf-8")
    flags = 0
    if os.name == "nt":
        flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW
    subprocess.Popen([sys.executable, str(SERVER)], cwd=str(ROOT), stdin=subprocess.DEVNULL, stdout=log,
                     stderr=subprocess.STDOUT, creationflags=flags, close_fds=True,
                     start_new_session=(os.name != "nt"))
    for _ in range(30):
        time.sleep(0.2)
        if server.health():
            return board_url(), "started"
    return None, f"it didn't start; see {tb.STATE_DIR / 'server.out'}"


def take_inbox():
    """The board's moves the Project Lead hasn't heard about yet; they are marked heard."""
    inbox = tb.STATE_DIR / "board-inbox.jsonl"
    if not inbox.exists():
        return []
    taking = tb.STATE_DIR / f"board-inbox.{os.getpid()}.taking"
    try:
        os.replace(inbox, taking)   # the server starts a new inbox for anything that arrives now
    except OSError:
        return []
    lines = taking.read_text(encoding="utf-8").splitlines()
    with (tb.STATE_DIR / "board-inbox-heard.jsonl").open("a", encoding="utf-8") as f:
        f.write("".join(l + "\n" for l in lines))
    taking.unlink()
    moves = []
    for l in lines:
        try:
            moves.append(json.loads(l))
        except ValueError:
            pass
    return moves


def describe_moves(moves):
    parts = []
    for m in moves:
        part = f"{m['id']} {m['from']} → {m['to']}"
        if m.get("note"):
            part += f" (note: {m['note']})"
        parts.append(part)
    return ("The board moved these tasks on the task board (the task files are already changed): "
            + "; ".join(parts) + ". Act on them: start the agent for a task moved to in-progress, run QA for one "
            "moved to in-qa, merge one the board marked done after a playtest, and tell the board what you did.")


def session_start(data):
    url, note = ensure_server()
    if url:
        msg = f"Task board: {url}"
        context = (f"The local task board is running at {url} ({note}). It reads the task files directly, so "
                   "it is always up to date. The board moves tasks by dragging cards; those moves reach you "
                   "through hooks.")
    else:
        msg = f"The task board isn't running: {note}."
        context = msg + " Tell the board."
    moves = take_inbox()
    if moves:
        context += " " + describe_moves(moves)
    return out({"systemMessage": msg,
                "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}})


def hand_over(event):
    moves = take_inbox()
    if not moves:
        return 0
    return out({"hookSpecificOutput": {"hookEventName": event, "additionalContext": describe_moves(moves)}})


def stop(data):
    if data.get("stop_hook_active"):
        return 0
    moves = take_inbox()
    if not moves:
        return 0
    return out({"decision": "block", "reason": describe_moves(moves)})


def main():
    data = json.load(sys.stdin)
    if (tb.STATE_DIR / "debug").exists():
        tb.STATE_DIR.mkdir(exist_ok=True)
        with (tb.STATE_DIR / "hook-debug.jsonl").open("a", encoding="utf-8") as f:
            f.write(json.dumps(data, ensure_ascii=False)[:20000] + "\n")
    event, tool = data.get("hook_event_name"), data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    if event == "SessionStart":
        return session_start(data)
    if event == "PreToolUse":
        if tool in ("Edit", "Write", "MultiEdit"):
            return pre_edit(tool, tool_input)
        if tool in ("Bash", "PowerShell"):
            return pre_shell(tool_input)
    if event == "UserPromptSubmit":
        return hand_over("UserPromptSubmit")
    if event == "PostToolUse" and tool == "Agent":
        return hand_over("PostToolUse")
    if event == "Stop":
        return stop(data)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # a broken hook must never block work silently
        print(json.dumps({"systemMessage": f"board_gate hook error: {e}"}))
        sys.exit(0)
