"""Tests for fix_power_up_icon_rusty_overcoat.py (T-465)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fix_power_up_icon_rusty_overcoat as fix  # noqa: E402

from PIL import Image  # noqa: E402

V2 = fix.ROOT / "art-archive" / "T-465" / "style-loop" / "v2-4.png"
GREENBULL = {(104, 220, 96), (247, 208, 52)}


class RustyOvercoatFixTest(unittest.TestCase):
    def setUp(self):
        self.im = fix.make_v2()

    def test_size_and_mode(self):
        self.assertEqual(self.im.size, (32, 32))
        self.assertEqual(self.im.mode, "RGBA")

    def test_hard_alpha_and_colour_budget(self):
        px = list(self.im.getdata())
        self.assertFalse([p for p in px if 0 < p[3] < 255])
        colours = {p[:3] for p in px if p[3]}
        self.assertLessEqual(len(colours), 30)
        self.assertFalse(colours & GREENBULL)

    def test_transparent_corners(self):
        for xy in [(0, 0), (31, 0), (0, 31), (31, 31)]:
            self.assertEqual(self.im.getpixel(xy)[3], 0)

    def test_neon_glints_have_stepped_halos(self):
        for (x, y), c in fix.GLOW.items():
            if c in (fix.CYAN, fix.MAG):
                mids = {fix.CYAN_MID, fix.MAG_MID}
                near = [self.im.getpixel((x + dx, y + dy))[:3]
                        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]]
                self.assertTrue(any(n in mids for n in near), (x, y))

    def test_only_edits_change_v1(self):
        v1 = fix.load_v1()
        edited = set().union(*[set(e) for e in fix.EDITS])
        for y in range(32):
            for x in range(32):
                if (x, y) not in edited:
                    self.assertEqual(v1.getpixel((x, y)), self.im.getpixel((x, y)))

    def test_archived_v2_reproduces(self):
        if not V2.exists():
            self.skipTest("v2-4.png not saved yet")
        self.assertEqual(list(Image.open(V2).convert("RGBA").getdata()), list(self.im.getdata()))

    def test_refuses_to_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "x.png"
            out.write_bytes(b"x")
            with self.assertRaises(SystemExit):
                fix.main([str(out)])


if __name__ == "__main__":
    unittest.main()
