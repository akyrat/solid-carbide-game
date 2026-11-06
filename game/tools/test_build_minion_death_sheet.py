"""Tests for build_minion_death_sheet.py (T-532). Run: python -m unittest discover game/tools -p "test_build_minion_death*" """
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_minion_death_sheet as b  # noqa: E402

PAL = [(0, 0, 0), (100, 200, 50), (147, 93, 93)]


def frame(colour, alpha=255):
    im = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    im.putpixel((10, 10), (*colour, alpha))
    return im


class SheetTest(unittest.TestCase):
    def test_snap_moves_to_nearest_and_binarises_alpha(self):
        out = b.snap_frame(frame((110, 190, 60), 200), PAL)
        self.assertEqual(out.getpixel((10, 10)), (100, 200, 50, 255))
        out = b.snap_frame(frame((110, 190, 60), 100), PAL)
        self.assertEqual(out.getpixel((10, 10))[3], 0)

    def test_sheet_is_one_row_of_48(self):
        sheet = b.build_sheet([frame((150, 90, 90)) for _ in range(8)], PAL)
        self.assertEqual(sheet.size, (384, 48))
        self.assertEqual(sheet.getpixel((48 * 3 + 10, 10)), (147, 93, 93, 255))

    def test_hold_repeats_frame_before(self):
        fs = [frame((0, 0, 0)) for _ in range(3)] + [frame((100, 200, 50))] + [frame((147, 93, 93))] * 2
        sheet = b.build_sheet(fs, PAL, hold=2)
        for i in (3, 4, 5):
            self.assertEqual(sheet.getpixel((48 * i + 10, 10)), (100, 200, 50, 255))

    def test_wrong_size_and_bad_hold_refused(self):
        with self.assertRaises(ValueError):
            b.build_sheet([Image.new("RGBA", (40, 48))], PAL)
        with self.assertRaises(ValueError):
            b.build_sheet([frame((0, 0, 0))] * 2, PAL, hold=2)

    def test_pick_joins_frames_from_two_folders(self):
        with tempfile.TemporaryDirectory() as d:
            a, c = Path(d) / "a", Path(d) / "c"
            a.mkdir(); c.mkdir()
            frame((0, 0, 0)).save(a / "x_2.png")
            frame((147, 93, 93)).save(c / "x_5.png")
            out = Path(d) / "v.png"
            orig = b.walk_palette
            b.walk_palette = lambda: PAL
            try:
                b.main(["unused", "x", str(out), "--pick", f"{a}:2,{c}:5"])
            finally:
                b.walk_palette = orig
            sheet = Image.open(out)
            self.assertEqual(sheet.size, (96, 48))
            self.assertEqual(sheet.getpixel((58, 10)), (147, 93, 93, 255))

    def test_main_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            for i in range(3):
                frame((100, 200, 50)).save(Path(d) / f"x_{i}.png")
            out = Path(d) / "v.png"
            out.write_bytes(b"keep")
            with self.assertRaises(SystemExit):
                b.main([d, "x", str(out), "--count", "2"])
            self.assertEqual(out.read_bytes(), b"keep")


if __name__ == "__main__":
    unittest.main()
