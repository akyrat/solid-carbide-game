import contextlib
import io
import json
import os
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_level_up_shot as c  # noqa: E402
import style_rules  # noqa: E402

GAME_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DARK = style_rules.GREENBULL_DARK_GREEN
LIGHT = style_rules.GREENBULL_LIGHT_GREEN
ART = c.art_colours(GAME_DIR)


def write_png(path, pixels, w, h):
    raw = b"".join(b"\x00" + b"".join(bytes(p + (255,)) for p in pixels[y * w:(y + 1) * w]) for y in range(h))

    def chunk(t, d):
        x = struct.pack(">I", len(d)) + t + d
        return x + struct.pack(">I", zlib.crc32(t + d))
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def rows_of(pixels, w):
    return [[p + (255,) for p in pixels[i:i + w]] for i in range(0, len(pixels), w)]


class CheckLevelUpShot(unittest.TestCase):
    def test_art_colours_hold_the_greens_and_leave_out_cream_and_ink(self):
        self.assertIn(DARK, ART)
        self.assertNotIn(c.CREAM, ART)
        self.assertNotIn(c.CREAM_D, ART)
        self.assertNotIn(c.TEXT_INK, ART)

    def test_clean_image_passes(self):
        pixels = [DARK] * 6 + [LIGHT] * 2 + [(0, 0, 0)] * 4 + [c.CREAM] * 4
        rep = c.check(rows_of(pixels, 4), ART)
        self.assertEqual(rep["red_pixels"], 0)
        self.assertEqual(rep["most_common_art_colour"], list(DARK))
        self.assertTrue(rep["most_common_is_dark_green"])
        self.assertTrue(rep["ok"])

    def test_red_pixel_fails_and_is_located(self):
        pixels = [DARK] * 7 + [(135, 17, 27)]
        rep = c.check(rows_of(pixels, 4), ART)
        self.assertEqual(rep["red_pixels"], 1)
        self.assertEqual(rep["red_positions"][0], {"x": 3, "y": 1, "rgb": [135, 17, 27]})
        self.assertFalse(rep["ok"])

    def test_light_green_leading_fails(self):
        pixels = [LIGHT] * 5 + [DARK] * 3
        rep = c.check(rows_of(pixels, 4), ART)
        self.assertEqual(rep["most_common_art_colour"], list(LIGHT))
        self.assertFalse(rep["most_common_is_dark_green"])
        self.assertFalse(rep["ok"])

    def test_command_line_exit_codes_and_json(self):
        with tempfile.TemporaryDirectory() as d:
            good, bad = os.path.join(d, "good.png"), os.path.join(d, "bad.png")
            write_png(good, [DARK] * 3 + [LIGHT], 2, 2)
            write_png(bad, [LIGHT] * 3 + [DARK], 2, 2)
            for path, code in ((good, 0), (bad, 1)):
                out = io.StringIO()
                with contextlib.redirect_stdout(out):
                    self.assertEqual(c.main([path, "--game-dir", GAME_DIR]), code)
                self.assertEqual(json.loads(out.getvalue())["ok"], code == 0)


if __name__ == "__main__":
    unittest.main()
