"""Tests for build_creator_buildings_art.py (T-257). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_buildings as bcb  # noqa: E402
import build_creator_buildings_art as art  # noqa: E402
from PIL import Image  # noqa: E402

RAW = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art-archive", "T-257", "raw")


class FinalArtTest(unittest.TestCase):
    def test_final_art_matches_data_and_rules(self):
        self.assertEqual(bcb.check(), [])
        for p, t in bcb.textures(bcb.load()):
            self.assertIn("creator_final", t["texture"])
            im = Image.open(bcb.res_path(t["texture"])).convert("RGBA")
            cols = {px[:3] for px in im.getdata() if px[3]}
            self.assertLessEqual(len(cols), 30)

    def test_build_is_deterministic(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            art.build_all(RAW, a)
            art.build_all(RAW, b)
            for name in os.listdir(a):
                if name.endswith(".png"):
                    self.assertEqual(open(os.path.join(a, name), "rb").read(), open(os.path.join(b, name), "rb").read())



if __name__ == "__main__":
    unittest.main()
