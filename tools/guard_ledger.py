"""The ledger of task-file states that tools/task_status.py wrote (T-149).

A task's `status`, `qa_rounds` and `lead` lines change only through the status script. The hooks
(.claude/hooks/board_gate.py) refuse the edits they can recognise, but no command filter can see every
way to write a file (a script written earlier, a glob, a `mv`). So the script also keeps this ledger:
each time it changes those lines it appends the new state, and it refuses to work on a file whose
state it did not write (and that is not simply what git has committed). The hook runs the same check
on `git commit`, so a hand-edited line cannot be committed whichever tool made the edit.

The ledger is `.board/blessed-states.jsonl` of the main checkout (shared by every task folder, git-ignored).
Until it exists the checks are off; the first script run creates it, trusting the states it finds then.
A state is the task file's guarded header lines, as (key, value) pairs.
"""

import json
import re
import subprocess
from pathlib import Path

import taskboard_sync as tb

LINE_RE = re.compile(r"^[ \t]*(status|qa_rounds|lead)[ \t]*:(.*)$", re.I | re.M)
LEDGER_NAME = "blessed-states.jsonl"


def state(text):
    """The guarded header lines of a task file as a tuple of (key, value), in file order; every line counts,
    so a repeated `qa_rounds:` line shows. An empty `lead:` line is the same as none. None without a header."""
    match = tb.HEADER_RE.match(text.replace("\r\n", "\n"))
    if not match:
        return None
    pairs = [(m.group(1).lower(), m.group(2).strip()) for m in LINE_RE.finditer(match.group(1))]
    return tuple(p for p in pairs if p != ("lead", ""))


def is_initial(st):
    """A new task: open or blocked, no qa_rounds or 0, no owner (tasks/README.md)."""
    if st is None:
        return False
    d = dict(st)
    return len(d) == len(st) and d.get("status") in ("open", "blocked") and d.get("qa_rounds", "0") == "0"


def task_id(text):
    match = re.search(r"^id:[ \t]*(T-\d+)[ \t]*$", text.replace("\r\n", "\n").split("\n---\n", 1)[0], re.M)
    return match.group(1) if match else None


def git(cwd, *args):
    """Output of a git command run in `cwd`, or None when it fails."""
    try:
        done = subprocess.run(["git", "-C", str(cwd), *args], capture_output=True, check=True,
                              creationflags=tb.no_window())
    except (OSError, subprocess.CalledProcessError):
        return None
    return done.stdout.decode("utf-8", "replace")


def ledger_path():
    """The ledger file: in the main checkout's .board when tb.STATE_DIR is the real one, else beside STATE_DIR."""
    if tb.STATE_DIR != tb.ROOT / ".board":
        return tb.STATE_DIR / LEDGER_NAME
    common = git(tb.ROOT, "rev-parse", "--git-common-dir")
    if common and common.strip():
        common = Path(common.strip())
        common = common if common.is_absolute() else (tb.ROOT / common)
        return common.resolve().parent / ".board" / LEDGER_NAME
    return tb.STATE_DIR / LEDGER_NAME


def read():
    """{task id: set of blessed states}, or None when there is no ledger (the checks are off)."""
    path = ledger_path()
    if not path.exists():
        return None
    blessed = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        try:
            row = json.loads(line)
            blessed.setdefault(row["id"], set()).add(tuple((k, v) for k, v in row["state"]))
        except (ValueError, KeyError, TypeError):
            continue
    return blessed


def bless(tid, text):
    """Record the state of a task file the script has just written."""
    st = state(text)
    if st is None:
        return
    path = ledger_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"id": tid, "state": st}) + "\n")


def seed(paths):
    """Create the ledger from the task files as they are now, if there is none (trust on first use)."""
    if ledger_path().exists():
        return
    for p in paths:
        try:
            text = Path(p).read_bytes().decode("utf-8", "replace")
        except OSError:
            continue
        if task_id(text):
            bless(task_id(text), text)
    path = ledger_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch()


def head_text(path):
    """The file's text at HEAD of the repo it is in, or None (untracked, or not in a repo)."""
    path = Path(path)
    out = git(path.parent, "show", f"HEAD:./{path.name}")
    return out


def ok(tid, text, committed, ledger):
    """May a task file with this text exist? Yes when the ledger is off, its guarded lines are what git has
    committed, the script wrote that state, or it is a brand-new task in its starting state."""
    if ledger is None:
        return True
    st = state(text)
    if committed is not None:
        return st == state(committed) or st in ledger.get(tid, ())
    return st in ledger.get(tid, ()) or is_initial(st)
