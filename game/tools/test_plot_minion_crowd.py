"""Tests for plot_minion_crowd.py (task T-538): the summary of the rounds and the plot file."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import plot_minion_crowd as pmc  # noqa: E402

HEADER = "label,count,headless,frame_avg_ms,frame_median_ms\n"


class SummaryTest(unittest.TestCase):
    def test_median_low_high_per_count_and_label(self):
        rows = [
            {"label": "before", "count": "200", "frame_avg_ms": "14"},
            {"label": "before", "count": "100", "frame_avg_ms": "7"},
            {"label": "before", "count": "200", "frame_avg_ms": "16"},
            {"label": "before", "count": "200", "frame_avg_ms": "15"},
            {"label": "after", "count": "200", "frame_avg_ms": "9"},
        ]
        s = pmc.summarise(rows)
        self.assertEqual(list(s), ["before", "after"], "labels in the order first seen")
        self.assertEqual(s["before"], [(100, 7.0, 7.0, 7.0), (200, 15.0, 14.0, 16.0)])
        self.assertEqual(s["after"], [(200, 9.0, 9.0, 9.0)])

    def test_an_empty_label_is_a_run(self):
        self.assertEqual(list(pmc.summarise([{"label": "", "count": "5", "frame_avg_ms": "1"}])), ["run"])


class MainTest(unittest.TestCase):
    def test_writes_a_png_and_rejects_a_missing_column(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "a.csv"
            f.write_text(HEADER + "before,100,1,7,7\nafter,100,1,4,4\nbefore,200,1,14,14\nafter,200,1,8,8\n",
                         encoding="utf-8")
            out = Path(d) / "shots" / "plot.png"
            self.assertEqual(pmc.main([str(f), "--out", str(out), "--titles", "Headless"]), 0)
            self.assertTrue(out.exists())
            self.assertEqual(out.read_bytes()[:8], b"\x89PNG\r\n\x1a\n")
            self.assertEqual(pmc.main([str(f), "--out", str(out), "--stat", "nope"]), 2)

    def test_no_data(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "a.csv"
            f.write_text(HEADER, encoding="utf-8")
            self.assertEqual(pmc.main([str(f), "--out", str(Path(d) / "p.png")]), 1)


if __name__ == "__main__":
    unittest.main()
