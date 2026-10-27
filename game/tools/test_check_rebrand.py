import os
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_rebrand  # noqa: E402


def write_png(path, colour, size=4):
    raw = b"".join(b"\x00" + bytes(colour + (255,)) * size for _ in range(size))

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d))
    data = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


class CheckRebrandTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.g = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def kinds(self):
        return [(f["kind"], f["file"]) for f in check_rebrand.run(self.g)["findings"]]

    def test_flags_loaded_red_png(self):
        write_png(os.path.join(self.g, "art/effects/spark.png"), (204, 18, 28))
        write(os.path.join(self.g, "scripts/a.gd"), 'var t = load("res://art/effects/spark.png")\n')
        self.assertIn(("red", "art/effects/spark.png"), self.kinds())

    def test_ignores_red_png_nobody_loads(self):
        write_png(os.path.join(self.g, "art/effects/unused.png"), (204, 18, 28))
        self.assertEqual(self.kinds(), [])

    def test_passes_kept_subject_heart(self):
        write_png(os.path.join(self.g, "art/hud/likes_heart.png"), (219, 26, 41))
        write(os.path.join(self.g, "scripts/hud.gd"), 'var t = load("res://art/hud/likes_heart.png")\n')
        rep = check_rebrand.run(self.g)
        self.assertEqual(rep["findings"], [])
        self.assertEqual([k["file"] for k in rep["kept_red"]], ["art/hud/likes_heart.png"])

    def test_non_red_png_passes(self):
        write_png(os.path.join(self.g, "art/effects/coin.png"), (12, 76, 44))
        write(os.path.join(self.g, "scenes/a.tscn"), '[ext_resource path="res://art/effects/coin.png"]\n')
        self.assertEqual(self.kinds(), [])

    def test_flags_file_named_redgull(self):
        write_png(os.path.join(self.g, "art/logo/redgull_logo.png"), (12, 76, 44))
        write(os.path.join(self.g, "scripts/a.gd"), 'var t = load("res://art/logo/redgull_logo.png")\n')
        self.assertIn(("name", "art/logo/redgull_logo.png"), self.kinds())

    def test_pattern_and_folder_loads(self):
        write_png(os.path.join(self.g, "art/kaiju/kaiju_e.png"), (204, 18, 28))
        write_png(os.path.join(self.g, "art/banners/x/sign.png"), (204, 18, 28))
        write(os.path.join(self.g, "scripts/a.gd"),
              'load("res://art/kaiju/kaiju_%s.png" % d)\nvar dir = "res://art/banners/"\n')
        self.assertEqual(self.kinds(), [("red", "art/kaiju/kaiju_e.png")])

    def test_flags_redgull_text(self):
        write(os.path.join(self.g, "scripts/a.gd"), 'label.text = "Sponsored by Redgull"\n')
        write(os.path.join(self.g, "data/t.json"), '{"title": "Redgull gives wings"}\n')
        self.assertEqual(sorted(self.kinds()), [("text", "data/t.json"), ("text", "scripts/a.gd")])

    def test_comments_are_not_text(self):
        write(os.path.join(self.g, "scripts/a.gd"), '# the old "Redgull logo" is history\nvar x = 1\n')
        self.assertEqual(self.kinds(), [])

    def test_exit_code(self):
        write(os.path.join(self.g, "scripts/a.gd"), 'label.text = "Sponsored by Redgull"\n')
        self.assertEqual(check_rebrand.main(["--game-dir", self.g]), 1)


if __name__ == "__main__":
    unittest.main()
