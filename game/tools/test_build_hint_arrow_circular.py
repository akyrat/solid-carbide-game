"""Tests for build_hint_arrow_circular.py (T-577): run with
python -m unittest discover -s game/tools -p test_build_hint_arrow_circular.py -t game/tools"""
import base64
import math
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hint_arrow_circular as ring  # noqa: E402

GREENBULL = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


def opaque_colours(im):
    return {p[:3] for p in im.getdata() if p[3] == 255}


def at_angle(degrees, radius):
    """The pixel at a polar position round the ring's centre (y down, so angles increase clockwise)."""
    x = ring.CENTRE[0] + radius * math.cos(math.radians(degrees))
    y = ring.CENTRE[1] + radius * math.sin(math.radians(degrees))
    return int(x), int(y)


class TestInit(unittest.TestCase):
    def setUp(self):
        self.im = ring.arrow()
        self.px = self.im.load()
        self.cells = ring.arrow_cells()

    def test_is_a_64_px_rgba_sprite_with_hard_alpha_and_few_colours(self):
        self.assertEqual(self.im.size, (64, 64))
        self.assertEqual(self.im.mode, "RGBA")
        self.assertTrue(all(p[3] in (0, 255) for p in self.im.getdata()))
        self.assertLessEqual(len(opaque_colours(self.im)), 30)
        self.assertTrue(opaque_colours(self.im) <= {c[:3] for c in ring.PALETTE})
        self.assertFalse(opaque_colours(self.im) & GREENBULL)
        for corner in ((0, 0), (63, 0), (0, 63), (63, 63)):
            self.assertEqual(self.px[corner][3], 0)

    def test_is_a_centred_ring_about_54_px_across_with_a_hole(self):
        xs = {x for x, y in self.cells}
        self.assertEqual((min(xs), max(xs)), (5, 58))                       # 54 columns
        self.assertEqual(max(y for x, y in self.cells), 60)                 # the ring's bottom: rows 7..60
        self.assertEqual(self.px[32, 34][3], 0)                             # the hole
        self.assertEqual(self.px[at_angle(135, 6)][3], 0)
        self.assertEqual(self.px[at_angle(225, 12)][3], 0)
        for degrees in (10, 45, 90, 135, 180, 225, 260):                    # the 13 px stroke all the way round
            for radius in (15, 20, 26):
                self.assertIn(at_angle(degrees, radius), self.cells, (degrees, radius))
        self.assertEqual({x for x in range(32) if self.px[x, 34][3] == 255}, set(range(5, 18)))

    def test_runs_clockwise_with_a_gap_at_the_top_right_and_the_head_at_the_top_pointing_right(self):
        # The gap: nothing on the ring between the head's tip and the tail's cut.
        for radius in (15, 20, 26):
            self.assertNotIn(at_angle(-40, radius), self.cells, radius)
        self.assertNotIn((52, 15), self.cells)
        # The tail's flat cut is level with the centre on the right, the head at the top: increasing angle
        # (clockwise on screen).
        self.assertIn(at_angle(5, 20), self.cells)
        self.assertNotIn(at_angle(-5, 20), self.cells)
        self.assertEqual({x for x in range(64) if self.px[x, 33][3] == 255 and x > 40}, set())
        self.assertEqual({x for x in range(64) if self.px[x, 35][3] == 255 and x > 40}, set(range(46, 59)))
        # The head: its tip on rows 13 and 14 at column 44, pointing right, its base 26 px tall at column 32.
        self.assertEqual({y for y in range(64) if self.px[44, y][3] == 255 and y < 30}, {13, 14})
        self.assertEqual({y for y in range(64) if self.px[32, y][3] == 255 and y < 30}, set(range(1, 27)))
        # Between the head and the tail's cut, the gap and the hole: nothing in the head's columns there.
        self.assertFalse({(x, y) for x, y in self.cells if 40 < x < 46 and 18 <= y <= 33})
        self.assertEqual(self.px[45, 13][3], 0)
        self.assertEqual(self.px[45, 14][3], 0)

    def test_has_outline_edge_line_rim_light_stepped_shade_and_glints_breaking_the_outline(self):
        colours = opaque_colours(self.im)
        for c in ring.PALETTE:
            self.assertIn(c[:3], colours)
        self.assertEqual(len(colours), 9)
        lay = ring.layers()
        outer = {p for p in self.cells if any(q not in self.cells for q in ring.nbrs8(p))}
        inner = {p for p in self.cells - outer if any(q in outer for q in ring.nbrs8(p))}
        self.assertTrue(lay["glint"])
        self.assertTrue(lay["glint"] <= outer)                              # the runs sit on the outer ring only
        self.assertTrue(inner <= lay["outline"])                            # the inner ring is never broken
        self.assertEqual(outer, (lay["outline"] & outer) | lay["glint"])
        self.assertLessEqual(len(lay["glint"]), int(0.2 * len(outer)))      # short, deliberate runs
        # Two runs on the ring's upper-left outer edge, one on the head's upper slope, the tip's outline dark.
        upper_left = {p for p in lay["glint"] if p[0] < 32 and p[1] < 34}
        self.assertTrue(upper_left)
        self.assertGreaterEqual(len({p[1] for p in upper_left}), 12)       # two runs, not one speck
        self.assertTrue({p for p in lay["glint"] if 36 <= p[0] <= 41 and p[1] < 13})
        self.assertFalse({p for p in lay["glint"] if p[0] >= 42})
        self.assertFalse({p for p in lay["glint"] if p[1] > 34})
        # Across the ring's left side (row 34): the lit outer edge with its near-white edge line and rim light,
        # the plain body, then the five shade steps ending in the cool plum against the hole's outline.
        row = [self.px[x, 34] for x in range(5, 18)]   # the stroke: columns 5..17, 13 px
        self.assertEqual(row, [ring.INK, ring.INK, ring.GLINT, ring.BLUSH_LIGHT, ring.BLUSH, ring.BLUSH,
                               ring.BLUSH_MID2, ring.BLUSH_MID, ring.BLUSH_SHADE, ring.BLUSH_DEEP, ring.COOL_DEEP,
                               ring.INK, ring.INK])
        # The ring's lower-right outer edge is in shade; its inner rim there is lit with the plain rim light,
        # never the near-white (no pale specks inside the ring), and the same on the tail's flat cut.
        def first_colour_inward(degrees, radii):
            for radius in radii:
                c = self.px[at_angle(degrees, radius)]
                if c[3] == 255 and c != ring.INK:
                    return c
            return None

        self.assertEqual(first_colour_inward(45, [27 - k * 0.5 for k in range(12)]), ring.COOL_DEEP)
        self.assertEqual(first_colour_inward(45, [14 + k * 0.5 for k in range(12)]), ring.BLUSH_LIGHT)
        self.assertFalse({p for p in lay["edge"] if math.hypot(p[0] + 0.5 - 32, p[1] + 0.5 - 34) < 20 and p[1] > 30})
        self.assertEqual({self.px[x, 36] for x in range(50, 56)}, {ring.BLUSH_LIGHT})
        # The stair-steps of the pixel circle never bleed shade into the lit side (a lone corner neighbour).
        self.assertFalse(lay["cool"] & {(x, y) for x in range(7, 12) for y in range(20, 42)})
        self.assertFalse(lay["deep"] & {(x, y) for x in range(7, 12) for y in range(20, 42)})

    def test_no_dark_pixel_outside_the_shape(self):
        self.assertTrue(all(self.px[x, y][3] == 0 for x in range(64) for y in range(64) if (x, y) not in self.cells))

    def test_roles_map_is_one_letter_per_pixel(self):
        lines = ring.roles_map().splitlines()
        self.assertEqual(len(lines), 65)
        self.assertTrue(all(len(line) == 68 for line in lines[1:]))
        self.assertEqual(lines[35][4 + 5:4 + 18], "##El..nmsdc##")
        self.assertEqual(lines[1 + 34][4 + 32], " ")


