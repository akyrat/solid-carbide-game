"""Layer 2, gap detection: which sub-goals are already covered, already in flight, or missing.

The scan is code: every ticket header (taskboard_sync, which also reads open tickets from their
branch folders) and a short index of the game's code (the files under game/, without addons, the
Godot cache, art and audio, and the headings of game/README.md). Claude gets the sub-goals and that
compact view and gives one verdict per sub-goal: `covered` (done tickets and code; named),
`in-flight` (open tickets already cover it; named and reused) or `missing` (with ticket drafts).
The drafts go through tickets.check(); a refused set is asked for once more with the reasons, and
refused again, the run pauses with them.
"""

from pathlib import Path

import taskboard_sync as tb
from goal_agent import tickets
from goal_agent.claude_call import Pause

SKIP = {"addons", ".godot", "art", "audio"}
VERDICTS = ["covered", "in-flight", "missing"]
SCHEMA = {
    "type": "object",
    "properties": {"verdicts": {"type": "array", "items": {
        "type": "object",
        "properties": {
            "sub_goal": {"type": "string", "description": "S1, S2, ..."},
            "verdict": {"type": "string", "enum": VERDICTS},
            "tickets": {"type": "array", "items": {"type": "string"}, "description": "T-NNN ids that cover it"},
            "code": {"type": "array", "items": {"type": "string"}, "description": "files under game/ that cover it"},
            "drafts": {"type": "array", "items": tickets.DRAFT, "description": "only for missing"},
        },
        "required": ["sub_goal", "verdict", "tickets", "code", "drafts"]}}},
    "required": ["verdicts"],
}


def existing_tickets(root):
    """{id: ticket} for every task file, open ones read from their branch folder."""
    root = Path(root)
    return {t["id"]: t for t in tb.tickets_now(root / "tasks", tb.task_folders(root))}


def code_index(root):
    """The files under game/ (relative paths, skipping SKIP folders) and the headings of game/README.md."""
    game = Path(root) / "game"
    files = sorted(p.relative_to(game).as_posix() for p in game.rglob("*")
                   if p.is_file() and not SKIP & set(p.relative_to(game).parts[:-1]) and not p.suffix == ".import")
    readme = game / "README.md"
    heads = [l for l in readme.read_text(encoding="utf-8").splitlines() if l.startswith("#")] if readme.exists() else []
    return files, heads


def prompt(goal_text, sub_goals, existing, code, reasons=None):
    files, heads = code
    goals = "\n".join(f"- {s['id']}: {s['title']}. Criteria: {'; '.join(s['criteria'])}" for s in sub_goals)
    rows = "\n".join(f"- {t['id']} [{t['status']}] {t['to']}, {t['epic']}: {t['title']}" for t in existing.values())
    retry = ""
    if reasons:
        retry = ("\n\nYour last answer was refused for these reasons. Fix them and answer again:\n"
                 + "\n".join(f"- {r}" for r in reasons))
    return f"""You are checking what is still missing for one goal in Solid Carbide, a Godot game built by AI agents.
Read tasks/README.md and tasks/_TEMPLATE.md first: every ticket draft must follow their rules.

The board's goal:
{goal_text}

Its sub-goals:
{goals}

The tickets (id [status] agent, epic: title):
{rows or '- (none)'}

The files under game/ (without addons, .godot, art, audio):
{chr(10).join(files) or '(none)'}

game/README.md headings:
{chr(10).join(heads) or '(none)'}

For each sub-goal give one verdict:
- covered: done tickets and code already do it; name the tickets and the files.
- in-flight: open tickets already cover it; name them (they are reused, not rewritten).
- missing: write ticket drafts for it, with keys D1, D2, ... unique across the whole answer. A draft's
  depends_on names other drafts by key or existing tickets by id. A visual: a functional ticket with a
  placeholder, and an asset-generation ticket that depends on it. Player-facing text: a narrative-theme
  ticket first, which the main ticket depends on. Anything the player sees, reads or hears gets a
  review line (the text after "The board's review:"). Build only what the goal and the docs say.{retry}"""


def check_verdicts(verdicts, sub_goals, existing):
    reasons = []
    ids = [s["id"] for s in sub_goals]
    given = [v.get("sub_goal") for v in verdicts]
    for i in ids:
        if given.count(i) != 1:
            reasons.append(f"{i} needs exactly one verdict; it has {given.count(i)}.")
    for v in verdicts:
        name = v.get("sub_goal")
        if name not in ids:
            reasons.append(f"A verdict names {name!r}, which is not a sub-goal.")
        if v.get("verdict") not in VERDICTS:
            reasons.append(f"{name}: verdict {v.get('verdict')!r} is not one of {', '.join(VERDICTS)}.")
        elif v["verdict"] == "missing" and not v.get("drafts"):
            reasons.append(f"{name}: missing but no ticket drafts.")
        elif v["verdict"] != "missing":
            if not v.get("tickets"):
                reasons.append(f"{name}: {v['verdict']} but names no tickets.")
            if v.get("drafts"):
                reasons.append(f"{name}: {v['verdict']} but has drafts; only missing sub-goals get drafts.")
        for t in v.get("tickets") or []:
            if t not in existing:
                reasons.append(f"{name}: names {t}, which is not an existing ticket.")
    return reasons


def detect(claude, goal_text, sub_goals, root, model=None):
    """(verdicts, existing tickets) once the drafts pass tickets.check(). Raises Pause."""
    existing, code = existing_tickets(root), code_index(root)
    reasons = None
    for attempt in (1, 2):
        answer = claude.ask("gaps", prompt(goal_text, sub_goals, existing, code, reasons), SCHEMA, model=model,
                            cwd=str(root), allowed_tools="Read,Glob,Grep")
        if answer.denials:
            raise Pause(f"Gap detection was refused: {answer.denials}")
        verdicts = list(answer.data.get("verdicts") or [])
        drafts = [d for v in verdicts for d in v.get("drafts") or []]
        reasons = check_verdicts(verdicts, sub_goals, existing) + tickets.check(drafts, existing, root)
        if not reasons:
            return verdicts, existing
    raise Pause("Gap detection's tickets were refused twice:\n" + "\n".join(f"  - {r}" for r in reasons))
