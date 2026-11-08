"""Tests for build_hint_arrow_curved.py (T-577): run with
python -m unittest discover -s game/tools -p test_build_hint_arrow_curved.py -t game/tools"""
import base64
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hint_arrow_curved as curved  # noqa: E402

GREENBULL = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


def opaque_colours(im):
    return {p[:3] for p in im.getdata() if p[3] == 255}


class TestInit(unittest.TestCase):
    def setUp(self):
        self.im = curved.arrow()
        self.px = self.im.load()

    def test_is_a_64_px_rgba_sprite_with_hard_alpha_and_few_colours(self):
        self.assertEqual(self.im.size, (64, 64))
        self.assertEqual(self.im.mode, "RGBA")
        self.assertTrue(all(p[3] in (0, 255) for p in self.im.getdata()))
        self.assertLessEqual(len(opaque_colours(self.im)), 30)
        self.assertTrue(opaque_colours(self.im) <= {c[:3] for c in curved.PALETTE})
        self.assertFalse(opaque_colours(self.im) & GREENBULL)
        for corner in ((0, 0), (63, 0), (0, 63), (63, 63)):
            self.assertEqual(self.px[corner][3], 0)

    def test_starts_at_the_bottom_centre_and_turns_right(self):
        self.assertEqual(self.im.getbbox(), (24, 2, 60, 60))   # 36 x 58: columns 24..59, rows 2..59
        self.assertEqual({x for x in range(64) if self.px[x, 59][3] == 255}, set(range(24, 38)))   # the shaft's end
        self.assertEqual({y for y in range(64) if self.px[59, y][3] == 255}, {19, 20})   # the tip, pointing right
        cells = curved.arrow_cells()
        # The head is in the top right, the shaft in the bottom left half: a right turn, never a left one.
        self.assertTrue(all(y < 40 for x, y in cells if x >= 50))
        self.assertFalse(any(x < 24 for x, y in cells))
        # The bend is a quarter circle: the band's outer edge touches both the shaft's left and the head's top.
        self.assertIn((24, 30), cells)
        self.assertIn((41, 13), cells)
        self.assertNotIn((38, 30), cells)   # the inner corner is rounded, not filled

    def test_has_outline_rim_light_stepped_shade_and_glints_breaking_the_outline(self):
        colours = opaque_colours(self.im)
        for c in (curved.INK, curved.GLINT, curved.BLUSH_LIGHT, curved.BLUSH, curved.BLUSH_MID, curved.BLUSH_SHADE,
                  curved.BLUSH_DEEP):
            self.assertIn(c[:3], colours)
        self.assertEqual(len(colours), 7)   # the rich pass's two extra tones are not in v1
        lay = curved.layers()
        cells = curved.arrow_cells()
        full_outline = {p for p in cells if any(q not in cells for q in curved.nbrs8(p))}
        self.assertTrue(lay["glint"])
        self.assertTrue(lay["glint"] & full_outline)   # the glints sit on the outline itself
        self.assertTrue(all(p not in lay["body"] for p in lay["glint"]))
        # The shaft's left is lit, its right is in shade, with the steps between.
        self.assertEqual(self.px[26, 50], curved.BLUSH_LIGHT)
        self.assertEqual(self.px[35, 50], curved.BLUSH_DEEP)
        self.assertEqual(self.px[34, 50], curved.BLUSH_SHADE)
        self.assertEqual(self.px[33, 50], curved.BLUSH_MID)
        self.assertEqual(self.px[29, 50], curved.BLUSH)
        # The head's upper slope has the near-white edge; its lower slope is in shade.
        self.assertTrue(any(self.px[x, y] == curved.GLINT for x, y in lay["edge"]))
        self.assertTrue(all(y < 20 for x, y in lay["edge"]))
        lower_slope = {(x, y) for x, y in lay["deep"] if x > 42 and y > 20}
        self.assertTrue(lower_slope)
        # The glint runs break the shaft's left outline and the outer bend.
        self.assertEqual(self.px[24, 40], curved.GLINT)
        self.assertTrue(any(x < 42 and y < 31 for x, y in lay["glint"] if x > 25))
        self.assertEqual(self.px[24, 55], curved.INK)


