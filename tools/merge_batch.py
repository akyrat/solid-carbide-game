"""Merge a batch of finished tickets into master, one by one, printing one line each (T-344).

Does what docs/working-with-the-board.md, "Merging (Project Lead)" lists, for each ticket in turn:
no merge in progress, mark the task done on its branch (task_status.py), merge --no-ff --no-commit and
check it happened, revert Godot's line-ending-only .import noise, regenerate the long GDD and the short GDD's
fingerprint, run the three test sets, add the timeline entry, commit only the merge's own files, remove the
worktree and the branch.

Usage, from the repo root (the Project Lead's checkout on master):

  python tools/merge_batch.py T-101 T-102 --note T-101="review note" --title T-101="Timeline title"
      --entry T-101="Decision or change text" --docs T-101="a.md, b.md"
      [--log FILE] [--root DIR] [--test-cmd "cmd"] ... [--no-tests]

--note goes to task_status.py done. --title, --entry and --docs make the timeline entry (title defaults to the
ticket's title, docs to the docs/ files the merge changed). --test-cmd (repeatable) replaces the three default
test sets; --no-tests skips them. Full output goes to the log file (default .board/merge_batch-<time>.log); the
last line printed names it.

A ticket that can't be merged is stopped cleanly: a merge in progress, a dirty file it needs, a conflict, a red
test. The merge is undone, master is as it was, the reason is printed, and the next ticket is tried only if
master is clean. A worktree that can't be removed (Godot has it open) leaves the merge committed and is reported.
A ticket already marked done on its branch (QA does that) skips the status step. *.import and *.uid files the
branch added, which master does not track, are dropped from the branch first and left out of the merge; the
ticket's line says so (T-347).
Exit code 0 when every ticket merged, 1 otherwise.
"""

import re
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_TESTS = [
    f'"{sys.executable}" -m unittest discover -s game/tools -p "test_*.py"',
    f'"{sys.executable}" -m unittest discover -s tools -p "test_*.py"',
    "bash game/tools/run_tests.sh",
]
GENERATED = (".import", ".uid")   # Godot writes these; a branch that added any leaves them out of the merge (T-347)
SHARED = ["docs/long-gdd.md", "docs/short-gdd/README.md", "docs/timeline.md"]


class Stop(Exception):
    pass


class Runner:
    def __init__(self, root, log):
        self.root, self.log = Path(root), Path(log)
        self.log.parent.mkdir(parents=True, exist_ok=True)

    def run(self, args, cwd=None, shell=False, check=False):
        shown = args if isinstance(args, str) else " ".join(args)
        done = subprocess.run(args, cwd=str(cwd or self.root), capture_output=True, text=True, encoding="utf-8",
                              errors="replace", shell=shell)
        with self.log.open("a", encoding="utf-8") as f:
            f.write(f"\n$ {shown}   (in {cwd or self.root})\n{done.stdout}{done.stderr}[exit {done.returncode}]\n")
        if check and done.returncode != 0:
            raise Stop(f"{shown} failed: {(done.stderr or done.stdout).strip()[-200:]}")
        return done

    def git(self, *args, cwd=None, check=False):
        return self.run(["git", *args], cwd=cwd, check=check)

    def out(self, *args, cwd=None):
        return self.git(*args, cwd=cwd).stdout


def merge_in_progress(r):
    return r.git("rev-parse", "-q", "--verify", "MERGE_HEAD").returncode == 0


def modified(r, cwd=None):
    """Tracked files with changes in the working tree or the index."""
    names = set()
    for line in r.out("status", "--porcelain", "--untracked-files=no", cwd=cwd).splitlines():
        names.add(line[3:].split(" -> ")[-1].strip('"'))
    return names


def revert_import_noise(r, cwd=None):
    """Revert .import files whose only change is line endings (never staged ones: those are the merge's)."""
    for name in sorted(modified(r, cwd)):
        if name.endswith(".import") and not r.out("diff", "--cached", "--name-only", "--", name, cwd=cwd).strip():
            if r.git("diff", "--ignore-cr-at-eol", "--quiet", "--", name, cwd=cwd).returncode == 0:
                r.git("checkout", "--", name, cwd=cwd)


def find_branch(r, tid):
    out = r.out("branch", "--list", f"task/{tid}-*", "--format=%(refname:short)").split()
    if len(out) != 1:
        raise Stop(f"expected one branch task/{tid}-*, found {len(out)}")
    return out[0]


