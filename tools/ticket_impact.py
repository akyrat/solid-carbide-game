"""Which unfinished tickets unblock the most work?

For every ticket that is not done or cancelled, counts the unfinished tickets that wait on
it: directly (they list it in depends_on) and in total (anything further down the chain).
Tickets with the most work waiting on them are the best ones to do next.

Usage, from the repo root:

  python tools/ticket_impact.py            # the top 15, MVP tickets only
  python tools/ticket_impact.py --top 30   # more rows
  python tools/ticket_impact.py --all      # include final-release tickets
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from taskboard_sync import TASKS_DIR, parse_header, task_files  # noqa: E402

FINISHED = {"done", "cancelled"}


def load(tasks_dir=TASKS_DIR):
    """id -> header fields, for every task file."""
    tickets = {}
    for path in task_files(tasks_dir):
        fields = parse_header(path.read_text(encoding="utf-8"))
        if fields and "id" in fields:
            tickets[fields["id"]] = fields
    return tickets


def impact(tickets, mvp_only=True):
    """Rows of (id, title, status, agent, direct, total), most total dependents first."""
    open_ids = {i for i, t in tickets.items()
                if t.get("status") not in FINISHED and (not mvp_only or t.get("milestone") == "mvp")}
    waiting_on = {i: set() for i in tickets}          # id -> unfinished tickets listing it directly
    for i in open_ids:
        for dep in tickets[i].get("depends_on", []):
            if dep in waiting_on:
                waiting_on[dep].add(i)
    rows = []
    for i in sorted(open_ids):
        seen, stack = set(), [i]
        while stack:                                    # everything further down the chain
            for child in waiting_on[stack.pop()]:
                if child not in seen:
                    seen.add(child)
                    stack.append(child)
        t = tickets[i]
        rows.append((i, t.get("title", ""), t.get("status", ""), t.get("to", ""), len(waiting_on[i]), len(seen)))
    rows.sort(key=lambda r: (-r[5], -r[4], r[0]))
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--all", action="store_true", help="include tickets for later milestones")
    args = ap.parse_args(argv)
    rows = impact(load(), mvp_only=not args.all)[: args.top]
    print(f"{'ticket':7} {'status':15} {'agent':17} {'direct':>6} {'total':>5}  title")
    for i, title, status, to, direct, total in rows:
        print(f"{i:7} {status:15} {to:17} {direct:6} {total:5}  {title[:70]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