class TestWide(unittest.TestCase):
    """The v2 pass: bolder, with shading bands and glint runs that show at native 64 px."""

    def setUp(self):
        self.im = curved.arrow(wide=True)
        self.px = self.im.load()

    def test_is_bolder_than_v1_and_still_a_right_turn_from_the_bottom(self):
        self.assertEqual(self.im.getbbox(), (20, 3, 60, 60))   # 40 x 57: columns 20..59, rows 3..59
        self.assertEqual({x for x in range(64) if self.px[x, 59][3] == 255}, set(range(20, 38)))   # 18 px shaft
        self.assertEqual({y for y in range(64) if self.px[59, y][3] == 255}, {20, 21})   # the tip, pointing right
        self.assertEqual({y for y in range(64) if self.px[42, y][3] == 255}, set(range(3, 39)))   # the head's base, 36 px
        cells = curved.arrow_cells(wide=True)
        self.assertGreater(len(cells), len(curved.arrow_cells()))
        self.assertTrue(all(y < 40 for x, y in cells if x >= 50))
        self.assertIn((20, 33), cells)    # the outer bend meets the shaft's left
        self.assertNotIn((38, 33), cells)  # the inner bend is rounded (radius 5)
        self.assertTrue(all(p[3] in (0, 255) for p in self.im.getdata()))
        self.assertTrue(opaque_colours(self.im) <= {c[:3] for c in curved.PALETTE})

    def test_bands_are_wider_and_glint_runs_three_pixels_wide(self):
        lay = curved.layers(wide=True)
        # The shaft's right: two deep, two shade, two mid; its left: the near-white run and the rim light.
        # Row 48 is clear of the shaft's end, whose own shade band reaches up to row 52.
        self.assertEqual([self.px[x, 48] for x in (35, 34)], [curved.BLUSH_DEEP] * 2)
        self.assertEqual([self.px[x, 48] for x in (33, 32)], [curved.BLUSH_SHADE] * 2)
        self.assertEqual([self.px[x, 48] for x in (31, 30)], [curved.BLUSH_MID] * 2)
        self.assertEqual([self.px[x, 48] for x in (25, 26, 27)], [curved.BLUSH] * 3)
        self.assertEqual([self.px[x, 55] for x in (22, 23, 24)], [curved.BLUSH_LIGHT] * 3)
        self.assertEqual([self.px[x, 45] for x in (20, 21, 22)], [curved.GLINT] * 3)
        self.assertEqual(self.px[20, 55], curved.INK)
        self.assertGreater(len(lay["glint"]), len(curved.layers()["glint"]))
        self.assertTrue(lay["edge"] & {(22, y) for y in range(38, 51)})
        # The inner bend and the corners either side of it are in shadow: no pale specks there.
        cx, cy = curved.GEOM[True]["centre"]
        near = {p for p in lay["edge"] | lay["light"] if ((p[0] + 0.5 - cx) ** 2 + (p[1] + 0.5 - cy) ** 2) < 81}
        self.assertEqual(near, set())
        self.assertEqual(self.px[35, 38], curved.BLUSH_DEEP)

    def test_polish_wide_grows_v1_and_fills_the_new_body_with_pixellabs_blush(self):
        v1 = curved.arrow()
        px = v1.load()
        for x, y in curved.layers()["body"]:
            px[x, y] = (243, 198, 220, 255)   # PixelLab's own blush on v1's body
        out = curved.polish(v1, wide=True)
        opx = out.load()
        self.assertEqual(out.getbbox(), (20, 3, 60, 60))
        body = curved.layers(wide=True)["body"]
        # v1's outline and shade pixels that now sit inside the wider body are repainted, not kept.
        self.assertTrue(all(opx[x, y] == (243, 198, 220, 255) for x, y in body))
        self.assertLessEqual(len(opaque_colours(out)), 30)


