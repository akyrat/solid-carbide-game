"""Tests for the goal file (goal_file.py): byte-identical round trips, every field and section, ids."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from goal_agent import goal_file  # noqa: E402
from goal_agent.goal_file import GoalFile  # noqa: E402

ODD = ("---\nid: G-007\ntitle: Odd: spacing  kept\nstatus: planned\nart_cap:   3\nart_used: 0\niteration: 0\n"
       "max_iterations: 10\ncreated: 2026-10-18\nlead: Goal-G-007\nextra: kept too\n---\n\nA preamble line.\n"
       "## Goal\nNo blank line after the heading.\n\n\n## Sub-goals  \n\n| rank | id |\n|---|---|\n| 1 | S1 |\n"
       "## Pauses\n\n- none, and no newline at the end")


class RoundTrip(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def roundtrip(self, raw):
        path = self.dir / "G-007-odd.md"
        path.write_bytes(raw)
        GoalFile.load(path).save()
        self.assertEqual(path.read_bytes(), raw)

    def test_hand_written_file_is_byte_identical(self):
        self.roundtrip(ODD.encode("utf-8"))

    def test_crlf_file_is_byte_identical(self):
        self.roundtrip(ODD.replace("\n", "\r\n").encode("utf-8"))

    def test_new_file_is_byte_identical_and_complete(self):
        goal = goal_file.new(self.dir, "The trick system with its final art", art_cap=20, max_iterations=6,
                             day="2026-10-18")
        goal.set_section("Sub-goals", goal_file.table([{"rank": 1, "id": "S1", "title": "A | B", "score": "s",
                                                        "why": "w", "verdict": "missing", "tickets": "T-200"}]))
        goal.log("planned.", day="2026-10-18")
        goal.save()
        raw = goal.path.read_bytes()
        self.roundtrip_path(goal.path, raw)
        again = GoalFile.load(goal.path)
        for key in goal_file.FIELDS:
            self.assertIsNotNone(again.get(key), key)
        self.assertEqual([n for n, _ in again.sections], goal_file.SECTIONS)
        self.assertEqual(again.get("lead"), "Goal-G-001")
        self.assertEqual(again.get("art_cap"), "20")
        self.assertEqual(again.section("Goal"), "The trick system with its final art")
        self.assertEqual(goal_file.read_table(again.section("Sub-goals"))[0]["title"], "A / B")
        self.assertEqual(goal.path.name, "G-001-the-trick-system-with-its.md")

    def roundtrip_path(self, path, raw):
        GoalFile.load(path).save()
        self.assertEqual(path.read_bytes(), raw)

    def test_changing_one_field_leaves_the_rest(self):
        path = self.dir / "G-007-odd.md"
        path.write_bytes(ODD.encode("utf-8"))
        goal = GoalFile.load(path)
        goal.set("status", "paused")
        goal.save()
        self.assertEqual(path.read_text(encoding="utf-8"), ODD.replace("status: planned", "status: paused"))

    def test_pause_writes_the_reason(self):
        goal = goal_file.new(self.dir, "g", day="2026-10-18")
        goal.pause("refused twice", day="2026-10-18")
        self.assertEqual(goal.get("status"), "paused")
        self.assertEqual(goal.section("Pauses"), "- 2026-10-18: refused twice")
        self.assertIn("paused", goal.section("Iteration log"))

    def test_next_id(self):
        self.assertEqual(goal_file.next_id(self.dir), "G-001")
        (self.dir / "G-001-a.md").write_text("x")
        (self.dir / "G-012-b.md").write_text("x")
        (self.dir / "README.md").write_text("x")
        self.assertEqual(goal_file.next_id(self.dir), "G-013")


if __name__ == "__main__":
    unittest.main()
