"""Tests for build_weapon_effects.py (task T-071): the pipe is erased, the cells point where they say, the art obeys the rules."""
import math
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_weapon_effects as b  # noqa: E402


class WeaponEffectsTests(unittest.TestCase):
    def test_pipe_pixels_are_erased_and_flame_pixels_kept(self):
        im = Image.new("RGBA", (4, 1), (0, 0, 0, 0))
        im.putpixel((0, 0), (127, 126, 124, 255))  # grey pipe
        im.putpixel((1, 0), (6, 3, 1, 255))  # its outline
        im.putpixel((2, 0), (249, 126, 3, 255))  # flame
        im.putpixel((3, 0), (253, 254, 198, 255))  # pale core
        out = b.erase_pipe(im)
        self.assertEqual([out.getpixel((x, 0))[3] for x in range(4)], [0, 0, 255, 255])

    def test_a_cell_points_where_its_direction_says(self):
        src = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        for x in range(10, 30):  # a plume along +x from the base at (10, 20)
            for y in range(19, 21):
                src.putpixel((x, y), (250, 200, 0, 255))
        base, axis = (10.0, 20.0), 0.0
        for d in (0, 8, 16, 24):
            cell = b.flame_cell(src, base, axis, d, False)
            xs = [(x, y) for y in range(b.CELL) for x in range(b.CELL) if cell.getpixel((x, y))[3]]
            self.assertTrue(xs, "direction %d is empty" % d)
            cx = sum(p[0] for p in xs) / len(xs) - b.CELL / 2
            cy = sum(p[1] for p in xs) / len(xs) - b.CELL / 2
            want = math.tau * d / b.DIRECTIONS
            got = math.atan2(cy, cx)
            self.assertAlmostEqual(math.cos(got), math.cos(want), delta=0.1)
            self.assertAlmostEqual(math.sin(got), math.sin(want), delta=0.1)

    def test_the_mirror_frame_differs_for_a_lopsided_plume(self):
        src = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        for x in range(10, 30):
            src.putpixel((x, 20), (250, 200, 0, 255))
        src.putpixel((20, 18), (250, 200, 0, 255))  # a lick on one side
        a = b.flame_cell(src, (10.0, 20.0), 0.0, 0, False)
        m = b.flame_cell(src, (10.0, 20.0), 0.0, 0, True)
        self.assertNotEqual(a.tobytes(), m.tobytes())

    def test_bullet_is_two_opaque_frames_inside_the_palette(self):
        im = b.build_bullet()
        self.assertEqual(im.size, (24, 12))
        self.assertEqual({p[3] for p in im.getdata()}, {0, 255})
        self.assertNotEqual(im.crop((0, 0, 12, 12)).tobytes(), im.crop((12, 0, 24, 12)).tobytes())
        self.assertLessEqual(len({p[:3] for p in im.getdata() if p[3]}), 30)

    def test_built_art_obeys_the_rules(self):
        if not (b.RAW / "exhaust_flame_raw.png").exists():
            self.skipTest("raw art not in the archive")
        b.build()
        self.assertEqual(b.check(), 0)
        sheet = Image.open(b.OUT / "exhaust_flame_sheet.png")
        self.assertEqual(sheet.size, (b.CELL * b.COLS, b.CELL * 8))
        self.assertEqual(Image.open(b.OUT / "burning_flames.png").size, (b.BURN_SIZE[0] * 2, b.BURN_SIZE[1]))

    def test_no_grey_left_in_the_flame_sheet(self):
        sheet = Image.open(b.OUT / "exhaust_flame_sheet.png").convert("RGBA")
        for p in sheet.getdata():
            if p[3]:
                self.assertGreater(max(p[:3]) - min(p[:3]), 12, "a grey pixel (the pipe) is left: %s" % (p,))


if __name__ == "__main__":
    unittest.main()