class TestRich(unittest.TestCase):
    """The v3 pass: the wide geometry with more tones, an edge line and more glint runs."""

    def setUp(self):
        self.im = curved.arrow(wide="rich")
        self.px = self.im.load()

    def test_keeps_the_wide_geometry_and_adds_two_tones(self):
        self.assertEqual(curved.arrow_cells("rich"), curved.arrow_cells(True))
        self.assertEqual(self.im.getbbox(), (20, 3, 60, 60))
        colours = opaque_colours(self.im)
        self.assertEqual(len(colours), 9)
        self.assertTrue(colours <= {c[:3] for c in curved.PALETTE})
        self.assertIn(curved.COOL_DEEP[:3], colours)
        self.assertIn(curved.BLUSH_MID2[:3], colours)
        self.assertTrue(all(p[3] in (0, 255) for p in self.im.getdata()))
        self.assertFalse(colours & GREENBULL)

    def test_shaft_has_five_stepped_shade_tones_a_cool_deepest_step_and_an_edge_line(self):
        # From the shaft's right outline inwards: cool plum, deep, two shade, two mid, two mid-tone, then body.
        self.assertEqual(self.px[35, 48], curved.COOL_DEEP)
        self.assertEqual(self.px[34, 48], curved.BLUSH_DEEP)
        self.assertEqual([self.px[x, 48] for x in (33, 32)], [curved.BLUSH_SHADE] * 2)
        self.assertEqual([self.px[x, 48] for x in (31, 30)], [curved.BLUSH_MID] * 2)
        self.assertEqual([self.px[x, 48] for x in (29, 28)], [curved.BLUSH_MID2] * 2)
        self.assertEqual(self.px[26, 48], curved.BLUSH)
        # The lit edge is a near-white line everywhere, with the rim light inside it.
        self.assertEqual(self.px[22, 55], curved.GLINT)
        self.assertEqual([self.px[x, 55] for x in (23, 24)], [curved.BLUSH_LIGHT] * 2)
        lay = curved.layers("rich")
        self.assertFalse(lay.get("light", set()) & {(22, y) for y in range(36, 58)})
        # The cool step sits only against the outline, on the shade side: never next to the lit edge line.
        full_outline = lay["outline"] | lay["glint"]
        self.assertTrue(all(any(q in full_outline for q in curved.nbrs8(p)) for p in lay["cool"]))
        self.assertFalse(lay["cool"] & {(x - 1, y) for x, y in lay["edge"]} & {(x, y - 1) for x, y in lay["edge"]})
        self.assertTrue(all(x > 30 or y > 52 for x, y in lay["cool"]))   # the right and lower edges, the inner bend

    def test_more_glint_runs_break_the_outline_on_the_bend_and_the_head(self):
        rich, wide = curved.layers("rich"), curved.layers(True)
        self.assertGreater(len(rich["glint"]), len(wide["glint"]))
        cx, cy = curved.GEOM["rich"]["centre"]

        def on_arc(lay):
            return {(x, y) for x, y in lay["glint"] if x < cx and y < cy and x > 21}

        self.assertGreater(len(on_arc(rich)), len(on_arc(wide)))   # two runs on the bend instead of one
        self.assertTrue({(x, y) for x, y in rich["glint"] if x >= 44 and x < 55})   # the head's upper slope
        # Some of the outline stays near-black between the runs, and the tip keeps its dark outline.
        self.assertTrue({(x, y) for x, y in rich["outline"] if x < cx and y < cy and y < 20})
        self.assertFalse({(x, y) for x, y in rich["glint"] if x >= 56})
        # The inner arc's outline never carries a run (it is in shadow), in every pass.
        r_in, r_out = curved.GEOM["rich"]["radii"]
        for lay in (rich, wide, curved.layers()):
            inner = {p for p in lay["glint"] if p[0] < cx and p[1] < cy
                     and ((p[0] + 0.5 - cx) ** 2 + (p[1] + 0.5 - cy) ** 2) ** 0.5 < (r_in + r_out) / 2}
            self.assertEqual(inner, set())

    def test_polish_rich_grows_v1_like_wide(self):
        v1 = curved.arrow()
        px = v1.load()
        for x, y in curved.layers()["body"]:
            px[x, y] = (243, 198, 220, 255)
        out = curved.polish(v1, wide="rich")
        opx = out.load()
        self.assertEqual(out.getbbox(), (20, 3, 60, 60))
        self.assertTrue(all(opx[x, y] == (243, 198, 220, 255) for x, y in curved.layers("rich")["body"]))
        self.assertEqual(len(opaque_colours(out)), 9)


