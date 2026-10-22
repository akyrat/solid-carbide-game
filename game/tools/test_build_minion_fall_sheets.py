import sys, unittest
from pathlib import Path
from PIL import Image
sys.path.insert(0, str(Path(__file__).parent))
import build_minion_fall_sheets as b


class T(unittest.TestCase):
    def test_snap(self):
        pal = [(0, 0, 0), (200, 200, 200)]
        im = Image.new("RGBA", (2, 1), (0, 0, 0, 0))
        im.putpixel((0, 0), (190, 190, 190, 200))
        out = b.snap_frame(im, pal)
        self.assertEqual(out.getpixel((0, 0)), (200, 200, 200, 255))
        self.assertEqual(out.getpixel((1, 0))[3], 0)

    def test_sheet_size_and_palette(self):
        pal = b.walk_palette()
        src = b.ROOT / "art-archive" / "T-227" / "fall_se"
        s = b.build_sheet([src / f"minion_fall_se_{i}.png" for i in range(b.FRAMES)], pal)
        self.assertEqual(s.size, (b.FRAME * b.FRAMES, b.FRAME))
        cols = {p[:3] for p in s.getdata() if p[3]}
        self.assertTrue(cols <= set(pal))
        self.assertTrue(all(p[3] in (0, 255) for p in s.getdata()))


if __name__ == "__main__":
    unittest.main()
