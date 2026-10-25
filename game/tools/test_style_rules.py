"""Tests for style_rules.py (T-290): each art and text check passes a good example and fails a bad one."""
import contextlib
import io
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import style_rules as s  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
CLEAR = (0, 0, 0, 0)
BLUE = (40, 60, 120, 255)


def make_png(rows):
    h, w = len(rows), len(rows[0])
    raw = b"".join(b"\x00" + b"".join(bytes(p) for p in r) for r in rows)

    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def sprite(w=8, h=8, fill=BLUE):
    """A filled square in the middle of a transparent w x h image."""
    return [[fill if 2 <= x < w - 2 and 2 <= y < h - 2 else CLEAR for x in range(w)] for y in range(h)]


def failed(checks):
    return {(c["rule"], c["check"]) for c in checks if not c["ok"]}


def run_cli(argv):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = s.main(argv)
    return code, json.loads(out.getvalue())


class ArtChecks(unittest.TestCase):
    def test_a_good_sprite_passes_every_rule(self):
        checks = s.art_checks(sprite(), size=(8, 8))
        self.assertEqual(failed(checks), set())
        self.assertEqual({c["rule"] for c in checks}, {1, 3, 6})

    def test_rule_1_semi_transparent_pixel_fails(self):
        rows = sprite()
        rows[3][3] = (40, 60, 120, 128)
        self.assertIn((1, "no semi-transparent pixels"), failed(s.art_checks(rows)))

    def test_rule_1_opaque_background_fails(self):
        rows = sprite()
        rows[0][0] = BLUE
        self.assertIn((1, "transparent background (corners)"), failed(s.art_checks(rows)))

    def test_rule_1_too_many_colours_fails(self):
        rows = [[CLEAR] * 8 for _ in range(8)]
        for i in range(31):
            rows[1 + i // 6][1 + i % 6] = (i * 4, 100, 200, 255)
        self.assertIn((1, "about 30 colours or fewer"), failed(s.art_checks(rows)))
        rows[1][1] = rows[1][2]  # 30 colours
        self.assertEqual(failed(s.art_checks(rows)), set())

    def test_rule_3_size_whole_image_and_each_frame(self):
        self.assertIn((3, "size 16x8"), failed(s.art_checks(sprite(), size=(16, 8))))
        sheet = [a + b for a, b in zip(sprite(), sprite())]  # two 8 x 8 frames
        self.assertEqual(failed(s.art_checks(sheet, size=(8, 8), frames=2)), set())
        self.assertIn((3, "frame 1: size 4x8"), failed(s.art_checks(sheet, size=(4, 8), frames=2)))
        with self.assertRaises(ValueError):
            s.art_checks(sheet, frames=3)

    def test_rule_6_redgull_red_fails_unless_redgull_or_allowed(self):
        for red in (s.REDGULL_RED, s.HEART_COLOR, (255, 0, 0)):
            rows = sprite(fill=red + (255,))
            self.assertEqual({r for r, _ in failed(s.art_checks(rows))}, {6}, red)
            self.assertEqual(failed(s.art_checks(rows, redgull=True)), set())
            self.assertEqual(failed(s.art_checks(rows, allow_red=[red])), set())

    def test_the_red_check_keeps_the_heart_distance(self):
        self.assertTrue(s.is_redgull_red(s.REDGULL_RED))
        self.assertTrue(s.is_redgull_red(s.HEART_COLOR))
        self.assertTrue(s.is_redgull_red((200, 40, 60)))
        for c in [(255, 64, 200), (0, 229, 255), (160, 90, 255), (255, 255, 255)]:
            self.assertFalse(s.is_redgull_red(c), c)
        self.assertAlmostEqual(s.red_distance(s.HEART_COLOR), 0.0)
        self.assertGreater(s.red_distance((0, 229, 255)), s.RED_MIN_DISTANCE)
        self.assertLess(s.red_distance(s.REDGULL_RED), s.RED_MIN_DISTANCE)
        self.assertEqual(s.rgb_distance((0, 0, 0), (3, 4, 0)), 5.0)

    def test_logo_one_colour(self):
        good = Image.new("RGBA", (4, 4), CLEAR)
        good.putpixel((1, 1), s.REDGULL_RED + (255,))
        self.assertEqual(failed(s.logo_checks(good)), set())
        bad = good.copy()
        bad.putpixel((2, 2), (10, 200, 10, 255))
        self.assertEqual({r for r, _ in failed(s.logo_checks(bad))}, {6})
        for n in (128, 64, 32):
            self.assertEqual(s.check_logo(Image.open(ROOT / f"game/art/logo/redgull_logo_{n}.png")), [])

    def test_cli_art_prints_json_and_exits_1_on_a_fail(self):
        with tempfile.TemporaryDirectory() as d:
            good, bad = Path(d) / "good.png", Path(d) / "bad.png"
            good.write_bytes(make_png(sprite()))
            bad.write_bytes(make_png(sprite(fill=s.HEART_COLOR + (255,))))
            code, out = run_cli(["art", str(good), "--size", "8x8"])
            self.assertEqual(code, 0)
            self.assertTrue(all(set(c) == {"rule", "check", "ok", "detail"} for c in out))
            code, out = run_cli(["art", str(bad), "--size", "8x8"])
            self.assertEqual(code, 1)
            self.assertEqual({c["rule"] for c in out if not c["ok"]}, {6})
            self.assertEqual(run_cli(["art", str(bad), "--redgull"])[0], 0)
            self.assertEqual(run_cli(["art", str(bad), "--allow-red", "219,26,41"])[0], 0)
            self.assertEqual(run_cli(["art", str(good), "--size", "4x8", "--frames", "2", "--redgull"])[0], 0)
            self.assertEqual(run_cli(["art", str(good), "--size", "4", "--frames", "2", "--redgull"])[0], 1)
            code, out = run_cli(["art", str(ROOT / "game/art/logo/redgull_logo_32.png"), "--logo"])
            self.assertEqual(code, 0)


class TextChecks(unittest.TestCase):
    def test_popup(self):
        self.assertEqual(failed(s.text_checks("COMBO BROKEN!", "popup")), set())
        self.assertEqual(failed(s.text_checks("AIR 360!", "popup")), set())
        self.assertEqual(failed(s.text_checks("combo broken", "popup")),
                         {(4, "popup: in capitals"), (4, 'popup: ends with "!"')})
        self.assertIn((4, "popup: one line"), failed(s.text_checks("LONG\nDRIFT!", "popup")))

    def test_rule_2_banned_words(self):
        for bad in ("Gain more XP", "+50 points", "The godzilla is here"):
            self.assertEqual(failed(s.text_checks(bad, "card_desc")), {(2, "no banned words (XP, points, Godzilla)")}, bad)
        self.assertEqual(failed(s.text_checks("Gain more likes", "card_desc")), set())
        self.assertEqual(failed(s.text_checks("Expert pointers", "card_desc")), set())  # whole words only

    def test_rule_3_redgull_says(self):
        self.assertEqual(failed(s.text_checks("Redgull says: drift!", "card_desc")), {(3, 'no "Redgull says ..." line')})
        self.assertEqual(failed(s.text_checks("Redgull wants you to drift", "card_desc")), set())

    def test_card_and_garage_lengths(self):
        cases = [("card_title", 30), ("card_desc", 90), ("garage_name", 25), ("garage_desc", 80)]
        for kind, limit in cases:
            self.assertEqual(failed(s.text_checks("a" * limit, kind)), set(), kind)
            self.assertEqual({r for r, _ in failed(s.text_checks("a" * (limit + 1), kind))}, {4}, kind)

    def test_garage_description_names_no_number(self):
        self.assertEqual(failed(s.text_checks("Grippier tyres for longer drifts.", "garage_desc")), set())
        self.assertEqual(failed(s.text_checks("Grip up by 20%.", "garage_desc")), {(4, "garage_desc: names no number")})

    def test_label_sentence_case(self):
        self.assertEqual(failed(s.text_checks("Music volume", "label")), set())
        self.assertEqual(failed(s.text_checks("Redgull Stunt Driver", "label")), set())
        self.assertIn((4, "label: sentence case"), failed(s.text_checks("Music Volume", "label")))
        self.assertIn((4, "label: sentence case"), failed(s.text_checks("music volume", "label")))
        self.assertIn((4, "label: sentence case"), failed(s.text_checks("MUSIC VOLUME", "label")))

    def test_unknown_kind_raises(self):
        with self.assertRaises(ValueError):
            s.text_checks("Hi", "tooltip")

    def test_cli_text(self):
        code, out = run_cli(["text", "COMBO BROKEN!", "--kind", "popup"])
        self.assertEqual(code, 0)
        self.assertTrue(all(c["ok"] for c in out))
        code, out = run_cli(["text", "Gain more XP", "--kind", "card_desc"])
        self.assertEqual(code, 1)
        self.assertEqual([c["rule"] for c in out if not c["ok"]], [2])


if __name__ == "__main__":
    unittest.main()