class TestClean(unittest.TestCase):
    """The v4 pass: the rich look with a continuous outline and short, deliberate outer-ring runs."""

    def setUp(self):
        self.lay = curved.layers("clean")
        self.cells = curved.arrow_cells("clean")
        self.outer = {p for p in self.cells if any(q not in self.cells for q in curved.nbrs8(p))}
        self.inner = {p for p in self.cells - self.outer if any(q in self.outer for q in curved.nbrs8(p))}

    def test_keeps_the_rich_geometry_and_palette(self):
        self.assertEqual(self.cells, curved.arrow_cells("rich"))
        im = curved.arrow("clean")
        self.assertEqual(im.getbbox(), (20, 3, 60, 60))
        self.assertEqual(len(opaque_colours(im)), 9)
        self.assertTrue(opaque_colours(im) <= {c[:3] for c in curved.PALETTE})
        self.assertTrue(all(p[3] in (0, 255) for p in im.getdata()))

    def test_outline_is_continuous_and_the_runs_sit_on_the_outer_ring_only(self):
        self.assertTrue(self.inner <= self.lay["outline"])          # the inner ring is never broken
        self.assertTrue(self.lay["glint"] <= self.outer)             # the glints are on the outer ring
        self.assertTrue(self.lay["glint"])
        self.assertLess(len(self.lay["glint"]), len(curved.layers("rich")["glint"]) // 2)
        self.assertLessEqual(len(self.lay["glint"]), int(0.2 * len(self.outer)))   # short, deliberate runs
        # No dark pixel outside the shape, and the whole outer ring is either near-black or a glint.
        self.assertEqual(self.outer, (self.lay["outline"] & self.outer) | self.lay["glint"])
        im = curved.arrow("clean")
        px = im.load()
        self.assertTrue(all(px[x, y][3] == 0 for x in range(64) for y in range(64) if (x, y) not in self.cells))
        # Three runs: the shaft's left, the outer bend's upper-left, the head's upper slope.
        cx, cy = curved.GEOM["clean"]["centre"]
        self.assertTrue({p for p in self.lay["glint"] if p[0] == 20})
        self.assertTrue({p for p in self.lay["glint"] if 21 < p[0] < cx and p[1] < cy})
        self.assertTrue({p for p in self.lay["glint"] if p[0] >= 46})
        self.assertFalse({p for p in self.lay["glint"] if p[0] >= 53})   # the tip's outline stays dark

    def test_polish_clean_grows_v1_like_the_others(self):
        v1 = curved.arrow()
        px = v1.load()
        for x, y in curved.layers()["body"]:
            px[x, y] = (243, 198, 220, 255)
        out = curved.polish(v1, wide="clean")
        opx = out.load()
        self.assertEqual(out.getbbox(), (20, 3, 60, 60))
        self.assertTrue(all(opx[x, y] == (243, 198, 220, 255) for x, y in self.lay["body"]))
        self.assertTrue(all(opx[x, y] == curved.INK for x, y in self.inner))


class TestRequest(unittest.TestCase):
    def test_body_carries_the_init_image_and_the_sprite_size(self):
        png = curved._png_bytes(curved.arrow())
        body = curved.request(png, strength=500, seed=7)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertTrue(body["no_background"])
        self.assertEqual(body["init_image_strength"], 500)
        self.assertEqual(body["seed"], 7)
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), png)
        self.assertIn("curved", body["description"])
        self.assertIn("right", body["description"])
        self.assertIn("left turn", body["negative_description"])
        self.assertNotIn("seed", curved.request(png))


class TestFinish(unittest.TestCase):
    def raw(self):
        im = curved.arrow()
        px = im.load()
        px[0, 0] = (200, 10, 10, 255)       # noise outside the arrow
        px[30, 50] = (246, 201, 222, 90)    # a half pixel inside
        px[31, 50] = (0, 0, 0, 0)           # a lost arrow pixel
        px[29, 50] = (240, 190, 210, 255)   # a body pixel a few units off the palette
        px[24, 55] = (30, 20, 40, 255)      # an outline pixel tinted purple
        return im

    def test_clears_outside_snaps_alpha_and_refills_lost_pixels(self):
        out = curved.finish(self.raw(), do_polish=False)
        px = out.load()
        self.assertEqual(px[0, 0][3], 0)
        self.assertEqual(px[30, 50], curved.BLUSH)
        self.assertEqual(px[31, 50], curved.BLUSH)
        self.assertTrue(all(p[3] in (0, 255) for p in out.getdata()))
        self.assertEqual(px[29, 50][:3], (240, 190, 210))   # PixelLab's own pixel stays without polish
        self.assertEqual(px[24, 55][:3], (30, 20, 40))

    def test_polish_repaints_the_roles_and_keeps_pixellab_body_pixels(self):
        out = curved.finish(self.raw())
        px = out.load()
        self.assertEqual(px[24, 55], curved.INK)             # the outline is exactly near-black again
        self.assertEqual(px[24, 40], curved.GLINT)
        self.assertEqual(px[29, 50][:3], (240, 190, 210))    # a plain body pixel of PixelLab's stays
        self.assertEqual(px[31, 50], curved.BLUSH)           # a lost body pixel takes the spec blush
        self.assertLessEqual(len(opaque_colours(out)), 30)
        self.assertEqual(out.getbbox(), (24, 2, 60, 60))

    def test_polish_resizes_a_wrong_sized_image_and_clears_the_halo(self):
        big = curved.arrow().resize((128, 128), Image.NEAREST)
        bpx = big.load()
        bpx[2, 2] = (255, 0, 255, 255)
        out = curved.polish(big)
        self.assertEqual(out.size, (64, 64))
        self.assertEqual(out.load()[1, 1][3], 0)


if __name__ == "__main__":
    unittest.main()
