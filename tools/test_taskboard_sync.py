"""Tests for taskboard_sync.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import sys
import tempfile
import unittest
from unittest import mock
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

    def test_ticket_reads_the_header_with_lists(self):
        doc = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual(doc["status"], "blocked")
        self.assertEqual(doc["depends_on"], ["T-012", "T-029"])
        self.assertEqual(doc["file"], "tasks/T-900-test.md")
        self.assertEqual(doc["file_status"], "blocked")

    def test_ticket_reads_the_review_and_result_notes(self):
        body = ("Body.\n\nThe board's review: drive it and judge the feel.\n"
                "Board review files: [game/README.md, docs/drifting.md]\n\n## Result notes\n\nIt works.\n")
        (self.tasks / "T-900-test.md").write_text(TASK.replace("Body text with status: in words.\n", body), encoding="utf-8")
        doc = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual(doc["review"], "drive it and judge the feel.")
        self.assertEqual(doc["review_files"], ["game/README.md", "docs/drifting.md"])
        self.assertEqual(doc["result_notes"], "It works.")
        self.assertEqual(doc["qa_rounds"], 0)

    def test_tickets_now_prefers_the_task_branch_folder(self):
        folder = Path(self.tmp.name) / "worktrees" / "T-900"
        (folder / "tasks").mkdir(parents=True)
        (folder / "tasks" / "T-900-test.md").write_text(TASK.replace("status: blocked", "status: in-qa"), encoding="utf-8")
        tickets = tb.tickets_now(self.tasks, {"T-900": folder})
        self.assertEqual(len(tickets), 1)
        self.assertEqual(tickets[0]["status"], "in-qa")
        self.assertTrue(tickets[0]["folder"].endswith("T-900"))

    def test_tickets_now_reads_master_without_a_branch(self):
        tickets = tb.tickets_now(self.tasks, {})
        self.assertEqual([t["status"] for t in tickets], ["blocked"])

    def run_task_folders_as(self, os_name):
        done = mock.Mock(stdout="worktree C:/w/T-900\nbranch refs/heads/task/T-900-test\n")
        with mock.patch.object(tb.os, "name", os_name), mock.patch.object(tb.subprocess, "run", return_value=done) as run:
            folders = tb.task_folders()
        return folders, run.call_args.kwargs.get("creationflags")

    def test_task_folders_opens_no_window_on_windows(self):
        # The board's server has no console; without this flag git opens a terminal window on every refresh (T-110).
        folders, flags = self.run_task_folders_as("nt")
        self.assertEqual(flags, 0x08000000)
        self.assertEqual(folders, {"T-900": Path("C:/w/T-900")})

    def test_task_folders_passes_no_flags_elsewhere(self):
        _, flags = self.run_task_folders_as("posix")
        self.assertEqual(flags, 0)

    def test_real_task_files_all_parse(self):
        for path in tb.task_files():
            self.assertIsNotNone(tb.ticket(path), path.name)


if __name__ == "__main__":
    unittest.main()
