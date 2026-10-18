"""QA helper (role: runs the goal runner on a fixture in a throwaway copy of the repo, never the real checkout).

  python tools/goal_agent/try_fixture.py [fixture]      # default: tools/goal_agent/fixtures/sample-goal.json

Clones this checkout's committed state into a new temporary folder, puts it on a local `master`, runs
`run.py start "Sample goal" --fake <fixture>` and `run.py status G-001` there, and prints both, with the
runner's commit. The folder is kept so it can be inspected; its path is printed first.
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
    fixture = argv[0] if argv else "tools/goal_agent/fixtures/sample-goal.json"
    copy = Path(tempfile.mkdtemp(prefix="goal-runner-qa-")) / "repo"
    print(f"Temporary copy: {copy}")
    if step(["git", "clone", "-q", str(ROOT), str(copy)], ROOT) or step(["git", "checkout", "-q", "-B", "master"], copy):
        return 1
    run = [sys.executable, "tools/goal_agent/run.py"]
    code = step(run + ["start", "Sample goal", "--fake", fixture], copy)
    step(run + ["status", "G-001"], copy)
    step(["git", "log", "-1", "--name-status", "--format=%h %s"], copy)
    return code


if __name__ == "__main__":
    sys.exit(main())
