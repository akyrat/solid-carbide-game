"""Layer 3, code writing: builds the goal's tickets with the studio's agents, one ticket at a time.

The goal's build is the branch playtest/<goal id>, made from master as a worktree beside the main checkout
(Places: one setting for every folder and branch, so tests use temporary ones). Each ticket, in order:
  1. its own worktree and task/ branch, made from the goal's build (tasks/README.md, "Git branches"),
     with .env (and .secrets/) copied in;
  2. `in-progress`, through the main checkout's status script (the only way a status changes);
  3. its agent, headless: `claude -p --agent <to> --model <model>` in the ticket's folder;
  4. `in-qa`, and the QA/Integration Agent, headless on sonnet, marks every criterion on the ticket;
  5. passed: `needs-playtest` or `done`, then merged into the goal's build (Godot's line-ending-only
     .import noise reverted). First fail: back to `in-progress` on opus, the agent and QA again.
     Second fail: `flagged-for-review`.
Every headless session first takes the name Goal-<goal id> on the task board, under a session id the
runner chooses, so it hears only the goal's own tickets. PixelLab generations are counted from the new
lines in game/art/pixellab-generation-log.jsonl on the ticket's branch. Every command goes through
Shell, and a refused or failed one pauses the goal, as does any refusal a headless session reports.
"""

import json
import re
import shutil
import subprocess
import sys
import uuid
from pathlib import Path

import taskboard_sync as tb
from task_status import set_field, verdicts
from goal_agent.claude_call import Pause

ART_LOG = "game/art/pixellab-generation-log.jsonl"
QA_MODEL = "sonnet"            # QA always runs on sonnet (tasks/README.md, "Models")
RETRY_MODEL = "opus"           # a ticket that failed QA once
PERMISSION_MODE = "acceptEdits"   # a headless agent may edit files in its folder; Bash still follows the settings
AGENT_TIMEOUT = 4 * 3600       # seconds for one headless agent or QA session
PASSED = ("needs-playtest", "done")
SETTLED = PASSED + ("cancelled",)
TASK_ID_RE = re.compile(r"T-\d+")

AGENT_SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {"type": "string", "description": "what you did, in two or three sentences"},
        "art_generations_used": {"type": "integer", "minimum": 0},
        "refusals": {"type": "array", "items": {"type": "string"},
                     "description": "every action the permission system or a hook refused, with what you wanted"},
        "blocked": {"type": "boolean",
                    "description": "true only when a refused action was essential and you could not finish "
                                   "your job without it"},
    },
    "required": ["summary", "art_generations_used", "refusals", "blocked"],
}
QA_SCHEMA = {
    "type": "object",
    "properties": {"summary": {"type": "string"}, "refusals": {"type": "array", "items": {"type": "string"}},
                   "blocked": {"type": "boolean",
                               "description": "true only when a refused action was essential and you could not "
                                              "finish the checks without it"}},
    "required": ["summary", "refusals", "blocked"],
}


class Places:
    """Where a goal's folders and branches live. The default is the studio's: C:\\solid-carbide-worktrees."""

    def __init__(self, root, worktrees=None):
        self.root = Path(root)
        self.worktrees = Path(worktrees) if worktrees else self.root.parent / "solid-carbide-worktrees"

    def goal_branch(self, gid):
        return f"playtest/{gid}"

    def goal_folder(self, gid):
        return self.worktrees / gid

    def ticket_folder(self, tid):
        return self.worktrees / tid

    def ticket_branch(self, ticket):
        return "task/" + Path(ticket["file"]).stem      # tasks/T-012-short-title.md -> task/T-012-short-title


class Shell:
    """Runs the runner's own commands. A failed one (check=True) pauses the goal: the runner never retries
    a refused command another way."""

    def run(self, cmd, cwd, check=True):
        done = subprocess.run([str(c) for c in cmd], cwd=str(cwd), capture_output=True, text=True,
                              encoding="utf-8", errors="replace")
        if check and done.returncode != 0:
            raise Pause(f"A command the runner ran was refused or failed: {' '.join(str(c) for c in cmd)}: "
                        f"{(done.stderr or done.stdout).strip()[:800]}", "command")
        return done

    def git(self, cwd, *args, check=True):
        return self.run(["git", "-C", cwd, *args], cwd, check)


class Build:
    """What layer 3 needs for one goal: the places, Claude (or a fake), the goal file and the shell."""

    def __init__(self, places, claude, goal, shell=None):
        self.places, self.claude, self.goal = places, claude, goal
        self.shell = shell or Shell()
        self.root = places.root

    @property
    def gid(self):
        return self.goal.id

    @property
    def lead(self):
        return f"Goal-{self.gid}"


