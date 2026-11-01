"""Tests for gif_to_sheet.py (task T-485): a small GIF becomes a sheet with the right grid and timing."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gif_to_sheet as g  # noqa: E402


class SheetTest(unittest.TestCase):
    def test_grid_pixels_and_timing(self):
        with tempfile.TemporaryDirectory() as tmp:
            colours = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0), (0, 255, 255)]
            frames = [Image.new("RGB", (4, 3), c) for c in colours]
            gif = Path(tmp) / "t.gif"
            frames[0].save(gif, save_all=True, append_images=frames[1:], duration=[40, 80, 40, 60, 40], loop=0)
            names, meta = g.convert(gif)
            out = Path(tmp) / names[0]
            self.assertEqual(meta["frames"], 5)
            self.assertEqual(meta["durations_ms"], [40, 80, 40, 60, 40])
            self.assertEqual(meta["columns"], 1024)
            self.assertEqual(meta["frame_size"], [4, 3])
            sheet = Image.open(out)
            self.assertEqual(sheet.size, (20, 3))
            self.assertEqual(sheet.convert("RGBA").getpixel((1, 1)), colours[0] + (255,))
            self.assertEqual(sheet.convert("RGBA").getpixel((9, 1)), colours[2] + (255,))
            self.assertEqual(sheet.convert("RGBA").getpixel((13, 1)), colours[3] + (255,))
            self.assertTrue(out.with_suffix(".json").exists())
            self.assertEqual(json.loads(out.with_suffix(".json").read_text())["clip"], "t")

    def test_big_clips_split_into_pages_of_at_most_4096(self):
        frames = [Image.new("RGB", (480, 320), (i, 0, 0)) for i in range(100)]
        pages, cols, rows = g.build_sheets(frames)
        self.assertEqual((cols, rows), (8, 12))
        self.assertEqual(len(pages), 2, "100 frames do not fit one 8 x 12 page")
        for p in pages:
            self.assertLessEqual(max(p.size), 4096)
        self.assertEqual(pages[0].size, (3840, 3840))
        self.assertEqual(pages[1].getpixel((1, 1))[0], 96, "page 2 starts at frame 96")


if __name__ == "__main__":
    unittest.main()
