"""The style loop (role: runs it, with no one stepping in; tasks/README.md, "The style loop", T-291).

1. Generate: the task's agent (asset-generation for art, narrative-theme for text) makes version 1 from the brief.
2. Evaluate: game/tools/style_rules.py runs its script checks, then the style-evaluator agent scores the version
   from 1 to 10 and gives the reason and the rule numbers broken (SCORE_SCHEMA).
3. Refine: below PASS, the same generator session is resumed with the reason and makes the next version.
4. Stop: at PASS or more; or after MAX_REFINES refines, the best-scoring version is kept (the earliest on a tie)
   and the task is flagged for the board's review through task_status.py.

Every round is written into the task's `## Style review` section as it ends, by task_status.write_section (only
the status script finds and writes tickets: board, 2026-10-25), and the
last line says which version was kept. Every art version is saved in art-archive/<task id>/style-loop/ and never
overwritten; the kept one is copied to the brief's output file. `claude` is a RealClaude or a FakeClaude
(tools/goal_agent/claude_call.py), the only way this tool calls Claude.
"""

import json
import shutil
import sys
import uuid
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

import task_status as ts   # tools/ is on the path: style_loop/__init__.py
from goal_agent.claude_call import Pause

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "game" / "tools"))
import style_rules  # noqa: E402

PASS = 8
MAX_REFINES = 3
GENERATOR = {"art": "asset-generation", "text": "narrative-theme"}
EVALUATOR = "style-evaluator"
EVALUATOR_TOOLS = "Read,Glob,Grep"   # it looks and reads; it never makes or fixes anything
GUIDE = {"art": 'docs/visual-style.md, Content, "Rules"', "text": 'docs/extended-narrative.md, Content, "Text rules"'}

VERSION_SCHEMA = {
    "art": {"type": "object", "required": ["file", "changed"], "properties": {
        "file": {"type": "string", "description": "the PNG of this version"},
        "changed": {"type": "string", "description": "what this version is, or what changed since the last one"}}},
    "text": {"type": "object", "required": ["text", "changed"], "properties": {
        "text": {"type": "string", "description": "the text of this version, exactly as the player would read it"},
        "changed": {"type": "string", "description": "what this version is, or what changed since the last one"}}},
}
SCORE_SCHEMA = {"type": "object", "required": ["score", "reason", "rules_broken"], "properties": {
    "score": {"type": "integer", "minimum": 1, "maximum": 10},
    "reason": {"type": "string", "description": "which rules the version breaks and how, precisely enough to fix"},
    "rules_broken": {"type": "array", "items": {"type": "integer"}, "description": "the rule numbers broken"}}}


@dataclass
class Spec:
    """One run: what is made, for which task, from which brief, and the script checks' options."""
    kind: str                      # "art" or "text"
    task: str                      # T-NNN; its ticket is found and written only by task_status.py
    root: Path                     # the checkout the agents work in (task_status.task_checkout); art-archive/ is here
    brief: str                     # the brief's text
    brief_name: str = ""           # where the brief came from, for the record
    out: Path = None               # where the kept version goes (art: required; text: optional)
    text_kind: str = None          # style_rules text kind (popup, label, ...)
    size: tuple = None             # art: (w, h) of the image, or of each frame
    frames: int = 0
    redgull: bool = False
    allow_red: list = field(default_factory=list)
    max_colors: int = 30


@dataclass
class Round:
    n: int
    version: str                   # the text, or the archived file (relative to root)
    changed: str
    checks: list
    score: int
    reason: str
    rules_broken: list
    refused: list = field(default_factory=list)


# --- the four steps ---

