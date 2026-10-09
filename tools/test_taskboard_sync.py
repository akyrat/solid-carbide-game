"""Tests for taskboard_sync.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import taskboard_sync as tb  # noqa: E402

TASK = """---
id: T-900
title: A test task
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012, T-029]
documents_affected: []
files_to_read_first: [tasks/README.md]
files_expected_to_change: []
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
-->

## Description

Body text with status: in words.
"""


class TaskboardSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tasks = Path(self.tmp.name) / "tasks"
        self.tasks.mkdir()
        (self.tasks / "T-900-test.md").write_text(TASK.replace("\n", "\r\n"), encoding="utf-8", newline="")

    def tearDown(self):
        self.tmp.cleanup()

    def test_export_reads_the_header_with_lists(self):
        out = Path(self.tmp.name) / "out"
        tickets = tb.export(out, self.tasks)
        self.assertEqual(len(tickets), 1)
        doc = json.loads((out / "T-900.json").read_text(encoding="utf-8"))
        self.assertEqual(doc["status"], "blocked")
        self.assertEqual(doc["depends_on"], ["T-012", "T-029"])
        self.assertEqual(doc["file"], "tasks/T-900-test.md")
        self.assertEqual(doc["file_status"], "blocked")
        self.assertTrue((out / "_meta.json").exists())

    def test_export_reads_the_review_and_result_notes(self):
        body = ("Body.\n\nThe board's review: drive it and judge the feel.\n"
                "Board review files: [game/README.md, docs/drifting.md]\n\n## Result notes\n\nIt works.\n")
        (self.tasks / "T-900-test.md").write_text(TASK.replace("Body text with status: in words.\n", body), encoding="utf-8")
        doc = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual(doc["review"], "drive it and judge the feel.")
        self.assertEqual(doc["review_files"], ["game/README.md", "docs/drifting.md"])
        self.assertEqual(doc["result_notes"], "It works.")
        self.assertEqual(doc["qa_rounds"], 0)

    def test_export_prefers_the_task_branch_folder(self):
        worktrees = Path(self.tmp.name) / "worktrees"
        (worktrees / "T-900" / "tasks").mkdir(parents=True)
        (worktrees / "T-900" / "tasks" / "T-900-test.md").write_text(TASK.replace("status: blocked", "status: in-qa"), encoding="utf-8")
        out = Path(self.tmp.name) / "out"
        tb.export(out, self.tasks, worktrees)
        doc = json.loads((out / "T-900.json").read_text(encoding="utf-8"))
        self.assertEqual(doc["status"], "in-qa")
        self.assertTrue(doc["folder"].endswith("T-900"))

    def test_apply_changes_only_the_header_status_and_keeps_crlf(self):
        changed = tb.apply_moves([{"id": "T-900", "status": "in-progress"}], self.tasks)
        self.assertEqual(changed, [("T-900", "blocked", "in-progress")])
        raw = (self.tasks / "T-900-test.md").read_bytes().decode("utf-8")
        self.assertIn("status: in-progress\r\n", raw)
        self.assertIn("status: open | in-progress", raw)   # the comment line is untouched
        self.assertNotIn("\n\n\n", raw.replace("\r\n", "\n").split("## Description")[0][-3:])
        self.assertEqual(raw.count("\r\n"), raw.count("\n"))

    def test_apply_skips_unchanged_and_rejects_unknown_status(self):
        self.assertEqual(tb.apply_moves([{"id": "T-900", "status": "blocked"}], self.tasks), [])
        with self.assertRaises(ValueError):
            tb.apply_moves([{"id": "T-900", "status": "finished"}], self.tasks)

    def test_real_task_files_all_parse(self):
        for path in tb.task_files():
            self.assertIsNotNone(tb.ticket(path), path.name)


if __name__ == "__main__":
    unittest.main()
