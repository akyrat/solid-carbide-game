"""The mechanical part of QA, in one script (T-347; tasks/README.md, "QA").

  python tools/qa_check.py T-NNN [--root DIR] [--base master] [--no-marks] [--test-cmd "cmd"] ... [--no-tests] [--all-tests]

Run from the ticket's own folder (or give --root). It prints one line per check, PASS or FAIL, then a total line:

  tests        the test sets run and pass on the ticket's branch: the Godot set and the game/tools set always, the
               tools set (the studio's own scripts) only when the branch changes something under tools/ or .claude/
               against --base (otherwise the line says it was skipped and why); --all-tests forces all three
  documents    every file in the ticket's documents_affected changed on the branch (against --base)
  screenshots  at least one image or recording in art-archive/<id>/screenshots/ when the ticket shows anything
               (changes_visuals or user_facing_text is yes, or it has a `The board's review:` line)
  marks        every acceptance criterion carries a (QA: pass) or (QA: fail ...) mark

--no-marks leaves the marks check out (QA runs the script first, then marks the criteria, then runs it again).
The second run, after marking, checks only the marks: `--no-tests` (alias `--marks-only`) skips the test sets, so
the full sets are paid once per ticket (tasks/README.md, "Which tests run when").
--test-cmd (repeatable) replaces the default test sets; --no-tests skips them. Exit code 0 when every check
passes, 1 otherwise. The full test output is not printed, only its last lines on a failure. Judging each
acceptance criterion is still QA's job: this script only does what needs no judgment.
"""

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import taskboard_sync as tb  # noqa: E402
from task_status import verdicts  # noqa: E402

# (name, command, only_when_studio_scripts_changed)
DEFAULT_SETS = [
    ("game/tools", f'"{sys.executable}" -m unittest discover -s game/tools -p "test_*.py"', False),
    ("tools", f'"{sys.executable}" -m unittest discover -s tools -p "test_*.py"', True),
    ("godot", "bash game/tools/run_tests.sh", False),
]
STUDIO_PATHS = ("tools/", ".claude/")
MEDIA = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".mp4", ".webm"}


def ticket_file(root, tid):
    found = sorted((Path(root) / "tasks").glob(f"{tid}-*.md"))
    return found[0] if found else None


def default_tests(root, base, force=False):
    """(commands, skipped note): the tools set is left out unless the branch changes tools/ or .claude/."""
    studio = force or any(f.startswith(STUDIO_PATHS) for f in changed_files(root, base))
    cmds = [c for _, c, only in DEFAULT_SETS if studio or not only]
    skipped = "" if studio else "tools set skipped: the branch changes nothing under tools/ or .claude/"
    return cmds, skipped


def check_tests(root, tests, skipped=""):
    ok, detail = _run_tests(root, tests)
    return ok, f"{detail} ({skipped})" if ok and skipped and tests else detail


def _run_tests(root, tests):
    for n, cmd in enumerate(tests, 1):
        done = subprocess.run(cmd, cwd=str(root), shell=True, capture_output=True, text=True, encoding="utf-8",
                              errors="replace")
        if done.returncode != 0:
            tail = " | ".join((done.stdout + done.stderr).strip().splitlines()[-3:])
            return False, f"red: test set {n} of {len(tests)} (exit {done.returncode}): {tail[:300]}"
    return True, f"{len(tests)} test set(s) passed" if tests else "skipped (--no-tests)"


def changed_files(root, base):
    """Files that differ from the branch's merge-base with `base`, committed or not."""
    def git(*a):
        return subprocess.run(["git", *a], cwd=str(root), capture_output=True, text=True, encoding="utf-8")
    mb = git("merge-base", base, "HEAD")
    start = mb.stdout.strip() if mb.returncode == 0 and mb.stdout.strip() else base
    names = set(git("diff", "--name-only", start).stdout.split())
    names |= set(git("ls-files", "--others", "--exclude-standard").stdout.split())
    return names


def check_documents(root, fields, base):
    docs = [d for d in fields.get("documents_affected", []) if d]
    if not docs:
        return True, "no documents listed"
    changed = changed_files(root, base)
    missing = [d for d in docs if d not in changed]
    if missing:
        return False, f"not changed on the branch: {', '.join(missing)}"
    return True, f"{len(docs)} changed"


def shows_something(fields, text):
    yes = lambda k: str(fields.get(k, "")).strip().lower() == "yes"   # noqa: E731
    return yes("changes_visuals") or yes("user_facing_text") or bool(re.search(r"^The board's review:", text, re.M))


def check_screenshots(root, fields, text, tid):
    if not shows_something(fields, text):
        return True, "nothing to picture (ticket shows nothing)"
    folder = Path(root) / "art-archive" / tid / "screenshots"
    found = [p for p in folder.rglob("*") if p.suffix.lower() in MEDIA] if folder.exists() else []
    if not found:
        return False, f"no image or recording in art-archive/{tid}/screenshots/"
    return True, f"{len(found)} file(s) in art-archive/{tid}/screenshots/"


def check_marks(text):
    passed, failed, unchecked = verdicts(text)
    total = len(passed) + len(failed) + len(unchecked)
    if total == 0:
        return False, "the ticket has no acceptance criteria"
    if unchecked:
        return False, f"{len(unchecked)} of {total} criteria have no pass or fail mark"
    return True, f"{len(passed)} pass, {len(failed)} fail marked"


def run_checks(tid, root, base="master", marks=True, tests=None, all_tests=False):
    """[(name, ok, detail)] for the ticket in `root`."""
    path = ticket_file(root, tid)
    if path is None:
        return [("ticket", False, f"no tasks/{tid}-*.md in {root}")]
    text = path.read_text(encoding="utf-8")
    fields = tb.parse_header(text) or {}
    skipped = ""
    if tests is None:
        tests, skipped = default_tests(root, base, all_tests)
    results = [("tests", *check_tests(root, tests, skipped)),
               ("documents", *check_documents(root, fields, base)),
               ("screenshots", *check_screenshots(root, fields, text, tid))]
    if marks:
        results.append(("marks", *check_marks(text)))
    return results


def main(argv=None):
    tb.utf8_output()
    argv = sys.argv[1:] if argv is None else argv
    tid, root, base, marks, tests, no_tests, all_tests = None, Path.cwd(), "master", True, [], False, False
    it = iter(argv)
    for a in it:
        if re.fullmatch(r"T-\d+", a):
            tid = a
        elif a == "--root":
            root = Path(next(it, "."))
        elif a == "--base":
            base = next(it, "master")
        elif a == "--no-marks":
            marks = False
        elif a == "--test-cmd":
            tests.append(next(it, ""))
        elif a in ("--no-tests", "--marks-only"):
            no_tests = True
        elif a == "--all-tests":
            all_tests = True
        else:
            raise SystemExit(__doc__)
    if not tid:
        raise SystemExit(__doc__)
    results = run_checks(tid, root, base, marks, [] if no_tests else (tests or None), all_tests)
    for name, ok, detail in results:
        print(f"{'PASS' if ok else 'FAIL'} {name}: {detail}")
    bad = [n for n, ok, _ in results if not ok]
    print(f"{tid}: {'all checks pass' if not bad else 'FAILED: ' + ', '.join(bad)}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
