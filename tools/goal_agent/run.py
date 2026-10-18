"""The goal runner's command line (role: entry point). This part runs layers 1 and 2; T-163 adds 3 and 4.

  python tools/goal_agent/run.py start "<goal>" [--art-cap N] [--max-iterations N] [--fake FIXTURE]
      Plans the goal (layer 1), finds its gaps and writes the missing tickets (layer 2), writes the goal
      file in goals/ and leaves the goal `planned` (or `paused`, with the reason). Commits the goal file
      and its tickets on master, staging only those files, unless a merge is in progress.
  python tools/goal_agent/run.py status G-NNN
      The goal's status, its sub-goals with their verdicts, and its tickets with their current status.

--fake answers from a JSON fixture (claude_call.FakeClaude) instead of calling Claude.
"""

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # tools/, for taskboard_sync and goal_agent

import taskboard_sync as tb  # noqa: E402
from goal_agent import gaps, goal_file, prioritize, tickets  # noqa: E402
from goal_agent.claude_call import FakeClaude, Pause, RealClaude  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MODEL = "opus"


def record_plan(goal, plan):
    goal.set_section("Goal acceptance criteria", "\n".join(f"- [ ] {c} (QA: pass / fail)" for c in plan["goal_criteria"]))
    goal.set_section("Open questions", "\n".join(f"- {q}" for q in plan["open_questions"]))
    goal.set_section("Scoring", prioritize.SCORING_RULE)
    record_sub_goals(goal, plan["sub_goals"], {})


def record_sub_goals(goal, sub_goals, verdicts):
    """The `## Sub-goals` section: the ranked table, then each sub-goal's criteria and needs."""
    rows, details = [], []
    for s in sub_goals:
        v = verdicts.get(s["id"], {})
        rows.append({**s, "verdict": v.get("verdict", ""), "tickets": ", ".join(v.get("ticket_ids", []))})
        needs = ", ".join(s["needs"]) or "nothing"
        details.append(f"### {s['id']}: {s['title']}\n\nNeeds: {needs}.\n\n" + "\n".join(f"- {c}" for c in s["criteria"]))
    goal.set_section("Sub-goals", goal_file.table(rows) + "\n\n" + "\n\n".join(details))


def record_gaps(goal, plan, verdicts, written, existing):
    """Verdicts into the table, and every ticket the goal wrote or reused into `## Tickets`."""
    by_id, lines = {}, []
    for v in verdicts:
        if v["verdict"] == "missing":
            ids = [written[d["key"]][0] for d in v["drafts"]]
            lines += [f"- {written[d['key']][0]}: {d['title']} ({v['sub_goal']}, written)" for d in v["drafts"]]
        else:
            ids = list(v["tickets"])
            how = "reused" if v["verdict"] == "in-flight" else "covers it"
            lines += [f"- {t}: {existing[t]['title']} ({v['sub_goal']}, {v['verdict']}, {how})" for t in ids]
        by_id[v["sub_goal"]] = {"verdict": v["verdict"], "ticket_ids": ids}
    record_sub_goals(goal, plan["sub_goals"], by_id)
    goal.set_section("Tickets", "\n".join(lines))


def start(goal_text, root, claude, art_cap=0, max_iterations=10, model=MODEL, commit=True):
    """Layers 1 and 2 for a new goal; returns the goal file (saved, and committed when `commit`)."""
    root = Path(root)
    goal = goal_file.new(root / "goals", goal_text, art_cap, max_iterations)
    goal.log("started: planning.")
    files = [goal.path]
    try:
        plan = prioritize.plan(claude, goal_text, root, model)
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
        goal.pause(str(p))
    goal.save()
    if commit:
        commit_files(root, files, f"{goal.id}: {goal.get('status')}, \"{goal.get('title')}\" (goal runner)")
    return goal


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8")


def commit_files(root, paths, message):
    """Commit only these files on master; refuses (prints why, returns False) during a merge or off master."""
    if git(root, "rev-parse", "-q", "--verify", "MERGE_HEAD").stdout.strip():
        print("Not committed: a merge is in progress (another session's). Commit these files later.")
        return False
    branch = git(root, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "master":
        print(f"Not committed: this checkout is on {branch!r}, not master.")
        return False
    rel = [str(Path(p).resolve().relative_to(Path(root).resolve())) for p in paths]
    for step in (["add", "--", *rel], ["commit", "-m", message, "--", *rel]):
        done = git(root, *step)
        if done.returncode != 0:
            print(f"Not committed: git {step[0]} failed: {(done.stderr or done.stdout).strip()}")
            return False
    print(f"Committed on master: {message}")
    return True


def status(goal_id, root):
    """The lines `run.py status` prints."""
    root = Path(root)
    goal = goal_file.find(root / "goals", goal_id)
    lines = [f"{goal.id}: {goal.get('status')}, \"{goal.get('title')}\" (iteration {goal.get('iteration')} of "
             f"{goal.get('max_iterations')}, art {goal.get('art_used')} of {goal.get('art_cap')})", "", "Sub-goals:"]
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
        lines += ["", "Pauses:", pauses]
    return lines


def main(argv=None):
    tb.utf8_output()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    s = sub.add_parser("start", help="plan a new goal and write its missing tickets")
    s.add_argument("goal", help="the goal, in the board's words")
    s.add_argument("--art-cap", type=int, default=0, help="PixelLab generations this goal may use")
    s.add_argument("--max-iterations", type=int, default=10)
    s.add_argument("--fake", metavar="FIXTURE", help="answer from a FakeClaude fixture instead of calling Claude")
    t = sub.add_parser("status", help="print a goal's status, sub-goals and tickets")
    t.add_argument("goal_id", metavar="G-NNN")
    args = ap.parse_args(argv)
    if args.command == "start":
        claude = FakeClaude(args.fake) if args.fake else RealClaude()
        goal = start(args.goal, ROOT, claude, args.art_cap, args.max_iterations)
        print(f"{goal.id}: {goal.get('status')} ({goal.path})")
        return 0 if goal.get("status") == "planned" else 1
    try:
        print("\n".join(status(args.goal_id, ROOT)))
    except FileNotFoundError as e:
        print(e, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
