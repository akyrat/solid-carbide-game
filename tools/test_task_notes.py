"""Tests for task_notes.py (T-469). Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402
import task_notes as tn  # noqa: E402
import importlib.util  # noqa: E402

_spec = importlib.util.spec_from_file_location("board_gate", TOOLS.parent / ".claude" / "hooks" / "board_gate.py")
gate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate)

TICKET = """---
id: T-001
title: A test
status: in-progress
lead: Tools
qa_rounds: 0
---

## Description

Do a thing. status: not a header here.

## Acceptance criteria

- [ ] It works (QA: pass / fail)

## Updates

## Style review

## Result notes

{notes}
"""


class Notes(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.tasks = root / "tasks"
        self.tasks.mkdir()
        self.saved = (tb.TASKS_DIR, tb.task_folders)
        tb.TASKS_DIR = self.tasks
        tb.task_folders = lambda root=None: {}
        self.path = self.tasks / "T-001-test.md"

    def tearDown(self):
        tb.TASKS_DIR, tb.task_folders = self.saved
        self.tmp.cleanup()

    def put(self, notes=tb.NOTES_PLACEHOLDER, newline="\n"):
        self.path.write_bytes(TICKET.format(notes=notes).replace("\n", newline).encode("utf-8"))

    def text(self):
        return self.path.read_bytes().decode("utf-8")

    def test_appends_to_result_notes_and_nothing_else_changes(self):
        self.put()
        before = self.text()
        tn.run("T-001", "Built it.\n- one\n- two")
        after = self.text()
        cut = before.index("## Result notes")
        self.assertEqual(after[:cut], before[:cut])   # header and every other section, byte for byte
        self.assertEqual(after[cut:], "## Result notes\n\nBuilt it.\n- one\n- two\n")

    def test_second_append_keeps_the_first(self):
        self.put()
        tn.run("T-001", "First.")
        tn.run("T-001", "Second.")
        self.assertTrue(self.text().endswith("## Result notes\n\nFirst.\n\nSecond.\n"))

    def test_existing_notes_are_kept(self):
        self.put(notes="Old note.")
        tn.run("T-001", "New.")
        self.assertTrue(self.text().endswith("Old note.\n\nNew.\n"))

    def test_text_that_looks_like_a_header_line_stays_in_the_notes(self):
        self.put()
        before = self.text()
        tn.run("T-001", "status: done\nqa_rounds: 2")
        after = self.text()
        self.assertEqual(ts.header(self.path)["status"], "in-progress")
        self.assertEqual(ts.header(self.path)["qa_rounds"], "0")
        self.assertEqual(after.split("## Result notes")[0], before.split("## Result notes")[0])

    def test_section_after_result_notes_is_untouched(self):
        self.put(notes="Notes.\n\n## Later\n\nOther.")
        tn.run("T-001", "Added.")
        self.assertTrue(self.text().endswith("Notes.\n\nAdded.\n\n## Later\n\nOther.\n"))

    def test_crlf_files_stay_crlf(self):
        self.put(newline="\r\n")
        tn.run("T-001", "Line one\nLine two")
        raw = self.text()
        self.assertNotIn("\r\r", raw)
        self.assertEqual(raw.count("\n"), raw.count("\r\n"))
        self.assertIn("Line one\r\nLine two\r\n", raw)

    def test_missing_ticket_is_refused(self):
        with self.assertRaises(ts.Refused):
            tn.run("T-999", "x")

    def test_missing_section_is_refused_and_file_unchanged(self):
        self.path.write_text("---\nid: T-001\nstatus: open\n---\n\n## Description\n\nx\n", encoding="utf-8")
        before = self.text()
        with self.assertRaises(ts.Refused):
            tn.run("T-001", "x")
        self.assertEqual(self.text(), before)

    def test_empty_text_is_refused(self):
        self.put()
        with self.assertRaises(ts.Refused):
            tn.run("T-001", "  \n")

    def test_finds_the_ticket_in_its_branch_folder(self):
        self.put()
        branch = Path(self.tmp.name) / "wt"
        (branch / "tasks").mkdir(parents=True)
        (branch / "tasks" / "T-001-test.md").write_text(TICKET.format(notes=tb.NOTES_PLACEHOLDER), encoding="utf-8")
        main_before = self.text()
        tn.run("T-001", "On the branch.", folders={"T-001": branch})
        self.assertEqual(self.text(), main_before)
        self.assertIn("On the branch.", (branch / "tasks" / "T-001-test.md").read_text(encoding="utf-8"))

    def test_cli(self):
        self.put()
        f = Path(self.tmp.name) / "r.md"
        f.write_text("From file.\n", encoding="utf-8")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(tn.main(["T-001", "--append", str(f)]), 0)
            self.assertEqual(tn.main(["T-001", "--text", "From text."]), 0)
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            self.assertEqual(tn.main(["T-001", "--append", str(f) + ".missing"]), 1)
            self.assertEqual(tn.main(["T-777", "--text", "x"]), 1)
            self.assertEqual(tn.main(["bogus", "--text", "x"]), 2)
        self.assertTrue(self.text().endswith("From file.\n\nFrom text.\n"))


class GuardLetsItThrough(unittest.TestCase):
    """The command guard (.claude/hooks/board_gate.py) allows the script as it is, with no change (T-469)."""

    def denied(self, command):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            gate.pre_shell({"command": command})
        return '"deny"' in buf.getvalue()

    def test_calls_pass(self):
        for c in ('python C:/solid-carbide-game/tools/task_notes.py T-469 --append report.md',
                  'python tools/task_notes.py T-469 --text "Built it. Tests 10/10."',
                  'python tools/task_notes.py T-469 --text "the status: done line"'):
            self.assertFalse(self.denied(c), c)


if __name__ == "__main__":
    unittest.main()
