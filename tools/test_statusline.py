"""Tests for statusline.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import statusline  # noqa: E402


class StatuslineTests(unittest.TestCase):
    def test_overall_is_the_average_and_lowest_docs_are_listed(self):
        line = statusline.render({"docs": {"A": 100, "B": 50, "C": 0}})
        self.assertTrue(line.startswith("MVP docs 50% "))
        self.assertIn("lowest: C 0% · B 50%", line)

    def test_bar_width_and_rounding(self):
        self.assertEqual(statusline.bar(0), "░" * 10)
        self.assertEqual(statusline.bar(100), "▓" * 10)
        self.assertEqual(statusline.bar(43), "▓" * 4 + "░" * 6)

    def test_empty_data_gives_a_notice(self):
        self.assertEqual(statusline.render({}), "MVP docs: no readiness data")

    def test_real_file_is_valid(self):
        data = json.loads(statusline.READINESS.read_text(encoding="utf-8"))
        self.assertEqual(len(data["docs"]), 8)
        for pct in data["docs"].values():
            self.assertTrue(0 <= pct <= 100)


if __name__ == "__main__":
    unittest.main()
