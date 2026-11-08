"""Tests for build_hint_arrow.py (T-577): run with
python -m unittest discover -s game/tools -p test_build_hint_arrow.py -t game/tools"""
import base64
import io
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hint_arrow as arrow  # noqa: E402

GREENBULL = {(12, 76, 44), (104, 220, 96), (247, 208, 52)}


def opaque_colours(im):
    return {p[:3] for p in im.getdata() if p[3] == 255}


class TestInit(unittest.TestCase):
    def setUp(self):
        self.im = arrow.arrow()
        self.px = self.im.load()

    def test_is_a_64_px_rgba_sprite_with_hard_alpha_and_few_colours(self):
        self.assertEqual(self.im.size, (64, 64))
        self.assertEqual(self.im.mode, "RGBA")
        self.assertTrue(all(p[3] in (0, 255) for p in self.im.getdata()))
        self.assertLessEqual(len(opaque_colours(self.im)), 30)
        self.assertFalse(opaque_colours(self.im) & GREENBULL)
        for corner in ((0, 0), (63, 0), (0, 63), (63, 63)):
            self.assertEqual(self.px[corner][3], 0)

    def test_fills_about_40_by_56_px_centred_and_points_up(self):
        self.assertEqual(self.im.getbbox(), (12, 4, 52, 60))   # 40 x 56, columns 12..51, rows 4..59
        self.assertEqual({x for x in range(64) if self.px[x, 4][3] == 255}, {31, 32})   # the tip
        self.assertEqual({x for x in range(64) if self.px[x, 59][3] == 255}, set(range(24, 40)))   # the shaft's end
        cells = arrow.arrow_cells()
        self.assertEqual(cells, {(63 - x, y) for x, y in cells})   # mirror-symmetric about the centre

    def test_has_outline_body_highlight_and_shade_with_glints_breaking_the_outline(self):
        colours = opaque_colours(self.im)
        for c in (arrow.INK, arrow.BLUSH, arrow.BLUSH_LIGHT, arrow.BLUSH_SHADE, arrow.BLUSH_MID, arrow.GLINT):
            self.assertIn(c[:3], colours)
        lay = arrow.layers()
        self.assertTrue(lay["glint"])
        full_outline = {p for p in arrow.arrow_cells() if any(
            (p[0] + dx, p[1] + dy) not in arrow.arrow_cells() for dx in (-1, 0, 1) for dy in (-1, 0, 1))}
        self.assertTrue(lay["glint"] <= full_outline)   # the glints sit on the outline itself
        # The light comes from the top-left: the head's left edge is lit, its right edge is in shade.
        self.assertEqual(self.px[33 - 12, 4 + 12], arrow.BLUSH_LIGHT)
        self.assertEqual(self.px[30 + 12, 4 + 12], arrow.BLUSH_SHADE)
        self.assertEqual(self.px[29 + 12, 4 + 12], arrow.BLUSH_MID)
        # The underside of the head's shoulders is in shade too.
        self.assertEqual(self.px[16, 22], arrow.BLUSH_SHADE)


class TestRequest(unittest.TestCase):
    def test_body_carries_the_init_image_and_the_sprite_size(self):
        png = arrow._png_bytes(arrow.arrow())
        body = arrow.request(png, strength=500, seed=7)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertTrue(body["no_background"])
        self.assertEqual(body["init_image_strength"], 500)
        self.assertEqual(body["seed"], 7)
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), png)
        self.assertIn("arrow", body["description"])
        self.assertNotIn("seed", arrow.request(png))


class TestFinish(unittest.TestCase):
    def raw(self):
        im = arrow.arrow()
        px = im.load()
        px[0, 0] = (200, 10, 10, 255)       # noise outside the arrow
        px[31, 30] = (246, 201, 222, 90)    # a half pixel inside
        px[32, 30] = (0, 0, 0, 0)           # a lost arrow pixel
        px[33, 30] = (240, 190, 210, 255)   # a pixel a few units off the palette
        return im

    def test_clears_outside_snaps_alpha_and_refills_lost_pixels(self):
        out = arrow.finish(self.raw())
        px = out.load()
        self.assertEqual(px[0, 0][3], 0)
        self.assertEqual(px[31, 30], arrow.BLUSH)
        self.assertEqual(px[32, 30], arrow.BLUSH)
        self.assertEqual(px[33, 30], (240, 190, 210, 255))   # kept: PixelLab's pixel stays where it can
        self.assertTrue(all(p[3] in (0, 255) for p in out.getdata()))
        self.assertEqual({p for p in arrow.arrow_cells()}, {(x, y) for y in range(64) for x in range(64) if px[x, y][3] == 255})

    def test_snap_maps_every_pixel_to_the_script_palette(self):
        out = arrow.finish(self.raw(), snap=True)
        self.assertTrue(opaque_colours(out) <= {c[:3] for c in arrow.PALETTE})
        self.assertEqual(out.load()[33, 30], arrow.BLUSH)

    def test_resizes_a_wrong_size_result(self):
        big = self.raw().resize((128, 128), Image.NEAREST)
        self.assertEqual(arrow.finish(big).size, (64, 64))


class TestCli(unittest.TestCase):
    def test_init_request_finish_and_preview_write_files(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            init = Path(tmp) / "init.png"
            req = Path(tmp) / "req.json"
            fin = Path(tmp) / "fin.png"
            prev = Path(tmp) / "prev.png"
            self.assertEqual(arrow.main(["init", str(init)]), 0)
            self.assertEqual(arrow.main(["request", str(req), "--init", str(init), "--seed", "3"]), 0)
            self.assertEqual(arrow.main(["finish", str(init), str(fin), "--snap"]), 0)
            self.assertEqual(arrow.main(["preview", str(fin), str(prev), "--scale", "2"]), 0)
            with Image.open(fin) as f:
                self.assertEqual((f.size, f.mode), ((64, 64), "RGBA"))
            with Image.open(prev) as p:
                self.assertEqual(p.size, (2 * 128 + 4 * 4, 128 + 2 * 4))
            self.assertIn('"seed": 3', req.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
