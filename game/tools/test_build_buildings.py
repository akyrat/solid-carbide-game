"""Tests for build_buildings.py (T-064). No PixelLab call."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_buildings as bb  # noqa: E402


def tower_like(w=20, h=40, wall=(48, 46, 62), sign=(255, 64, 200)):
    """A small opaque block on a flat grey background, with a pink stripe."""
    img = Image.new("RGBA", (w + 10, h + 10), (102, 95, 107, 255))
    for y in range(5, 5 + h):
        for x in range(5, 5 + w):
            img.putpixel((x, y), wall + (255,))
        img.putpixel((8, y), sign + (255,))
    return img


class PaletteTests(unittest.TestCase):
    def test_palette_size_and_no_red(self):
        pal = bb.build_palette()
        self.assertLessEqual(len(pal), bb.MAX_COLORS)
        self.assertTrue(all(bb.red_distance(c) > bb.RED_MIN_DISTANCE for c in pal))
        self.assertIn((255, 64, 200), pal)
        self.assertIn((0, 229, 255), pal)

    def test_palette_image_round_trip(self):
        pal = bb.build_palette()
        img = bb.palette_image(pal)
        self.assertEqual(sorted(bb.opaque_colors(img)), sorted(pal))

    def test_request_body_settings(self):
        tmp = Path(__file__).resolve().parent / "_test_palette.png"
        try:
            bb.palette_image(bb.build_palette()).save(tmp)
            body = bb.request_body(tmp)
        finally:
            tmp.unlink(missing_ok=True)
        self.assertEqual(body["image_size"], {"width": 384, "height": 400})
        self.assertTrue(body["isometric"])
        self.assertEqual(body["color_image"]["type"], "base64")


class CleanTests(unittest.TestCase):
    def test_background_removed_and_rules_hold(self):
        pal = bb.build_palette()
        out = bb.clean(tower_like(), pal)
        rep = bb.sprite_report(out)
        self.assertTrue(rep["pass"], rep)
        self.assertEqual(out.size, (22, 42))  # cropped with a 1 px border
        self.assertEqual(rep["semi_transparent_pixels"], 0)

    def test_map_to_palette_only_palette_colours(self):
        pal = [(0, 0, 0), (255, 255, 255)]
        img = Image.new("RGBA", (2, 1))
        img.putpixel((0, 0), (10, 10, 10, 255))
        img.putpixel((1, 0), (240, 250, 250, 100))
        out = bb.map_to_palette(img, pal)
        self.assertEqual(out.getpixel((0, 0)), (0, 0, 0, 255))
        self.assertEqual(out.getpixel((1, 0)), (0, 0, 0, 0))

    def test_drop_specks(self):
        img = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
        img.putpixel((1, 1), (1, 2, 3, 255))
        for x in range(5, 9):
            img.putpixel((x, 5), (1, 2, 3, 255))
        bb.drop_specks(img, 4)
        self.assertEqual(img.getpixel((1, 1))[3], 0)
        self.assertEqual(img.getpixel((5, 5))[3], 255)


class VariantTests(unittest.TestCase):
    def test_swap_pairs_pink_and_cyan_without_red(self):
        pal = bb.build_palette()
        m = bb.neon_swap_map(pal)
        self.assertEqual(bb.hue_kind(m[(255, 64, 200)]), "cyan")
        self.assertEqual(bb.hue_kind(m[(0, 229, 255)]), "pink")
        self.assertTrue(all(v in pal for v in m.values()))

    def test_stretch_and_shorten_heights(self):
        img = tower_like()
        self.assertEqual(bb.stretch(img, 10, 20, 25).size[1], img.size[1] + 25)
        self.assertEqual(bb.shorten(img, 10, 20, 5).size[1], img.size[1] - 5)
        self.assertEqual(bb.stretch(img, 10, 20, 0).size, img.size)

    def test_variant_plan_neighbours_differ(self):
        plan = bb.variant_plan(4)
        for gy in range(4):
            for gx in range(3):
                a, b = plan[gy][gx], plan[gy][gx + 1]
                self.assertNotEqual((a["mirror"], a["swap"], a["height"]), (b["mirror"], b["swap"], b["height"]))

    def test_iso_matches_game_projection(self):
        self.assertEqual(bb.iso(1, 0), (32, 16))
        self.assertEqual(bb.iso(0, 1), (-32, 16))
        self.assertEqual(bb.iso(0, 0, 1), (0, -32))


if __name__ == "__main__":
    unittest.main()
