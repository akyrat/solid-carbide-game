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

    def test_rule_6_red_is_not_reserved(self):
        for red in ((255, 0, 0), s.OLD_LOGO_RED, s.HEART_COLOR):
            self.assertEqual(failed(s.art_checks(sprite(fill=red + (255,)))), set(), red)

    def test_rule_6_light_green_fails_unless_greenbull(self):
        rows = sprite(fill=(104, 220, 96, 255))
        self.assertEqual({r for r, _ in failed(s.art_checks(rows))}, {6})
        self.assertEqual(failed(s.art_checks(rows, greenbull=True)), set())

    def test_rule_6_yellow_fails_unless_greenbull(self):
        rows = sprite(fill=(247, 208, 52, 255))
        self.assertEqual({r for r, _ in failed(s.art_checks(rows))}, {6})
        self.assertEqual(failed(s.art_checks(rows, greenbull=True)), set())

    def test_rule_6_colours_that_read_as_greenbulls(self):
        near = [(110, 214, 100), (240, 200, 60)]  # within GREENBULL_MAX_DIST
        clear = [(255, 178, 60), (243, 180, 46), (s.GREENBULL_DARK_GREEN), (60, 140, 60), (255, 255, 255)]
        for c in near:
            self.assertIsNotNone(s.greenbull_colour(c), c)
            self.assertEqual({r for r, _ in failed(s.art_checks(sprite(fill=c + (255,))))}, {6}, c)
            self.assertEqual(failed(s.art_checks(sprite(fill=c + (255,)), allow=[c])), set(), c)
        for c in clear:
            self.assertIsNone(s.greenbull_colour(c), c)

    def test_the_red_check_keeps_the_heart_distance(self):
        self.assertTrue(s.reads_as_red(s.OLD_LOGO_RED))
        self.assertTrue(s.reads_as_red(s.HEART_COLOR))
        self.assertTrue(s.reads_as_red((200, 40, 60)))
        for c in [(255, 64, 200), (0, 229, 255), (160, 90, 255), (255, 255, 255)]:
            self.assertFalse(s.reads_as_red(c), c)
        self.assertAlmostEqual(s.red_distance(s.HEART_COLOR), 0.0)
        self.assertGreater(s.red_distance((0, 229, 255)), s.RED_MIN_DISTANCE)
        self.assertLess(s.red_distance(s.OLD_LOGO_RED), s.RED_MIN_DISTANCE)
        self.assertEqual(s.rgb_distance((0, 0, 0), (3, 4, 0)), 5.0)

    def test_redgull_red(self):
        self.assertTrue(s.is_redgull_red((135, 17, 27)))
        self.assertTrue(s.is_redgull_red((140, 22, 30)))  # within the threshold
        self.assertFalse(s.is_redgull_red((120, 60, 60)))  # a red-brown, far from every brand red
        self.assertFalse(s.is_redgull_red(s.HEART_COLOR))
        dim = tuple(round(c * 0.4) for c in s.HEART_COLOR)  # about (88, 10, 16)
        self.assertFalse(s.is_redgull_red(dim), dim)
        self.assertFalse(s.is_redgull_red(s.GREENBULL_DARK_GREEN))

    def test_greenbull_logo_follows_rule_1(self):
        good = Image.new("RGBA", (4, 4), CLEAR)
        for x, c in enumerate((s.GREENBULL_DARK_GREEN, s.GREENBULL_LIGHT_GREEN, s.GREENBULL_YELLOW)):
            good.putpixel((x + 1, 1), c + (255,))
        self.assertEqual(failed(s.logo_checks(good)), set())
        self.assertEqual({c["rule"] for c in s.logo_checks(good)}, {1})
        bad = good.copy()
        bad.putpixel((2, 2), (12, 76, 44, 128))
        self.assertEqual(failed(s.logo_checks(bad)), {(1, "Greenbull's logo: no semi-transparent pixels")})
        self.assertTrue(s.check_logo(bad))

    def test_greenbull_logo_accepts_the_approved_emblem_and_wordmark(self):
        for p in ["art-archive/T-294/greenbull_emblem_%d.png" % n for n in (128, 64, 32)] + [
                "art-archive/T-295/greenbull_wordmark.png"]:
            self.assertEqual(s.check_logo(Image.open(ROOT / p)), [], p)

    def test_old_logo_check_kept(self):
        for n in (128, 64, 32):
            self.assertEqual(s.check_old_logo(Image.open(ROOT / f"game/art/logo/redgull_logo_{n}.png")), [])

    def test_cli_art_prints_json_and_exits_1_on_a_fail(self):
        with tempfile.TemporaryDirectory() as d:
            good, bad = Path(d) / "good.png", Path(d) / "bad.png"
            good.write_bytes(make_png(sprite()))
            bad.write_bytes(make_png(sprite(fill=s.GREENBULL_YELLOW + (255,))))
            code, out = run_cli(["art", str(good), "--size", "8x8"])
            self.assertEqual(code, 0)
            self.assertTrue(all(set(c) == {"rule", "check", "ok", "detail"} for c in out))
            code, out = run_cli(["art", str(bad), "--size", "8x8"])
            self.assertEqual(code, 1)
            self.assertEqual({c["rule"] for c in out if not c["ok"]}, {6})
            self.assertEqual(run_cli(["art", str(bad), "--greenbull"])[0], 0)
            self.assertEqual(run_cli(["art", str(bad), "--allow-colour", "247,208,52"])[0], 0)
            self.assertEqual(run_cli(["art", str(bad), "--allow-red", "247,208,52"])[0], 0)  # the old name
            self.assertEqual(run_cli(["art", str(good), "--size", "4x8", "--frames", "2"])[0], 0)
            self.assertEqual(run_cli(["art", str(good), "--size", "4", "--frames", "2"])[0], 1)
            code, out = run_cli(["art", str(ROOT / "art-archive/T-295/greenbull_wordmark.png"), "--logo"])
            self.assertEqual(code, 0)
            self.assertEqual(run_cli(["art", str(ROOT / "art-archive/T-294/greenbull_emblem_32.png"), "--logo"])[0], 0)

    def test_cli_art_help_names_greenbull_not_the_old_flag(self):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), self.assertRaises(SystemExit):
            s.main(["art", "--help"])
        self.assertIn("--greenbull", out.getvalue())
        self.assertNotIn("--redgull", out.getvalue())


