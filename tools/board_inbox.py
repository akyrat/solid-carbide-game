"""Named Project Lead sessions and their reading of the board's inbox of drags (T-127).

The board runs several Project Lead sessions at once, all on one task board. Each session has a
short name the board gives it (for example "Camera" or "Tools"), and each ticket can have an
owner (the `lead:` line, set with `python tools/task_status.py T-012 --lead Tools`).

The task board server appends every drag to .board/board-inbox.jsonl. Nothing empties or renames
that file. Each session keeps its own read position (a cursor) in .board/sessions/<session id>.json,
together with its name, and gets only the new moves that concern it:

- moves on tickets it owns, and moves on tickets nobody owns (with a note to claim them first);
- never moves on another session's tickets;
- a session without a name gets every move, with a reminder to ask the board for a name.

The hooks (.claude/hooks/board_gate.py) and the watcher below advance the same cursor, so a move
reaches a session once. A session with no cursor yet starts at the current end of the inbox: it
never replays older moves.

Usage (from the main repo):

  python tools/board_inbox.py name <session id> <Name> [--take-over]
      Gives a session its name, or renames it. A name another live session holds (one seen in the
      last 12 hours) is refused; --take-over moves it to this session (for example after /clear,
      which starts a new session id).

  python tools/board_inbox.py watch <session id> [--interval 1]
      Prints each new move that concerns the session as one line, checking once a second, for the
      Monitor tool. It advances the same cursor as the hooks.

Exit codes: 0 done, 1 refused (the reason is printed), 2 usage error.
"""

import json
import re
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402

SESSION_ID_RE = re.compile(r"[A-Za-z0-9_-]{1,100}")
LIVE_FOR = timedelta(hours=12)   # a session seen this recently still holds its name
SEEN_EVERY = 60                  # seconds between "last seen" updates when nothing else changes
READ_WAIT = 3                    # seconds a reader waits for another reader of the same session
NAME_CMD = "python tools/board_inbox.py name"
LEAD_CMD = "python tools/task_status.py"


class Refused(Exception):
    pass


def inbox_path():
    return tb.STATE_DIR / "board-inbox.jsonl"


def sessions_dir():
    return tb.STATE_DIR / "sessions"


def now():
    return datetime.now(timezone.utc)


def stamp(t=None):
    return (t or now()).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_stamp(s):
    try:
        return datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return None


def check_session_id(sid):
    if not isinstance(sid, str) or not SESSION_ID_RE.fullmatch(sid):
        raise Refused(f"Not a session id: {sid!r}.")
    return sid


def session_file(sid):
    return sessions_dir() / f"{check_session_id(sid)}.json"


def session_lock(sid):
    return sessions_dir() / f"{check_session_id(sid)}.lock"


def load(sid):
    try:
        data = json.loads(session_file(sid).read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save(sid, data):
    path = session_file(sid)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data), encoding="utf-8")
    tmp.replace(path)


def all_sessions():
    out = {}
    for path in sorted(sessions_dir().glob("*.json")):
        sid = path.stem
        if SESSION_ID_RE.fullmatch(sid):
            out[sid] = load(sid)
    return out


def is_live(data, at=None):
    seen = parse_stamp(data.get("seen"))
    return bool(seen) and (at or now()) - seen < LIVE_FOR


def name_of(sid):
    return load(sid).get("name") or ""


def same_name(a, b):
    return bool(a) and bool(b) and a.casefold() == b.casefold()


# --- Names ---

def register(sid, name, take_over=False):
    """Give a session its name (or rename it). Returns the line to print; raises Refused."""
    check_session_id(sid)
    if not isinstance(name, str) or not tb.NAME_RE.fullmatch(name):
        raise Refused(f"Not a name: {name!r}. A name is one short word: letters, digits, - or _ "
                      "(up to 30 characters), for example Camera or Tools.")
    with tb.file_lock(sessions_dir() / "names.lock"):
        at = now()
        moved_from = []
        for other, data in all_sessions().items():
            if other == sid or not same_name(data.get("name"), name):
                continue
            if is_live(data, at) and not take_over:
                raise Refused(f"Another session ({other}, last seen {data.get('seen')}) is named "
                              f"{data.get('name')}. Pick another name, or add --take-over if that "
                              "session has ended (for example after /clear).")
            with tb.file_lock(session_lock(other)):
                data = load(other)
                data.pop("name", None)
                save(other, data)
            moved_from.append(other)
        with tb.file_lock(session_lock(sid)):
            data = load(sid)
            old = data.get("name") or ""
            data["name"] = name
            data["seen"] = stamp(at)
            if "cursor" not in data:
                data["cursor"] = inbox_size()
            save(sid, data)
    line = f"This session ({sid}) is now named {name}" + (f" (was {old})" if old and old != name else "") + "."
    if moved_from:
        line += f" The name was taken over from {', '.join(moved_from)}."
    return line


# --- Reading the inbox ---

def inbox_size():
    try:
        return inbox_path().stat().st_size
    except OSError:
        return 0


