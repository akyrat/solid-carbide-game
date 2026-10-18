"""The goal runner's command line (role: entry point). It runs all four layers.

  python tools/goal_agent/run.py start "<goal>" [--art-cap N] [--max-iterations N] [--plan-only] [--fake FIXTURE]
      Plans the goal (layer 1), finds its gaps and writes the missing tickets (layer 2), writes the goal
      file in goals/ and commits it with its tickets on master (staging only those files, and not during a
      merge). Then, unless --plan-only, it carries on into the loop: builds the tickets (layer 3) and
      rescans after each one (layer 4) until the goal is `ready-to-play`, or `paused` with the reason.
  python tools/goal_agent/run.py resume G-NNN [--force] [--fake FIXTURE]
      Rebuilds a stopped goal's state from its goal file, its tickets and the worktrees, and carries on.
      A paused goal resumes only when its reason is cleared (or with --force).
  python tools/goal_agent/run.py status G-NNN
      The goal's status, iteration, art spent, its sub-goals with their verdicts, its tickets with their
      current status, and any pause.

--fake answers from a JSON fixture (fake_team.FakeTeam) instead of calling Claude; the fake team also does
the agents' and QA's work in the ticket folders. --worktrees puts the goal's folders somewhere else than
C:\\solid-carbide-worktrees (for QA's runs in a temporary copy).
Exit codes: 0 ready-to-play (planned with --plan-only; resumed or shown for the others), 1 paused or refused.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # tools/, for taskboard_sync and goal_agent

import taskboard_sync as tb  # noqa: E402
from goal_agent import build, gaps, goal_file, loop, prioritize, tickets  # noqa: E402
from goal_agent.claude_call import Pause, RealClaude  # noqa: E402
from goal_agent.fake_team import FakeTeam  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MODEL = "opus"
commit_files = build.commit_files
record_sub_goals = goal_file.write_sub_goals


def record_plan(goal, plan):
    goal.set_section("Goal acceptance criteria", "\n".join(f"- [ ] {c} (QA: pass / fail)" for c in plan["goal_criteria"]))
    goal.set_section("Open questions", "\n".join(f"- {q}" for q in plan["open_questions"]))
    goal.set_section("Scoring", prioritize.SCORING_RULE)
    record_sub_goals(goal, plan["sub_goals"], {})


def record_gaps(goal, plan, verdicts, written, existing):
    """Verdicts into the table, and every ticket the goal wrote or reused into `## Tickets`."""
    by_id, lines = {}, []
    for v in verdicts:
        if v["verdict"] == "missing":
            ids = [written[d["key"]][0] for d in v["drafts"]]
            lines += [f"- {written[d['key']][0]}: {d['title']} ({v['sub_goal']}, written)" for d in v["drafts"]]
        else:
            ids = list(v["tickets"])
            how = ", reused" if v["verdict"] == "in-flight" else ""
            lines += [f"- {t}: {existing[t]['title']} ({v['sub_goal']}, {v['verdict']}{how})" for t in ids]
        by_id[v["sub_goal"]] = {"verdict": v["verdict"], "ticket_ids": ids}
    record_sub_goals(goal, plan["sub_goals"], by_id)
    goal.set_section("Tickets", "\n".join(lines))


def start(goal_text, root, claude, art_cap=0, max_iterations=20, model=MODEL, commit=True):
    """Layers 1 and 2 for a new goal; returns the goal file (saved, and committed when `commit`)."""
    root = Path(root)
    goal = goal_file.new(root / "goals", goal_text, art_cap, max_iterations)
    goal.log("started: planning.")
    files = [goal.path]
    try:
        plan = prioritize.plan(claude, goal_text, goal.id, root, model)
        record_plan(goal, plan)
        goal.log(f"priority scoring: {len(plan['sub_goals'])} sub-goals ranked, "
                 f"{len(plan['goal_criteria'])} goal criteria, {len(plan['open_questions'])} open questions.")
        verdicts, existing = gaps.detect(claude, goal_text, plan["sub_goals"], root, model)
        drafts = [d for v in verdicts for d in v.get("drafts") or []]
        written = tickets.write(drafts, existing, root, goal.id)
        files += [path for _, path in written.values()]
        left = []
        for t in [t for v in verdicts if v["verdict"] == "in-flight" for t in v["tickets"]]:
            path = tickets.mark_reused(root, existing[t], goal.id)
            if path:
                files.append(path)
            else:
                left.append(t)
        record_gaps(goal, plan, verdicts, written, existing)
        if left:
            goal.log(f"reused, goal line left alone (open branch, or set already): {', '.join(left)}.")
        counts = {k: sum(v["verdict"] == k for v in verdicts) for k in gaps.VERDICTS}
        goal.log(f"gap detection: {counts['covered']} covered, {counts['in-flight']} in flight, "
                 f"{counts['missing']} missing; wrote {len(written)} tickets.")
        goal.set("status", "planned")
    except Pause as p:
        goal.pause(str(p), kind=p.kind)
    goal.save()
    if commit:
        commit_files(root, files, f"{goal.id}: {goal.get('status')}, \"{goal.get('title')}\" (goal runner)")
    return goal


def status(goal_id, root, places=None):
    """The lines `run.py status` prints."""
    root = Path(root)
    places = places or build.Places(root)
    goal = goal_file.find(root / "goals", goal_id)
    lines = [f"{goal.id}: {goal.get('status')}, \"{goal.get('title')}\" (iteration {goal.get('iteration')} of "
             f"{goal.get('max_iterations')}, art {goal.get('art_used')} of {goal.get('art_cap')})",
             f"Build: {places.goal_branch(goal.id)} in {places.goal_folder(goal.id)}"
             + ("" if places.goal_folder(goal.id).exists() else " (not made yet)"), "", "Sub-goals:"]
    for r in goal_file.read_table(goal.section("Sub-goals")):
        lines.append(f"  {r['rank']}. {r['id']} {r['title']} [{r['verdict'] or 'not checked'}] {r['tickets']}")
    now = gaps.existing_tickets(root)
    lines += ["", "Tickets:"]
    for line in (goal.section("Tickets") or "").splitlines():
        tid = line[2:].split(":", 1)[0] if line.startswith("- T-") else None
        if tid:
            lines.append(f"  {tid} [{now.get(tid, {}).get('status', 'missing')}]{line[2 + len(tid):]}")
    pauses = goal.section("Pauses")
    if pauses and pauses != goal_file.EMPTY:
        kind = goal.last_pause_kind()
        lines += ["", f"Pauses (last: {kind}, {loop.KINDS.get(kind, kind)}):", pauses]
    return lines


def main(argv=None):
    tb.utf8_output()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    s = sub.add_parser("start", help="plan a new goal, write its missing tickets, and build it")
    s.add_argument("goal", help="the goal, in the board's words")
    s.add_argument("--art-cap", type=int, default=0, help="PixelLab generations this goal may use")
    s.add_argument("--max-iterations", type=int, default=20)
    s.add_argument("--plan-only", action="store_true", help="stop once the goal is planned (layers 1 and 2)")
    r = sub.add_parser("resume", help="carry on with a stopped or paused goal")
    r.add_argument("goal_id", metavar="G-NNN")
    r.add_argument("--force", action="store_true", help="resume a paused goal even if its reason isn't cleared")
    t = sub.add_parser("status", help="print a goal's status, iteration, art, sub-goals, tickets and pauses")
    t.add_argument("goal_id", metavar="G-NNN")
    for p in (s, r, t):
        p.add_argument("--worktrees", metavar="FOLDER", help="where the goal's folders go (default: beside the repo)")
    for p in (s, r):
        p.add_argument("--fake", metavar="FIXTURE", help="answer from a fake-team fixture instead of calling Claude")
    args = ap.parse_args(argv)
    places = build.Places(ROOT, args.worktrees)
    try:
        if args.command == "status":
            print("\n".join(status(args.goal_id, ROOT, places)))
            return 0
        claude = FakeTeam(args.fake) if args.fake else RealClaude()
        if args.command == "start":
            goal = start(args.goal, ROOT, claude, args.art_cap, args.max_iterations)
            if goal.get("status") == "planned" and not args.plan_only:
                loop.run(build.Build(places, claude, goal))
            print(f"{goal.id}: {goal.get('status')} ({goal.path})")
            return 0 if goal.get("status") in ("planned", "ready-to-play") else 1
        goal, message = loop.resume(loop.load(places, claude, args.goal_id), args.force)
        print(message)
        return 0 if goal.get("status") == "ready-to-play" else 1
    except FileNotFoundError as e:
        print(e, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