def run(claude, spec, flag=None):
    """Runs the loop; returns (the kept round, every round). `flag(spec, kept)` is called when the kept
    version is still below PASS (default: task_status.move to flagged-for-review)."""
    flag = flag or flag_task
    agent, session, rounds = GENERATOR[spec.kind], str(uuid.uuid4()), []
    for n in range(1, MAX_REFINES + 2):
        target = archive_target(spec, n) if spec.kind == "art" else None
        common = dict(agent=agent, cwd=str(spec.root), permission_mode="acceptEdits", activity=spec.task)
        if n == 1:
            answer = claude.ask("generate", generate_prompt(spec, target), VERSION_SCHEMA[spec.kind],
                                session_id=session, **common)
        else:
            answer = claude.ask("refine", refine_prompt(spec, rounds[-1], n, target), VERSION_SCHEMA[spec.kind],
                                resume=session, **common)
        version = take_version(spec, answer.data, target)
        checks = script_checks(spec, version)
        verdict = claude.ask("evaluate", evaluate_prompt(spec, version, checks), SCORE_SCHEMA, agent=EVALUATOR,
                             cwd=str(spec.root), tools=EVALUATOR_TOOLS, activity=spec.task)
        score = read_score(verdict.data)
        rounds.append(Round(n, version, str(answer.data.get("changed", "")).strip(), checks, score,
                            str(verdict.data.get("reason", "")).strip(), list(verdict.data.get("rules_broken") or []),
                            [json.dumps(d, sort_keys=True) for d in list(answer.denials) + list(verdict.denials)]))
        write_record(spec, rounds)
        if score >= PASS:
            break
    kept = max(rounds, key=lambda r: (r.score, -r.n))
    keep(spec, kept)
    write_record(spec, rounds, kept)
    if kept.score < PASS:
        flag(spec, kept)
    return kept, rounds


def archive_target(spec, n):
    """art-archive/<task>/style-loop/v<n>.png, or v<n>-2.png, ... when an earlier run left one: never overwritten."""
    folder = spec.root / "art-archive" / spec.task / "style-loop"
    path, i = folder / f"v{n}.png", 2
    while path.exists():
        path, i = folder / f"v{n}-{i}.png", i + 1
    return path


def take_version(spec, data, target):
    """The version as the record shows it: the text, or the archived PNG's path relative to root. An art
    version the agent saved somewhere else is copied into the archive (the original is left where it is)."""
    if spec.kind == "text":
        text = data.get("text")
        if not isinstance(text, str) or not text.strip():
            raise Pause(f"The {GENERATOR['text']} agent gave no text.")
        return text.strip()
    made = Path(str(data.get("file") or ""))
    if not made.is_absolute():
        made = next((p for p in (spec.root / made, Path.cwd() / made) if p.is_file()), spec.root / made)
    if not data.get("file") or not made.is_file():
        if not target.is_file():
            raise Pause(f"The {GENERATOR['art']} agent made no PNG (expected {target}).")
    elif made.resolve() != target.resolve():
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(made, target)
    return target.relative_to(spec.root).as_posix()


def script_checks(spec, version):
    """style_rules.py's checks on the version: a list of {"rule", "check", "ok", "detail"}."""
    if spec.kind == "text":
        return style_rules.text_checks(version, spec.text_kind)
    try:
        _, _, rows = style_rules.decode_png((spec.root / version).read_bytes())
        return style_rules.art_checks(rows, spec.size, spec.frames, spec.redgull, spec.allow_red, spec.max_colors)
    except ValueError as e:
        return [style_rules._result(1, "an 8-bit RGBA PNG that splits into the frames", False, str(e))]


def read_score(data):
    try:
        score = int(data.get("score"))
    except (TypeError, ValueError):
        raise Pause(f"The {EVALUATOR} agent gave no score: {data!r}")
    return min(max(score, 1), 10)


def keep(spec, kept):
    """The kept version goes where the brief says: the PNG copied to `out`, the text written to `out` if given."""
    if not spec.out:
        return
    spec.out.parent.mkdir(parents=True, exist_ok=True)
    if spec.kind == "art":
        shutil.copyfile(spec.root / kept.version, spec.out)
    else:
        spec.out.write_text(kept.version + "\n", encoding="utf-8")


def flag_task(spec, kept):
    """Flags the task for the board's review through the status script (in-progress → flagged-for-review)."""
    note = (f"the style loop kept version {kept.n} (score {kept.score}/10), still below {PASS} after "
            f"{MAX_REFINES} refines; every version is in its Style review")
    return ts.move(spec.task, "flagged-for-review", note=note, by="style-loop")


# --- the prompts ---

def what(spec):
    return "a piece of art" if spec.kind == "art" else f"one piece of player-facing text (kind: {spec.text_kind})"


def generate_prompt(spec, target):
    lines = [f"Task {spec.task}: make {what(spec)} through the style loop (tasks/README.md, \"The style loop\"). "
             f"Its style guide is {GUIDE[spec.kind]}.", "", "The brief:", "", spec.brief.strip(), ""]
    lines += make_lines(spec, 1, target)
    return "\n".join(lines)


