"""Tests for build_hud_mission_art.py (T-464). Run with the Python tool tests (game/README.md)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_mission_art as art  # noqa: E402

GREENBULL = [(104, 220, 96), (247, 208, 52)]


class Page(unittest.TestCase):
    def setUp(self):
        self.im = art.page()
        self.px = self.im.load()

    def test_size_and_mode(self):
        self.assertEqual(self.im.size, (88, 90))
        self.assertEqual(self.im.mode, "RGBA")

    def test_only_opaque_or_clear_and_few_colours(self):
        colours = set(self.im.getdata())
        self.assertTrue(all(c[3] in (0, 255) for c in colours))
        self.assertLessEqual(len([c for c in colours if c[3] == 255]), 30)

    def test_no_greenbull_colours(self):
        for c in self.im.getdata():
            if c[3] == 255:
                for g in GREENBULL:
                    self.assertGreater(sum(abs(c[k] - g[k]) for k in range(3)), 60)

    def test_corners_are_clear_and_outline_is_dark(self):
        self.assertEqual(self.px[0, 0][3], 0)
        self.assertEqual(self.px[87, 89][3], 0)
        self.assertEqual(self.px[87, 45], art.OUT)
        self.assertEqual(self.px[45, 89], art.OUT)

    def test_ruled_lines_every_ten_from_24(self):
        for y in range(24, 88, 10):
            self.assertEqual(self.px[45, y][:3], art.RULE, y)
            if y + 5 < 86:
                self.assertEqual(self.px[45, y + 5][:3], art.PAPER, y)

    def test_margin_line(self):
        self.assertEqual(self.px[art.MARGIN_X, 40][:3], art.MARGIN)

    def test_header_band_and_writing_area_are_plain(self):
        allowed = {art.PAPER, art.RULE}
        for y in range(art.TAPE_BOX[3] + 1, art.HEADER_BOTTOM + 1):
            for x in range(art.WRITE_X[0], art.WRITE_X[1] + 1):
                self.assertEqual(self.px[x, y][:3], art.PAPER, (x, y))
        for y in range(art.HEADER_BOTTOM + 1, 86):
            for x in range(art.WRITE_X[0], art.WRITE_X[1] - 3):
                self.assertIn(self.px[x, y][:3], allowed, (x, y))

    def test_binding_holes_are_punched_through(self):
        for hy in art.HOLE_ROWS:
            self.assertEqual(self.px[art.HOLE_X, hy][3], 0)
            self.assertEqual(self.px[art.HOLE_X - 1, hy], art.OUT)

    def test_deterministic(self):
        self.assertEqual(list(art.page().getdata()), list(self.im.getdata()))


class Marks(unittest.TestCase):
    def test_sizes_modes_and_clean_pixels(self):
        for fn, size in ((art.checkbox, (7, 7)), (art.tick, (7, 7)), (art.cross, (24, 4))):
            im = fn()
            self.assertEqual(im.size, size)
            self.assertEqual(im.mode, "RGBA")
            colours = set(im.getdata())
            self.assertTrue(all(c[3] in (0, 255) for c in colours))
            self.assertLessEqual(len(colours), 30)
            for c in colours:
                if c[3] == 255:
                    for g in GREENBULL:
                        self.assertGreater(sum(abs(c[k] - g[k]) for k in range(3)), 60)
            self.assertEqual(list(fn().getdata()), list(im.getdata()))

    def test_checkbox_ink_outline_and_opaque_paper_inside(self):
        px = art.checkbox().load()
        self.assertEqual(px[3, 0][:3], art.INK)
        self.assertEqual(px[0, 3][:3], art.INK)
        self.assertEqual(px[6, 3][:3], art.INK)
        self.assertEqual(px[3, 6][:3], art.INK)
        for corner in ((0, 0), (6, 0), (0, 6), (6, 6)):
            self.assertEqual(px[corner][3], 0, corner)
        inside = {px[x, y] for x in range(1, 6) for y in range(1, 6)}
        self.assertTrue(all(c[3] == 255 for c in inside))
        self.assertEqual({c[:3] for c in inside}, {art.PAPER, art.PAPER_LIGHT})

    def test_tick_is_ink_on_clear(self):
        im = art.tick()
        self.assertEqual({c for c in im.getdata()}, {art.CLEAR, art.rgba(art.INK)})
        px = im.load()
        self.assertEqual(px[5, 0][:3], art.INK)          # the flick reaches the top row
        for corner in ((0, 0), (6, 0), (0, 6), (6, 6)):
            self.assertEqual(px[corner][3], 0, corner)

    def test_cross_middle_tiles(self):
        im = art.cross()
        px = im.load()
        cols = [tuple(px[x, y] for y in range(4)) for x in range(art.CROSS_REPEAT[0], art.CROSS_REPEAT[1] + 1)]
        self.assertEqual(len(set(cols)), 1)
        self.assertEqual(cols[0], tuple(px[art.CROSS_REPEAT[0] - 1, y] for y in range(4)))
        self.assertEqual(cols[0], tuple(px[art.CROSS_REPEAT[1] + 1, y] for y in range(4)))
        for x in (0, 23):
            self.assertEqual(sum(px[x, y][3] == 255 for y in range(4)), 1)


class Save(unittest.TestCase):
    def test_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "p.png"
            art.save(art.page(), out)
            with self.assertRaises(FileExistsError):
                art.save(art.page(), out)


class CardFrame(unittest.TestCase):
    def setUp(self):
        self.im = art.card_frame()
        self.px = self.im.load()

    def test_size_mode_alpha_and_colours(self):
        self.assertEqual(self.im.size, (170, 170))
        colours = set(self.im.getdata())
        self.assertTrue(all(c[3] in (0, 255) for c in colours))
        self.assertLessEqual(len([c for c in colours if c[3] == 255]), 30)

    def test_no_greenbull_colours_and_no_green(self):
        for c in set(self.im.getdata()):
            if c[3] == 255:
                for g in GREENBULL:
                    self.assertGreater(sum(abs(c[k] - g[k]) for k in range(3)), 60)
                self.assertFalse(c[1] > c[0] and c[1] > c[2], c)

    def test_stepped_corners_and_outline(self):
        for x, y in [(0, 0), (1, 0), (0, 1), (169, 169), (168, 169), (169, 168)]:
            self.assertEqual(self.px[x, y][3], 0)
        for x, y in [(2, 0), (1, 1), (0, 2), (85, 0), (0, 85), (169, 85), (85, 169)]:
            self.assertEqual(self.px[x, y], art.OUT)

    def test_middle_is_flat_steel(self):
        steel = art.rgba(art.STEEL)
        for y in range(art.CARD_MARGIN, 170 - art.CARD_MARGIN):
            for x in range(art.CARD_MARGIN, 170 - art.CARD_MARGIN):
                self.assertEqual(self.px[x, y], steel)

    def test_amber_frame_light_top_left_dark_bottom_right(self):
        self.assertEqual(self.px[85, 4], art.rgba(art.AMBER))
        self.assertEqual(self.px[85, 1], art.rgba(art.AMBER_LIGHT))
        self.assertEqual(self.px[1, 85], art.rgba(art.AMBER_LIGHT))
        self.assertEqual(self.px[85, 168], art.rgba(art.AMBER_SHADE))
        self.assertEqual(self.px[168, 85], art.rgba(art.AMBER_SHADE))

    def test_bolts_in_each_corner_and_hazard_stripes(self):
        bolt = {art.rgba(art.BOLT), art.rgba(art.BOLT_LIGHT), art.rgba(art.BOLT_SHADE), art.OUT}
        for x, y in [(4, 4), (165, 4), (4, 165), (165, 165)]:
            self.assertIn(self.px[x, y], bolt)
        for x0, x1 in art.HAZARD_SPANS:
            row = {self.px[x, 4] for x in range(x0, x1 + 1)}
            self.assertEqual(row, {art.rgba(art.AMBER), art.rgba(art.HAZARD_DARK)})

    def test_cli_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "card.png"
            art.main(["card", "--out", str(out)])
            with self.assertRaises(FileExistsError):
                art.main(["card", "--out", str(out)])


class CardFrameV2(unittest.TestCase):
    def setUp(self):
        self.im = art.card_frame_v2()
        self.px = self.im.load()

    def test_rules(self):
        self.assertEqual(self.im.size, (170, 170))
        colours = set(self.im.getdata())
        self.assertTrue(all(c[3] in (0, 255) for c in colours))
        self.assertLessEqual(len([c for c in colours if c[3] == 255]), 30)
        for c in colours:
            if c[3] == 255:
                for g in GREENBULL:
                    self.assertGreater(sum(abs(c[k] - g[k]) for k in range(3)), 60)
                self.assertFalse(c[1] > c[0] and c[1] > c[2], c)
        for x, y in [(0, 0), (1, 0), (0, 1), (169, 169)]:
            self.assertEqual(self.px[x, y][3], 0)

    def test_middle_is_flat_steel(self):
        steel = art.rgba(art.STEEL)
        for y in range(art.CARD_MARGIN, 170 - art.CARD_MARGIN):
            for x in range(art.CARD_MARGIN, 170 - art.CARD_MARGIN):
                self.assertEqual(self.px[x, y], steel)

    def test_two_px_bevel_bands(self):
        for y in (1, 2):
            self.assertEqual(self.px[90, y], art.rgba(art.AMBER_BRIGHT))
            self.assertEqual(self.px[y, 90], art.rgba(art.AMBER_BRIGHT))
            self.assertEqual(self.px[90, 169 - y], art.rgba(art.AMBER_DEEP))
            self.assertEqual(self.px[169 - y, 90], art.rgba(art.AMBER_DEEP))

    def test_bolts_have_highlight_and_slot(self):
        for x0, y0 in [(2, 2), (162, 2), (2, 162), (162, 162)]:
            self.assertEqual(self.px[x0 + 1, y0 + 1], art.rgba(art.BOLT2_LIGHT))
            self.assertEqual([self.px[x0 + i, y0 + 3] for i in range(1, 5)], [art.OUT] * 4)

    def test_rivet_line(self):
        self.assertEqual(self.px[4, 20], art.rgba(art.BOLT2_LIGHT))
        self.assertEqual(self.px[80, 4], art.rgba(art.BOLT2_LIGHT))


if __name__ == "__main__":
    unittest.main()
