"""Tests for tilt_kaiju_frame.py (T-613). Run: python -m unittest discover game/tools -p "test_tilt_kaiju*" """
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import tilt_kaiju_frame as t  # noqa: E402

GREEN = (20, 90, 90, 255)
CYAN = (150, 240, 220, 255)


def standing(w=40, h=120, left=90, bottom=200):
    """A tall block standing on row `bottom`, with a cyan top."""
    im = Image.new("RGBA", (224, 224), (0, 0, 0, 0))
    for y in range(bottom - h, bottom):
        for x in range(left, left + w):
            im.putpixel((x, y), CYAN if y < bottom - h + 10 else GREEN)
    return im


class TiltTest(unittest.TestCase):
    def test_quarter_turn_lies_down_on_the_same_ground_row(self):
        out = t.tilt(standing(), 90)
        box = out.getchannel("A").getbbox()
        self.assertEqual(box[3], 200)
        self.assertEqual((box[2] - box[0], box[3] - box[1]), (120, 40))
        self.assertEqual(box[0], (224 - 120) // 2)

    def test_clockwise_puts_the_top_on_the_right(self):
        out = t.tilt(standing(), 90)
        box = out.getchannel("A").getbbox()
        self.assertEqual(out.getpixel((box[2] - 2, box[3] - 20)), CYAN)
        self.assertEqual(out.getpixel((box[0] + 2, box[3] - 20)), GREEN)

    def test_no_new_colours_and_hard_alpha(self):
        out = t.tilt(standing(), 37)
        self.assertEqual({p for p in out.getdata() if p[3]}, {GREEN, CYAN})
        self.assertEqual({p[3] for p in out.getdata()}, {0, 255})
        self.assertEqual(out.getchannel("A").getbbox()[3], 200)

    def test_too_big_or_wrong_size_is_refused(self):
        with self.assertRaises(ValueError):
            t.tilt(standing(w=200, h=190, left=10), 45)
        with self.assertRaises(ValueError):
            t.tilt(Image.new("RGBA", (48, 48), GREEN), 10)
        with self.assertRaises(ValueError):
            t.tilt(Image.new("RGBA", (224, 224), (0, 0, 0, 0)), 10)

    def test_main_never_overwrites(self):
        with tempfile.TemporaryDirectory() as d:
            src, out = Path(d) / "in.png", Path(d) / "out.png"
            standing().save(src)
            self.assertEqual(t.main([str(src), str(out), "--angle", "30", "--preview", str(Path(d) / "p.png")]), 0)
            self.assertEqual(Image.open(out).size, (224, 224))
            self.assertEqual(Image.open(Path(d) / "p.png").size, (672, 672))
            with self.assertRaises(SystemExit):
                t.main([str(src), str(out), "--angle", "30"])


if __name__ == "__main__":
    unittest.main()
