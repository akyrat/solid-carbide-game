import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

from PIL import Image

import car_frame_check as cfc


def square_frame(colour=(40, 120, 60, 255), box=(50, 50, 70, 70), extra=()):
    im = Image.new("RGBA", (cfc.F, cfc.F), (0, 0, 0, 0))
    px = im.load()
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            px[x, y] = colour
    for (x, y) in extra:
        px[x, y] = colour
    return im


class CarFrameCheckTest(unittest.TestCase):
    def test_edge_report_counts_non_dark_edge_pixels(self):
        rows = cfc.rows_of(square_frame())
        r = cfc.edge_report(rows)
        self.assertEqual(r["edge_px"], 76)          # the perimeter of a 20 x 20 square
        self.assertEqual(r["edge_not_dark"], 76)    # none of it is near-black
        self.assertEqual(r["not_dark_share"], 1.0)

    def test_islands_sorted_largest_first(self):
        rows = cfc.rows_of(square_frame(extra=[(10, 10), (11, 10)]))
        self.assertEqual([len(c) for c in cfc.islands(rows)], [400, 2])

    def test_fix_closes_outline_drops_strays_adds_shadow_and_keeps_car_pixels(self):
        with tempfile.TemporaryDirectory() as d:
            src = Path(d) / "in.png"
            out = Path(d) / "out.png"
            square_frame(extra=[(10, 10), (11, 10)]).save(src)
            cfc.cmd_fix(Namespace(candidate=str(src), out=str(out), max_island=3, outline_colour="6,2,27",
                                  highlight=150.0, shadow_dy=4, shadow_dx=0, shadow_colour="10,4,31"))
            im = Image.open(out).convert("RGBA")
            px = im.load()
            self.assertEqual(px[10, 10][3], 0)                       # stray island removed
            self.assertEqual(px[49, 60], (6, 2, 27, 255))            # outline left of the square
            self.assertEqual(px[60, 49], (6, 2, 27, 255))            # outline above it
            self.assertEqual(px[60, 60], (40, 120, 60, 255))         # the car's own pixel kept
            self.assertEqual(px[60, 72], (10, 4, 31, 255))           # shadow below the outline
            self.assertEqual(px[60, 75], (0, 0, 0, 0))               # and no further than 4 px
            self.assertEqual(cfc.edge_report(cfc.rows_of(im))["edge_not_dark"], 0)
            with self.assertRaises(SystemExit):                      # never overwrites
                cfc.cmd_fix(Namespace(candidate=str(src), out=str(out), max_island=3, outline_colour="6,2,27",
                                      highlight=150.0, shadow_dy=0, shadow_dx=0, shadow_colour="10,4,31"))

    def test_bright_highlights_keep_breaking_the_outline(self):
        with tempfile.TemporaryDirectory() as d:
            src = Path(d) / "in.png"
            out = Path(d) / "out.png"
            square_frame(colour=(240, 240, 240, 255)).save(src)
            cfc.cmd_fix(Namespace(candidate=str(src), out=str(out), max_island=3, outline_colour="6,2,27",
                                  highlight=150.0, shadow_dy=0, shadow_dx=0, shadow_colour="10,4,31"))
            self.assertEqual(Image.open(out).convert("RGBA").getpixel((49, 60)), (0, 0, 0, 0))


