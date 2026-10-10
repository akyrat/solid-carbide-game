"""Tests for build_mvp_map.py (task T-019). Run: python -m unittest discover -s game/tools -p "test_*.py"."""

import json
import math
import shutil
import tempfile
import unittest
from pathlib import Path

import build_mvp_map as B


class ChallengeCountTest(unittest.TestCase):
    def test_thirty_percent_rounded_half_up_at_least_one(self):
        self.assertEqual(B.challenge_count(12), 4)   # 3.6
        self.assertEqual(B.challenge_count(10), 3)   # 3.0
        self.assertEqual(B.challenge_count(5), 2)    # 1.5 rounds up
        self.assertEqual(B.challenge_count(1), 1)    # 0.3, at least 1
        self.assertEqual(B.challenge_count(15), 5)   # 4.5 rounds up


class GeometryTest(unittest.TestCase):
    def test_smooth_keeps_the_ends(self):
        pts = [(0, 0), (2, 0), (2, 2), (4, 2)]
        line = B.smooth(pts)
        self.assertEqual(line[0], (0.0, 0.0))
        self.assertEqual(line[-1], (4.0, 2.0))
        self.assertGreater(len(line), 30)

    def test_rotation_quarter_turns_clockwise_on_screen(self):
        self.assertEqual(B.rotate((1, 0), 90), (0, 1))     # right -> down
        self.assertEqual(B.rotate((1, 0), 180), (-1, 0))
        self.assertEqual(B.rotate((0, 1), 270), (1, 0))

    def test_rotation_keeps_direction_around_a_boulder(self):
        pts = [(math.cos(a / 10), math.sin(a / 10)) for a in range(70)]
        before = B.turn_around(pts, 0, 0)
        after = B.turn_around([B.rotate(p, 90) for p in pts], 0, 0)
        self.assertAlmostEqual(before, after, places=6)

    def test_rect_distance(self):
        self.assertEqual(B.rect_distance(1, 1, (0, 0, 2, 2)), 0)
        self.assertAlmostEqual(B.rect_distance(5, 1, (0, 0, 2, 2)), 3)
        self.assertAlmostEqual(B.rect_distance(5, 6, (0, 0, 2, 2)), 5)


class FittedTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fitted, cls.layout = B.build()

    def sketch(self, pattern, arrow):
        return json.loads((B.SKETCH_DIR / pattern / (arrow + ".json")).read_text(encoding="utf-8"))

    def test_every_sketch_has_a_fitted_version(self):
        self.assertEqual(sorted(self.fitted), [("single-boulder", "arrow-1"), ("single-boulder", "arrow-2"),
                                               ("two-boulders", "arrow-1")])

    def test_fitted_keeps_boulders_and_directions(self):
        for (pattern, arrow), data in self.fitted.items():
            sk = self.sketch(pattern, arrow)
            self.assertEqual(len(data["boulders"]), len(sk["boulders"]))
            got = [t["direction"] for t in data["arrow"]["around_boulders"]]
            want = [t["direction"] for t in sk["arrow"]["around_boulders"]]
            self.assertEqual(got, want, (pattern, arrow))
            for t, s in zip(data["arrow"]["around_boulders"], sk["arrow"]["around_boulders"]):
                # Still goes all the way around (more than three quarters of a turn), like the sketch.
                self.assertGreater(t["degrees"], 270)
                self.assertLess(abs(t["degrees"] - s["degrees"]), 120)

    def test_fitted_keeps_point_count_and_boulder_size(self):
        for (pattern, arrow), data in self.fitted.items():
            sk = self.sketch(pattern, arrow)
            self.assertEqual(len(data["arrow"]["points"]), len(sk["arrow"]["points"]))
            for b in data["boulders"]:
                self.assertEqual(b["diameter"], 3.0)

    def test_fitted_fits_its_place(self):
        for (pattern, arrow), data in self.fitted.items():
            boulders = [(b["x"], b["y"]) for b in data["boulders"]]
            buildings = B.context_buildings(B.FIT_CONTEXTS[pattern])
            self.assertLessEqual(B.violations(B.smooth(data["arrow"]["points"]), boulders, buildings), 1e-9)

    def test_files_on_disk_are_up_to_date(self):
        for (pattern, arrow), data in self.fitted.items():
            path = B.SKETCH_DIR / pattern / (arrow + ".fitted.json")
            self.assertEqual(json.loads(path.read_text(encoding="utf-8")), data, path)
        self.assertEqual(json.loads(B.MAP_OUT.read_text(encoding="utf-8")), self.layout)

    def test_build_is_the_same_every_time(self):
        _, again = B.build()
        self.assertEqual(again, self.layout)


class MapTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        _, cls.layout = B.build()

    def test_twelve_blocks_outside_the_gravel(self):
        self.assertEqual(len(self.layout["buildings"]), 12)
        rows = self.layout["ground_rows"]
        self.assertEqual(len(rows), 80)
        self.assertEqual(sum(r.count("B") for r in rows), 12 * 100)
        self.assertEqual(sum(r.count("G") for r in rows), 28 * 28)

    def test_challenges_are_thirty_percent(self):
        rule = self.layout["challenge_rule"]
        self.assertEqual(rule["challenges"], B.challenge_count(rule["copies"]))
        self.assertEqual(len(self.layout["challenges"]), rule["challenges"])

    def test_corridors_clear_of_buildings_and_inside_the_map(self):
        for ch in self.layout["challenges"]:
            for x, y in ch["centre_line"]:
                self.assertLessEqual(abs(x) + 1.5, 40)
                self.assertLessEqual(abs(y) + 1.5, 40)
                for r in self.layout["buildings"]:
                    self.assertGreaterEqual(B.rect_distance(x, y, (r["x"], r["y"], r["w"], r["h"])), 1.5)


class WriteTest(unittest.TestCase):
    def test_write_leaves_the_sketches_unchanged(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            for pattern in B.FIT_CONTEXTS:
                shutil.copytree(B.SKETCH_DIR / pattern, tmp / pattern,
                                ignore=shutil.ignore_patterns("*.fitted.*", "*.driven.*"))
            before = {p: p.read_bytes() for p in tmp.rglob("*") if p.is_file()}
            self.assertEqual(len(before), 6)
            B.write(tmp, tmp / "map.json")
            for p, data in before.items():
                self.assertEqual(p.read_bytes(), data)
            self.assertTrue((tmp / "single-boulder" / "arrow-1.fitted.svg").exists())
            self.assertTrue((tmp / "map.json").exists())
        finally:
            shutil.rmtree(tmp)

    def test_only_the_sketches_are_read(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            for pattern in B.FIT_CONTEXTS:
                shutil.copytree(B.SKETCH_DIR / pattern, tmp / pattern,
                                ignore=shutil.ignore_patterns("*.fitted.*", "*.driven.*"))
            clean, _ = B.build(tmp)
            for pattern in B.FIT_CONTEXTS:
                d = tmp / pattern
                for f in sorted(d.glob("arrow-*.json")):
                    stem = f.name[:-len(".json")]
                    (d / (stem + ".driven.json")).write_text('{"driven": true}', encoding="utf-8")
                    (d / (stem + ".fitted.json")).write_text('{"fitted": true}', encoding="utf-8")
            again, _ = B.build(tmp)
            self.assertEqual(again, clean)
            self.assertEqual(len(again), 3)
        finally:
            shutil.rmtree(tmp)


if __name__ == "__main__":
    unittest.main()