def find_worktree(r, branch):
    path = None
    for line in r.out("worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            path = Path(line[9:])
        if line.strip() == f"branch refs/heads/{branch}":
            return path
    return None


def ticket_title(r, tid):
    for p in sorted((r.root / "tasks").glob(f"{tid}-*.md")):
        m = re.search(r"^title:\s*(.+)$", p.read_text(encoding="utf-8"), re.M)
        if m:
            return m.group(1).strip()
    return tid


def ticket_status(r, branch, tid):
    """The ticket's status line on its branch ("" if not found)."""
    for name in r.out("ls-tree", "--name-only", branch, "--", "tasks/").splitlines():
        if re.fullmatch(rf"tasks/{tid}-.*\.md", name):
            m = re.search(r"^status:\s*(\S+)", r.out("show", f"{branch}:{name}"), re.M)
            return m.group(1) if m else ""
    return ""


def generated_added(r, branch):
    """Godot-generated files (*.import, *.uid) the branch added that master does not track."""
    names = r.out("diff", "--name-only", "--diff-filter=A", f"HEAD...{branch}").splitlines()
    return [n for n in names if n.endswith(GENERATED)]


def undo(r, extra):
    """Back to how master was: abort the merge, restore the files this script regenerated or wrote."""
    if merge_in_progress(r):
        if r.git("merge", "--abort").returncode != 0:
            r.git("reset", "--merge")
    existing = [p for p in extra if r.git("cat-file", "-e", f"HEAD:{p}").returncode == 0]
    if existing:
        r.git("checkout", "HEAD", "--", *existing)


def merge_one(r, tid, opts, tests):
    root = r.root
    if merge_in_progress(r):
        raise Stop("a merge is already in progress on master (another instance's?); not touching it")
    revert_import_noise(r)
    if r.out("diff", "--cached", "--name-only").strip():
        raise Stop("master has staged changes; not starting")
    dirty = [p for p in SHARED if p in modified(r)]
    if dirty:
        raise Stop(f"master has uncommitted changes in {', '.join(dirty)}")
    branch = find_branch(r, tid)
    wt = find_worktree(r, branch)
    tasks_dirty_before = {p for p in modified(r) if p.startswith("tasks/")}
    title = opts["title"].get(tid) or ticket_title(r, tid)
    # 0. Godot-generated files the branch added are left out of the merge
    left_out = generated_added(r, branch)
    if left_out and wt:
        r.git("rm", "-q", "--cached", "--ignore-unmatch", "--", *left_out, cwd=wt, check=True)
        r.git("commit", "-q", "-m", f"{tid}: drop Godot-generated files swept into the branch", cwd=wt, check=True)
        for n in left_out:
            (wt / n).unlink(missing_ok=True)
    # 1. mark done on the branch (and commit that there); a ticket QA already marked done keeps its status
    already_done = ticket_status(r, branch, tid) == "done"
    if not already_done:
        cmd = [sys.executable, str(root / "tools" / "task_status.py"), tid, "done"]
        if tid in opts["note"]:
            cmd += ["--note", opts["note"][tid]]
        done = r.run(cmd)
        if done.returncode != 0:
            raise Stop(f"task_status refused: {(done.stderr or done.stdout).strip()[:200]}")
    prev = marked = None
    if wt and not already_done:
        files = [p for p in modified(r, cwd=wt) if p.startswith("tasks/")]
        if files:
            prev = r.out("rev-parse", "HEAD", cwd=wt).strip()
            r.git("add", "--", *files, cwd=wt, check=True)
            r.git("commit", "-q", "-m", f"{tid}: marked done", cwd=wt, check=True)
            marked = r.out("rev-parse", "HEAD", cwd=wt).strip()

    def unmark():
        """A stopped ticket must not stay done on its branch: drop our own done commit if it is still the tip."""
        if marked and r.out("rev-parse", "HEAD", cwd=wt).strip() == marked:
            r.git("reset", "-q", "--keep", prev, cwd=wt)
    tasks_touched = sorted({p for p in modified(r) if p.startswith("tasks/")} - tasks_dirty_before)
    written = list(SHARED) + tasks_touched
    try:
        # 2. merge, checked
        if merge_in_progress(r):
            raise Stop("a merge appeared on master; not committing")
        m = r.git("merge", "--no-ff", "--no-commit", branch)
        if m.returncode != 0:
            conflicts = r.out("diff", "--name-only", "--diff-filter=U").split()
            raise Stop(f"merge conflict in {', '.join(conflicts) or 'unknown files'}; merge undone, master clean")
        if not merge_in_progress(r):
            raise Stop("nothing to merge (branch already in master)")
        if left_out and not wt:   # no worktree to edit: unstage what the merge brought in
            for n in left_out:
                r.git("rm", "-q", "-f", "--cached", "--ignore-unmatch", "--", n)
                (root / n).unlink(missing_ok=True)
        revert_import_noise(r)
        staged = [p for p in r.out("diff", "--cached", "--name-only").splitlines() if p]
        # 3. regenerate the long GDD and the short GDD's fingerprint
        for script in ("generate_long_gdd.py", "update_short_gdd_fingerprint.py"):
            r.run([sys.executable, str(root / "tools" / script)], check=True)
        # 4. tests
        for t in tests:
            if r.run(t, shell=True).returncode != 0:
                raise Stop(f"test failed: {t}; merge undone, master clean")
        # 5. timeline entry
        docs = opts["docs"].get(tid) or ", ".join(f"`{p}`" for p in staged if p.startswith("docs/")) or "none"
        entry = opts["entry"].get(tid) or f"merged {tid} ({title})."
        tl = root / "docs" / "timeline.md"
        text = tl.read_text(encoding="utf-8").rstrip("\n")
        tl.write_text(f"{text}\n\n## {date.today().isoformat()}: {title}\n- Decision or change: {entry}\n"
                      f"- Documents touched: {docs}\n- Tasks: {tid}\n", encoding="utf-8")
        # 6. commit: only what the merge changed, plus the files written above
        r.git("add", "--", *[p for p in written if (root / p).exists()], check=True)
        if not merge_in_progress(r):
            raise Stop("the merge disappeared before the commit")
        c = r.git("commit", "-q", "-m", f"{tid}: {title}\n\nCo-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>")
        if c.returncode != 0:
            raise Stop(f"commit failed: {(c.stderr or c.stdout).strip()[:200]}")
    except Stop:
        undo(r, written)
        unmark()
        raise
    except Exception as e:   # never leave a half merge behind
        undo(r, written)
        unmark()
        raise Stop(f"unexpected error: {e}; merge undone")
    # 7. remove the worktree and branch
    note = ""
    if wt and wt.exists():
        revert_import_noise(r, cwd=wt)
        rm = r.git("worktree", "remove", str(wt))
        if rm.returncode != 0:
            note = f" (worktree {wt} not removed, close Godot and remove it by hand; branch kept)"
    if not note:
        if r.git("branch", "-d", branch).returncode != 0:
            note = f" (branch {branch} not deleted)"
    extras = ""
    if already_done:
        extras += " (already done)"
    if left_out:
        extras += f" (left out {len(left_out)} Godot-generated .import/.uid files the branch added)"
    return f"merged{extras}{note}"


def parse(argv):
    opts = {"note": {}, "title": {}, "entry": {}, "docs": {}}
    tickets, tests, root, log, no_tests = [], [], None, None, False
    it = iter(argv)
    for a in it:
        if a in ("--note", "--title", "--entry", "--docs"):
            k, _, v = next(it, "").partition("=")
            if not re.fullmatch(r"T-\d+", k) or not v:
                raise SystemExit(f"{a} needs T-NNN=text")
            opts[a[2:]][k] = v
        elif a == "--test-cmd":
            tests.append(next(it, ""))
        elif a == "--no-tests":
            no_tests = True
        elif a == "--log":
            log = next(it, None)
        elif a == "--root":
            root = next(it, None)
        elif re.fullmatch(r"T-\d+", a):
            tickets.append(a)
        else:
            raise SystemExit(__doc__)
    if not tickets:
        raise SystemExit(__doc__)
    return tickets, opts, (tests or ([] if no_tests else DEFAULT_TESTS)), root, log


def safe_output():
    """A cp1252 console can't print task_status's arrow: write UTF-8, replacing what still can't be written (T-425)."""
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")


def main(argv=None):
    safe_output()
    tickets, opts, tests, root, log = parse(sys.argv[1:] if argv is None else argv)
    root = Path(root) if root else HERE.parent
    log = Path(log) if log else root / ".board" / f"merge_batch-{datetime.now():%Y%m%d-%H%M%S}.log"
    r = Runner(root, log)
    failed = False
    for tid in tickets:
        try:
            line = merge_one(r, tid, opts, tests)
        except Stop as e:
            failed = True
            line = f"stopped: {e}"
        print(f"{tid}: {line}", flush=True)
        if failed and (merge_in_progress(r) or r.out("diff", "--cached", "--name-only").strip()):
            print("master is not clean; stopping the batch.", flush=True)
            break
    print(f"Full log: {log}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