class TextChecks(unittest.TestCase):
    def test_popup(self):
        self.assertEqual(failed(s.text_checks("COMBO BROKEN!", "popup")), set())
        self.assertEqual(failed(s.text_checks("AIR 360!", "popup")), set())
        self.assertEqual(failed(s.text_checks("combo broken", "popup")),
                         {(4, "popup: in capitals"), (4, 'popup: ends with "!"')})
        self.assertIn((4, "popup: one line"), failed(s.text_checks("LONG\nDRIFT!", "popup")))

    def test_rule_2_banned_words(self):
        rule2 = (2, "no banned words (XP, points, Godzilla, Redgull)")
        for bad in ("Gain more XP", "+50 points", "The godzilla is here"):
            self.assertEqual(failed(s.text_checks(bad, "card_desc")), {rule2}, bad)
        self.assertEqual(failed(s.text_checks("Gain more likes", "card_desc")), set())
        self.assertEqual(failed(s.text_checks("Expert pointers", "card_desc")), set())  # whole words only

    def test_rule_2_old_sponsor_name_is_banned_in_any_case(self):
        rule2 = (2, "no banned words (XP, points, Godzilla, Redgull)")
        for bad in ("A gift from Redgull", "A GIFT FROM REDGULL", "a gift from redgull"):
            self.assertEqual(failed(s.text_checks(bad, "card_desc")), {rule2}, bad)

    def test_rule_3_greenbull_says(self):
        self.assertEqual(failed(s.text_checks("Greenbull says hi", "card_desc")), {(3, 'no "Greenbull says ..." line')})
        self.assertEqual(failed(s.text_checks("Greenbull wants you to drift", "card_desc")), set())

    def test_greenbull_alone_passes_rules_2_and_3(self):
        for kind in ("card_desc", "label"):
            self.assertEqual(failed(s.text_checks("A gift from Greenbull", kind)), set(), kind)

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
        self.assertEqual(failed(s.text_checks("Greenbull Stunt Driver", "label")), set())
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
