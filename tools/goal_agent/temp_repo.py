"""Test support (role: a small temporary git repo for the tests, so they never touch the real checkout).

make() copies in what the runner reads (the task template and README, the agent definitions, the status
script and its helpers, the guard hook, the goal runner itself) and commits it on master.
"""

import shutil
import subprocess
from pathlib import Path

REAL = Path(__file__).resolve().parents[2]
COPY = ["tasks/_TEMPLATE.md", "tasks/README.md", "tools/taskboard_sync.py", "tools/guard_ledger.py",
        "tools/task_status.py", "tools/board_inbox.py", ".claude/hooks/board_gate.py"]


def git(root, *args, check=True):
    done = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8")
    if check and done.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {done.stderr}")
    return done.stdout


def ticket_text(tid, status="open", to="ui", title=None, goal=None, depends_on=""):
    goal_line = "" if goal is None else f"goal: {goal}\n"
    return (f"---\nid: {tid}\ntitle: {title or 'Ticket ' + tid}\nstatus: {status}\nfrom: project-lead\nto: {to}\n"
            f"lead:\nepic: tooling\nmilestone: mvp\n{goal_line}depends_on: [{depends_on}]\nmodel: sonnet\nqa_rounds: 0\n"
            f"---\n\n## Description\n\nA ticket.\n\n## Acceptance criteria\n\n- [ ] It works (QA: pass / fail)\n\n"
            f"## Result notes\n\nWritten by the agent when it finishes.\n")


def add_ticket(root, tid, **fields):
    path = Path(root) / "tasks" / f"{tid}-ticket.md"
    path.write_bytes(ticket_text(tid, **fields).encode("utf-8"))
    return path


def make(folder):
    """A git repo in `folder` (on master, one commit), ready for the goal runner. Returns its path."""
    root = Path(folder)
    for rel in COPY:
        (root / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(REAL / rel, root / rel)
    for agent in (REAL / ".claude" / "agents").glob("*.md"):
        (root / ".claude" / "agents").mkdir(parents=True, exist_ok=True)
        shutil.copyfile(agent, root / ".claude" / "agents" / agent.name)
    shutil.copytree(REAL / "tools" / "goal_agent", root / "tools" / "goal_agent",
                    ignore=shutil.ignore_patterns("__pycache__"))
    (root / ".gitignore").write_text(".board/\n__pycache__/\n.env\n.secrets/\n", encoding="utf-8")   # as the studio's
    for rel, text in (("game/README.md", "# Game\n## Setup\n"), ("game/scripts/car.gd", "extends Node\n"),
                      ("game/art/car.png", "x"), ("game/addons/gut/gut.gd", "x"), ("game/.godot/cache", "x")):
        (root / rel).parent.mkdir(parents=True, exist_ok=True)
        (root / rel).write_text(text, encoding="utf-8")
    git(root, "init", "-q")
    git(root, "symbolic-ref", "HEAD", "refs/heads/master")
    git(root, "config", "user.name", "Test")
    git(root, "config", "user.email", "test@example.com")
    git(root, "config", "core.autocrlf", "false")
    git(root, "add", "-A")
    git(root, "commit", "-q", "-m", "initial")
    return root