# --- reading the tickets ---

def tickets_now(root):
    """{id: ticket} as the task board sees them (open ones from their branch folders), each with its
    `goal` line and `path` (the copy the status script changes)."""
    root = Path(root)
    out = {}
    for t in tb.tickets_now(root / "tasks", tb.task_folders(root)):
        path = Path(t["folder"]) / t["file"] if t["folder"] else root / t["file"]
        fields = tb.parse_header(path.read_text(encoding="utf-8")) or {}
        out[t["id"]] = dict(t, goal=fields.get("goal", ""), path=path)
    return out


def dep_met(ticket, dep):
    """The status script's rule (task_status.dep_met): done, or needs-playtest in the same goal."""
    if dep is None:
        return False
    return dep["status"] == "done" or (dep["status"] == "needs-playtest" and bool(ticket["goal"])
                                       and dep["goal"] == ticket["goal"])


def waits_on(ticket, now):
    """The dependencies of a ticket that are not met yet."""
    return [d for d in ticket["depends_on"] if not dep_met(ticket, now.get(d))]


def ready(ticket, now):
    """Ready to start: open, or blocked with every dependency met."""
    return ticket["status"] in ("open", "blocked") and not waits_on(ticket, now)


def merged(b, ticket):
    """Is the ticket's branch already in the goal's build?"""
    branch = b.places.ticket_branch(ticket)
    if b.shell.git(b.root, "rev-parse", "-q", "--verify", f"refs/heads/{branch}", check=False).returncode:
        return False
    return b.shell.git(b.root, "merge-base", "--is-ancestor", branch, b.places.goal_branch(b.gid),
                       check=False).returncode == 0


# --- folders and branches ---

def copy_secrets(root, folder):
    """Copy the git-ignored .env (and .secrets/, if present) into a new folder."""
    if (root / ".env").exists():
        shutil.copyfile(root / ".env", folder / ".env")
    if (root / ".secrets").is_dir() and not (folder / ".secrets").exists():
        shutil.copytree(root / ".secrets", folder / ".secrets")


def branch_exists(b, branch):
    return b.shell.git(b.root, "rev-parse", "-q", "--verify", f"refs/heads/{branch}", check=False).returncode == 0


def ensure_goal_build(b):
    """The goal's folder on playtest/<goal id>, made from master the first time. Returns the folder."""
    folder, branch = b.places.goal_folder(b.gid), b.places.goal_branch(b.gid)
    if not folder.exists():
        b.places.worktrees.mkdir(parents=True, exist_ok=True)
        if branch_exists(b, branch):
            b.shell.git(b.root, "worktree", "add", folder, branch)
        else:
            b.shell.git(b.root, "worktree", "add", "-b", branch, folder, "master")
        copy_secrets(b.root, folder)
    return folder


def ensure_ticket_folder(b, ticket):
    """The ticket's folder on its task/ branch, made from the goal's build. A ticket written after the goal's
    build was made (a rescan) has its file only on master: it is brought into the build first."""
    folder, branch = b.places.ticket_folder(ticket["id"]), b.places.ticket_branch(ticket)
    if folder.exists():
        return folder
    goal_folder = ensure_goal_build(b)
    if branch_exists(b, branch):
        b.shell.git(b.root, "worktree", "add", folder, branch)
    else:
        if b.shell.git(goal_folder, "cat-file", "-e", f"HEAD:{ticket['file']}", check=False).returncode:
            b.shell.git(goal_folder, "checkout", "master", "--", ticket["file"])
            b.shell.git(goal_folder, "commit", "-q", "-m",
                        f"{b.gid}: bring {ticket['id']}'s task file from master (goal runner)", "--", ticket["file"])
        b.shell.git(b.root, "worktree", "add", "-b", branch, folder, b.places.goal_branch(b.gid))
    copy_secrets(b.root, folder)
    return folder


def commit_ticket(b, ticket, message):
    """Commit the ticket's task file in its folder, if the status script (or the runner) changed it."""
    folder = b.places.ticket_folder(ticket["id"])
    b.shell.git(folder, "add", "--", ticket["file"])
    if b.shell.git(folder, "diff", "--cached", "--quiet", check=False).returncode:
        b.shell.git(folder, "commit", "-q", "-m", message)


# --- the status script, the task board name and the agents ---

