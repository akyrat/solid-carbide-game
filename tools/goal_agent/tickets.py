"""Layer 2, gap detection (the ticket side): checks ticket drafts against the studio's rules and writes them.

check() refuses a set of drafts, with one reason per broken rule (CLAUDE.md, tasks/README.md).
write() turns accepted drafts into task files from tasks/_TEMPLATE.md, with `goal:` set, starting as
`open` (or `blocked` while they depend on unfinished work), and claims each one for the goal's session
(`lead: Goal-G-NNN`) through the status script, the only way a `lead` line changes.
Criteria only the Project Lead can meet (the long GDD, the short GDD, the docs staleness check, the timeline,
merging: lead_only()) are dropped before a ticket is written (T-215): only the Project Lead does those, at merge,
so no agent or QA could make them pass. A draft left with no criteria is refused.
Ticket ids are the next free number after every id in tasks/, on task/* branches and in master's log.
"""

import re
import subprocess
import sys
from pathlib import Path

import taskboard_sync as tb
from task_status import set_field
from goal_agent.claude_call import Pause
from goal_agent.goal_file import slug

ID_RE = re.compile(r"T-(\d+)")
DRAFT = {
    "type": "object",
    "properties": {
        "key": {"type": "string", "description": "D1, D2, ...: how other drafts name it in depends_on"},
        "title": {"type": "string"},
        "to": {"type": "string", "description": "the agent's name, from .claude/agents/"},
        "epic": {"type": "string"},
        "milestone": {"type": "string"},
        "model": {"type": "string", "enum": ["sonnet", "opus"]},
        "user_facing_text": {"type": "string", "enum": ["yes", "no"]},
        "changes_visuals": {"type": "string", "enum": ["yes", "no"]},
        "depends_on": {"type": "array", "items": {"type": "string"}, "description": "draft keys or T-NNN ids"},
        "documents_affected": {"type": "array", "items": {"type": "string"}},
        "files_to_read_first": {"type": "array", "items": {"type": "string"}},
        "files_expected_to_change": {"type": "array", "items": {"type": "string"}},
        "description": {"type": "string"},
        "acceptance_criteria": {"type": "array", "items": {"type": "string"}},
        "review": {"type": "string", "description": "the text after \"The board's review:\", or empty"},
    },
    "required": ["key", "title", "to", "epic", "milestone", "model", "user_facing_text", "changes_visuals",
                 "depends_on", "documents_affected", "files_to_read_first", "files_expected_to_change",
                 "description", "acceptance_criteria", "review"],
}


MERGE = r"\bmerg(?:e|ed|es|ing)\b"
LEAD_ONLY = [
    (re.compile(r"\blong[- ]?gdd\b|long-gdd\.md|generate_long_gdd", re.I), "the long GDD"),
    (re.compile(r"\bshort[- ]?gdd\b|short-gdd|update_short_gdd_fingerprint", re.I), "the short GDD"),
    (re.compile(r"\bstaleness\b|\bdocs? (?:are |is )?(?:not )?stale\b", re.I), "the docs staleness check"),
    (re.compile(r"docs/timeline\.md|\btimeline (?:entry|entries|record)\b|\b(?:in|to|on) the timeline\b", re.I),
     "the timeline"),
    (re.compile(MERGE + r".*\b(?:master|branch|playtest|goal's build)\b|\b(?:master|branch|playtest)\b.*" + MERGE, re.I),
     "merging"),
]
LEAD_ONLY_WHY = ("Only the Project Lead regenerates the long GDD and the short GDD's fingerprint, runs the docs "
                 "staleness check, writes the timeline and merges, at merge time; no agent or QA can make such a "
                 "criterion pass, so QA would fail it.")


def lead_only(criterion):
    """What a criterion is about that only the Project Lead can do ("the long GDD", ...), or None (T-215)."""
    for pattern, what in LEAD_ONLY:
        if pattern.search(criterion or ""):
            return what
    return None


def kept_criteria(d):
    """The draft's criteria without the empty ones and the ones only the Project Lead can meet."""
    return [c for c in d.get("acceptance_criteria") or [] if c.strip() and not lead_only(c)]


def dropped_criteria(d):
    return [c.strip() for c in d.get("acceptance_criteria") or [] if c.strip() and lead_only(c)]


