import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_button_plates as b  # noqa: E402

GREENBULL = {(104, 220, 96), (247, 208, 52), (12, 76, 44)}


class ButtonPlates(unittest.TestCase):
    def test_every_state_is_a_rule_1_plate(self):
        for s in b.STATES:
            im = b.draw(s)
            self.assertEqual(im.size, (72, 22))
            cols = set()
            for p in im.getdata():
                self.assertIn(p[3], (0, 255), s)
                if p[3]:
                    cols.add(p[:3])
            self.assertLess(len(cols), 30, s)
            self.assertEqual(cols == set(), False)
            self.assertIn(b.OUT, cols)
            self.assertFalse(cols & GREENBULL, s)

    def test_stepped_corners_and_outline(self):
        for s in b.STATES:
            im = b.draw(s)
            for xy in [(0, 0), (1, 0), (0, 1), (71, 0), (0, 21), (71, 21)]:
                self.assertEqual(im.getpixel(xy)[3], 0, (s, xy))
            for xy in [(2, 0), (0, 2), (1, 1), (36, 0), (36, 21), (0, 11), (71, 11)]:
                self.assertEqual(im.getpixel(xy)[:3], b.OUT, (s, xy))

    def test_states_differ_and_slice_centre_is_flat(self):
        imgs = {s: b.draw(s) for s in b.STATES}
        for i, s in enumerate(b.STATES):
            for t in b.STATES[i + 1:]:
                self.assertNotEqual(imgs[s].tobytes(), imgs[t].tobytes(), (s, t))
            c = {imgs[s].getpixel((x, y)) for x in range(20, 52) for y in range(4, 18)}
            self.assertEqual(len(c), 1, s)
            if s == "focus":
                self.assertEqual(next(iter(c))[3], 0, "the ring is open in the middle")   # the stretched middle must be one flat colour

        def lum(im):
            return sum(im.getpixel((36, 10))[:3])
        self.assertLess(lum(imgs["pressed"]), lum(imgs["normal"]))
        self.assertGreater(lum(imgs["hover"]), lum(imgs["normal"]))
        self.assertLess(lum(imgs["disabled"]), lum(imgs["normal"]))

    def test_lit_from_the_top_left(self):
        for s in ("normal", "hover", "focus"):
            im = b.draw(s)
            self.assertGreater(sum(im.getpixel((30, 1))[:3]), sum(im.getpixel((30, 20))[:3]))
            self.assertGreater(sum(im.getpixel((1, 10))[:3]), sum(im.getpixel((70, 10))[:3]))

    def test_build_is_deterministic_and_writes_the_record(self):
        with tempfile.TemporaryDirectory() as d:
            paths = b.build(Path(d))
            self.assertEqual(len(paths), 5)
            first = [p.read_bytes() for p in paths]
            b.build(Path(d))
            self.assertEqual(first, [p.read_bytes() for p in paths])
            self.assertTrue((Path(d) / "button_plates.json").exists())


if __name__ == "__main__":
    unittest.main()
