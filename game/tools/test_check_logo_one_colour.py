import sys, unittest
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
import check_logo_one_colour as c, flatten_logo as f

ROOT = Path(__file__).resolve().parents[2]


class T(unittest.TestCase):
    def test_flatten_makes_it_pass(self):
        im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        im.putpixel((1, 1), (215, 62, 63, 255)); im.putpixel((2, 1), (104, 40, 37, 255)); im.putpixel((2, 2), (1, 1, 1, 90))
        self.assertTrue(c.check(im))
        self.assertEqual(c.check(f.flatten(im)), [])

    def test_two_colours_fail(self):
        im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        im.putpixel((1, 1), (150, 24, 28, 255)); im.putpixel((2, 1), (10, 200, 10, 255))
        self.assertTrue(c.check(im))

    def test_sample(self):
        for n in (128, 64, 32):
            p = ROOT / f"game/art/logo/redgull_logo_{n}.png"
            self.assertEqual(c.check(Image.open(p)), [], p.name)

    def test_only_three_final_files(self):
        names = sorted(p.name for p in (ROOT / "game/art/logo").glob("*.png"))
        self.assertEqual(names, ["redgull_logo_128.png", "redgull_logo_32.png", "redgull_logo_64.png"])


if __name__ == "__main__":
    unittest.main()
