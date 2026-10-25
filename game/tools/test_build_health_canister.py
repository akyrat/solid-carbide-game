import unittest
from pathlib import Path

from PIL import Image

import build_health_canister as b

ROOT = Path(__file__).resolve().parents[2]


class BuildHealthCanisterTest(unittest.TestCase):
    def setUp(self):
        self.out = b.build(Image.open(b.RAW), 14)

    def test_coin_sized_and_rules(self):
        self.assertLessEqual(self.out.width, 16)
        self.assertLessEqual(self.out.height, 12)
        alphas = {p[3] for p in self.out.getdata()}
        self.assertEqual(alphas, {0, 255}, "no semi-transparent pixels")
        self.assertEqual(self.out.getpixel((0, 0))[3], 0, "transparent corner")
        self.assertLessEqual(len(b.opaque_colours(self.out)), 30)

    def test_no_colour_near_redgull_red(self):
        for c in b.opaque_colours(self.out):
            self.assertGreaterEqual(b.rgb_distance(c, b.REDGULL_RED), b.MIN_REDGULL_DISTANCE, c)

    def test_still_clearly_red(self):
        reds = [c for c in b.opaque_colours(self.out) if c[0] > 150 and c[0] > 2 * c[1]]
        self.assertGreaterEqual(len(reds), 2)

    def test_cross_is_a_plus(self):
        px = self.out.load()
        white = {(x, y) for y in range(self.out.height) for x in range(self.out.width) if px[x, y][:3] == b.WHITE}
        self.assertEqual(len(white), 5)
        cx = sum(x for x, _ in white) // 5
        cy = sum(y for _, y in white) // 5
        self.assertEqual(white, {(cx, cy), (cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)})

    def test_committed_art_matches_script(self):
        shipped = Image.open(ROOT / "game" / "art" / "effects" / "health_canister.png").convert("RGBA")
        self.assertEqual(list(shipped.getdata()), list(self.out.getdata()))


if __name__ == "__main__":
    unittest.main()
