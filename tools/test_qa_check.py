"""Tests for tools/qa_check.py, on throwaway repos only."""

import contextlib
import io
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent / "goal_agent"))
import qa_check  # noqa: E402
import temp_repo  # noqa: E402

PASS = f'"{sys.executable}" -c "import sys; sys.exit(0)"'
FAIL = f'"{sys.executable}" -c "import sys; sys.exit(1)"'

TICKET = """---
id: T-950
title: A ticket
status: in-qa
from: project-lead
to: ui
lead:
epic: tooling
milestone: mvp
user_facing_text: {text}
changes_visuals: {visuals}
depends_on: []
documents_affected: [{docs}]
model: sonnet
qa_rounds: 0
---

## Description

A ticket.

## Acceptance criteria

{criteria}

## Result notes

Done.
"""


class QaCheckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = temp_repo.make(Path(self.tmp.name) / "repo")

    def write_ticket(self, text="no", visuals="no", docs="docs/sample.md",
                     criteria="- [x] It works (QA: pass)\n- [ ] It holds (QA: fail: code - broken)"):
        path = self.root / "tasks" / "T-950-ticket.md"
        path.write_bytes(TICKET.format(text=text, visuals=visuals, docs=docs, criteria=criteria).encode("utf-8"))

    def on_branch(self, changes=None):
        temp_repo.git(self.root, "checkout", "-q", "-b", "task/T-950-ticket")
        for rel, body in (changes or {}).items():
            p = self.root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(body.encode("utf-8"))
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "work", "--allow-empty")

    def results(self, tests=(PASS,), **kw):
        return {n: (ok, d) for n, ok, d in qa_check.run_checks("T-950", self.root, tests=None if tests is None else list(tests), **kw)}

    def test_everything_in_order_passes_with_one_line_each(self):
        self.write_ticket()
        self.on_branch({"docs/sample.md": "changed\n"})
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = qa_check.main(["T-950", "--root", str(self.root), "--test-cmd", PASS])
        lines = out.getvalue().splitlines()
        self.assertEqual(code, 0, lines)
        self.assertEqual([l.split(":")[0] for l in lines[:4]],
                         ["PASS tests", "PASS documents", "PASS screenshots", "PASS marks"])
        self.assertEqual(lines[-1], "T-950: all checks pass")

    def test_a_red_test_fails(self):
        self.write_ticket()
        self.on_branch({"docs/sample.md": "changed\n"})
        r = self.results(tests=(PASS, FAIL))
        self.assertFalse(r["tests"][0])
        self.assertTrue(r["documents"][0])
        self.assertIn("test set 2 of 2", r["tests"][1])
        with contextlib.redirect_stdout(io.StringIO()):
            code = qa_check.main(["T-950", "--root", str(self.root), "--test-cmd", FAIL])
        self.assertEqual(code, 1)

    def test_an_unchanged_affected_document_fails(self):
        self.write_ticket(docs="docs/sample.md, tasks/README.md")
        self.on_branch({"docs/sample.md": "changed\n"})
        ok, detail = self.results()["documents"]
        self.assertFalse(ok)
        self.assertIn("tasks/README.md", detail)
        self.assertNotIn("docs/sample.md", detail)

    def test_missing_screenshots_fail_only_when_the_ticket_shows_something(self):
        self.write_ticket(visuals="yes")
        self.on_branch({"docs/sample.md": "changed\n"})
        self.assertFalse(self.results()["screenshots"][0])
        self.write_ticket(visuals="no", text="no")
        self.assertTrue(self.results()["screenshots"][0])
        self.write_ticket(text="yes")
        self.assertFalse(self.results()["screenshots"][0])
        shot = self.root / "art-archive" / "T-950" / "screenshots" / "a.png"
        shot.parent.mkdir(parents=True)
        shot.write_bytes(b"png")
        self.assertTrue(self.results()["screenshots"][0])

    def test_an_unmarked_criterion_fails_and_no_marks_leaves_the_check_out(self):
        self.write_ticket(criteria="- [x] It works (QA: pass)\n- [ ] It holds (QA: pass / fail)")
        self.on_branch({"docs/sample.md": "changed\n"})
        ok, detail = self.results()["marks"]
        self.assertFalse(ok)
        self.assertIn("1 of 2", detail)
        self.assertNotIn("marks", self.results(marks=False))

    def test_a_ticket_without_criteria_fails_the_marks_check(self):
        self.write_ticket(criteria="(none)")
        self.on_branch({"docs/sample.md": "changed\n"})
        self.assertFalse(self.results()["marks"][0])

    def fresh_repo(self):
        self.tmp.cleanup()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = temp_repo.make(Path(self.tmp.name) / "repo")

    def ran_sets(self, changes, **kw):
        """Which default sets ran (their commands leave a mark), and the tests line."""
        self.write_ticket()
        self.on_branch(changes)
        log = Path(self.tmp.name) / "ran.txt"
        mark = lambda n: f'"{sys.executable}" -c "open(r\'{log}\', \'a\').write(\'{n} \')"'   # noqa: E731
        sets = [("game/tools", mark("game"), False), ("tools", mark("tools"), True), ("godot", mark("godot"), False)]
        with mock.patch.object(qa_check, "DEFAULT_SETS", sets):
            line = self.results(tests=None, **kw)["tests"]
        return (log.read_text().split() if log.exists() else []), line

    def test_the_tools_set_is_skipped_unless_tools_or_claude_change(self):
        ran, (ok, detail) = self.ran_sets({"docs/sample.md": "changed\n"})
        self.assertEqual(ran, ["game", "godot"])
        self.assertTrue(ok)
        self.assertIn("tools set skipped", detail)

    def test_the_tools_set_runs_when_tools_or_claude_change(self):
        for rel in ("tools/x.py", ".claude/agents/a.md"):
            self.fresh_repo()
            ran, (ok, detail) = self.ran_sets({rel: "x\n"})
            self.assertEqual(ran, ["game", "tools", "godot"], rel)
            self.assertNotIn("skipped", detail)

    def test_the_force_flag_runs_all_three_sets(self):
        ran, (ok, detail) = self.ran_sets({"docs/sample.md": "changed\n"}, all_tests=True)
        self.assertEqual(ran, ["game", "tools", "godot"])
        self.assertNotIn("skipped", detail)

    def test_marks_only_skips_the_tests_and_the_usage_says_so(self):
        self.assertIn("--marks-only", qa_check.__doc__)
        self.assertIn("--all-tests", qa_check.__doc__)
        self.write_ticket(criteria="- [x] It works (QA: pass)")
        self.on_branch({"docs/sample.md": "changed\n"})
        for flag in ("--no-tests", "--marks-only"):
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                code = qa_check.main(["T-950", "--root", str(self.root), flag])
            self.assertEqual(code, 0, out.getvalue())
            self.assertIn("skipped (--no-tests)", out.getvalue())


if __name__ == "__main__":
    unittest.main()
