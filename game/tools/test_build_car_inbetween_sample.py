"""Tests for build_car_inbetween_sample.py (task T-102). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_inbetween_sample as s  # noqa: E402
import build_car_sheet as cs  # noqa: E402

T = (0, 0, 0, 0)
O = (10, 20, 30, 255)
RAW = cs.REPO / "art-archive/T-102/car_rot11_from_f02_south_raw.png"


def bar(w, h, horizontal):
    return [[O if (horizontal and y == h // 2) or (not horizontal and x == w // 2) else T
             for x in range(w)] for y in range(h)]


class InbetweenSampleTests(unittest.TestCase):
    def test_axis_of_a_horizontal_bar_is_0_and_vertical_is_90(self):
        self.assertEqual(s.axis_angle(bar(9, 9, True)), 0.0)
        self.assertEqual(s.axis_angle(bar(9, 9, False)), 90.0)

    def test_compose_size_and_background(self):
        f = [[T, O], [O, T]]
        out = s.compose([f, f, f], s.DARK, scale=2, gap=1)
        self.assertEqual(len(out), (2 + 2) * 2)
        self.assertEqual(len(out[0]), (3 * 2 + 4) * 2)
        self.assertEqual(out[0][0], s.DARK)
        self.assertEqual(out[2][4], O)  # frame pixel (x 1, y 0) -> canvas (2, 1) -> enlarged (4, 2)
        self.assertEqual(out[2][2], s.DARK)  # transparent frame pixel shows the background

    def test_sheet_frame_cuts_one_frame(self):
        sheet = [[(i, 0, 0, 255) for i in range(6)] for _ in range(2)]
        self.assertEqual(s.sheet_frame(sheet, 1, size=2), [[(2, 0, 0, 255), (3, 0, 0, 255)]] * 2)

    @unittest.skipUnless(RAW.is_file(), "sample raw frame not present")
    def test_sample_uses_only_the_approved_palette_and_no_semi_transparency(self):
        final, dark, light, m = s.build(RAW, 2)
        palette = set(cs.palette_of(cs.read_rows(cs.REPO / cs.REFERENCE)))
        self.assertTrue(set(cs.palette_of(final)) <= palette)
        self.assertTrue(all(p[3] in (0, 255) for r in final for p in r))
        self.assertEqual((m["left_frame"], m["right_frame"]), (2, 3))
        self.assertEqual(len(dark), len(light))


if __name__ == "__main__":
    unittest.main()
