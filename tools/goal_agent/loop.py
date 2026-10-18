"""Layer 4, the iteration loop: build the next ticket, rescan, and repeat until the goal's own criteria pass.

Each step builds one ticket (layer 3, build.py): the goal's highest-ranked sub-goal with a ticket ready to
start, after any ticket a stopped run left in progress. After every ticket the loop rescans the tickets
and the code and runs gap detection (layer 2) again for the sub-goals not yet `covered`; new drafts go
through the same rule checks. Each step is one entry in the goal file's `## Iteration log`, and one more
`iteration`. When no goal ticket is ready or in progress and every one has passed QA, the QA/Integration
Agent checks the goal's own acceptance criteria in the goal's folder: all pass, the goal is
`ready-to-play`; a fail goes back into gap detection as a gap. Just before that check the runner brings the
long GDD and the short GDD's fingerprint up to date in the goal's folder (committing only those docs) and
gives the check's result to QA, so QA need not run the docs scripts. The goal check is told the pre-approved
commands and reports `blocked`, like the ticket sessions.

The goal pauses (status `paused`, the reason in `## Pauses` with its kind, a printed message) and changes
nothing more on these stop rules (KINDS): the iteration cap; the art cap with an asset-generation ticket
next; a flagged ticket other goal tickets wait on (independent work carries on first); the same gap or
failing goal criterion twice with no ticket passing in between; a refusal that blocked a session (one it got
past is only written in the iteration log); two refused sets of drafts.
The run is rebuilt from the files each step (goal file, tickets, worktrees), so `resume` is the same loop.
"""

import re
import sys
from pathlib import Path

from goal_agent import build, gaps, goal_file, tickets
from goal_agent.claude_call import Pause

KINDS = {
    "max-iterations": "the goal reached its iteration cap",
    "art-cap": "the art cap is reached and an asset-generation ticket is next",
    "flagged": "a ticket is flagged for review and nothing else can go on",
    "waiting": "goal tickets wait on tickets this goal doesn't build",
    "repeat": "the same gap or failing goal criterion came back twice with no ticket passing in between",
    "refusal": "a headless session reported a refusal that blocked its work",
    "command": "a command the runner ran was refused or failed",
    "drafts-refused": "gap detection's drafts were refused twice",
    "merge": "a merge into the goal's build conflicted",
    "qa": "QA left criteria unmarked",
    "stop": "another stop",
}
CLEARABLE = {"max-iterations", "art-cap", "flagged", "waiting"}   # resume checks these; the rest need --force
MODEL = "opus"                     # gap detection, as in run.py start
TICKET_LINE_RE = re.compile(r"^- (T-\d+): (.*) \(([^,()]+), (written|in-flight|covered)(, reused)?\)$")
CRITERION_RE = re.compile(r"^- \[[ xX]\] (.*?)(?: \(QA: [^)]*\))?$")
CHECK_SCHEMA = {
    "type": "object",
    "properties": {
        "criteria": {"type": "array", "items": {
            "type": "object",
            "properties": {"criterion": {"type": "string"}, "result": {"type": "string", "enum": ["pass", "fail"]},
                           "notes": {"type": "string"}},
            "required": ["criterion", "result", "notes"]}},
        "refusals": {"type": "array", "items": {"type": "string"}},
        "blocked": {"type": "boolean",
                    "description": "true only when a refused action was essential and you could not finish "
                                   "the checks without it"},
    },
    "required": ["criteria", "refusals", "blocked"],
}


# --- what the goal file says ---

def goal_tickets(goal):
    """[(ticket id, sub-goal id, how)] from `## Tickets`; how is written, in-flight or covered."""
    return [(m.group(1), m.group(3), m.group(4)) for line in (goal.section("Tickets") or "").splitlines()
            for m in [TICKET_LINE_RE.match(line.strip())] if m]


def goal_criteria(goal):
    return [m.group(1) for line in (goal.section("Goal acceptance criteria") or "").splitlines()
            for m in [CRITERION_RE.match(line.strip())] if m]