def move(b, tid, status, note=None, reply=None):
    """Move a ticket through the main checkout's status script; a refused move pauses the goal."""
    cmd = [sys.executable, b.root / "tools" / "task_status.py", tid, status]
    if note:
        cmd += ["--note", note]
    if reply:
        cmd += ["--reply", reply]
    b.shell.run(cmd, b.root)


def register_session(b):
    """A new session id, named Goal-<goal id> on the task board (--take-over: one name for the whole goal)."""
    sid = str(uuid.uuid4())
    b.shell.run([sys.executable, b.root / "tools" / "board_inbox.py", "name", sid, b.lead, "--take-over"], b.root)
    return sid


def check_refusals(answer, who):
    """The refusals a headless session met. If it says `blocked` (a missing field counts as blocked), the goal
    pauses; otherwise the session got
    past them without working around them, and they are returned (as text) to be recorded."""
    data = answer.data or {}
    refused = list(answer.denials) + list(data.get("refusals") or [])
    if refused and data.get("blocked", True):
        raise Pause(f"{who} reported a refusal; the runner never works around one: {refused}", "refusal")
    return [r if isinstance(r, str) else json.dumps(r, sort_keys=True) for r in refused]


def ask_headless(b, step, prompt, schema, agent, model, folder):
    """One headless session in `folder` (no --add-dir: with acceptEdits it could edit the main checkout, and
    the runner, not the agent, moves the ticket)."""
    sid = register_session(b)
    return b.claude.ask(step, prompt, schema, model=model, agent=None if agent == "project-lead" else agent,
                        session_id=sid, cwd=str(folder), permission_mode=PERMISSION_MODE, timeout=AGENT_TIMEOUT)


def art_left(b):
    return max(b.goal.number("art_cap") - b.goal.number("art_used"), 0)


def pre_approved(root):
    """The `permissions.allow` entries of the repo's .claude/settings.json: [] when the file or list is missing."""
    try:
        data = json.loads((Path(root) / ".claude" / "settings.json").read_text(encoding="utf-8"))
        allowed = data["permissions"]["allow"]
    except (OSError, ValueError, KeyError, TypeError):
        return []
    return [str(a) for a in allowed] if isinstance(allowed, list) else []


def pre_approved_note(root):
    """Prompt lines naming the pre-approved commands ('' when there are none)."""
    allowed = pre_approved(root)
    if not allowed:
        return ""
    return ("\nThese commands are pre-approved in the project settings (permissions.allow):\n"
            + "\n".join(f"  {a}" for a in allowed)
            + "\nRun them as plain, separate Bash commands: no && chains, no pipes into other programs, no heredocs, "
              "no PowerShell for them. Anything else needs an approval you can't get, and is refused.")


EDIT_TICKETS_RULE = ("Edit ticket files (result notes, QA marks, notes) only with the file editing tool (Edit or Write), "
                     "never with shell commands or scripts: the guard refuses scripts that write task files.")


def agent_prompt(b, ticket, folder):
    return f"""Work on task {ticket['id']} ("{ticket['title']}"), in its folder {folder}, on branch \
{b.places.ticket_branch(ticket)}. Its task file there is {ticket['file']}.
It is part of goal {b.gid}, which the goal runner builds without the board's review along the way
(docs/working-with-the-board.md and tasks/README.md, "Goal runs").
- Read the task file and every file in its files_to_read_first, then do what its Description says.
- Work and commit only in that folder, in small commits. Never commit to master, never merge, never push.
- Write tests for your code and run them. Write your result notes in the task file's "## Result notes".
- Don't change the task's status, qa_rounds or lead lines: the goal runner moves the task.
- {EDIT_TICKETS_RULE}
- PixelLab: this goal has {art_left(b)} generations left under its art cap. Never go over it; one round per
  task, no regenerations.
- If the permission system or a hook refuses anything, never work around it. If the action isn't essential, skip it
  and carry on; list it in refusals, and in your result notes. Set blocked to true only when the refused action was
  essential and you can't finish the task without it; then stop.{pre_approved_note(b.root)}
Answer with a short summary, the PixelLab generations you used, every refusal you met, and blocked."""


