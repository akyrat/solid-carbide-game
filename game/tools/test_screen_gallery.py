"""Tests for screen_gallery.py (task T-479): the manifest check, without starting Godot."""
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import screen_gallery as gallery  # noqa: E402


def png(path, w, h):
    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))
    raw = b"".join(b"\x00" + b"\x00\x00\x00" * w for _ in range(h))
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                     + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class GalleryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name)

    def write(self, screens, not_reached=()):
        (self.dir / "manifest.json").write_text(json.dumps(
            {"size": [1280, 720], "screens": screens, "not_reached": list(not_reached)}), encoding="utf-8")

    def test_png_size_reads_the_header(self):
        png(self.dir / "a.png", 5, 3)
        self.assertEqual(gallery.png_size(self.dir / "a.png"), (5, 3))
        (self.dir / "b.png").write_bytes(b"nope")
        self.assertIsNone(gallery.png_size(self.dir / "b.png"))

    def test_a_good_folder_has_no_problems(self):
        png(self.dir / "menu.png", 1280, 720)
        self.write([{"name": "menu", "file": "menu.png", "how": "Launch."}],
                   [{"name": "runs_list", "reason": "not in the game yet"}])
        self.assertEqual(gallery.check_manifest(self.dir), [])

    def test_missing_manifest_missing_file_and_wrong_size_are_reported(self):
        self.assertEqual(gallery.check_manifest(self.dir), ["no manifest.json"])
        png(self.dir / "small.png", 100, 100)
        self.write([{"name": "gone", "file": "gone.png", "how": "x"}, {"name": "small", "file": "small.png", "how": "x"}])
        problems = gallery.check_manifest(self.dir)
        self.assertEqual(len(problems), 2)
        self.assertIn("gone.png is not on disk", problems[0])
        self.assertIn("not (1280, 720)", problems[1])

    def test_an_entry_without_how_or_a_reason_is_reported(self):
        png(self.dir / "menu.png", 1280, 720)
        self.write([{"name": "menu", "file": "menu.png", "how": ""}], [{"name": "x", "reason": ""}])
        self.assertEqual(len(gallery.check_manifest(self.dir)), 2)


if __name__ == "__main__":
    unittest.main()