class View:
    """One look at the goal: its sub-goals (ranked), its tickets now, which are its own and which reused."""

    def __init__(self, b):
        self.subs = goal_file.read_sub_goals(b.goal)
        self.rank = {s["id"]: s["rank"] for s in self.subs}
        self.now = build.tickets_now(b.root)
        listed = goal_tickets(b.goal)
        self.sub_of = {tid: sub for tid, sub, _ in listed}
        self.own = [tid for tid, _, how in listed if how == "written" and tid in self.now
                    and self.now[tid]["lead"] == b.lead]
        self.reused = [tid for tid, _, how in listed if how == "in-flight" and tid in self.now and tid not in self.own]

    def ranked(self, ids):
        return sorted(ids, key=lambda t: (self.rank.get(self.sub_of.get(t), 10 ** 6), t))

    def status(self, tid):
        return self.now[tid]["status"]


def next_step(b, view=None):
    """("build", ticket id) or ("check", None). Raises Pause on a stop rule. Reads only."""
    v = view or View(b)
    active = [t for t in v.own if v.status(t) in ("in-progress", "in-qa")
              or (v.status(t) in build.PASSED and not build.merged(b, v.now[t]) and build.branch_exists(
                  b, b.places.ticket_branch(v.now[t])))]
    waiting = [t for t in v.ranked(v.own) if build.ready(v.now[t], v.now)]
    pick = (v.ranked(active) or waiting or [None])[0]
    if pick:
        if b.goal.number("iteration") >= b.goal.number("max_iterations", 20):
            raise Pause(f"The goal reached its iteration cap ({b.goal.get('max_iterations')}); {pick} is next.",
                        "max-iterations")
        if (pick not in active and v.now[pick]["to"] == "asset-generation"
                and b.goal.number("art_used") >= b.goal.number("art_cap")):
            raise Pause(f"The art cap is reached ({b.goal.get('art_used')} of {b.goal.get('art_cap')} PixelLab "
                        f"generations) and {pick}, an asset-generation ticket, is next.", "art-cap")
        return "build", pick
    flagged = [t for t in v.own if v.status(t) == "flagged-for-review"]
    if flagged:
        deps = [t for t in v.own if set(v.now[t]["depends_on"]) & set(flagged) and v.status(t) not in build.SETTLED]
        why = (f"{', '.join(deps)} wait on it" if deps else "the goal check waits for it")
        raise Pause(f"{', '.join(flagged)} failed QA twice and is flagged for the board's review; {why}. "
                    "Nothing else can go on.", "flagged")
    unsettled = [t for t in v.own + v.reused if v.status(t) not in build.SETTLED]
    if unsettled:
        lines = [f"{t} ({v.status(t)}, lead {v.now[t]['lead'] or 'none'}"
                 + (f", waits on {', '.join(build.waits_on(v.now[t], v.now))})" if t in v.own else
                    ", reused: this goal doesn't build it)") for t in unsettled]
        raise Pause("Nothing left to build, and these goal tickets haven't passed QA: " + "; ".join(lines) + ".",
                    "waiting")
    return "check", None


# --- rescans ---