def qa_prompt(b, ticket, folder, text):
    round_no = ticket["qa_rounds"] + 1
    criteria = re.findall(r"^\s*- \[[ xX]\] .*$", text.split("## Acceptance criteria", 1)[-1].split("\n## ", 1)[0], re.M)
    return f"""QA round {round_no} for task {ticket['id']} ("{ticket['title']}"), in its folder {folder}.
Its task file there is {ticket['file']}. It is part of goal {b.gid} (tasks/README.md, "Goal runs").
Check every acceptance criterion, running the tests it names:
{chr(10).join(criteria)}
Mark each one in the task file as `(QA: pass)` or `(QA: fail: <reason>)`, and commit the task file in that folder.
Don't change the task's status, qa_rounds or lead lines: the goal runner moves the task.
{EDIT_TICKETS_RULE}
If the permission system or a hook refuses anything, never work around it. If the action isn't essential, skip that
check and carry on; list it in refusals. Set blocked to true only when the refused action was essential and you
can't finish the checks without it; then stop.{pre_approved_note(b.root)}
Answer with a short summary, every refusal you met, and blocked."""


def run_agent(b, ticket, folder):
    """The agent's answer; its `refusals` are the ones it got past (a blocked agent pauses the goal)."""
    answer = ask_headless(b, "agent", agent_prompt(b, ticket, folder), AGENT_SCHEMA, ticket["to"],
                          ticket["model"] or "sonnet", folder)
    return dict(answer.data, refusals=check_refusals(answer, f"The {ticket['to']} agent on {ticket['id']}"))


def run_qa(b, ticket, folder):
    """QA's answer; its `refusals` are the ones it got past (a blocked QA pauses the goal)."""
    text = Path(folder, ticket["file"]).read_text(encoding="utf-8")
    answer = ask_headless(b, "qa", qa_prompt(b, ticket, folder, text), QA_SCHEMA, "qa-integration", QA_MODEL, folder)
    return dict(answer.data, refusals=check_refusals(answer, f"QA on {ticket['id']}"))


# --- art and merging ---

