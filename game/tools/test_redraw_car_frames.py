"""Tests for redraw_car_frames.py (T-584). No PixelLab call is made."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import redraw_car_frames as r  # noqa: E402
import build_car_sheet as cs  # noqa: E402


class RedrawCarFramesTest(unittest.TestCase):
    def test_targets_are_the_seven_frames_in_order_of_the_turn(self):
        self.assertEqual(sorted(r.TARGETS), [2, 3, 19, 20, 21, 22, 23])
        run = [r.TARGETS[k] for k in (19, 20, 21, 22, 23)]
        self.assertEqual(run, sorted(run))
        self.assertLess(r.TARGETS[2], r.TARGETS[3])

    def test_compass_for_picks_the_nearest_direction(self):
        self.assertEqual(r.compass_for(88), "south")
        self.assertEqual(r.compass_for(330), "north-east")
        self.assertEqual(r.compass_for(5), "east")
        self.assertEqual(r.compass_for(20), "south-east")

    def test_process_maps_to_the_approved_palette_and_keeps_the_size(self):
        ref = cs.read_rows(r.REPO / cs.REFERENCE)
        palette = set(cs.palette_of(ref))
        rows = [[(0, 0, 0, 0)] * r.FRAME for _ in range(r.FRAME)]
        for y in range(40, 60):
            for x in range(30, 90):
                rows[y][x] = (200, 40, 50, 255)
        out, shift = r.process_rows(rows)
        self.assertEqual((len(out), len(out[0])), (r.FRAME, r.FRAME))
        self.assertTrue(set(cs.palette_of(out)) <= palette)
        self.assertIsInstance(shift, tuple)


if __name__ == "__main__":
    unittest.main()
