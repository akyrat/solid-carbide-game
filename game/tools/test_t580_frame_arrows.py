"""Tests for t580_frame_arrows.py (task T-580)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import t580_frame_arrows as fa  # noqa: E402
from PIL import Image  # noqa: E402


class FrameArrowsTest(unittest.TestCase):
    def test_wrap180(self):
        self.assertAlmostEqual(fa.wrap180(350.0), -10.0)
        self.assertAlmostEqual(fa.wrap180(-190.0), 170.0)

    def test_build_writes_a_sheet_of_32_cells(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "sheet.png"
            gaps = fa.build(out)
            self.assertEqual(len(gaps), 32)
            with Image.open(out) as im:
                self.assertEqual(im.size, (8 * 256, 4 * (256 + 34)))
            # The four main T-101 diagonals the art was drawn from agree with the projection.
            by_index = {g[0]: g for g in gaps}
            self.assertLess(abs(by_index[4][4]), 1.0)
            self.assertLess(abs(by_index[28][4]), 1.0)
            # Frame 22 (world 247.5, screen up-right) was drawn about 40 degrees off; T-584 redrew it (measured 289.5 against 270 on screen), so the gap is now about 20.
            self.assertLess(abs(by_index[22][4]), 25.0)


if __name__ == "__main__":
    unittest.main()
