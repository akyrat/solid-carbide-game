"""Mark a task done after merging it, and unblock the tasks that were waiting only on it.

Run from the repo root, after `git merge --no-ff --no-commit <branch>`:

  python tools/finish_task.py T-038 "the board's note"   # adds a "### Board review" section
  python tools/finish_task.py T-038 ""                   # no note

Prints what it changed. Some tasks also wait on things that are not in depends_on (for
example T-016 and T-027); check every "unblocked" line and set those back to blocked.
"""

import re
import sys
from pathlib import Path

TASKS_DIR = Path(__file__).resolve().parent.parent / "tasks"


def _header(text):
    return text.replace("\r\n", "\n").split("---")[1]


def _field(text, name):
    m = re.search(rf"^{name}: (.*)$", _header(text), re.M)
    return m.group(1).strip() if m else ""


def _set_status(path, status):
    raw = path.read_bytes().decode("utf-8")
    path.write_bytes(re.sub(r"^status: \S+", f"status: {status}", raw, count=1, flags=re.M).encode("utf-8"))


def finish(tid, note, tasks_dir=TASKS_DIR):
    """Set `tid` to done (adding the note), open blocked tasks whose dependencies are now all done.

    Returns the list of lines it would print."""
    tasks_dir = Path(tasks_dir)
    out = []
    path = next(tasks_dir.glob(f"{tid}-*.md"))
    _set_status(path, "done")
    if note:
        raw = path.read_bytes().decode("utf-8")
        nl = "\r\n" if "\r\n" in raw else "\n"
        raw = raw.rstrip() + nl + nl + "### Board review" + nl + nl + note + nl
        path.write_bytes(raw.encode("utf-8"))
    out.append(f"{tid}: done")

    status, deps, files = {}, {}, {}
    for p in tasks_dir.glob("T-*.md"):
        t = p.read_text(encoding="utf-8")
        i = _field(t, "id")
        status[i] = _field(t, "status")
        deps[i] = [d.strip() for d in _field(t, "depends_on").strip("[]").split(",") if d.strip()]
        files[i] = p
    for i, d in sorted(deps.items()):
        if status[i] == "blocked" and tid in d and all(status.get(x) == "done" for x in d):
            _set_status(files[i], "open")
            out.append(f"{i}: unblocked")
    return out


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if len(argv) != 2:
        print(__doc__)
        return 2
    for line in finish(argv[0], argv[1]):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
