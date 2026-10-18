"""The goal file (role: the run's record, read and written by every layer): goals/G-NNN-short-title.md.

A parseable `---` header (FIELDS), then the sections in SECTIONS. Reading a file and writing it back
leaves it byte-identical: the header is kept as its own lines and each section as its own text, and
only what a layer changes is rewritten.
"""

import re
from datetime import date
from pathlib import Path

FIELDS = ["id", "title", "status", "art_cap", "art_used", "iteration", "max_iterations", "created", "lead"]
SECTIONS = ["Goal", "Goal acceptance criteria", "Open questions", "Sub-goals", "Scoring", "Tickets",
            "Iteration log", "Pauses"]
STATUSES = ["planning", "planned", "building", "paused", "ready-to-play", "done", "cancelled"]
EMPTY = "None yet."
HEADER_RE = re.compile(r"\A---\n(.*?\n)---\n", re.S)
HEADING_RE = re.compile(r"^## (.*)$", re.M)
ID_RE = re.compile(r"^(G-(\d{3,}))-")
SUBGOAL_COLUMNS = ["rank", "id", "title", "score", "why", "verdict", "tickets"]
PAUSE_RE = re.compile(r"^- \d{4}-\d{2}-\d{2}(?: \[([a-z-]+)\])?:", re.M)
DETAIL_RE = re.compile(r"^### ([^:\n]+): (.*)\n\nNeeds: (.*?)\.\n\n((?:- .*\n?)*)", re.M)
VALUE_RE = re.compile(r"value (\d+)")


