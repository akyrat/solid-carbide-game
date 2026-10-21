"""Tests for build_car_sheet32.py and generate_car_inbetweens.py (task T-102). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_sheet32 as b  # noqa: E402
import check_sprite_rules as rules  # noqa: E402
import generate_car_inbetweens as gen  # noqa: E402

T = (0, 0, 0, 0)
O = (200, 200, 200, 255)


class MeasureTests(unittest.TestCase):
    def test_unwrap_makes_a_full_turn_increasing(self):
        self.assertEqual(b.unwrap_axes([170.0, 10.0, 60.0, 150.0, 20.0]), [170.0, 190.0, 240.0, 330.0, 380.0])
        self.assertEqual(b.unwrap_axes([100.0, 95.0, 130.0]), [100.0, 95.0, 130.0])  # a small step back stays small

    def test_position_between_neighbours(self):
        self.assertAlmostEqual(b.position(115.0, 100.0, 130.0), 0.5)
        self.assertAlmostEqual(b.position(10.0, 170.0, 200.0), 2.0 / 3.0)  # 10 is 190 mod 180

    def test_body_axis_of_bars(self):
        rows = [[O if y == 4 and 1 <= x <= 8 else T for x in range(10)] for y in range(10)]
        self.assertAlmostEqual(b.body_axis(rows), 0.0)
        rows = [[O if x == 4 and 1 <= y <= 8 else T for x in range(10)] for y in range(10)]
        self.assertAlmostEqual(b.body_axis(rows), 90.0)

    def test_assign_takes_the_raw_nearest_the_middle_inside_the_interval(self):
        raws = {k: {"position": 0.5} for k in range(16)}
        raws[3] = {"position": 0.05}   # barely turned: still inside (3, 4)
        raws[4] = {"position": -0.6}   # turned back into (3, 4), nearer its middle
        slots = b.assign(raws)
        self.assertEqual(slots[3], 4)
        self.assertIsNone(slots[4])
        self.assertEqual(slots[0], 0)


class GeneratorTests(unittest.TestCase):
    def test_one_call_per_t101_frame_and_the_sample_reused(self):
        self.assertEqual(sorted(gen.FROM_DIRECTION), list(range(16)))
        self.assertEqual(gen.raw_name(2), "car_rot16_from_f02_south_raw")
        self.assertEqual(gen.raw_name(5), "car_rot16_from_f05_south-west_raw")

    def test_request_matches_the_approved_sample(self):
        sample = json.loads((b.REPO / gen.OUT_DIR / "car_rot16_from_f02_south_raw.json").read_text(encoding="utf-8"))
        req = gen.request(2, b"x", b"y")
        for key in ("direction_change", "from_view", "to_view", "from_direction", "to_direction",
                    "isometric", "image_guidance_scale", "image_size", "view_change"):
            self.assertEqual(req[key], sample["request_params"][key], key)


class CommittedSheetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sheet, cls.layout, _, _, _ = b.build()
        _, _, cls.t101 = rules.decode_png((b.REPO / b.SHEET16).read_bytes())

    def test_build_matches_committed_files(self):
        _, _, committed = rules.decode_png((b.REPO / b.OUT_PNG).read_bytes())
        self.assertEqual(self.sheet, committed, "car_iso.png is what the script builds")
        on_disk = json.loads((b.REPO / b.OUT_JSON).read_text(encoding="utf-8"))
        self.assertEqual(json.loads(json.dumps(self.layout)), on_disk, "car_iso.json is what the script builds")

    def test_t101_frames_are_identical_in_the_even_places(self):
        for k in range(16):
            self.assertEqual(b.frame_of(self.sheet, 2 * k), b.frame_of(self.t101, k), f"T-101 frame {k}")

    def test_layout_is_32_frames_of_11_25_degrees(self):
        self.assertEqual(self.layout["frame_count"], 32)
        self.assertEqual(self.layout["columns"], 32)
        self.assertEqual(self.layout["step_deg"], 11.25)
        self.assertEqual(self.layout["file"], "car_iso.png")
        self.assertEqual([f["heading_deg"] for f in self.layout["frames"]], [i * 11.25 for i in range(32)])

    def test_every_frame_passes_the_rules(self):
        for i, (results, _info) in enumerate(rules.check_sheet(str(b.REPO / b.OUT_PNG), 32, 128, max_colors=33)):
            self.assertTrue(all(ok for _, ok, _ in results), f"frame {i}: {results}")

    def test_every_new_frame_has_a_pixellab_record(self):
        for f in self.layout["frames"][1::2]:
            rec = json.loads((b.REPO / f["source"]).with_suffix(".json").read_text(encoding="utf-8"))
            self.assertEqual(rec["endpoint"], "/rotate")
            self.assertEqual(rec["task"], "T-102")


if __name__ == "__main__":
    unittest.main()
