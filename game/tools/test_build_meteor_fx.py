"""Tests for build_meteor_fx.py and frames_to_gif.py (task T-070)."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_meteor_fx as fx  # noqa: E402
import check_sprite_rules as rules  # noqa: E402
import frames_to_gif  # noqa: E402
from remove_car_shadow import write_png  # noqa: E402


class MeteorFxTests(unittest.TestCase):
    def test_pixel_sheets_follow_the_sprite_rules_and_are_not_red(self):
        for kind, n in (("tail", fx.TAIL_FRAMES), ("impact", fx.IMPACT_FRAMES)):
            p = fx.png_path(kind, "pixel")
            res = rules.check_sheet(str(p), n, size=fx.CELL, max_colors=fx.MAX_COLORS)
            self.assertEqual(len(res), n)
            for rs, _ in res:
                self.assertTrue(all(r[1] for r in rs), rs)
            self.assertEqual(fx._redgull_pixels(p), 0)

    def test_building_is_deterministic(self):
        a = fx.sheet([fx.tail_frame(f) for f in range(fx.TAIL_FRAMES)])
        b = fx.sheet([fx.tail_frame(f) for f in range(fx.TAIL_FRAMES)])
        self.assertEqual(a, b)
        self.assertEqual(fx.impact_frame(3).rows(), fx.impact_frame(3).rows())

    def test_committed_pixel_sheets_are_up_to_date(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "t.png"
            write_png(out, fx.sheet([fx.tail_frame(f) for f in range(fx.TAIL_FRAMES)]))
            self.assertEqual(out.read_bytes(), fx.png_path("tail", "pixel").read_bytes())
            write_png(out, fx.sheet([fx.impact_frame(f) for f in range(fx.IMPACT_FRAMES)]))
            self.assertEqual(out.read_bytes(), fx.png_path("impact", "pixel").read_bytes())

    def test_the_animations_change_from_frame_to_frame(self):
        self.assertNotEqual(fx.tail_frame(0).rows(), fx.tail_frame(1).rows())
        self.assertNotEqual(fx.impact_frame(2).rows(), fx.impact_frame(3).rows())

    def test_records_exist_for_every_sheet(self):
        for kind in ("tail", "impact"):
            for ver in ("pixel", "pixellab"):
                rec = json.loads(fx.png_path(kind, ver).with_suffix(".json").read_text(encoding="utf-8"))
                self.assertEqual(rec["frame_size"], [fx.CELL, fx.CELL])

    def test_the_gif_maker_writes_every_changing_frame(self):
        with tempfile.TemporaryDirectory() as d:
            for i in range(4):
                write_png(Path(d) / f"f{i:04d}.png", [[(i * 60, 10, 20, 255)] * 20 for _ in range(10)])
            out = Path(d) / "o.gif"
            self.assertEqual(frames_to_gif.frames_to_gif(d, out, skip=1), 4)
            self.assertTrue(out.exists())


if __name__ == "__main__":
    unittest.main()