class GoalFile:
    def __init__(self, path, header_lines, preamble, sections, newline="\n"):
        self.path = Path(path) if path else None
        self.header_lines = header_lines      # the header's lines, without line ends
        self.preamble = preamble              # text between the header and the first section
        self.sections = sections              # [[name, body]]; body starts right after the heading
        self.newline = newline

    @classmethod
    def parse(cls, text, path=None):
        newline = "\r\n" if "\r\n" in text else "\n"
        text = text.replace("\r\n", "\n")
        match = HEADER_RE.match(text)
        if not match:
            raise ValueError(f"{path or 'goal file'} has no --- header.")
        rest = text[match.end():]
        heads = list(HEADING_RE.finditer(rest))
        preamble = rest[:heads[0].start()] if heads else rest
        sections = [[h.group(1), rest[h.end():heads[i + 1].start() if i + 1 < len(heads) else len(rest)]]
                    for i, h in enumerate(heads)]
        return cls(path, match.group(1).split("\n")[:-1], preamble, sections, newline)

    @classmethod
    def load(cls, path):
        return cls.parse(Path(path).read_bytes().decode("utf-8"), path)

    def text(self):
        head = "".join(line + "\n" for line in self.header_lines)
        body = "".join(f"## {name}{text}" for name, text in self.sections)
        return f"---\n{head}---\n{self.preamble}{body}".replace("\n", self.newline)

    def save(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_bytes(self.text().encode("utf-8"))

    # --- header ---

    def get(self, key):
        for line in self.header_lines:
            k, _, v = line.partition(":")
            if k == key:
                return v.strip()
        return None

    def set(self, key, value):
        line = f"{key}: {value}" if str(value) != "" else f"{key}:"
        for i, old in enumerate(self.header_lines):
            if old.partition(":")[0] == key:
                self.header_lines[i] = line
                return
        self.header_lines.append(line)

    @property
    def id(self):
        return self.get("id")

    # --- sections ---

    def section(self, name):
        for n, body in self.sections:
            if n == name:
                return body.strip("\n")
        return None

    def set_section(self, name, content):
        body = f"\n\n{content.strip(chr(10)) or EMPTY}\n\n"
        for pair in self.sections:
            if pair[0] == name:
                pair[1] = body
                return
        self.sections.append([name, body])

    def append(self, name, line):
        """Add a line to a section, replacing its 'None yet.' placeholder."""
        old = self.section(name) or ""
        self.set_section(name, line if old in ("", EMPTY) else old + "\n" + line)

    def log(self, text, day=None):
        self.append("Iteration log", f"- {day or date.today().isoformat()}, iteration {self.get('iteration')}: {text}")

    def pause(self, reason, day=None, kind=None):
        """Status `paused`, the reason in `## Pauses` (with its kind in brackets, when given), and a log line."""
        self.set("status", "paused")
        tag = f" [{kind}]" if kind else ""
        self.append("Pauses", f"- {day or date.today().isoformat()}{tag}: {reason}")
        self.log("paused (see Pauses).", day)

    def last_pause_kind(self):
        """The kind of the newest pause in `## Pauses` ("stop" when it has none), or None without pauses."""
        kinds = [m.group(1) or "stop" for m in PAUSE_RE.finditer(self.section("Pauses") or "")]
        return kinds[-1] if kinds else None

    def number(self, key, default=0):
        try:
            return int(self.get(key) or default)
        except ValueError:
            return default


def slug(text, words=5):
    return "-".join(re.findall(r"[a-z0-9]+", text.lower())[:words]) or "goal"


def next_id(goals_dir):
    """The next free G-NNN in goals/."""
    numbers = [int(m.group(2)) for p in Path(goals_dir).glob("G-*.md") for m in [ID_RE.match(p.name)] if m]
    return f"G-{max(numbers, default=0) + 1:03d}"


def new(goals_dir, goal_text, art_cap=0, max_iterations=20, day=None):
    """A new goal file (not yet saved), status `planning`, with every header field and section."""
    gid = next_id(goals_dir)
    first_line = goal_text.strip().splitlines()[0] if goal_text.strip() else "goal"
    title = first_line if len(first_line) <= 70 else first_line[:67].rstrip() + "..."
    values = {"id": gid, "title": title, "status": "planning", "art_cap": art_cap, "art_used": 0, "iteration": 0,
              "max_iterations": max_iterations, "created": day or date.today().isoformat(), "lead": f"Goal-{gid}"}
    goal = GoalFile(Path(goals_dir) / f"{gid}-{slug(goal_text)}.md",
                    [f"{k}: {values[k]}" for k in FIELDS], "\n", [])
    for name in SECTIONS:
        goal.set_section(name, goal_text.strip() if name == "Goal" else "")
    return goal


def find(goals_dir, goal_id):
    matches = sorted(Path(goals_dir).glob(f"{goal_id}-*.md"))
    if not matches:
        raise FileNotFoundError(f"No goal file for {goal_id} in {goals_dir}.")
    return GoalFile.load(matches[0])


# --- the sub-goals table ---

def cell(value):
    return str(value).replace("|", "/").replace("\n", " ").strip()


def table(rows):
    """A Markdown table of sub-goals: one dict per row, with the keys in SUBGOAL_COLUMNS."""
    lines = ["| " + " | ".join(SUBGOAL_COLUMNS) + " |", "|" + "---|" * len(SUBGOAL_COLUMNS)]
    lines += ["| " + " | ".join(cell(r.get(c, "")) for c in SUBGOAL_COLUMNS) + " |" for r in rows]
    return "\n".join(lines)


def read_table(text):
    """The rows of the first Markdown table in a section, as dicts by column name."""
    lines = [l.strip() for l in (text or "").splitlines() if l.strip().startswith("|")]
    if len(lines) < 2:
        return []
    columns = [c.strip() for c in lines[0].strip("|").split("|")]
    return [dict(zip(columns, (c.strip() for c in l.strip("|").split("|")))) for l in lines[2:]]


def write_sub_goals(goal, sub_goals, verdicts):
    """The `## Sub-goals` section: the ranked table, then each sub-goal's criteria and needs.
    `verdicts`: {sub-goal id: {"verdict", "ticket_ids"}}."""
    rows, details = [], []
    for s in sub_goals:
        v = verdicts.get(s["id"], {})
        rows.append({**s, "verdict": v.get("verdict", ""), "tickets": ", ".join(v.get("ticket_ids", []))})
        needs = ", ".join(s["needs"]) or "nothing"
        details.append(f"### {s['id']}: {s['title']}\n\nNeeds: {needs}.\n\n" + "\n".join(f"- {c}" for c in s["criteria"]))
    goal.set_section("Sub-goals", table(rows) + "\n\n" + "\n\n".join(details))


def read_sub_goals(goal):
    """The sub-goals back from `## Sub-goals`, in rank order, as write_sub_goals() wrote them, each with its
    `verdict` and `ticket_ids`: so a run can be rebuilt from the goal file alone."""
    text = (goal.section("Sub-goals") or "") + "\n"
    details = {m.group(1): m for m in DETAIL_RE.finditer(text)}
    out = []
    for r in read_table(text):
        d = details.get(r["id"])
        needs = [n.strip() for n in d.group(3).split(",")] if d and d.group(3) != "nothing" else []
        value = VALUE_RE.search(r.get("score", ""))
        out.append({"rank": int(r["rank"]) if r["rank"].isdigit() else len(out) + 1, "id": r["id"],
                    "title": r["title"], "score": r.get("score", ""), "why": r.get("why", ""),
                    "value": int(value.group(1)) if value else 1, "needs": needs,
                    "criteria": [l[2:].strip() for l in d.group(4).splitlines() if l.startswith("- ")] if d else [],
                    "verdict": r.get("verdict", ""),
                    "ticket_ids": [t.strip() for t in r.get("tickets", "").split(",") if t.strip()]})
    return sorted(out, key=lambda s: s["rank"])
