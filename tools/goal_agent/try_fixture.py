"""QA helper (role: runs the goal runner on a fixture in a throwaway copy of the repo, never the real checkout).

  python tools/goal_agent/try_fixture.py [fixture] [--plan-only]
      default fixture: tools/goal_agent/fixtures/whole-goal.json (a whole fake goal, all four layers)

Clones this checkout's committed state into a new temporary folder, puts it on a local `master`, runs
`run.py start "Sample goal" --fake <fixture> --worktrees <temp>/worktrees` there (with --plan-only, it stops
once planned, as in T-162: use it for sample-goal.json and refused-twice.json), then `run.py status G-001`,
and shows master's new commits and the goal's build branch. The folder is kept so the goal file, the tickets
and the worktrees can be opened; its path is printed first.
"""

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def step(cmd, cwd):
    print(f"\n$ {' '.join(cmd)}")
    done = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, encoding="utf-8")
    print((done.stdout + done.stderr).rstrip())
    return done.returncode


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    plan_only = "--plan-only" in argv
    argv = [a for a in argv if a != "--plan-only"]
    fixture = argv[0] if argv else "tools/goal_agent/fixtures/whole-goal.json"
    base = Path(tempfile.mkdtemp(prefix="goal-runner-qa-"))
    copy, worktrees = base / "repo", base / "worktrees"
    print(f"Temporary copy: {copy}\nIts worktrees: {worktrees}")
    if step(["git", "clone", "-q", str(ROOT), str(copy)], ROOT) or step(["git", "checkout", "-q", "-B", "master"], copy):
        return 1
    first = subprocess.run(["git", "rev-parse", "HEAD"], cwd=str(copy), capture_output=True, text=True).stdout.strip()
    run = [sys.executable, "tools/goal_agent/run.py"]
    where = ["--worktrees", str(worktrees)]
    code = step(run + ["start", "Sample goal", "--fake", fixture] + (["--plan-only"] if plan_only else []) + where, copy)
    step(run + ["status", "G-001"] + where, copy)
    step(["git", "log", "--name-status", "--format=%h %s", f"{first}..master"], copy)
    if not plan_only:
        step(["git", "log", "--oneline", "--graph", "master..playtest/G-001"], copy)
        step(["git", "worktree", "list"], copy)
    return code


if __name__ == "__main__":
    sys.exit(main())
