"""Tests for update_short_gdd_fingerprint.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_long_gdd as g  # noqa: E402
import update_short_gdd_fingerprint as fp  # noqa: E402


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