def dropped_note(dropped):
    """The goal file's iteration log text for the criteria write() left out ("" for none)."""
    if not dropped:
        return ""
    return ("dropped criteria only the Project Lead can meet (T-215): "
            + "; ".join(f"{tid}: \"{c}\" ({what})" for tid, c, what in dropped) + ".")


def agents(root):
    return {p.stem for p in (Path(root) / ".claude" / "agents").glob("*.md")} | {"project-lead"}


def epics_and_milestones(root):
    """The epic ids and milestone ids from the two tables in tasks/README.md."""
    text = (Path(root) / "tasks" / "README.md").read_text(encoding="utf-8")
    part = text.split("## Epics and milestones", 1)[-1].split("\n## ", 1)[0]
    epics, _, milestones = part.partition("**Milestone:**")
    row = re.compile(r"^\| `([a-z0-9-]+)` \|", re.M)
    return set(row.findall(epics)), set(row.findall(milestones))


def shows_player(d):
    """Does the draft change what the player sees, reads or hears?"""
    return d.get("changes_visuals") == "yes" or d.get("user_facing_text") == "yes" or d.get("to") == "sfx"


def check(drafts, existing, root):
    """Reasons the set of drafts is refused ([] when it is accepted). `existing`: {id: ticket} (taskboard_sync)."""
    known_agents = agents(root)
    epics, milestones = epics_and_milestones(root)
    by_key = {d.get("key"): d for d in drafts}
    reasons = []
    if len(by_key) != len(drafts):
        reasons.append("Draft keys repeat; each draft needs its own key (D1, D2, ...).")

    def to_of(ref):
        return (by_key.get(ref) or existing.get(ref) or {}).get("to")

    for d in drafts:
        name = f"{d.get('key')} ({d.get('title', '')})"
        reads, deps = d.get("files_to_read_first") or [], d.get("depends_on") or []
        say = lambda why: reasons.append(f"{name}: {why}")   # noqa: E731
        if d.get("to") not in known_agents:
            say(f"`to` is {d.get('to')!r}, not an agent in .claude/agents/ or project-lead.")
        if d.get("model") not in ("sonnet", "opus"):
            say(f"`model` is {d.get('model')!r}; it must be sonnet or opus.")
        if d.get("epic") not in epics:
            say(f"`epic` {d.get('epic')!r} is not in the table in tasks/README.md.")
        if d.get("milestone") not in milestones:
            say(f"`milestone` {d.get('milestone')!r} is not in the table in tasks/README.md.")
        if d.get("changes_visuals") == "yes":
            for doc in ("docs/visual-style.md", "docs/extended-narrative.md"):
                if doc not in reads:
                    say(f"changes_visuals is yes but files_to_read_first lacks {doc}.")
        if d.get("user_facing_text") == "yes" and d.get("to") != "narrative-theme":
            if "docs/extended-narrative.md" not in reads:
                say("user_facing_text is yes but files_to_read_first lacks docs/extended-narrative.md.")
            if not any(to_of(dep) == "narrative-theme" for dep in deps):
                say("user_facing_text is yes but it doesn't depend on a narrative-theme ticket for its text.")
        if d.get("to") == "asset-generation":
            if not any(to_of(dep) not in (None, "asset-generation") for dep in deps):
                say("an art ticket must depend on the functional ticket it swaps its art into.")
            if not (d.get("review") or "").strip():
                say("every art ticket needs a \"The board's review:\" line.")
        elif shows_player(d) and not (d.get("review") or "").strip():
            say("it changes what the player sees, reads or hears but has no \"The board's review:\" line.")
        if not kept_criteria(d):
            dropped = dropped_criteria(d)
            say("it has no acceptance criteria" + (f" left once the ones only the Project Lead can meet are dropped "
                                                    f"({'; '.join(dropped)}). {LEAD_ONLY_WHY}" if dropped else "."))
        for dep in deps:
            if dep not in by_key and dep not in existing:
                say(f"depends_on names {dep!r}, which is neither another draft nor an existing ticket.")
    return reasons


def git_lines(root, *args):
    done = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8")
    return done.stdout.splitlines() if done.returncode == 0 else []


def next_number(root):
    """The next free ticket number: after every id in tasks/, on task/* branches and in master's log."""
    names = [p.name for p in (Path(root) / "tasks").glob("T-*.md")]
    names += git_lines(root, "for-each-ref", "--format=%(refname:short)", "refs/heads/task/")
    names += git_lines(root, "log", "master", "--format=%s")
    return max((int(n) for name in names for n in ID_RE.findall(name)), default=0) + 1