def rescan(b, subs, seen, context=None):
    """Gap detection again for the sub-goals not yet covered; writes any new tickets and records the verdicts.
    Returns (summary, new or changed files to commit, a "repeat" Pause to raise once they are saved, or None)."""
    todo = [s for s in subs if s["verdict"] != "covered"]
    if not todo:
        return "every sub-goal is covered", [], None
    verdicts, existing = gaps.detect(b.claude, b.goal.section("Goal"), todo, b.root, MODEL,
                                     code_root=build.ensure_goal_build(b), context=context)
    drafts = [d for v in verdicts for d in v.get("drafts") or []]
    written = tickets.write(drafts, existing, b.root, b.gid) if drafts else {}
    paths = [p for _, p in written.values()]
    listed = {tid for tid, _, _ in goal_tickets(b.goal)}
    by_id = {s["id"]: s for s in subs}
    parts, repeats = [], []
    for v in verdicts:
        s = by_id[v["sub_goal"]]
        s["verdict"] = v["verdict"]
        if v["verdict"] == "missing":
            ids = [written[d["key"]][0] for d in v["drafts"]]
            for d in v["drafts"]:
                b.goal.append("Tickets", f"- {written[d['key']][0]}: {d['title']} ({s['id']}, written)")
            seen[f"sub-goal {s['id']}"] = seen.get(f"sub-goal {s['id']}", 0) + 1
            if seen[f"sub-goal {s['id']}"] >= 2:
                repeats.append(f"sub-goal {s['id']} ({s['title']}) is missing again")
        else:
            ids = list(v["tickets"])
            for t in ids:
                if t not in listed:
                    how = ", reused" if v["verdict"] == "in-flight" else ""
                    b.goal.append("Tickets", f"- {t}: {existing[t]['title']} ({s['id']}, {v['verdict']}{how})")
                    listed.add(t)
                    if v["verdict"] == "in-flight":
                        path = tickets.mark_reused(b.root, existing[t], b.gid)
                        paths += [path] if path else []
        s["ticket_ids"] = s["ticket_ids"] + [t for t in ids if t not in s["ticket_ids"]]
        parts.append(f"{s['id']} {v['verdict']}" + (f" (wrote {', '.join(ids)})" if v["verdict"] == "missing" else ""))
    save_sub_goals(b.goal, subs)
    repeat = Pause("The same gap came back twice with no ticket passing in between: " + "; ".join(repeats) + ".",
                   "repeat") if repeats else None
    return ", ".join(parts), paths, repeat


def save_sub_goals(goal, subs):
    goal_file.write_sub_goals(goal, subs, {s["id"]: {"verdict": s["verdict"], "ticket_ids": s["ticket_ids"]}
                                           for s in subs})


def after_ticket(b, res, seen):
    """One iteration log entry for a built ticket, the art it used, and the rescan."""
    goal = b.goal
    goal.set("iteration", goal.number("iteration") + 1)
    goal.set("art_used", goal.number("art_used") + res["art"])
    if res["outcome"] == "passed":
        seen.clear()
    context = (f"The last ticket built: {res['id']}, {res['outcome']} ({res['status']}). "
               f"Its agent said: {' / '.join(res['summaries']) or '(nothing)'}")
    try:
        found = rescan(b, View(b).subs, seen, context)
    except Pause as p:                       # logged with the step first, then the goal pauses
        found = (f"stopped ({p.kind})", [], p)
    merged = f", merged into {b.places.goal_branch(b.gid)}" if res["outcome"] == "passed" else ""
    said = " / ".join(s.strip().rstrip(".") for s in res["summaries"]) or "(nothing new)"
    skipped = (f" Refused, got past and not blocking: {' / '.join(res['refusals'])}."
               if res.get("refusals") else "")
    goal.log(f"{res['id']} ({View(b).sub_of.get(res['id'], '?')}, {res['to']}, {res['model']}): {res['outcome']} "
             f"({res['status']}, QA rounds {res['rounds']}){merged}; art {res['art']}; agent: {said}.{skipped} "
             f"Rescan: {found[0]}.")
    save(b, found[1], f"{b.gid}: iteration {goal.get('iteration')}, {res['id']} {res['outcome']} (goal runner)")
    if found[2]:
        raise found[2]


# --- the goal check ---

def sync_docs(b, folder):
    """Bring the long GDD and the short GDD's fingerprint up to date in the goal's build folder, before the goal
    check: runs `generate_long_gdd.py --check` through the shell (a non-zero exit means stale, and is the one
    exit allowed here: exit 2, a doc that breaks its structure, or any other failure still pauses). If stale it
    regenerates both, commits only the changed docs on the goal's build branch, and checks again. Returns the
    last check's output, for the goal check's prompt."""
    py, check_cmd = sys.executable, [sys.executable, "tools/generate_long_gdd.py", "--check"]

    def checked():
        done = b.shell.run(check_cmd, folder, check=False)
        if done.returncode not in (0, 1):
            raise Pause(f"A command the runner ran was refused or failed: {' '.join(check_cmd)}: "
                        f"{(done.stderr or done.stdout).strip()[:800]}", "command")
        return done
    done = checked()
    note = ""
    if done.returncode == 1:
        b.shell.run([py, "tools/generate_long_gdd.py"], folder)
        b.shell.run([py, "tools/update_short_gdd_fingerprint.py"], folder)
        changed = [l[3:].strip().strip('"') for l in b.shell.git(folder, "status", "--porcelain", "--", "docs").stdout
                   .splitlines() if len(l) > 3]
        if changed:
            b.shell.git(folder, "add", "--", *changed)
            b.shell.git(folder, "commit", "-q", "-m", f"{b.gid}: regenerate the long GDD and the short GDD's "
                                                      f"fingerprint (goal runner)", "--", *changed)
        note = f"The runner found the docs stale and regenerated them ({', '.join(changed) or 'no file changed'}); "
        done = checked()
    return f"{note}docs check now: {(done.stdout or done.stderr).strip()} (exit {done.returncode})"


