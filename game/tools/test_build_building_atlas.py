"""Tests for build_building_atlas.py and keep_main (T-064). No PixelLab call."""
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_building_atlas as ba  # noqa: E402
import build_buildings as bb  # noqa: E402

WALL = (48, 46, 62)
PINK = (255, 64, 200)


def tower(w=30, h=120):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            img.putpixel((x, y), WALL + (255,))
        if y % 20 < 10:
            img.putpixel((3, y), (0, 229, 255, 255))
    return img


class AtlasTests(unittest.TestCase):
    def test_keep_main_drops_stray_marks(self):
        img = tower()
        big = Image.new("RGBA", (60, 130), (0, 0, 0, 0))
        big.alpha_composite(img, (0, 0))
        for x in (50, 52, 54):
            big.putpixel((x, 125), WALL + (255,))
        out = bb.keep_main(big)
        self.assertEqual(out.getpixel((50, 125))[3], 0)
        self.assertEqual(out.getpixel((10, 10))[3], 255)

    def test_hull_of_a_square(self):
        pts = [(0, 0), (4, 0), (4, 4), (0, 4), (2, 2)]
        self.assertEqual(sorted(ba.hull(pts)), [(0, 0), (0, 4), (4, 0), (4, 4)])

    def test_versions_and_heights(self):
        pal = sorted({WALL, PINK, (0, 229, 255)})
        vs = ba.versions_of(tower(), 1, bb.neon_swap_map(pal), band=(30, 50, 0))
        ids = {v["id"] for v in vs}
        self.assertEqual(len(ids), len(vs))
        self.assertTrue(any(v["extra_units"] == 3 for v in vs))
        self.assertTrue(all(v["height_units"] <= ba.MAX_HEIGHT_UNITS or v["extra_units"] == 0 for v in vs))
        base = [v for v in vs if v["extra_units"] == 0 and not v["mirror"] and not v["swap"]][0]
        taller = [v for v in vs if v["extra_units"] == 3 and not v["mirror"] and not v["swap"]][0]
        self.assertAlmostEqual(taller["height_units"] - base["height_units"], 3.0, places=1)

    def test_unstretchable_tower_has_only_four_versions(self):
        vs = ba.versions_of(tower(), 3, {})
        self.assertEqual(len(vs), 4)

    def test_pack_regions_hold_the_images(self):
        items = [{"image": tower(20, 50)}, {"image": tower(30, 80)}, {"image": tower(25, 60)}]
        atlas, items = ba.pack(items, width=64)
        for it in items:
            x, y, w, h = it["region"]
            self.assertEqual(atlas.crop((x, y, x + w, y + h)).tobytes(), it["image"].tobytes())

    def test_real_atlas_passes_the_sprite_rules(self):
        repo = Path(__file__).resolve().parents[2]
        atlas_png = repo / "game" / "art" / "buildings" / "buildings_atlas.png"
        if not atlas_png.exists():
            self.skipTest("atlas not built")
        import json
        data = json.loads((repo / "game" / "art" / "buildings" / "buildings.json").read_text(encoding="utf-8"))
        bad, semi = ba.check_atlas(Image.open(atlas_png).convert("RGBA"), data["variants"])
        self.assertEqual(bad, [])
        self.assertEqual(semi, 0)
        self.assertEqual({v["tower"] for v in data["variants"]}, set(range(1, 9)))


if __name__ == "__main__":
    unittest.main()
