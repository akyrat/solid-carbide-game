"""Move a task to its next status: the only way a task changes phase.

The status rules in tasks/README.md and CLAUDE.md ("How work flows") are checked here, so a
task can't skip a phase. Hooks in .claude/settings.json refuse direct edits to a task file's
status and qa_rounds lines, so every move goes through this script.

Usage (always this repo's copy, also from a task's branch folder, so open task branches are found):

  python C:/solid-carbide-game/tools/task_status.py T-012
      Shows the task's status, where its file is, and which moves are allowed now.

  python C:/solid-carbide-game/tools/task_status.py T-012 in-qa [--note "text"]
      Moves the task. The note is added to its result notes with the date and the move.

A task whose branch is open is changed in its branch folder (tasks/README.md, "Git branches").
Exit codes: 0 moved (or shown), 1 move refused (the reason is printed), 2 usage error.
"""

import json
import re
import sys
from datetime import date, datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import taskboard_sync as tb  # noqa: E402

LOG = tb.STATE_DIR / "moves.log"
CRITERIA_RE = re.compile(r"^## Acceptance criteria[ \t]*\n(.*?)(?=^## |\Z)", re.S | re.M)
CRITERION_RE = re.compile(r"^\s*- \[[ xX]\] .*$", re.M)
QA_PASS_RE = re.compile(r"\(QA:\s*pass\)", re.I)
QA_FAIL_RE = re.compile(r"\(QA:\s*fail\b", re.I)
FINAL = {"done", "cancelled"}
NOTE_REQUIRED = {
    "cancelled": "say why the task is no longer wanted (tasks are never deleted)",
    "flagged-for-review": None,
}


class Refused(Exception):
    pass


def find(task_id, folders=None):
    """(path, folder) of a task's file: its branch folder's copy while its branch is open."""
    folders = tb.task_folders() if folders is None else folders
    matches = sorted(tb.TASKS_DIR.glob(f"{task_id}-*.md"))
    if not matches:
        raise Refused(f"No task file for {task_id} in tasks/.")
    path = matches[0]
    folder = folders.get(task_id)
    if folder and (folder / "tasks" / path.name).exists():
        return folder / "tasks" / path.name, folder
    return path, None


def header(path):
    fields = tb.parse_header(path.read_text(encoding="utf-8"))
    if not fields:
        raise Refused(f"{path} has no header.")
    return fields


def verdicts(text):
    """(passed, failed, unchecked) acceptance criteria, from QA's '(QA: pass)' / '(QA: fail)' marks."""
    section = CRITERIA_RE.search(text.replace("\r\n", "\n"))
    lines = CRITERION_RE.findall(section.group(1)) if section else []
    passed = [l for l in lines if QA_PASS_RE.search(l) and not QA_FAIL_RE.search(l)]
    failed = [l for l in lines if QA_FAIL_RE.search(l) and "pass / fail" not in l]
    unchecked = [l for l in lines if l not in passed and l not in failed]
    return passed, failed, unchecked


def has_result_notes(text):
    return bool(tb.review_parts(text)[2])


def unfinished_deps(fields, folders):
    out = []
    for dep in fields.get("depends_on", []):
        try:
            status = header(find(dep, folders)[0]).get("status")
        except Refused:
            status = "missing"
        if status != "done":
            out.append(f"{dep} ({status})")
    return out


def allowed(fields, text, folders):
    """{status: why it is allowed} and {status: why not} for this task right now."""
    old = fields.get("status", "open")
    deps = unfinished_deps(fields, folders)
    rounds = int(fields.get("qa_rounds", "0") or 0)
    ok, no = {}, {}

    def rule(new, cond, why_not, why=""):
        (ok if cond else no)[new] = why if cond else why_not

    if old in FINAL:
        return ok, {"*": f"{old} is final. Write a new task instead (for example \"Rework ({fields.get('id')}): ...\")."}
    if old == "open":
        rule("in-progress", not deps, f"it depends on unfinished tasks: {', '.join(deps)}")
        rule("blocked", True, "")
    if old == "blocked":
        rule("open", not deps, f"it still depends on unfinished tasks: {', '.join(deps)}")
        rule("in-progress", not deps, f"it still depends on unfinished tasks: {', '.join(deps)}")
    if old == "in-progress":
        rule("in-qa", has_result_notes(text), "the agent hasn't written its result notes yet")
        rule("blocked", True, "")
        rule("open", True, "")
    if old == "in-qa":
        passed, failed, unchecked = verdicts(text)
        review = bool(tb.review_parts(text)[0])
        if unchecked:
            why = f"QA hasn't marked every acceptance criterion pass or fail ({len(unchecked)} left)"
            for s in ("done", "needs-playtest", "in-progress", "flagged-for-review"):
                no[s] = why
        elif failed:
            if rounds + 1 >= 2:
                rule("flagged-for-review", True, "", "failed QA a second time")
                no["in-progress"] = "it failed QA a second time, so it goes to the board: flagged-for-review"
            else:
                rule("in-progress", True, "", "failed QA once: back to the agent")
                no["flagged-for-review"] = "it has failed QA only once: send it back to the agent (in-progress)"
            no["done"] = no["needs-playtest"] = f"{len(failed)} acceptance criteria failed"
        else:
            if review:
                rule("needs-playtest", True, "", "QA passed and it has a \"The board's review:\" line")
                no["done"] = "it has a \"The board's review:\" line, so it waits for the board: needs-playtest"
            else:
                rule("done", True, "", "QA passed every criterion")
                no["needs-playtest"] = "it has no \"The board's review:\" line, so it is done"
            no["in-progress"] = no["flagged-for-review"] = "QA passed every criterion"
    if old == "needs-playtest":
        rule("done", True, "", "the board approved it")
        rule("in-progress", True, "", "the board sent it back")
    if old == "flagged-for-review":
        for s in ("in-progress", "open", "done"):
            rule(s, True, "", "the board's call")
    rule("cancelled", True, "")
    return ok, no


