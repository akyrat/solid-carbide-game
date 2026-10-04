"""Generate the agent relationship diagrams in agent-notes/agents-interactions.md.

Reads every agent's working copy in agent-notes/ (each agent's own, current
version of its relationships), parses the "Gets work from", "Hands work to" and
"Collaborates with" lists, and writes two Mermaid diagrams with a table under
each: one for hand-offs and one for collaborations. Only the part of
agents-interactions.md between the two marker comments is rewritten.

Usage (from the repo root, Python 3.9+, standard library only):

  python tools/generate_agent_diagrams.py           # rewrite the generated part
  python tools/generate_agent_diagrams.py --check   # exit 1 if it is out of date

Exit codes: 0 ok, 1 out of date (--check only), 2 file or marker problem,
3 some relationship entries could not be matched to a known role (they are
listed on stderr; nothing is dropped silently).
"""

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
NOTES_DIR = REPO_ROOT / "agent-notes"
OVERVIEW_NAME = "agents-interactions.md"

BEGIN_MARKER = "<!-- BEGIN GENERATED: agent diagrams (tools/generate_agent_diagrams.py) -->"
END_MARKER = "<!-- END GENERATED: agent diagrams -->"

GETS, HANDS, COLLAB = "gets", "hands", "collab"
SECTION_TITLES = {
    "gets work from": GETS,
    "hands work to": HANDS,
    "collaborates with": COLLAB,
}

BOARD_KEY = "board"
BOARD_LABEL = "Board"
LABEL_MAX_WORDS = 6

TITLE_RE = re.compile(r"^#\s+Working copy:\s*(.+?)\s*$")
BOLD_HEADING_RE = re.compile(r"^\*\*(.+?)\*\*\s*$")
MD_HEADING_RE = re.compile(r"^#{1,6}\s+(.+?)\s*$")
ENTRY_RE = re.compile(r"^\s*[-*]\s+(.+?):\s+(.+?)\s*$")


def normalize_name(name):
    """Reduce a role name to a key: "The QA/Integration Agent" -> "qa/integration"."""
    key = name.strip().lower()
    key = re.sub(r"^the\s+", "", key)
    key = re.sub(r"\s+agent$", "", key)
    return re.sub(r"\s+", " ", key)


def short_label(name):
    """Display name for a diagram node: drop a trailing " Agent"."""
    return re.sub(r"\s+Agent$", "", name.strip())


def parse_working_copy(text):
    """Return (role name, {section: [(other role name, text), ...]}).

    Unknown sections and lines that are not list entries are ignored, so a
    working copy can grow new sections or notes without breaking the parser.
    """
    name = None
    sections = {GETS: [], HANDS: [], COLLAB: []}
    current = None
    for line in text.splitlines():
        if name is None:
            m = TITLE_RE.match(line)
            if m:
                name = m.group(1)
                continue
        heading = BOLD_HEADING_RE.match(line) or MD_HEADING_RE.match(line)
        if heading:
            current = SECTION_TITLES.get(heading.group(1).strip().lower())
            continue
        if current is None:
            continue
        m = ENTRY_RE.match(line)
        if m:
            sections[current].append((m.group(1).strip(), m.group(2).strip()))
    return name, sections


class Role:
    def __init__(self, key, name, node_id, order):
        self.key = key
        self.name = name
        self.node_id = node_id
        self.order = order


def load_roles(notes_dir=NOTES_DIR):
    """Read every working copy. Returns (roles by key, parsed sections by key, problems)."""
    roles = {BOARD_KEY: Role(BOARD_KEY, BOARD_LABEL, "board", 0)}
    parsed = {}
    problems = []
    files = sorted(p for p in Path(notes_dir).glob("*.md") if p.name != OVERVIEW_NAME)
    for path in files:
        name, sections = parse_working_copy(path.read_text(encoding="utf-8"))
        if name is None:
            problems.append(f"{path.name}: no '# Working copy: <name>' title, file skipped")
            continue
        key = normalize_name(name)
        node_id = path.stem.replace("-", "_")
        roles[key] = Role(key, name, node_id, 0)
        parsed[key] = sections
    # Board first, Project Lead second, then the agents in name order.
    ordered = sorted(
        roles.values(),
        key=lambda r: (r.key != BOARD_KEY, r.key != "project lead", r.name.lower()),
    )
    for i, role in enumerate(ordered):
        role.order = i
    return roles, parsed, problems


def build_graph(roles, parsed):
    """Merge both sides of every relationship.

    Returns (handoffs, collabs, unmatched):
      handoffs: {(from_key, to_key): {"sender": text|None, "receiver": text|None}}
      collabs:  {frozenset({a, b}): {a: text|None, b: text|None}}
      unmatched: ["<file role>: <section>: <entry name>", ...]
    """
    handoffs, collabs, unmatched = {}, {}, []

    def resolve(owner, section, other_name):
        key = normalize_name(other_name)
        if key not in roles:
            unmatched.append(f"{roles[owner].name}: {section}: '{other_name}'")
            return None
        if key == owner:
            return None
        return key

    for owner, sections in parsed.items():
        for other_name, text in sections[HANDS]:
            other = resolve(owner, "Hands work to", other_name)
            if other:
                handoffs.setdefault((owner, other), {"sender": None, "receiver": None})["sender"] = text
        for other_name, text in sections[GETS]:
            other = resolve(owner, "Gets work from", other_name)
            if other:
                handoffs.setdefault((other, owner), {"sender": None, "receiver": None})["receiver"] = text
        for other_name, text in sections[COLLAB]:
            other = resolve(owner, "Collaborates with", other_name)
            if other:
                pair = frozenset((owner, other))
                collabs.setdefault(pair, {owner: None, other: None})[owner] = text
    return handoffs, collabs, unmatched


