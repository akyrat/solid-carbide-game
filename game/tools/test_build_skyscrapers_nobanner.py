"""Tests for build_skyscrapers_nobanner.py (T-265): the sign-less bodies."""
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

import build_skyscrapers_nobanner as nb


@unittest.skipUnless(nb.DEFAULT_RAW.exists(), "the T-064 raw pieces are not in this checkout")
class T(unittest.TestCase):
    def test_rebuild_with_the_sign_is_the_art_in_the_game(self):
        # check() also asserts that leaving the sign out changes every body
        self.assertEqual(nb.check(out_dir=Path(tempfile.mkdtemp())), [])

    def test_written_copies_have_no_sign_and_keep_everything_else(self):
        with tempfile.TemporaryDirectory() as d:
            names = nb.write(d)
            self.assertEqual(len(names), 12)
            for n in range(1, 7):
                for k in range(2):
                    name = f"skyscraper_{n}_{k}.png"
                    plain = np.array(Image.open(Path(d) / name).convert("RGBA"))
                    signed = np.array(Image.open(nb.ART_DIR / name).convert("RGBA"))
                    self.assertEqual(plain.shape, (960, 768, 4))
                    diff = np.any(plain != signed, axis=2)
                    ys, xs = np.nonzero(diff)
                    self.assertGreater(len(xs), 500, name)
                    # the sign is one block on one wall; nothing else moved
                    self.assertLess(xs.max() - xs.min(), 100, name)
                    self.assertLess(ys.max() - ys.min(), 260, name)

    def test_the_committed_copies_match_the_script(self):
        self.assertEqual(nb.check(), [])


if __name__ == "__main__":
    unittest.main()
