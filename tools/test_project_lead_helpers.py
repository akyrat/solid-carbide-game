"""Tests for finish_task.py and update_short_gdd_fingerprint.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import finish_task  # noqa: E402
import generate_long_gdd as g  # noqa: E402
import update_short_gdd_fingerprint as fp  # noqa: E402


def write_task(d, tid, status, deps=()):
    (Path(d) / f"{tid}-x.md").write_text(
        f"---\nid: {tid}\ntitle: x\nstatus: {status}\ndepends_on: [{', '.join(deps)}]\n---\n\n## Result notes\n\nnotes\n",
        encoding="utf-8")


def status_of(d, tid):
    text = next(Path(d).glob(f"{tid}-*.md")).read_text(encoding="utf-8")
    return finish_task._field(text, "status")


class FinishTaskTests(unittest.TestCase):
    def test_done_note_and_unblocking(self):
        with tempfile.TemporaryDirectory() as d:
            write_task(d, "T-001", "needs-playtest")
            write_task(d, "T-002", "done")
            write_task(d, "T-003", "blocked", ["T-001", "T-002"])   # all done after: opens
            write_task(d, "T-004", "blocked", ["T-001", "T-009"])   # T-009 unknown: stays
            write_task(d, "T-005", "blocked", ["T-002"])            # not waiting on T-001: stays
            out = finish_task.finish("T-001", "approved", d)
            self.assertEqual(out, ["T-001: done", "T-003: unblocked"])
            self.assertEqual(status_of(d, "T-001"), "done")
            self.assertEqual(status_of(d, "T-003"), "open")
            self.assertEqual(status_of(d, "T-004"), "blocked")
            self.assertEqual(status_of(d, "T-005"), "blocked")
            self.assertIn("### Board review\n\napproved", next(Path(d).glob("T-001-*.md")).read_text(encoding="utf-8"))

    def test_empty_note_adds_no_section(self):
        with tempfile.TemporaryDirectory() as d:
            write_task(d, "T-001", "in-qa")
            finish_task.finish("T-001", "", d)
            self.assertNotIn("Board review", next(Path(d).glob("T-001-*.md")).read_text(encoding="utf-8"))


class FingerprintTests(unittest.TestCase):
    def test_line_matches_long_gdd(self):
        with tempfile.TemporaryDirectory() as d:
            long_gdd = Path(d) / "long.md"
            long_gdd.write_text("# Long GDD\n\nsome content\n", encoding="utf-8")
            readme = Path(d) / "README.md"
            readme.write_text("# Short GDD\n\nLast updated from long GDD: " + "0" * 64 + "\n\nmore\n", encoding="utf-8")
            old, new = fp.update(readme, long_gdd)
            self.assertIn("0" * 64, old)
            self.assertTrue(new.endswith(g.fingerprint(long_gdd.read_text(encoding="utf-8"))))
            self.assertIn(new, readme.read_text(encoding="utf-8"))
            self.assertTrue(readme.read_text(encoding="utf-8").endswith("more\n"))


if __name__ == "__main__":
    unittest.main()
