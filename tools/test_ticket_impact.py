"""Tests for ticket_impact.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ticket_impact as ti  # noqa: E402


def t(status, deps=(), milestone="mvp"):
    return {"status": status, "depends_on": list(deps), "milestone": milestone, "title": "", "to": ""}


class ImpactTests(unittest.TestCase):
    def test_counts_direct_and_chained_dependents(self):
        tickets = {"A": t("open"), "B": t("blocked", ["A"]), "C": t("blocked", ["B"]), "D": t("blocked", ["A", "B"])}
        rows = {r[0]: r for r in ti.impact(tickets)}
        self.assertEqual((rows["A"][4], rows["A"][5]), (2, 3))   # B and D directly; C through B
        self.assertEqual((rows["B"][4], rows["B"][5]), (2, 2))
        self.assertEqual(ti.impact(tickets)[0][0], "A")

    def test_finished_and_later_tickets_are_left_out(self):
        tickets = {"A": t("done"), "B": t("open", ["A"]), "C": t("blocked", ["B"], "final-release"), "X": t("cancelled", ["B"])}
        rows = {r[0]: r for r in ti.impact(tickets)}
        self.assertNotIn("A", rows)
        self.assertEqual(rows["B"][5], 0)          # C is final release, X is cancelled
        self.assertEqual({r[0]: r for r in ti.impact(tickets, mvp_only=False)}["B"][5], 1)

    def test_real_task_files_load(self):
        self.assertGreater(len(ti.impact(ti.load())), 0)


if __name__ == "__main__":
    unittest.main()