def check_prompt(b, criteria, folder, docs_check=""):
    lines = "\n".join(f"{i}. {c}" for i, c in enumerate(criteria, 1))
    docs = (f"\nThe runner already ran the docs staleness check (generate_long_gdd.py --check) in this folder and "
            f"brought the docs up to date. Its result: {docs_check}\nFor any criterion about the docs being in sync, "
            f"use that result; don't run the docs scripts yourself.\n" if docs_check else "")
    return f"""Goal check for goal {b.gid} ("{b.goal.get('title')}"), in the goal's build folder {folder}
(branch {b.places.goal_branch(b.gid)}). Every ticket of the goal has passed QA and is merged there.
Check each of the goal's own acceptance criteria against the build, running the tests and scenes they name:
{lines}
{docs}Answer one entry per criterion, in this order, with pass or fail and short notes. Don't change any file.
If the permission system or a hook refuses anything, never work around it. If the action isn't essential, skip that
check and carry on; list it in refusals. Set blocked to true only when the refused action was essential and you
can't finish the checks without it; then stop.{build.pre_approved_note(b.root)}
Answer with the criteria, every refusal you met, and blocked."""


def goal_check(b, seen):
    """True when every goal criterion passes (the goal is then ready-to-play). Raises Pause."""
    goal, criteria = b.goal, goal_criteria(b.goal)
    folder = build.ensure_goal_build(b)
    docs_check = sync_docs(b, folder)
    answer = build.ask_headless(b, "goal-check", check_prompt(b, criteria, folder, docs_check), CHECK_SCHEMA,
                                "qa-integration", build.QA_MODEL, folder)
    for r in build.check_refusals(answer, "The goal check"):          # the ones it got past: logged
        goal.log(f"goal check: refused, got past and not blocking: {r}.")
    results = list(answer.data.get("criteria") or [])
    if len(results) != len(criteria):
        raise Pause(f"The goal check answered {len(results)} criteria for {len(criteria)}.", "qa")
    marks = []
    for c, r in zip(criteria, results):
        ok = r.get("result") == "pass"
        notes = (r.get("notes") or "").strip().replace(")", "]").replace("(", "[")
        marks.append(f"- [x] {c} (QA: pass)" if ok else f"- [ ] {c} (QA: fail, {notes or 'no notes'})")
    goal.set_section("Goal acceptance criteria", "\n".join(marks))
    failing = [c for c, r in zip(criteria, results) if r.get("result") != "pass"]
    goal.log(f"goal check: {len(criteria) - len(failing)} of {len(criteria)} goal criteria pass.")
    if not failing:
        goal.set("status", "ready-to-play")
        goal.log("ready to play.")
        save(b, [], f"{b.gid}: ready-to-play (goal runner)")
        print(how_to_play(b))
        return True
    repeats = []
    subs = View(b).subs
    for c in failing:
        key = f"criterion {c}"
        seen[key] = seen.get(key, 0) + 1
        if seen[key] >= 2:
            repeats.append(c)
        sub = next((s for s in subs if s["criteria"] == [c] and s["id"].startswith("C")), None)
        if sub:
            sub["verdict"] = ""                                  # look at it again
        else:
            sub = {"id": f"C{sum(s['id'].startswith('C') for s in subs) + 1}", "title": f"Goal criterion: {c}",
                   "why": "it failed the goal check", "value": 5, "criteria": [c], "needs": [], "verdict": "",
                   "ticket_ids": [], "rank": len(subs) + 1, "score": "goal criterion"}
            subs.append(sub)
    if repeats:
        save_sub_goals(goal, subs)
        save(b, [], f"{b.gid}: goal check failed again (goal runner)")
        raise Pause("The same goal criteria failed twice with no ticket passing in between: "
                    + "; ".join(repeats) + ".", "repeat")
    found = rescan(b, subs, seen, "These goal criteria failed the goal check: " + "; ".join(failing))
    goal.log(f"gap detection on the failing goal criteria: {found[0]}.")
    save(b, found[1], f"{b.gid}: goal check failed, gaps found (goal runner)")
    if found[2]:
        raise found[2]
    return False