class PolishTest(unittest.TestCase):
    def test_despeckle_replaces_a_lone_bright_pixel_and_keeps_a_pair(self):
        im = square_frame()
        px = im.load()
        px[60, 60] = (240, 240, 240, 255)                 # a lone speck inside the green
        px[55, 55] = px[56, 55] = (240, 240, 240, 255)    # a 2-pixel run: a highlight, kept
        rows = cfc.rows_of(im)
        self.assertEqual(cfc.despeckle(rows), 1)
        self.assertEqual(rows[60][60], (40, 120, 60, 255))
        self.assertEqual(rows[55][55], (240, 240, 240, 255))
        self.assertEqual(rows[55][56], (240, 240, 240, 255))
        self.assertEqual(cfc.despeckle(rows), 0)         # edge pixels of the square are not specks

    def test_drop_rows_shortens_by_n_and_keeps_the_bottom_in_place(self):
        im = square_frame(box=(50, 40, 70, 90))
        px = im.load()
        for x in range(50, 70):
            px[x, 60] = (200, 200, 200, 255)             # a distinct line: never the most redundant row
        rows = cfc.rows_of(im)
        removed = cfc.drop_rows(rows, 3, band=(45, 85))
        self.assertEqual(len(removed), 3)
        ys = [y for y in range(cfc.F) if rows[y][60][3]]
        self.assertEqual((min(ys), max(ys)), (43, 89))   # 47 rows tall, bottom unchanged
        self.assertEqual(sum(1 for y in range(cfc.F) if rows[y][60] == (200, 200, 200, 255)), 1)

    def test_smooth_shadow_removes_a_spike_and_fills_a_notch(self):
        shadow = (10, 4, 31)
        im = square_frame(colour=shadow + (255,), box=(50, 50, 70, 70))
        px = im.load()
        px[60, 72] = shadow + (255,)                      # a spike two rows under the block
        px[60, 69] = (0, 0, 0, 0)                         # a notch in the bottom edge
        rows = cfc.rows_of(im)
        removed, added = cfc.smooth_shadow(rows, shadow, passes=1)
        self.assertEqual((removed, added), (1, 1))
        self.assertEqual(rows[72][60][3], 0)
        self.assertEqual(rows[69][60], shadow + (255,))

    def test_smooth_shadow_never_fills_a_notch_beside_car_colours(self):
        rows = cfc.rows_of(square_frame())               # green block
        rows[69][60] = (0, 0, 0, 0)
        self.assertEqual(cfc.smooth_shadow(rows, (10, 4, 31), passes=1), (0, 0))


