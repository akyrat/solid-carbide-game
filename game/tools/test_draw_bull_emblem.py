import sys, unittest
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
import draw_bull_emblem as b


class T(unittest.TestCase):
    def test_draw_is_hard_edged_in_palette(self):
        im = b.draw()
        self.assertEqual(im.size, (128, 128))
        for p in im.getdata():
            self.assertIn(p[3], (0, 255))
        counts = b.colour_counts(im)
        self.assertTrue(set(counts) <= set(b.PALETTE))
        self.assertLess(counts[b.YELLOW], counts[b.DARK])
        self.assertLess(counts[b.YELLOW], counts[b.LIGHT])
        self.assertEqual(im.getpixel((0, 0))[3], 0)

    def test_draw_is_near_symmetric(self):
        im = b.draw()
        same = sum(im.getpixel((x, y)) == im.getpixel((127 - x, y)) for y in range(128) for x in range(64))
        self.assertGreater(same / (128 * 64), 0.97)

    def test_remap_snaps_colours_and_alpha(self):
        im = Image.new("RGBA", (3, 1), (0, 0, 0, 0))
        im.putpixel((0, 0), (20, 80, 50, 255))
        im.putpixel((1, 0), (250, 200, 60, 200))
        im.putpixel((2, 0), (100, 220, 100, 40))
        out = b.remap(im)
        self.assertEqual(out.getpixel((0, 0)), b.DARK)
        self.assertEqual(out.getpixel((1, 0)), b.YELLOW)
        self.assertEqual(out.getpixel((2, 0))[3], 0)

    def test_request_body(self):
        req = b.pixflux_request(b.draw(), 200)
        self.assertEqual(req["init_image_strength"], 200)
        self.assertTrue(req["no_background"])
        self.assertEqual(req["image_size"], {"width": 128, "height": 128})


if __name__ == "__main__":
    unittest.main()