def refine_prompt(spec, last, n, target):
    failed = [c for c in last.checks if not c["ok"]]
    lines = [f"The Style Evaluator scored version {last.n} {last.score}/10; the loop keeps a version at {PASS} or more.",
             f"Reason: {last.reason}", f"Rules broken: {', '.join(map(str, last.rules_broken)) or 'none named'}"]
    if failed:
        lines.append("Script checks that failed (style_rules.py): " + "; ".join(check_line(c) for c in failed))
    lines += ["", f"Make version {n}: fix what the reason names and keep what works."]
    if spec.kind == "art":
        lines.append("Free script fixes come before a paid regeneration (docs/working-with-the-board.md, \"Art and money\").")
    lines += make_lines(spec, n, target)
    return "\n".join(lines)


def make_lines(spec, n, target):
    if spec.kind == "art":
        return [f"Save version {n} as an 8-bit RGBA PNG at {target} (never delete or overwrite an earlier version). "
                "Call PixelLab only within the task's go from the board (docs/working-with-the-board.md, "
                "\"Art and money\").",
                "Answer with `file` (the PNG's path) and `changed` (what this version is, or what you changed)."]
    return ["Answer with `text` (the text alone, exactly as the player reads it) and `changed` "
            "(what this version is, or what you changed)."]


def evaluate_prompt(spec, version, checks):
    shown = (f"The image is {spec.root / version}: open it and look at it." if spec.kind == "art"
             else f"The text:\n\n{version}")
    return "\n".join([
        f"Score this version of {what(spec)} for task {spec.task} from 1 to 10 against {GUIDE[spec.kind]}.",
        "", "The brief it was made from:", "", spec.brief.strip(), "", shown, "",
        "The script checks (game/tools/style_rules.py); take them as facts:", json.dumps(checks, indent=1), "",
        "Answer with `score`, `reason` (which rules it breaks and how, precisely enough for the agent that made it "
        "to fix it) and `rules_broken` (the rule numbers). Don't make or fix anything."])


# --- the record ---

def check_line(c):
    return f"rule {c['rule']}, {c['check']} ({c['detail']})"


def checks_summary(checks):
    failed = [c for c in checks if not c["ok"]]
    head = f"{len(checks) - len(failed)} of {len(checks)} pass"
    return head + ("; failed: " + "; ".join(check_line(c) for c in failed) if failed else "")


def show_version(spec, version):
    if spec.kind == "art":
        return f"`{version}`"
    return '"' + version.replace("\n", " / ") + '"'


def record(spec, rounds, kept=None):
    """The body of the task's `## Style review` section."""
    what_run = f"text, kind {spec.text_kind}" if spec.kind == "text" else "art"
    lines = [f"Run by `tools/style_loop/run.py` on {date.today().isoformat()}: {what_run}"
             + (f", brief `{spec.brief_name}`" if spec.brief_name else "") + ". "
             f"Generator: {GENERATOR[spec.kind]} (one session, resumed for each refine); evaluator: {EVALUATOR}. "
             f"Kept at {PASS}/10 or more, at most {MAX_REFINES} refines."]
    for r in rounds:
        lines += ["", f"### Round {r.n}", "", f"- Version {r.n}: {show_version(spec, r.version)}"]
        if r.n > 1:
            lines.append(f"- What changed: {r.changed or '(not said)'}")
        lines += [f"- Script checks: {checks_summary(r.checks)}", f"- Score: {r.score}/10", f"- Reason: {r.reason}",
                  f"- Rules broken: {', '.join(map(str, r.rules_broken)) or 'none'}"]
        if r.refused:
            lines.append(f"- Refused: {'; '.join(r.refused)}")
    if kept:
        tail = (f"still below {PASS} after {MAX_REFINES} refines, so the task is flagged for the board's review."
                if kept.score < PASS else f"it reached {PASS} or more.")
        lines += ["", f"**Kept:** version {kept.n}, score {kept.score}/10 ({show_version(spec, kept.version)}"
                  + (f", copied to `{spec.out.as_posix()}`" if spec.out else "") + f"): {tail}"]
    return "\n".join(lines)


def write_record(spec, rounds, kept=None):
    return ts.write_section(spec.task, "Style review", record(spec, rounds, kept))
