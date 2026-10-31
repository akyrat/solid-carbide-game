"""Write one or more new tickets' paperwork from a JSON file (T-345, token-spend epic).

  python tools/new_ticket.py tickets.json [--dry-run]

Run from the main checkout on `master`. For every ticket in the file it: picks the next free number
(the highest T-NNN found in tasks/, in `git log` on master and in task/T-NNN branches, plus one),
writes tasks/T-NNN-<slug>.md from tasks/_TEMPLATE.md (the template's comment and sections are copied),
claims it for the lead (through task_status.py), and appends a timeline entry to docs/timeline.md.
When the file names decision docs, it also regenerates the long GDD and the short GDD's fingerprint.
Then it commits only those files, in one commit, after checking that no merge is in progress.
It prints one line per ticket. The decisions themselves stay the Project Lead's: it writes the
Decisions line in the game area doc and the acceptance criteria before running this.

Input (JSON). Top level: "lead" (session name), "commit_message", "decision_docs" (docs already edited,
default []), "date" (timeline heading date, default today), "common_description" and "common_criteria"
(added to every ticket, optional), "tickets" (a list). A ticket: "title", "slug", "description",
"criteria" (list), "timeline" ({"title", "decision", "documents" (list)}), and optionally "to"
(default project-lead), "epic", "milestone" (default mvp), "model" (default sonnet), "user_facing_text",
"changes_visuals" (default no), "board_approved_art" (default no), "depends_on", "documents_affected", "files_to_read_first",
"files_expected_to_change" (lists), "lead" (overrides the top-level one).
Exit codes: 0 written and committed, 1 refused (nothing written), 2 usage or input error.
"""

import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
TEMPLATE = Path("tasks/_TEMPLATE.md")
TIMELINE = Path("docs/timeline.md")
TOP_KEYS = {"lead", "commit_message", "decision_docs", "date", "common_description", "common_criteria", "tickets"}
TICKET_KEYS = {"title", "slug", "description", "criteria", "timeline", "to", "epic", "milestone", "model",
               "user_facing_text", "changes_visuals", "board_approved_art", "depends_on", "documents_affected",
               "files_to_read_first", "files_expected_to_change", "lead"}
ID_RE = re.compile(r"\bT-(\d+)\b")


class Refused(Exception):
    pass


