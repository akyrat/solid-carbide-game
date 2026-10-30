import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hud_weapon_icons as b  # noqa: E402
import hud_sheet_check  # noqa: E402


class WeaponIconSheet(unittest.TestCase):
    def setUp(self):
        self.sheet = b.draw()

    def test_six_frames_of_24_in_order(self):
        self.assertEqual(self.sheet.size, (144, 24))
        self.assertEqual(self.sheet.mode, "RGBA")
        self.assertEqual(b.ORDER, ["gun", "flamethrower", "molotov", "bricks", "wiper", "underglow"])

    def test_alpha_only_0_or_255(self):
        self.assertTrue(all(a in (0, 255) for *_, a in self.sheet.getdata()))

    def test_each_frame_centred_and_filling_most_of_it(self):
        for i, w in enumerate(b.ORDER):
            f = self.sheet.crop((i * 24, 0, i * 24 + 24, 24))
            x0, y0, x1, y1 = f.getbbox()
            with self.subTest(weapon=w):
                self.assertGreaterEqual(max(x1 - x0, y1 - y0), 20)
                self.assertLessEqual(max(x1 - x0, y1 - y0), 23)   # room for the outline inside the frame
                self.assertLessEqual(abs(x0 - (24 - x1)), 1)
                self.assertLessEqual(abs(y0 - (24 - y1)), 1)

    def test_outline_and_colours_follow_the_hud_sheet(self):
        with tempfile.TemporaryDirectory() as d:
            for i, w in enumerate(b.ORDER):
                p = Path(d) / f"weapon_{w}.png"
                self.sheet.crop((i * 24, 0, i * 24 + 24, 24)).save(p)
                with self.subTest(weapon=w):
                    self.assertEqual(hud_sheet_check.check(p), [])
                    im = b.Image.open(p).convert("RGBA")
                    breaks = hud_sheet_check.outline_breaks(im)
                    edge = list(hud_sheet_check.edge_pixels(im))
                    self.assertLessEqual(len(breaks), hud_sheet_check.BREAK_SHARE * len(edge))
                    self.assertGreater(len(breaks), 0)   # a few lighter highlight pixels on the lit side

    def test_no_greenbull_colours(self):
        cols = {p[:3] for p in self.sheet.getdata() if p[3] == 255}
        for g in b.GREENBULL:
            self.assertNotIn(g, cols)

    def test_at_most_30_colours_per_icon(self):
        for i, w in enumerate(b.ORDER):
            f = self.sheet.crop((i * 24, 0, i * 24 + 24, 24))
            with self.subTest(weapon=w):
                self.assertLessEqual(len({p for p in f.getdata() if p[3] == 255}), 30)

    def test_build_writes_sheet_and_record(self):
        with tempfile.TemporaryDirectory() as d:
            p = b.build(Path(d) / "weapon_icons.png")
            self.assertEqual(b.Image.open(p).tobytes(), self.sheet.tobytes())
            rec = json.loads(p.with_suffix(".json").read_text(encoding="utf-8"))
            self.assertEqual(rec["task"], "T-429")
            self.assertEqual(rec["frame_order"], b.ORDER)
            self.assertEqual(rec["shown_at_scale"], 2)
            self.assertEqual(rec["pixellab_generations"], 0)
            for key in ("what", "size", "frames", "made_by", "style_loop", "references"):
                self.assertIn(key, rec)

    def test_deterministic(self):
        self.assertEqual(b.draw().tobytes(), self.sheet.tobytes())


if __name__ == "__main__":
    unittest.main()
