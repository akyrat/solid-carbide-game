"""Layer 1, priority scoring: the goal becomes its acceptance criteria and ranked sub-goals.

Claude proposes (from the goal, the short GDD for scope and the game area docs for details); the
ranking is done here, by code: first by how many other sub-goals wait on a sub-goal (directly or
further down the chain, as in tools/ticket_impact.py), then by Claude's value estimate, then by
Claude's order. A dependency cycle is refused. Because a sub-goal always has more sub-goals waiting
on it than any sub-goal that needs it, the ranking also builds every sub-goal after what it needs.
"""

from goal_agent.claude_call import Pause

SHORT_GDD = "docs/short-gdd/short-gdd.md"
GAME_AREA_DOCS = ["docs/drifting.md", "docs/enemies.md", "docs/weapons.md", "docs/game-loop-architecture.md",
                  "docs/level-design.md", "docs/garage-design.md", "docs/hud-and-menus.md", "docs/visual-style.md",
                  "docs/extended-narrative.md"]
SCORING_RULE = ("Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further "
                "down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. "
                "A sub-goal is therefore always ranked before every sub-goal that needs it. "
                "A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.")

SUB_GOAL = {
    "type": "object",
    "properties": {
        "id": {"type": "string", "description": "S1, S2, ... in your order"},
        "title": {"type": "string"},
        "why": {"type": "string", "description": "how it serves the goal"},
        "value": {"type": "integer", "minimum": 1, "maximum": 5},
        "criteria": {"type": "array", "items": {"type": "string"}, "minItems": 1},
        "needs": {"type": "array", "items": {"type": "string"}, "description": "ids of sub-goals needed first"},
    },
    "required": ["id", "title", "why", "value", "criteria", "needs"],
}
SCHEMA = {
    "type": "object",
    "properties": {
        "goal_criteria": {"type": "array", "items": {"type": "string"}, "minItems": 1},
        "sub_goals": {"type": "array", "items": SUB_GOAL, "minItems": 1},
        "open_questions": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["goal_criteria", "sub_goals", "open_questions"],
}


def prompt(goal_text):
    docs = "\n".join(f"- {d}" for d in GAME_AREA_DOCS)
    return f"""You are planning one goal for Solid Carbide, a Godot game built by a team of AI agents.

The board's goal, in its own words:
{goal_text}

Read {SHORT_GDD} for the game's scope. Read the game area docs for the details; they are the source of truth:
{docs}

Ideas come only from the board. Sub-goals build only what the goal and these docs say. Where the docs leave
something open, do not decide it: write it in open_questions instead of inventing an answer.

Answer with:
- goal_criteria: the goal's own acceptance criteria, its stop condition. Each must be something the
  QA/Integration Agent can check: a test that passes, a file that exists, a scene that runs and shows something.
- sub_goals: the parts of the goal, in the order you would build them, with ids S1, S2, ... Each has a title,
  why it serves the goal, a value estimate from 1 (nice to have) to 5 (the goal fails without it), its own
  acceptance criteria (checkable by QA), and needs: the ids of the sub-goals it needs first.
- open_questions: what the goal and the docs leave open.
Don't rank them: the ranking is computed from needs and value."""


def find_cycle(sub_goals):
    """A list of ids forming a cycle in `needs` (first id repeated at the end), or None."""
    needs = {s["id"]: s["needs"] for s in sub_goals}
    state, path = {}, []

    def visit(i):
        state[i] = "open"
        path.append(i)
        for n in needs[i]:
            if state.get(n) == "open":
                return path[path.index(n):] + [n]
            if n not in state:
                found = visit(n)
                if found:
                    return found
        state[i] = "done"
        path.pop()
        return None

    for i in needs:
        if i not in state:
            found = visit(i)
            if found:
                return found
    return None


def rank(sub_goals):
    """The sub-goals in rank order, each a copy with `rank`, `waiting` and `score` added. Raises Pause."""
    ids = [s["id"] for s in sub_goals]
    if len(set(ids)) != len(ids):
        raise Pause(f"Priority scoring: sub-goal ids repeat: {', '.join(ids)}.")
    for s in sub_goals:
        unknown = [n for n in s["needs"] if n not in ids]
        if unknown:
            raise Pause(f"Priority scoring: {s['id']} needs unknown sub-goals: {', '.join(unknown)}.")
        if not isinstance(s.get("value"), int) or not 1 <= s["value"] <= 5:
            raise Pause(f"Priority scoring: {s['id']} has a value outside 1 to 5: {s.get('value')!r}.")
    cycle = find_cycle(sub_goals)
    if cycle:
        raise Pause(f"Priority scoring refused the plan: a dependency cycle, {' -> '.join(cycle)}.")
    waiting_on = {i: set() for i in ids}            # id -> sub-goals that list it in needs
    for s in sub_goals:
        for n in s["needs"]:
            waiting_on[n].add(s["id"])
    waiting = {}
    for i in ids:                                   # everything further down the chain
        seen, stack = set(), [i]
        while stack:
            for child in waiting_on[stack.pop()]:
                if child not in seen:
                    seen.add(child)
                    stack.append(child)
        waiting[i] = len(seen)
    order = {i: n for n, i in enumerate(ids)}
    ranked = sorted(sub_goals, key=lambda s: (-waiting[s["id"]], -s["value"], order[s["id"]]))
    return [dict(s, rank=r, waiting=waiting[s["id"]], score=f"unblocks {waiting[s['id']]}, value {s['value']}")
            for r, s in enumerate(ranked, 1)]


def plan(claude, goal_text, root, model=None):
    """{goal_criteria, open_questions, sub_goals (ranked)} for a goal. Raises Pause."""
    answer = claude.ask("plan", prompt(goal_text), SCHEMA, model=model, cwd=str(root),
                        allowed_tools="Read,Glob,Grep")
    if answer.denials:
        raise Pause(f"Priority scoring was refused: {answer.denials}", "refusal")
    data = answer.data
    if not data.get("goal_criteria") or not data.get("sub_goals"):
        raise Pause("Priority scoring: Claude gave no goal criteria or no sub-goals.")
    return {"goal_criteria": list(data.get("goal_criteria") or []),
            "open_questions": list(data.get("open_questions") or []),
            "sub_goals": rank(list(data.get("sub_goals") or []))}
