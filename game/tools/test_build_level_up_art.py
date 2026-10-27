"""Tests for build_level_up_art.py (tasks T-140, T-303: the level-up screen in Greenbull's colours).

Run: python -m unittest discover -s game/tools -p "test_build_level_up_art.py"
"""
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_level_up_art as art  # noqa: E402
import style_rules as rules  # noqa: E402

SIZES = {"card_frame": (180, 150), "highlight_frame": (192, 162), "header_ribbon": (380, 44),
         "button_plate": (72, 22), "button_plate_pressed": (72, 22), "sunburst": (256, 256),
         "gift_pack_emblem": (128, 128)}


def opaque(im):
    return Counter(p[:3] for p in im.getdata() if p[3] == 255)


def build_into(folder):
    old = art.OUT
    art.OUT = Path(folder)
    try:
        art.build()
    finally:
        art.OUT = old


class BuiltPieces(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.dir = Path(cls.tmp.name) / "a"
        build_into(cls.dir)
        cls.ims = {n: Image.open(cls.dir / (n + ".png")).convert("RGBA") for n in art.FILES}

    @classmethod
    def tearDownClass(cls):
        for im in cls.ims.values():
            im.close()
        cls.tmp.cleanup()

    def test_every_piece_passes_the_rules(self):
        for name in art.FILES:
            results, _ = art.check_png(self.dir / (name + ".png"))
            self.assertTrue(all(r[1] for r in results), (name, results))
            self.assertTrue((self.dir / (name + ".json")).exists())

    def test_same_names_and_sizes_as_before(self):
        self.assertEqual({n: im.size for n, im in self.ims.items()}, SIZES)

    def test_no_red_and_style_rules_pass_with_greenbull(self):
        for name in art.FILES:
            _, _, rows = rules.decode_png((self.dir / (name + ".png")).read_bytes())
            self.assertFalse([p for r in rows for p in r if p[3] == 255 and rules.reads_as_red(p)], name)
            checks = rules.art_checks(rows, SIZES[name], greenbull=True)
            self.assertTrue(all(c["ok"] for c in checks), (name, [c for c in checks if not c["ok"]]))

    def test_dark_green_leads(self):
        """Greenbull's dark greens are most of the framing pieces (the card's pale paper left out)."""
        for name in ("card_frame", "sunburst", "gift_pack_emblem"):
            cols = opaque(self.ims[name])
            if name == "card_frame":
                cols = Counter({c: n for c, n in cols.items() if c not in (art.CREAM, art.CREAM_D)})
            greens = sum(n for c, n in cols.items() if c[1] > c[0] and c[1] > c[2] and c[1] < 120)
            self.assertGreater(greens, sum(cols.values()) / 2, name)
        self.assertIn(art.DG, opaque(self.ims["sunburst"]))

    def test_ribbon_field_is_dark_green_with_light_green_trim(self):
        """T-311: Greenbull's dark green is the ribbon's centre field and its most common colour;
        light green stays in the trim, with the thin yellow line on top."""
        im = self.ims["header_ribbon"]
        cols = opaque(im)
        self.assertEqual(cols.most_common(1)[0][0], art.DG)
        # The title area (art x 76..304) is plain dark green across the field's middle rows.
        for y in range(10, 34):
            for x in range(76, 305):
                self.assertEqual(im.getpixel((x, y))[:3], art.DG, (x, y))
        # Light green trim above and below the field, and the yellow line on top.
        for x in range(76, 305):
            self.assertEqual(im.getpixel((x, 3))[:3], art.YEL, x)
            self.assertEqual(im.getpixel((x, 5))[:3], art.LG, x)
            self.assertEqual(im.getpixel((x, 38))[:3], art.LG, x)
        # Light green only in the trim: no light green below row 7 or above row 36 in the body.
        for y in range(8, 36):
            for x in range(76, 305):
                self.assertNotEqual(im.getpixel((x, y))[:3], art.LG, (x, y))

    def test_ribbon_record_names_t311(self):
        import json
        rec = json.loads((self.dir / "header_ribbon.json").read_text(encoding="utf-8"))
        self.assertEqual(rec["task"], "T-311")
        self.assertIn("art-archive/T-311/t303/", rec["earlier"])
        self.assertIsNone(rec["prompt"])
        for name in art.FILES:
            if name not in art.DARK_FIELD:
                rec = json.loads((self.dir / (name + ".json")).read_text(encoding="utf-8"))
                self.assertEqual(rec["task"], "T-303", name)

    def test_yellow_is_a_small_accent(self):
        for name in art.FILES:
            cols = opaque(self.ims[name])
            yellow = sum(n for c, n in cols.items()
                         if c in (art.YEL, art.YEL_L) or rules.greenbull_colour(c) == art.YEL)
            # The highlight frame is hollow: one line of its six rings is yellow, so its share is higher.
            share = 0.2 if name == "highlight_frame" else 0.06
            self.assertLessEqual(yellow, sum(cols.values()) * share, name)

    def test_emblem_stamped_on_the_ribbon_and_the_box(self):
        logo = Image.open(art.EMBLEM_32).convert("RGBA")
        for name, centres in (("header_ribbon", [(46, 22), (380 - 47, 22)]), ("gift_pack_emblem", [(63, 91)])):
            for cx, cy in centres:
                for y in range(32):
                    for x in range(32):
                        p = logo.getpixel((x, y))
                        if p[3] == 255:
                            self.assertEqual(self.ims[name].getpixel((cx - 16 + x, cy - 16 + y)), p, (name, x, y))

    def test_no_gull_left(self):
        """None of the old logo's colours survive anywhere (its black aside)."""
        # The old logo files are in art-archive/T-075/ since T-312.
        old_logo = art.GAME.parent / "art-archive" / "T-075" / (rules.OLD_BRAND.lower() + "_logo_32.png")
        gull = set(opaque(Image.open(old_logo).convert("RGBA")))
        gull -= {(0, 0, 0)}
        for name, im in self.ims.items():
            self.assertFalse(gull & set(opaque(im)), name)

    def test_build_is_byte_identical(self):
        b = Path(self.tmp.name) / "b"
        build_into(b)
        for name in art.FILES:
            self.assertEqual((self.dir / (name + ".png")).read_bytes(), (b / (name + ".png")).read_bytes(), name)

    def test_piece_matches_build(self):
        one = Path(self.tmp.name) / "one"
        for name in art.FILES:
            art.write_piece(name, one / (name + ".png"))
            self.assertEqual((one / (name + ".png")).read_bytes(), (self.dir / (name + ".png")).read_bytes(), name)

    def test_committed_pieces_are_up_to_date(self):
        for name in art.FILES:
            self.assertEqual((art.GAME / "art" / "level_up" / (name + ".png")).read_bytes(),
                             (self.dir / (name + ".png")).read_bytes(), name)


class GiftBox(unittest.TestCase):
    def test_recolour_covers_every_raw_colour(self):
        raw = opaque(Image.open(art.RAW_BOX).convert("RGBA"))
        self.assertLessEqual(set(raw), set(art.BOX_MAP))

    def test_sparkles_turn_yellow_and_the_ribbon_light_green(self):
        cols = opaque(art.recolour_box(Image.open(art.RAW_BOX).convert("RGBA")))
        self.assertTrue(any(c in cols for c in art.SPARKLE_MAP.values()))
        self.assertIn(art.LG, cols)

    def test_raw_gift_box_is_left_alone(self):
        before = art.RAW_BOX.read_bytes()
        art.gift_pack_emblem()
        self.assertEqual(art.RAW_BOX.read_bytes(), before)


class Archive(unittest.TestCase):
    def test_archive_never_overwrites(self):
        with tempfile.TemporaryDirectory() as t:
            src, dst = Path(t) / "src", Path(t) / "dst"
            src.mkdir()
            dst.mkdir()
            (src / "card_frame.png").write_bytes(b"new")
            (dst / "card_frame.png").write_bytes(b"old")
            (src / "sunburst.png").write_bytes(b"sun")
            copied = art.archive_old(src, dst)
            self.assertEqual((dst / "card_frame.png").read_bytes(), b"old")
            self.assertEqual(copied, ["sunburst.png"])

    def test_archive_only_the_named_pieces(self):
        with tempfile.TemporaryDirectory() as t:
            src, dst = Path(t) / "src", Path(t) / "dst"
            src.mkdir()
            for name in ("header_ribbon", "card_frame"):
                (src / (name + ".png")).write_bytes(name.encode())
            self.assertEqual(art.archive_old(src, dst, names=("header_ribbon",)), ["header_ribbon.png"])
            self.assertFalse((dst / "card_frame.png").exists())

    def test_t303_light_green_ribbon_kept_in_the_archive(self):
        """T-311 changed only the ribbon; T-303's light green version is kept, never overwritten."""
        for name in art.DARK_FIELD:
            path = art.T303_ARCHIVE / (name + ".png")
            self.assertTrue(path.exists(), name)
            self.assertTrue((art.T303_ARCHIVE / (name + ".json")).exists(), name)
            with Image.open(path) as im:
                im = im.convert("RGBA")
                self.assertEqual(im.size, SIZES[name])
                self.assertEqual(im.getpixel((190, 22))[:3], art.LG)

    def test_old_red_and_gold_kept_in_the_archive(self):
        for name in art.FILES:
            self.assertTrue((art.OLD_ARCHIVE / (name + ".png")).exists(), name)
            with Image.open(art.OLD_ARCHIVE / (name + ".png")) as im:
                self.assertEqual(im.size, SIZES[name], name)


if __name__ == "__main__":
    unittest.main()