def git(root, *args, check=True):
    r = subprocess.run(["git", *args], cwd=root, capture_output=True, text=True, encoding="utf-8")
    if check and r.returncode:
        raise Refused(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r


def merge_in_progress(root):
    return bool(git(root, "rev-parse", "-q", "--verify", "MERGE_HEAD", check=False).stdout.strip())


def next_number(root):
    """Highest T-NNN in tasks/, in git log on master (or HEAD) and in task/T-NNN branches, plus one."""
    found = [0]
    for p in (Path(root) / "tasks").glob("T-*.md"):
        m = re.match(r"T-(\d+)", p.name)
        if m:
            found.append(int(m.group(1)))
    base = "master" if git(root, "rev-parse", "--verify", "-q", "master", check=False).stdout.strip() else "HEAD"
    log = git(root, "log", base, "--format=%s%n%b", check=False).stdout
    found += [int(n) for n in ID_RE.findall(log)]
    branches = git(root, "branch", "--list", "task/T-*", "--format=%(refname:short)", check=False).stdout
    found += [int(n) for n in ID_RE.findall(branches)]
    return max(found) + 1


def validate(spec):
    if not isinstance(spec, dict):
        raise Refused("The input must be a JSON object.")
    for k in spec:
        if k not in TOP_KEYS:
            raise Refused(f"Unknown top-level key {k!r}.")
    for k in ("lead", "commit_message", "tickets"):
        if not spec.get(k):
            raise Refused(f"Missing {k!r}.")
    if not isinstance(spec["tickets"], list):
        raise Refused("'tickets' must be a list.")
    for i, t in enumerate(spec["tickets"], 1):
        for k in t:
            if k not in TICKET_KEYS:
                raise Refused(f"Ticket {i}: unknown key {k!r}.")
        for k in ("title", "slug", "description", "criteria", "timeline"):
            if not t.get(k):
                raise Refused(f"Ticket {i}: missing {k!r}.")
        if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", t["slug"]):
            raise Refused(f"Ticket {i}: the slug must be lowercase words joined by -.")
        for k in ("title", "decision"):
            if not t["timeline"].get(k):
                raise Refused(f"Ticket {i}: timeline needs {k!r}.")
        if not t["timeline"].get("documents"):
            raise Refused(f"Ticket {i}: timeline needs 'documents' (the documents the decision touched).")


def lst(xs):
    return "[" + ", ".join(xs) + "]"


def render(template, spec, t, number):
    """The ticket text: the template's header lines filled in, its comment and sections copied."""
    text = template.replace("\r\n", "\n")
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        raise Refused("tasks/_TEMPLATE.md has no header.")
    values = {
        "id": f"T-{number:03d}", "title": t["title"], "status": "open", "from": "project-lead",
        "to": t.get("to", "project-lead"), "lead": "", "epic": t.get("epic", ""),
        "milestone": t.get("milestone", "mvp"), "goal": "",
        "user_facing_text": t.get("user_facing_text", "no"), "changes_visuals": t.get("changes_visuals", "no"),
        "board_approved_art": t.get("board_approved_art", "no"),
        "depends_on": lst(t.get("depends_on", [])),
        "documents_affected": lst(t.get("documents_affected", [])),
        "files_to_read_first": lst(t.get("files_to_read_first", ["tasks/README.md"])),
        "files_expected_to_change": lst(t.get("files_expected_to_change", [])),
        "model": t.get("model", "sonnet"), "qa_rounds": "0",
    }
    head = []
    for line in m.group(1).split("\n"):
        key = line.split(":", 1)[0]
        head.append(f"{key}: {values[key]}".rstrip() if key in values else line)
    rest = text[m.end():]
    comment = rest[rest.index("<!--"):rest.index("-->") + 3]
    intro_start = rest.index("## Acceptance criteria")
    intro = rest[intro_start + len("## Acceptance criteria"):rest.index("- [ ]", intro_start)].strip()
    tail = rest[rest.index("## Updates"):]
    desc = t["description"].strip()
    if spec.get("common_description"):
        desc += "\n\n" + spec["common_description"].strip()
    crit = "\n".join(f"- [ ] {c.strip()} (QA: pass / fail)" for c in list(t["criteria"]) + list(spec.get("common_criteria", [])))
    return ("---\n" + "\n".join(head) + "\n---\n\n" + comment + "\n\n## Description\n\n" + desc +
            "\n\n## Acceptance criteria\n\n" + intro + "\n\n" + crit + "\n\n" + tail)


def timeline_entry(day, t, number):
    tl = t["timeline"]
    return (f"\n## {day}: {tl['title']}\n- Decision or change: {tl['decision'].strip()}\n"
            f"- Documents touched: {', '.join(tl['documents'])}\n- Tasks: T-{number:03d}\n")


def run(spec, root=ROOT, dry_run=False):
    """Writes the tickets and commits; returns the lines to print. Raises Refused before writing anything."""
    root = Path(root)
    validate(spec)
    if merge_in_progress(root):
        raise Refused("A merge is in progress (MERGE_HEAD exists): it is another instance's. Not writing or committing.")
    template = (root / TEMPLATE).read_text(encoding="utf-8")
    day = spec.get("date") or date.today().isoformat()
    first = next_number(root)
    docs = list(spec.get("decision_docs", []))
    for d in docs:
        if not (root / d).is_file():
            raise Refused(f"Decision doc {d} not found.")
    plan = []
    for i, t in enumerate(spec["tickets"]):
        n = first + i
        path = Path("tasks") / f"T-{n:03d}-{t['slug']}.md"
        if (root / path).exists():
            raise Refused(f"{path} already exists.")
        plan.append((n, path, t))
    lines = [f"T-{n:03d} {p.as_posix()} (lead {t.get('lead', spec['lead'])})" for n, p, t in plan]
    if dry_run:
        return ["dry run: " + l for l in lines]
    files = []
    for n, path, t in plan:
        (root / path).write_text(render(template, spec, t, n), encoding="utf-8", newline="\n")
        files.append(path.as_posix())
    tl = root / TIMELINE
    body = tl.read_text(encoding="utf-8")
    if not body.endswith("\n"):
        body += "\n"
    for n, _, t in plan:
        body += timeline_entry(day, t, n)
    tl.write_text(body, encoding="utf-8", newline="\n")
    files.append(TIMELINE.as_posix())
    for n, _, t in plan:
        r = subprocess.run([sys.executable, str(root / "tools/task_status.py"), f"T-{n:03d}", "--lead",
                            t.get("lead", spec["lead"])], cwd=root, capture_output=True, text=True, encoding="utf-8")
        if r.returncode:
            raise Refused(f"Claiming T-{n:03d} failed: {(r.stdout + r.stderr).strip()}")
    files += docs
    if docs:
        for script in ("generate_long_gdd.py", "update_short_gdd_fingerprint.py"):
            r = subprocess.run([sys.executable, str(root / "tools" / script)], cwd=root, capture_output=True,
                               text=True, encoding="utf-8")
            if r.returncode:
                raise Refused(f"{script} failed: {(r.stdout + r.stderr).strip()}")
        files += ["docs/long-gdd.md", "docs/short-gdd/README.md"]
    if merge_in_progress(root):
        raise Refused("A merge started while writing. Files are written but not committed.")
    git(root, "add", "--", *files)
    git(root, "commit", "-m", spec["commit_message"], "--", *files)
    return lines


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    dry = "--dry-run" in argv
    args = [a for a in argv if a != "--dry-run"]
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        spec = json.loads(Path(args[0]).read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"Cannot read the input: {e}", file=sys.stderr)
        return 2
    try:
        for line in run(spec, ROOT, dry):
            print(line)
    except Refused as e:
        print(f"Refused: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