def set_field(text, key, value):
    newline = "\r\n" if "\r\n" in text else "\n"
    norm = text.replace("\r\n", "\n")
    match = tb.HEADER_RE.match(norm)
    head = re.sub(rf"^{key}: .*$", f"{key}: {value}", match.group(1), count=1, flags=re.M)
    return f"---\n{head}\n---\n{norm[match.end():]}".replace("\n", newline)


def add_note(text, line):
    newline = "\r\n" if "\r\n" in text else "\n"
    norm = text.replace("\r\n", "\n").rstrip("\n")
    if not re.search(r"^## Result notes[ \t]*$", norm, re.M):
        norm += "\n\n## Result notes\n"
    elif norm.endswith(tb.NOTES_PLACEHOLDER):
        norm = norm[: -len(tb.NOTES_PLACEHOLDER)].rstrip("\n") + "\n"
    return (norm + "\n" + line + "\n").replace("\n", newline)


def write(path, text):
    path.write_bytes(text.encode("utf-8"))


def log(entry):
    tb.STATE_DIR.mkdir(exist_ok=True)
    entry["at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def unblock_dependents(done_id, folders):
    """tasks/README.md: when a task is done, tasks now waiting on nothing move blocked -> open."""
    opened = []
    for path in tb.task_files():
        fields = tb.parse_header(path.read_text(encoding="utf-8"))
        if not fields or fields.get("status") != "blocked" or done_id not in fields.get("depends_on", []):
            continue
        real, _ = find(fields["id"], folders)
        fields = header(real)
        if fields.get("status") == "blocked" and not unfinished_deps(fields, folders):
            write(real, set_field(real.read_bytes().decode("utf-8"), "status", "open"))
            log({"id": fields["id"], "from": "blocked", "to": "open", "file": str(real), "note": f"{done_id} done"})
            opened.append(fields["id"])
    return opened


def move(task_id, new, note=None, folders=None, by="agent"):
    """Move a task; returns the lines to print. Raises Refused with the reason.

    `by` is "agent" for the script's command line and "board" for a drag on the local task board."""
    folders = tb.task_folders() if folders is None else folders
    if new not in tb.STATUSES:
        raise Refused(f"Unknown status {new!r}. Statuses: {', '.join(tb.STATUSES)}.")
    path, folder = find(task_id, folders)
    text = path.read_bytes().decode("utf-8")
    fields = tb.parse_header(text)
    old = fields.get("status", "open")
    if new == old:
        raise Refused(f"{task_id} is already {old}.")
    ok, no = allowed(fields, text, folders)
    if new not in ok:
        why = no.get(new) or no.get("*") or f"{old} can't move to {new}"
        moves = ", ".join(ok) or "none"
        raise Refused(f"{task_id} can't move {old} → {new}: {why}. Allowed now: {moves}.")
    if new == "cancelled" and not note:
        raise Refused(f"Cancelling needs --note: {NOTE_REQUIRED['cancelled']}.")
    if old == "needs-playtest" and new == "in-progress" and not note:
        raise Refused("Sending a playtest back needs --note with what the board asked for.")
    out = []
    if old == "in-qa":
        rounds = int(fields.get("qa_rounds", "0") or 0) + 1
        text = set_field(text, "qa_rounds", str(rounds))
        out.append(f"qa_rounds: {rounds}")
    text = set_field(text, "status", new)
    if note:
        text = add_note(text, f"- {date.today().isoformat()}, {old} → {new}: {note}")
    write(path, text)
    log({"id": task_id, "from": old, "to": new, "file": str(path), "note": note or "", "by": by})
    out.insert(0, f"{task_id}: {old} → {new} ({path})")
    if new == "done":
        opened = unblock_dependents(task_id, folders)
        if opened:
            out.append(f"Now open (everything they depend on is done): {', '.join(opened)}")
    return out


def show(task_id, folders=None):
    folders = tb.task_folders() if folders is None else folders
    path, folder = find(task_id, folders)
    text = path.read_text(encoding="utf-8")
    fields = tb.parse_header(text)
    ok, no = allowed(fields, text, folders)
    lines = [f"{task_id}: {fields.get('status')} ({path})"]
    lines += [f"  can move to {s}" + (f": {why}" if why else "") for s, why in ok.items()]
    lines += [f"  can't move to {s}: {why}" for s, why in no.items()]
    return lines


def main(argv=None):
    tb.utf8_output()
    argv = sys.argv[1:] if argv is None else argv
    note = None
    if "--note" in argv:
        i = argv.index("--note")
        if i + 1 >= len(argv):
            print("--note needs a text.", file=sys.stderr)
            return 2
        note = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    if len(argv) not in (1, 2) or not re.fullmatch(r"T-\d+", argv[0]):
        print(__doc__, file=sys.stderr)
        return 2
    try:
        lines = show(argv[0]) if len(argv) == 1 else move(argv[0], argv[1], note)
    except Refused as e:
        print(f"Refused. {e}", file=sys.stderr)
        return 1
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
