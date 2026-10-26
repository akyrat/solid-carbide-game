"""Tests for Greenbull's logo check (T-298): the approved emblem and wordmark pass, rule 1 breaks fail."""
import subprocess
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import check_greenbull_logo as c  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
APPROVED = ["art-archive/T-294/greenbull_emblem_128.png", "art-archive/T-294/greenbull_emblem_64.png",
            "art-archive/T-294/greenbull_emblem_32.png", "art-archive/T-295/greenbull_wordmark.png"]


class T(unittest.TestCase):
    def test_the_approved_emblem_and_wordmark_pass(self):
        for p in APPROVED:
            self.assertEqual(c.check(Image.open(ROOT / p)), [], p)

    def test_many_colours_pass_unlike_the_old_one_colour_check(self):
        im = Image.new("RGBA", (6, 6), (0, 0, 0, 0))
        for x, col in enumerate([(12, 76, 44), (104, 220, 96), (247, 208, 52), (0, 0, 0)]):
            im.putpixel((x + 1, 2), col + (255,))
        self.assertEqual(c.check(im), [])

    def test_rule_1_breaks_fail(self):
        semi = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
        semi.putpixel((1, 1), (104, 220, 96, 120))
        self.assertTrue(c.check(semi))
        opaque_bg = Image.new("RGBA", (4, 4), (12, 76, 44, 255))
        self.assertTrue(c.check(opaque_bg))
        many = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
        for i in range(31):
            many.putpixel((1 + i % 6, 1 + i // 6), (i * 8, 100, 50, 255))
        self.assertTrue(c.check(many))

    def test_command_line(self):
        tool = str(Path(__file__).parent / "check_greenbull_logo.py")
        ok = subprocess.run([sys.executable, tool] + [str(ROOT / p) for p in APPROVED], capture_output=True)
        self.assertEqual(ok.returncode, 0, ok.stdout)


if __name__ == "__main__":
    unittest.main()