def how_to_play(b):
    folder = b.places.goal_folder(b.gid)
    return (f"{b.gid} is ready to play. Open {folder / 'game' / 'project.godot'} in Godot, or press Play on its "
            f"entry in the Builds tab of the task board (http://localhost:8765). The build is the branch "
            f"{b.places.goal_branch(b.gid)}; the Project Lead merges it into master after the board's playtest.")


# --- the loop ---

def save(b, paths, message):
    b.goal.save()
    ids = {tid for tid, _, _ in goal_tickets(b.goal)}
    build.commit_files(b.root, [b.goal.path] + list(paths) + build.master_ticket_changes(b.root, ids), message)


def run(b):
    """Run the goal's loop until it is ready-to-play or paused; returns the goal file."""
    goal, seen = b.goal, {}
    if goal.get("status") != "building":
        goal.set("status", "building")
        goal.log("building.")
    try:
        if any(not s["verdict"] for s in View(b).subs):                 # gap detection never finished
            found = rescan(b, View(b).subs, seen)
            goal.log(f"gap detection: {found[0]}.")
            save(b, found[1], f"{b.gid}: gap detection (goal runner)")
            if found[2]:
                raise found[2]
        while True:
            step, tid = next_step(b)
            if step == "build":
                after_ticket(b, build.build_ticket(b, tid), seen)
            elif goal_check(b, seen):
                return goal
    except Pause as p:
        goal.pause(str(p), kind=p.kind)
        save(b, [], f"{b.gid}: paused, {p.kind} (goal runner)")
        print(f"{b.gid} paused ({KINDS.get(p.kind, p.kind)}): {p}")
        return goal


def cleared(b):
    """(True, why) when a paused goal's reason is gone: checked for CLEARABLE kinds by asking the loop's own
    rules again (without changing anything); the other kinds need --force."""
    kind = b.goal.last_pause_kind() or "stop"
    if kind not in CLEARABLE:
        return False, f"its last pause ({kind}: {KINDS.get(kind, kind)}) can't be checked by the runner"
    try:
        next_step(b)
    except Pause as p:
        if p.kind == kind:
            return False, f"it would pause again: {p}"
    return True, f"its last pause ({kind}) is cleared"


def resume(b, force=False):
    """Pick a stopped or paused goal up from its files and carry on. Returns (goal, message)."""
    goal, status = b.goal, b.goal.get("status")
    if status in ("ready-to-play", "done", "cancelled"):
        return goal, f"{b.gid} is {status}; nothing to resume."
    if not goal_file.read_sub_goals(goal):
        return goal, f"{b.gid} stopped before it had sub-goals; start it again with run.py start."
    if status == "paused":
        ok, why = cleared(b)
        if not ok and not force:
            return goal, f"{b.gid} stays paused: {why}. Clear the reason, or resume with --force."
        goal.log(f"resumed: {why}" + ("; --force." if not ok else "."))
    else:
        goal.log(f"resumed from {status}.")
    goal.set("status", "building")
    run(b)
    return goal, f"{b.gid}: {goal.get('status')}"


def load(places, claude, goal_id, shell=None):
    """A Build for an existing goal."""
    return build.Build(places, claude, goal_file.find(Path(places.root) / "goals", goal_id), shell)