class TestRequest(unittest.TestCase):
    def test_body_carries_the_init_image_and_the_sprite_size(self):
        png = ring._png_bytes(ring.arrow())
        body = ring.request(png, strength=500, seed=7)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertTrue(body["no_background"])
        self.assertEqual(body["init_image_strength"], 500)
        self.assertEqual(body["seed"], 7)
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), png)
        self.assertIn("circular", body["description"])
        self.assertIn("clockwise", body["description"])
        self.assertIn("anticlockwise", body["negative_description"])
        self.assertNotIn("seed", ring.request(png))


class TestFinish(unittest.TestCase):
    def raw(self):
        im = ring.arrow()
        px = im.load()
        lay = ring.layers()
        self.body_px = sorted(lay["body"])[0]
        self.shade_px = sorted(lay["shade"])[0]
        px[0, 0] = (200, 10, 10, 255)                 # noise outside the arrow
        px[self.body_px] = (240, 190, 210, 255)       # a body pixel a few units off the palette
        px[self.shade_px] = (246, 201, 222, 90)       # a half pixel inside
        px[32, 1] = (0, 0, 0, 0)                      # a lost outline pixel at the head's top corner
        px[5, 34] = (30, 20, 40, 255)                 # an outline pixel tinted purple
        return im

    def test_clears_outside_snaps_alpha_and_refills_lost_pixels(self):
        out = ring.finish(self.raw(), do_polish=False)
        px = out.load()
        self.assertEqual(px[0, 0][3], 0)
        self.assertEqual(px[self.shade_px], ring.BLUSH_SHADE)
        self.assertEqual(px[32, 1], ring.INK)
        self.assertTrue(all(p[3] in (0, 255) for p in out.getdata()))
        self.assertEqual(px[self.body_px][:3], (240, 190, 210))   # PixelLab's own pixel stays without polish
        self.assertEqual(px[5, 34][:3], (30, 20, 40))

    def test_polish_repaints_the_roles_and_keeps_pixellab_body_pixels(self):
        out = ring.finish(self.raw())
        px = out.load()
        self.assertEqual(px[5, 34], ring.INK)                      # the outline is exactly near-black again
        self.assertEqual(px[self.shade_px], ring.BLUSH_SHADE)
        self.assertEqual(px[self.body_px][:3], (240, 190, 210))    # a plain body pixel of PixelLab's stays
        self.assertLessEqual(len(opaque_colours(out)), 30)
        self.assertEqual(out.getbbox(), ring.arrow().getbbox())
        self.assertTrue(any(px[p] == ring.GLINT for p in ring.layers()["glint"]))

    def test_polish_resizes_a_wrong_sized_image_and_clears_the_halo(self):
        big = ring.arrow().resize((128, 128), Image.NEAREST)
        bpx = big.load()
        bpx[2, 2] = (255, 0, 255, 255)
        out = ring.polish(big)
        self.assertEqual(out.size, (64, 64))
        self.assertEqual(out.load()[1, 1][3], 0)


if __name__ == "__main__":
    unittest.main()
