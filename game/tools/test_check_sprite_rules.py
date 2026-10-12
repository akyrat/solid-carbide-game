import struct, sys, tempfile, unittest, zlib
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import check_sprite_rules as c


def make_png(w, h, pixel):
    raw = b"".join(b"\x00" + b"".join(bytes(pixel(x, y)) for x in range(w)) for y in range(h))
    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class T(unittest.TestCase):
    def run_check(self, png, **kw):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "s.png"
            p.write_bytes(png)
            return c.check(str(p), **kw)

    def test_good(self):
        r, info = self.run_check(make_png(8, 8, lambda x, y: (10, 20, 30, 255) if 2 <= x < 5 and 2 <= y < 5 else (0, 0, 0, 0)), size=8)
        self.assertTrue(all(ok for _, ok, _ in r))
        self.assertEqual(info["bbox"], (2, 2, 4, 4))

    def test_semi_transparent_fails(self):
        r, _ = self.run_check(make_png(8, 8, lambda x, y: (1, 2, 3, 128) if x == 3 else (0, 0, 0, 0)), size=8)
        self.assertFalse(dict((n, ok) for n, ok, _ in r)["no semi-transparent pixels"])

    def test_wrong_size_and_colours_fail(self):
        r, _ = self.run_check(make_png(8, 8, lambda x, y: (x * 10, y, 0, 255)), size=16, max_colors=5)
        d = {n: ok for n, ok, _ in r}
        self.assertFalse(d["frame size 16x16"])
        self.assertFalse(d["about 5 colours or fewer"])
        self.assertFalse(d["transparent background (corners)"])


if __name__ == "__main__":
    unittest.main()
