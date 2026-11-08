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
        for c in curved.PALETTE:
            self.assertIn(c[:3], colours)
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