def art_used(b, ticket):
    """PixelLab generations the ticket used: the lines its branch added to the generation log."""
    folder = b.places.ticket_folder(ticket["id"])
    diff = b.shell.git(folder, "diff", f"{b.places.goal_branch(b.gid)}...HEAD", "--", ART_LOG).stdout
    return sum(1 for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++") and l[1:].strip())


def revert_import_noise(b, folder):
    """Godot rewrites .import files with other line endings only: put those back before committing."""
    names = b.shell.git(folder, "diff", "--cached", "--name-only", "--diff-filter=M", "--", "*.import").stdout.split()
    reverted = []
    for name in names:
        if b.shell.git(folder, "diff", "--cached", "--ignore-cr-at-eol", "--quiet", "--", name,
                       check=False).returncode == 0:
            b.shell.git(folder, "checkout", "HEAD", "--", name)
            reverted.append(name)
    return reverted


def merge(b, ticket):
    """Merge the ticket's branch into playtest/<goal id> in the goal's folder (docs/working-with-the-board.md,
    "Merging"). A conflict is aborted and pauses the goal."""
    folder, branch = ensure_goal_build(b), b.places.ticket_branch(ticket)
    if merged(b, ticket):
        return False
    if b.shell.git(folder, "merge", "--no-ff", "--no-commit", branch, check=False).returncode != 0:
        b.shell.git(folder, "merge", "--abort", check=False)
        raise Pause(f"Merging {branch} into {b.places.goal_branch(b.gid)} conflicted; the merge was aborted.", "merge")
    if b.shell.git(folder, "rev-parse", "-q", "--verify", "MERGE_HEAD", check=False).returncode:
        return False                                    # nothing to merge
    revert_import_noise(b, folder)
    b.shell.git(folder, "commit", "-q", "-m", f"Merge {branch} into {b.places.goal_branch(b.gid)} (goal runner, "
                                              f"{ticket['id']} passed QA)")
    return True


# --- one ticket ---

def build_ticket(b, tid):
    """Build one ticket from wherever it stands (so a stopped run picks it up again); returns its result:
    {id, outcome: passed | flagged, status, rounds, model, art, summaries, refusals (the ones the agent and
    QA got past, to be recorded)}."""
    summaries, skipped = [], []
    while True:
        t = tickets_now(b.root)[tid]
        folder = b.places.ticket_folder(tid)
        status = t["status"]
        if status in ("open", "blocked"):
            ensure_ticket_folder(b, t)
            move(b, tid, "in-progress", reply=f"Goal runner ({b.gid}): started, in {folder}.")
            commit_ticket(b, tickets_now(b.root)[tid], f"{tid}: in progress (goal runner, {b.gid})")
        elif status == "in-progress":
            ensure_ticket_folder(b, t)
            done = run_agent(b, t, folder)
            summaries.append(done.get("summary", ""))
            skipped += [f"{t['to']}: {r}" for r in done["refusals"]]
            move(b, tid, "in-qa", reply=f"Goal runner ({b.gid}): the agent is done; QA is checking it.")
            commit_ticket(b, t, f"{tid}: in QA (goal runner, {b.gid})")
        elif status == "in-qa":
            ensure_ticket_folder(b, t)
            skipped += [f"QA: {r}" for r in run_qa(b, t, folder)["refusals"]]
            t = tickets_now(b.root)[tid]
            passed, failed, unchecked = verdicts(t["path"].read_text(encoding="utf-8"))
            if unchecked:
                raise Pause(f"QA left {len(unchecked)} criteria of {tid} unmarked.", "qa")
            if not failed:
                new = "needs-playtest" if t["review"] else "done"
                move(b, tid, new, note=f"QA passed every criterion (goal {b.gid}).",
                     reply=f"Goal runner ({b.gid}): QA passed; merged into {b.places.goal_branch(b.gid)}.")
            elif t["qa_rounds"] + 1 >= 2:
                move(b, tid, "flagged-for-review", note=f"Failed QA a second time (goal {b.gid}).",
                     reply=f"Goal runner ({b.gid}): failed QA twice; flagged for the board.")
                commit_ticket(b, t, f"{tid}: flagged for review (goal runner, {b.gid})")
                return result(b, tid, "flagged", summaries, refusals=skipped)
            else:
                why = "; ".join(re.sub(r"^\s*- \[[ xX]\] ", "", l) for l in failed)[:600]
                move(b, tid, "in-progress", note=f"QA failed: {why} Back to the agent on {RETRY_MODEL}.",
                     reply=f"Goal runner ({b.gid}): failed QA once; back to the agent on {RETRY_MODEL}.")
                path = tickets_now(b.root)[tid]["path"]
                path.write_bytes(set_field(path.read_bytes().decode("utf-8"), "model", RETRY_MODEL).encode("utf-8"))
            commit_ticket(b, t, f"{tid}: QA round {t['qa_rounds'] + 1} (goal runner, {b.gid})")
        elif status in PASSED:
            commit_ticket(b, t, f"{tid}: {status} (goal runner, {b.gid})")
            art = art_used(b, t) if folder.exists() else 0
            merge(b, t)
            return result(b, tid, "passed", summaries, art, skipped)
        elif status == "flagged-for-review":
            return result(b, tid, "flagged", summaries, refusals=skipped)
        else:
            raise Pause(f"{tid} is {status}; the goal runner doesn't build a ticket from there.", "stop")


def result(b, tid, outcome, summaries, art=None, refusals=()):
    t = tickets_now(b.root)[tid]
    if art is None:
        art = art_used(b, t) if b.places.ticket_folder(tid).exists() else 0
    return {"id": tid, "outcome": outcome, "status": t["status"], "rounds": t["qa_rounds"], "model": t["model"],
            "to": t["to"], "art": art, "summaries": [s for s in summaries if s], "refusals": list(refusals)}


# --- committing the goal's files on master ---

def commit_files(root, paths, message):
    """Commit only these files on master; refuses (prints why, returns False) during a merge or off master."""
    git = lambda *a: subprocess.run(["git", "-C", str(root), *a], capture_output=True, text=True,  # noqa: E731
                                    encoding="utf-8")
    if git("rev-parse", "-q", "--verify", "MERGE_HEAD").stdout.strip():
        print("Not committed: a merge is in progress (another session's). Commit these files later.")
        return False
    branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "master":
        print(f"Not committed: this checkout is on {branch!r}, not master.")
        return False
    rel = sorted({str(Path(p).resolve().relative_to(Path(root).resolve())) for p in paths})
    for step in (["add", "--", *rel], ["commit", "-m", message, "--", *rel]):
        done = git(*step)
        if done.returncode != 0:
            print(f"Not committed: git {step[0]} failed: {(done.stderr or done.stdout).strip()}")
            return False
    print(f"Committed on master: {message}")
    return True


def master_ticket_changes(root, ids):
    """The goal's task files on master that the status script changed (a ticket opened when what it waited
    on passed) or that are new: only these, with the goal file, are committed on master."""
    out = subprocess.run(["git", "-C", str(root), "status", "--porcelain", "--", "tasks"], capture_output=True,
                         text=True, encoding="utf-8").stdout
    paths = [Path(root) / line[3:].strip().strip('"') for line in out.splitlines() if len(line) > 3]
    return [p for p in paths if TASK_ID_RE.match(p.name) and TASK_ID_RE.match(p.name).group(0) in ids]
