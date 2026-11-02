"""Tests for build_power_up_icon_rusty_paintjob.py (T-503)."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_power_up_icon_rusty_paintjob as b  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
V1 = REPO / "art-archive" / "T-503" / "style-loop" / "v1.png"


@unittest.skipUnless(V1.exists(), "T-503 v1 not in this checkout")
class BuildV2Test(unittest.TestCase):
    def setUp(self):
        self.v1 = Image.open(V1).convert("RGBA")
        self.v2 = b.build_v2(self.v1)

    def test_matched_set_limits(self):
        s = b.stats(self.v2)
        self.assertEqual(s["size"], (32, 32))
        self.assertLessEqual(s["colours"], 30)
        self.assertEqual(s["semi"], 0)
        self.assertEqual(s["greenbull"], [])

    def test_can_sits_inside_the_frame(self):
        left, top, right, bottom = self.v2.getbbox()
        self.assertGreaterEqual(top, 1)
        self.assertLessEqual(bottom, 31)

    def test_has_rust_neon_and_outline(self):
        cols = {p[:3] for p in self.v2.getdata() if p[3]}
        for c in (b.OUTLINE, b.R_PIT, b.CYAN, b.MAGENTA, b.MIST, b.RIM):
            self.assertIn(c, cols)

    def test_deterministic(self):
        self.assertEqual(self.v2.tobytes(), b.build_v2(self.v1).tobytes())


class BuildV3Test(unittest.TestCase):
    def setUp(self):
        self.v3 = b.build_v3()

    def test_matched_set_limits(self):
        s = b.stats(self.v3)
        self.assertEqual(s["size"], (32, 32))
        self.assertLessEqual(s["colours"], 30)
        self.assertEqual(s["semi"], 0)
        self.assertEqual(s["greenbull"], [])

    def test_body_is_16_px_wide(self):
        left, _, right, _ = self.v3.getbbox()
        self.assertEqual(left, 8)
        row = [x for x in range(32) if self.v3.getpixel((x, 20))[3]]
        self.assertEqual(len(row), 16)

    def test_has_cap_rust_neon_and_puff(self):
        cols = {p[:3] for p in self.v3.getdata() if p[3]}
        for ch in "ONWrRKPCGS":
            self.assertIn(b.V3_PALETTE[ch], cols, ch)

    def test_rows_are_32_wide(self):
        rows = b.v3_rows()
        self.assertEqual(len(rows), 32)
        self.assertTrue(all(len(r) == 32 for r in rows))


class BuildV4Test(unittest.TestCase):
    def setUp(self):
        self.v4 = b.build_v4()

    def test_matched_set_limits(self):
        s = b.stats(self.v4)
        self.assertEqual(s["size"], (32, 32))
        self.assertLessEqual(s["colours"], 30)
        self.assertEqual(s["semi"], 0)
        self.assertEqual(s["greenbull"], [])
        left, top, right, bottom = s["bbox"]
        self.assertGreaterEqual(top, 1)
        self.assertLessEqual(bottom, 31)

    def test_shoulder_narrower_than_body(self):
        def width(y):
            return len([x for x in range(32) if self.v4.getpixel((x, y))[3]])
        self.assertLess(width(7), width(20))   # cap row vs body row
        self.assertEqual(width(20), 16)

    def test_highlight_strip_runs_down_the_body(self):
        whites = [y for y in range(14, 28) if self.v4.getpixel((11, y))[:3] == b.RIM]
        self.assertGreaterEqual(len(whites), 8)

    def test_has_cap_rust_neon_and_puff(self):
        cols = {p[:3] for p in self.v4.getdata() if p[3]}
        for ch in "ONWrRKPCGSs":
            self.assertIn(b.V4_PALETTE[ch], cols, ch)


if __name__ == "__main__":
    unittest.main()