def edge_label(text):
    """A few words for a diagram edge; the full text goes in the table.

    Keeps the first sentence, drops a trailing explanatory clause
    (", which ...", ", starting ...", ", for ...", ", in ...", ", written ..."),
    and caps the result at LABEL_MAX_WORDS words. Task-file hand-offs all start
    with "Task files", so they are labelled just "task files".
    """
    text = text.strip()
    if text.lower().startswith("task files"):
        return "task files"
    first = re.split(r"\.\s|\.$|;\s", text, maxsplit=1)[0]
    first = re.split(r",\s+(?:which|starting|for|in|written)\b", first, maxsplit=1)[0].strip()
    words = first.split()
    if len(words) > LABEL_MAX_WORDS:
        return " ".join(words[:LABEL_MAX_WORDS]) + "…"
    return first


def mermaid_text(text):
    return text.replace('"', "#quot;")


def table_text(text):
    return "—" if not text else text.replace("|", "\\|")


def render(roles, handoffs, collabs):
    by_order = sorted(roles.values(), key=lambda r: r.order)

    def node_lines(used):
        return [f'    {r.node_id}["{mermaid_text(short_label(r.name))}"]' for r in by_order if r.key in used]

    out = [BEGIN_MARKER, ""]

    # Hand-offs.
    edges = sorted(handoffs.items(), key=lambda kv: (roles[kv[0][0]].order, roles[kv[0][1]].order))
    used = {k for (a, b), _ in edges for k in (a, b)} | set(roles)
    out += ["### Hand-offs", "", "Who sends work to whom, and what.", "", "```mermaid", "flowchart TD"]
    out += node_lines(used)
    for (a, b), texts in edges:
        text = texts["sender"] or texts["receiver"]
        out.append(f'    {roles[a].node_id} -->|"{mermaid_text(edge_label(text))}"| {roles[b].node_id}')
    out += ["```", "", "| From | To | What | Listed by |", "|---|---|---|---|"]
    for (a, b), texts in edges:
        if texts["sender"] and texts["receiver"]:
            listed = "both"
        elif texts["sender"]:
            listed = f"{short_label(roles[a].name)} only"
        else:
            listed = f"{short_label(roles[b].name)} only"
        text = texts["sender"] or texts["receiver"]
        out.append(f"| {short_label(roles[a].name)} | {short_label(roles[b].name)} | {table_text(text)} | {listed} |")

    # Collaborations.
    pairs = sorted(
        (tuple(sorted(pair, key=lambda k: roles[k].order)), texts) for pair, texts in collabs.items()
    )
    pairs.sort(key=lambda p: (roles[p[0][0]].order, roles[p[0][1]].order))
    used = {k for (a, b), _ in pairs for k in (a, b)}
    out += ["", "### Collaborations", "", "Agents that shape each other's work, in both directions.", "",
            "```mermaid", "flowchart LR"]
    out += node_lines(used)
    for (a, b), _ in pairs:
        out.append(f"    {roles[a].node_id} --- {roles[b].node_id}")
    out += ["```", "", "| Agents | What | Listed by |", "|---|---|---|"]
    for (a, b), texts in pairs:
        name_a, name_b = short_label(roles[a].name), short_label(roles[b].name)
        text_a, text_b = texts[a], texts[b]
        if text_a and text_b and text_a == text_b:
            what, listed = table_text(text_a), "both"
        elif text_a and text_b:
            what = f"{name_a}: {table_text(text_a)}<br>{name_b}: {table_text(text_b)}"
            listed = "both, worded differently"
        else:
            what = table_text(text_a or text_b)
            listed = f"{name_a if text_a else name_b} only"
        out.append(f"| {name_a} and {name_b} | {what} | {listed} |")

    out += ["", END_MARKER]
    return "\n".join(out)


def replace_generated(document, generated):
    """Swap the text between the markers (markers included) for `generated`."""
    start = document.find(BEGIN_MARKER)
    end = document.find(END_MARKER)
    if start == -1 or end == -1 or end < start:
        raise ValueError("begin/end markers missing or out of order")
    return document[:start] + generated + document[end + len(END_MARKER):]


def main(argv=None, notes_dir=NOTES_DIR):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="exit 1 if the file is out of date; change nothing")
    args = parser.parse_args(argv)

    overview = Path(notes_dir) / OVERVIEW_NAME
    if not overview.exists():
        print(f"error: {overview} not found", file=sys.stderr)
        return 2

    roles, parsed, problems = load_roles(notes_dir)
    handoffs, collabs, unmatched = build_graph(roles, parsed)

    raw = overview.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in raw else "\n"
    current = raw.replace("\r\n", "\n")
    try:
        updated = replace_generated(current, render(roles, handoffs, collabs))
    except ValueError as exc:
        print(f"error: {overview.name}: {exc}", file=sys.stderr)
        return 2

    for problem in problems:
        print(f"warning: {problem}", file=sys.stderr)
    for entry in unmatched:
        print(f"unmatched: {entry}", file=sys.stderr)

    if args.check:
        if updated != current:
            print(f"{overview.name} is out of date: run python tools/generate_agent_diagrams.py", file=sys.stderr)
            return 1
        print(f"{overview.name} is up to date")
    elif updated != current:
        overview.write_bytes(updated.replace("\n", newline).encode("utf-8"))
        print(f"updated {overview.name}")
    else:
        print(f"{overview.name} already up to date")

    return 3 if (unmatched or problems) else 0


if __name__ == "__main__":
    sys.exit(main())