def header_list(items):
    return "[" + ", ".join(items) + "]"


def render(template, d, tid, goal_id, depends_on, status):
    """A task file's text from tasks/_TEMPLATE.md. The lead and qa_rounds lines stay as in the template."""
    reads = list(d.get("files_to_read_first") or [])
    if "tasks/README.md" not in reads:
        reads.insert(0, "tasks/README.md")
    values = {"id": tid, "title": " ".join(d["title"].split()), "status": status, "from": "project-lead",
              "to": d["to"], "epic": d["epic"], "milestone": d["milestone"], "goal": goal_id,
              "user_facing_text": d["user_facing_text"], "changes_visuals": d["changes_visuals"],
              "depends_on": header_list(depends_on), "documents_affected": header_list(d.get("documents_affected") or []),
              "files_to_read_first": header_list(reads),
              "files_expected_to_change": header_list(d.get("files_expected_to_change") or []), "model": d["model"]}
    text = template
    for key, value in values.items():
        text = set_field(text, key, value)
    description = d["description"].strip()
    if (d.get("review") or "").strip():
        description += f"\n\nThe board's review: {d['review'].strip()}"
    criteria = "\n".join(f"- [ ] {c.strip()} (QA: pass / fail)" for c in kept_criteria(d))
    text = re.sub(r"(^## Description\n\n).*?(?=^## Acceptance criteria)", lambda m: m.group(1) + description + "\n\n",
                  text, count=1, flags=re.S | re.M)
    text = re.sub(r"(^## Acceptance criteria\n\n).*?(?=^## Updates)", lambda m: m.group(1) + criteria + "\n\n",
                  text, count=1, flags=re.S | re.M)
    return text


def claim(root, tid, name):
    """Claim a ticket through the status script (tasks/README.md, "Owners"). Raises Pause when refused."""
    done = subprocess.run([sys.executable, str(Path(root) / "tools" / "task_status.py"), tid, "--lead", name],
                          cwd=str(root), capture_output=True, text=True, encoding="utf-8")
    if done.returncode != 0:
        raise Pause(f"The status script refused to claim {tid} for {name}: {(done.stderr or done.stdout).strip()}",
                    "command")


def write(drafts, existing, root, goal_id, claim=claim, dropped=None):
    """Write the drafts as task files and claim them; returns {draft key: (ticket id, path)}. Criteria only the
    Project Lead can meet are left out; each is added to `dropped` (a list, when given) as
    (ticket id, criterion, what it is about)."""
    root = Path(root)
    template = (root / "tasks" / "_TEMPLATE.md").read_text(encoding="utf-8").replace("\r\n", "\n")
    number = next_number(root)
    ids = {d["key"]: f"T-{number + i:03d}" for i, d in enumerate(drafts)}
    written = {}
    for d in drafts:
        deps = [ids.get(dep, dep) for dep in d.get("depends_on") or []]
        unfinished = [dep for dep in d.get("depends_on") or [] if dep in ids
                      or (existing.get(dep) or {}).get("status") != "done"]
        tid = ids[d["key"]]
        if dropped is not None:
            dropped += [(tid, c, lead_only(c)) for c in dropped_criteria(d)]
        path = root / "tasks" / f"{tid}-{slug(d['title'], 6)}.md"
        text = render(template, d, tid, goal_id, deps, "blocked" if unfinished else "open")
        path.write_bytes(text.encode("utf-8"))
        written[d["key"]] = (tid, path)
    try:
        for tid, _ in written.values():
            claim(root, tid, f"Goal-{goal_id}")
    except Pause as p:
        names = ", ".join(path.name for _, path in written.values())
        raise Pause(f"{p} The ticket files are written but not committed: {names}.", p.kind)
    return written


def mark_reused(root, ticket, goal_id):
    """Set the goal line of a reused ticket on master's copy. Returns the path, or None when it is left alone:
    its branch is open (it is edited only on its branch) or another goal already has it."""
    path = Path(root) / ticket["file"]
    if ticket.get("folder") or not path.exists():
        return None
    text = path.read_bytes().decode("utf-8")
    if (tb.parse_header(text) or {}).get("goal", ""):
        return None
    path.write_bytes(set_field(text, "goal", goal_id).encode("utf-8"))
    return path