class ColourFixTest(unittest.TestCase):
    def test_colour_specks_replaces_lone_pixels_and_keeps_runs(self):
        pink = (246, 221, 248)
        im = square_frame()
        px = im.load()
        px[60, 60] = pink + (255,)                        # a lone pink speck inside the green
        for x in range(52, 56):
            for y in range(52, 56):
                px[x, y] = pink + (255,)                  # a 4 x 4 pink window: kept
        rows = cfc.rows_of(im)
        self.assertEqual(cfc.colour_specks(rows, [pink]), 1)
        self.assertEqual(rows[60][60], (40, 120, 60, 255))
        self.assertEqual(rows[53][53], pink + (255,))
        self.assertEqual(cfc.colour_specks(rows, [pink]), 0)

    def test_colour_specks_min_run_two_replaces_a_pair(self):
        pink = (246, 221, 248)
        im = square_frame()
        px = im.load()
        px[60, 60] = px[61, 60] = pink + (255,)
        rows = cfc.rows_of(im)
        self.assertEqual(cfc.colour_specks(rows, [pink], min_run=2), 2)
        self.assertEqual(rows[60][61], (40, 120, 60, 255))

    def test_recolour_all_and_shadow_only(self):
        src, dst = (12, 10, 33), (10, 4, 31)
        rows = cfc.rows_of(square_frame(colour=src + (255,)))
        rows[60][60] = (40, 120, 60, 255)
        self.assertEqual(cfc.recolour(rows, src, dst, only={(50, 50), (51, 50)}), 2)
        self.assertEqual(rows[50][50], dst + (255,))
        self.assertEqual(rows[50][52], src + (255,))
        self.assertEqual(cfc.recolour(rows, src, dst), 397)
        self.assertEqual(rows[60][60], (40, 120, 60, 255))
        self.assertEqual(cfc.colour_counts(rows), {dst: 399, (40, 120, 60): 1})

    def test_recolour_box_and_next_to(self):
        src, dst, white = (12, 10, 33), (10, 4, 31), (237, 251, 251)
        rows = cfc.rows_of(square_frame(colour=src + (255,)))
        self.assertEqual(cfc.recolour(rows, src, dst, box=(50, 50, 52, 52)), 4)
        self.assertEqual(rows[51][51], dst + (255,))
        self.assertEqual(rows[52][52], src + (255,))
        rows[60][60] = white + (255,)
        self.assertEqual(cfc.recolour(rows, src, dst, next_to=white), 8)   # the 8 neighbours of the white pixel
        self.assertEqual(rows[59][59], dst + (255,))
        self.assertEqual(rows[58][58], src + (255,))
        self.assertEqual(rows[60][60], white + (255,))
        rows = cfc.rows_of(square_frame(colour=src + (255,)))
        self.assertEqual(cfc.recolour(rows, src, dst, diag=(100, 101)), 3)   # (50,50), (50,51), (51,50)
        self.assertEqual(rows[50][50], dst + (255,))
        self.assertEqual(rows[51][51], src + (255,))

    def test_smooth_edge_removes_a_spike_and_fills_a_notch(self):
        green, outline = (40, 120, 60, 255), (6, 2, 27)
        im = square_frame()
        px = im.load()
        px[72, 60] = green                                # a spike two columns right of the square
        px[69, 60] = (0, 0, 0, 0)                         # a notch in the right edge
        rows = cfc.rows_of(im)
        self.assertEqual(cfc.smooth_edge(rows, outline), (1, 1))
        self.assertEqual(rows[60][72][3], 0)
        self.assertEqual(rows[60][69], outline + (255,))
        self.assertEqual(rows[60][60], green)

    def test_cast_shadow_paints_only_transparent_pixels(self):
        shadow = (10, 4, 31)
        rows = cfc.rows_of(square_frame())
        self.assertEqual(cfc.cast_shadow(rows, -1, 4, shadow), 400 - 19 * 16)  # the shifted square minus the overlap
        self.assertEqual(rows[72][60], shadow + (255,))
        self.assertEqual(rows[60][49], shadow + (255,))
        self.assertEqual(rows[60][60], (40, 120, 60, 255))
        self.assertEqual(rows[75][60][3], 0)
        rows2 = cfc.rows_of(square_frame())
        self.assertGreater(cfc.cast_shadow(rows2, 0, 2, shadow, grow=1), 40)
        self.assertEqual(rows2[52][49], shadow + (255,))  # the grown ring, shifted down 2, shows beside the square
        before = sum(1 for r in rows2 for p in r if p[3])
        stripped = cfc.strip_shadow(rows2)                # the shadow that touches the background goes
        self.assertGreater(stripped, 0)
        self.assertEqual(sum(1 for r in rows2 for p in r if p[3]), before - stripped)
        self.assertEqual(rows2[60][60], (40, 120, 60, 255))

    def test_cmd_specks_and_recolour_write_new_files_only(self):
        pink = (246, 221, 248)
        with tempfile.TemporaryDirectory() as d:
            src = Path(d) / "in.png"
            out = Path(d) / "out.png"
            im = square_frame()
            im.load()[60, 60] = pink + (255,)
            im.save(src)
            cfc.cmd_specks(Namespace(candidate=str(src), colour=["246,221,248"], min_run=1, out=str(out)))
            self.assertEqual(Image.open(out).convert("RGBA").getpixel((60, 60)), (40, 120, 60, 255))
            with self.assertRaises(SystemExit):
                cfc.cmd_recolour(Namespace(candidate=str(src), src="40,120,60", dst="10,4,31", shadow_only=False,
                                           out=str(out)))
            out2 = Path(d) / "out2.png"
            cfc.cmd_recolour(Namespace(candidate=str(src), src="40,120,60", dst="10,4,31", shadow_only=False,
                                       out=str(out2)))
            self.assertEqual(Image.open(out2).convert("RGBA").getpixel((55, 55)), (10, 4, 31, 255))


if __name__ == "__main__":
    unittest.main()
