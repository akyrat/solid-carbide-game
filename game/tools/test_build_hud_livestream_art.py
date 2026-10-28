"""Tests for build_hud_livestream_art.py (T-339). Run with the Python tool tests (game/README.md)."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_livestream_art as art  # noqa: E402
import style_rules  # noqa: E402

FIRE_YELLOW = (255, 224, 77)


def rows_of(im):
    im = im.convert("RGBA")
    return [[im.getpixel((x, y)) for x in range(im.width)] for y in range(im.height)]


def failed(im, size=None, frames=0, allow=()):
    checks = style_rules.art_checks(rows_of(im), size, frames, False, list(allow), 30)
    return [c for c in checks if not c["ok"]]


class Pieces(unittest.TestCase):
    def test_each_piece_passes_the_script_rules_at_its_size(self):
        cases = [
            (art.panel(100, 36), (100, 36), 0),
            (art.panel(120, 36, rim=art.VIEWERS), (120, 36), 0),
            (art.subgoal_frame(64), (64, 64), 0),
            (art.digits_sheet(), (art.DW, art.DH), 12),
            (art.live_badge(), (34, 13), 0),
            (art.fire_sheet(), (art.FIRE_W, art.FIRE_H), art.FIRE_FRAMES),
            (art.heart(), (18, 16), 0),
            (art.heart_empty(art.heart()), (18, 16), 0),
            (art.eye(), (16, 11), 0),
            (art.subs_icon(), (22, 22), 0),
        ]
        for im, size, frames in cases:
            with self.subTest(size=size, frames=frames):
                self.assertEqual(failed(im, size, frames, [FIRE_YELLOW]), [])

    def test_deterministic(self):
        self.assertEqual(art.fire_sheet().tobytes(), art.fire_sheet().tobytes())
        self.assertEqual(art.digits_sheet().tobytes(), art.digits_sheet().tobytes())

    def test_fire_loops(self):
        self.assertEqual(art.fire_frame(0).tobytes(), art.fire_frame(art.FIRE_FRAMES).tobytes())
        self.assertNotEqual(art.fire_frame(0).tobytes(), art.fire_frame(1).tobytes())

    def test_fire_leaves_the_panel_clear(self):
        im = art.fire_frame(3)
        for y in range(art.PANEL_Y + 2, art.PANEL_Y + art.PANEL_H):
            for x in range(art.PANEL_X, art.PANEL_X + art.PANEL_W):
                self.assertEqual(im.getpixel((x, y))[3], 0, (x, y))

    def test_digits_are_greyscale_for_tinting(self):
        for p in art.digits_sheet().getdata():
            if p[3]:
                self.assertTrue(p[0] == p[1] == p[2], p)

    def test_digit_segments(self):
        self.assertEqual(len(art.glyph_pixels("8")), sum(len(art.segment_pixels(s)) for s in "abcdefg"))
        self.assertLess(len(art.glyph_pixels("1")), len(art.glyph_pixels("7")))

    def test_subgoal_inside_is_black(self):
        im = art.subgoal_frame(64)
        for y in range(4, 60):
            for x in range(4, 60):
                if min(x - 4, 59 - x) + min(y - 4, 59 - y) < 3:
                    continue                                   # the inside's corners are rounded too
                self.assertEqual(im.getpixel((x, y))[:3], (6, 7, 10))

    def test_empty_heart_keeps_outline_and_shape(self):
        full = art.heart()
        empty = art.heart_empty(full)
        for a, b in zip(full.getdata(), empty.getdata()):
            self.assertEqual(a[3], b[3])
            if a[:3] == art.OUT[:3]:
                self.assertEqual(b[:3], art.OUT[:3])
        self.assertFalse(any(style_rules.reads_as_red(p[:3]) for p in empty.getdata() if p[3]))


class KeptFiles(unittest.TestCase):
    """The script redraws the style loop's kept versions in game/art/hud/ pixel for pixel."""
    HUD = Path(__file__).resolve().parents[1] / "art" / "hud"

    def test_script_redraws_the_kept_files(self):
        cases = {"clock_panel": art.panel(100, 36), "viewers_panel": art.panel(120, 36, rim=art.VIEWERS),
                 "subgoal_frame": art.subgoal_frame(64), "clock_digits": art.digits_sheet(),
                 "live_badge": art.live_badge(), "viewers_fire": art.fire_sheet(), "heart_full": art.heart(),
                 "eye_icon": art.eye(), "subs_icon": art.subs_icon()}
        for name, im in cases.items():
            path = self.HUD / f"{name}.png"
            if not path.exists():
                continue
            with self.subTest(name=name):
                kept = Image.open(path).convert("RGBA")
                self.assertEqual(kept.size, im.size)
                self.assertEqual(kept.tobytes(), im.convert("RGBA").tobytes())

    def test_empty_heart_is_made_from_the_kept_full_heart(self):
        full, empty = self.HUD / "heart_full.png", self.HUD / "heart_empty.png"
        if full.exists() and empty.exists():
            made = art.heart_empty(Image.open(full))
            self.assertEqual(Image.open(empty).convert("RGBA").tobytes(), made.tobytes())


class Post(unittest.TestCase):
    def test_removes_flat_background_and_centres_without_scaling(self):
        raw = Image.new("RGBA", (32, 32), (40, 200, 40, 255))
        for y in range(10, 20):
            for x in range(8, 22):
                raw.putpixel((x, y), (200, 30, 30, 255))
        out = art.post(raw, (18, 14), outline=True)
        self.assertEqual(out.size, (18, 14))
        self.assertEqual(out.getpixel((0, 0))[3], 0)
        self.assertEqual(sum(1 for p in out.getdata() if p[:3] == (200, 30, 30) and p[3]), 140)
        self.assertEqual(failed(out, (18, 14)), [])

    def test_request_body(self):
        import io
        buf = io.BytesIO()
        art.heart().save(buf, format="PNG")
        body = art.request("a heart", (18, 16), buf.getvalue(), 120)
        self.assertEqual(body["image_size"], {"width": 18, "height": 16})
        self.assertTrue(body["no_background"])
        self.assertEqual(body["init_image"]["type"], "base64")
        self.assertEqual(body["init_image_strength"], 120)
        self.assertNotIn("init_image", art.request("a heart", (32, 32)))

    def test_refuses_to_scale(self):
        raw = Image.new("RGBA", (32, 32), (200, 30, 30, 255))
        with self.assertRaises(ValueError):
            art.post(raw, (16, 16))

    def test_split_and_never_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            paths = art.split(art.digits_sheet(), 12, art.DIGIT_NAMES, d)
            self.assertEqual(len(paths), 12)
            self.assertEqual(Image.open(paths[0]).size, (art.DW, art.DH))
            with self.assertRaises(SystemExit):
                art.save(art.heart(), paths[0])


if __name__ == "__main__":
    unittest.main()