def read_new(sid):
    """(name, moves) the session hasn't read yet, advancing its cursor past them. Every move is
    returned whoever owns it; relevant() picks the ones for this session."""
    try:
        with tb.file_lock(session_lock(sid), timeout=READ_WAIT):
            return _read_new_locked(sid)
    except TimeoutError:
        return name_of(sid), []   # another reader holds the lock; the moves come next time


def _read_new_locked(sid):
    data = load(sid)
    size = inbox_size()
    cursor = data.get("cursor")
    at = now()
    if not isinstance(cursor, int) or isinstance(cursor, bool):
        # First read for this session: start at the current end, never replay older moves.
        data["cursor"], data["seen"] = size, stamp(at)
        save(sid, data)
        return data.get("name") or "", []
    start = 0 if cursor > size else cursor   # a shorter inbox was put in its place: all of it is new
    chunk = b""
    if size > start:
        with inbox_path().open("rb") as f:
            f.seek(start)
            chunk = f.read(size - start)
    end = chunk.rfind(b"\n") + 1   # a line still being written is read next time
    moves = []
    for raw in chunk[:end].splitlines():
        try:
            m = json.loads(raw.decode("utf-8"))
        except ValueError:
            continue
        if isinstance(m, dict) and m.get("id"):
            moves.append(m)
    seen = parse_stamp(data.get("seen"))
    if start + end != cursor or not seen or (at - seen).total_seconds() > SEEN_EVERY:
        data["cursor"], data["seen"] = start + end, stamp(at)
        save(sid, data)
    return data.get("name") or "", moves


def ticket_owner(task_id, folders=None):
    """The ticket's lead, read where the ticket lives (its branch folder while open); "" if none."""
    try:
        path, _ = ts.find(task_id, folders)
        return (tb.parse_header(path.read_text(encoding="utf-8")) or {}).get("lead", "") or ""
    except (ts.Refused, OSError):
        return ""


def relevant(moves, name, owner_of=None):
    """[(move, needs_claim)] for a session named `name` ("" for no name)."""
    if not moves:
        return []
    if not name:
        return [(m, False) for m in moves]
    if owner_of is None:
        folders = tb.task_folders()
        owner_of = lambda tid: ticket_owner(tid, folders)  # noqa: E731
    out = []
    for m in moves:
        owner = owner_of(m["id"])
        if not owner:
            out.append((m, True))
        elif same_name(owner, name):
            out.append((m, False))
    return out


def take(sid, owner_of=None):
    """(name, [(move, needs_claim)]): the new moves that concern this session, read once."""
    name, moves = read_new(sid)
    return name, relevant(moves, name, owner_of)


# --- Messages, shared by the hooks and the watcher ---

def name_reminder(sid):
    return (f"This Project Lead session has no name yet (session id {sid}), so it gets every move on the "
            "task board. Ask the board for a short name for it (for example Camera or Tools), then "
            f"register it: {NAME_CMD} {sid} <Name>")


def claim_note(ids, name):
    return (f"No session owns {', '.join(ids)} yet. Claim each one before acting on it: "
            f"{LEAD_CMD} <id> --lead {name}. Act on it only if the claim succeeds: another session "
            "may claim it first.")


def move_line(m, needs_claim=False, name=""):
    line = f"{m['id']} {m.get('from')} → {m.get('to')}"
    if m.get("note"):
        line += f" (note: {m['note']})"
    if needs_claim:
        line += (f" [no owner yet: claim it with {LEAD_CMD} {m['id']} --lead {name}, "
                 "and act on it only if the claim succeeds]")
    return line


def watch(sid, interval=1.0, out=None, rounds=None):
    """Print each new move for this session as one line until stopped (`rounds` limits the polls)."""
    out = out or sys.stdout
    check_session_id(sid)
    if not name_of(sid):
        print(name_reminder(sid), file=out, flush=True)
    n = 0
    while rounds is None or n < rounds:
        name, moves = take(sid)
        for m, claim in moves:
            print(move_line(m, claim, name), file=out, flush=True)
        n += 1
        if rounds is None or n < rounds:
            time.sleep(interval)
    return 0


def main(argv=None):
    tb.utf8_output()
    argv = list(sys.argv[1:] if argv is None else argv)
    take_over = "--take-over" in argv
    argv = [a for a in argv if a != "--take-over"]
    interval = 1.0
    if "--interval" in argv:
        i = argv.index("--interval")
        try:
            interval = float(argv[i + 1])
        except (IndexError, ValueError):
            print("--interval needs a number of seconds.", file=sys.stderr)
            return 2
        argv = argv[:i] + argv[i + 2:]
    try:
        if len(argv) == 3 and argv[0] == "name":
            print(register(argv[1], argv[2], take_over))
            return 0
        if len(argv) == 2 and argv[0] == "watch":
            try:
                return watch(argv[1], interval)
            except KeyboardInterrupt:
                return 0
    except Refused as e:
        print(f"Refused. {e}", file=sys.stderr)
        return 1
    except TimeoutError as e:
        print(f"Refused. Try again: {e}.", file=sys.stderr)
        return 1
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
