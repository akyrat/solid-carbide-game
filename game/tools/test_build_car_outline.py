"""Tests for build_car_outline.py (T-566): the spans of a frame, and the committed file is up to date."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_outline as bco  # noqa: E402


class FrameSpansTest(unittest.TestCase):
    def test_spans_are_each_rows_leftmost_and_rightmost_opaque_pixel(self):
        img = Image.new("RGBA", (8, 4), (0, 0, 0, 0))
        img.putpixel((2, 1), (9, 9, 9, 255))
        img.putpixel((5, 1), (9, 9, 9, 255))
        img.putpixel((3, 3), (9, 9, 9, 200))
        img.putpixel((6, 3), (9, 9, 9, 100))  # under ALPHA_MIN: not drawn
        self.assertEqual(bco.frame_spans(img, 0, 0, 8, 4), [1, 2, 5, 3, 3, 3])

    def test_a_frame_is_read_at_its_offset_in_the_sheet(self):
        img = Image.new("RGBA", (8, 4), (0, 0, 0, 0))
        img.putpixel((6, 2), (9, 9, 9, 255))
        self.assertEqual(bco.frame_spans(img, 4, 0, 4, 4), [2, 2, 2])
        self.assertEqual(bco.frame_spans(img, 0, 0, 4, 4), [])


class CommittedFileTest(unittest.TestCase):
    def test_the_committed_outline_matches_the_art(self):
        self.assertEqual(bco.main(["--check"]), 0)

    def test_every_sheet_has_a_frame_per_direction(self):
        data = bco.build()
        for key in bco.SOURCES:
            self.assertEqual(len(data["sheets"][key]), data["frame_count"], key)
            self.assertTrue(all(len(f) > 0 and len(f) % 3 == 0 for f in data["sheets"][key]), key)


if __name__ == "__main__":
    unittest.main()
