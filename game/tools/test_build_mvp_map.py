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

    def test_challenge_designs_are_the_fitted_versions(self):
        designs = self.layout["challenge_designs"]
        self.assertEqual([d["id"] for d in designs],
                         ["single-boulder/arrow-1", "single-boulder/arrow-2", "two-boulders/arrow-1"])
        for d in designs:
            fv = self.fitted[(d["pattern"], d["arrow"])]
            self.assertEqual(d["boulders"], fv["boulders"])
            self.assertEqual(d["corridor_width"], 3.0)
            for got, want in zip(d["points"], fv["arrow"]["points"]):
                self.assertAlmostEqual(got[0], want[0], places=3)
                self.assertAlmostEqual(got[1], want[1], places=3)
            self.assertEqual(d["centre_line"][0], d["points"][0])
            self.assertEqual(d["centre_line"][-1], d["points"][-1])

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

    def test_map_is_242_by_242_with_8_unit_roads_and_10_unit_blocks(self):
        # 240 asked for; 13 blocks of 10 with 8-unit roads and the 8-unit perimeter road give 242.
        self.assertEqual(B.PERIMETER_ROAD * 2 + B.BLOCKS_PER_SIDE * B.BLOCK + (B.BLOCKS_PER_SIDE - 1) * B.ROAD,
                         B.MAP_SIZE)
        self.assertEqual(self.layout["map"]["width"], 242)
        self.assertEqual(self.layout["map"]["height"], 242)
        self.assertEqual(self.layout["map"]["rect"], {"x": -121.0, "y": -121.0, "w": 242, "h": 242})
        self.assertEqual(self.layout["perimeter_road_width"], 8)
        self.assertEqual(self.layout["road_width"], 8)
        self.assertEqual(self.layout["block_size"], 10)
        self.assertEqual(B.block_ranges()[0], -113)
        self.assertEqual(B.block_ranges()[-1], 103)

    def test_blocks_outside_the_gravel(self):
        # 13 by 13 blocks, minus the middle 5 by 5 under the gravel.
        self.assertEqual(len(self.layout["buildings"]), 13 * 13 - 5 * 5)
        self.assertEqual(self.layout["gravel"], {"x": -41.0, "y": -41.0, "w": 82, "h": 82})
        rows = self.layout["ground_rows"]
        self.assertEqual(len(rows), 242)
        self.assertTrue(all(len(r) == 242 for r in rows))
        self.assertEqual(sum(r.count("B") for r in rows), 144 * 100)
        self.assertEqual(sum(r.count("G") for r in rows), 82 * 82)
        for b in self.layout["buildings"]:
            self.assertEqual((b["w"], b["h"]), (10, 10))
            g = self.layout["gravel"]
            self.assertTrue(b["x"] + 10 <= g["x"] or b["x"] >= g["x"] + g["w"]
                            or b["y"] + 10 <= g["y"] or b["y"] >= g["y"] + g["h"])

    def test_copies_on_roads_outside_the_gravel(self):
        copies = self.layout["pattern_copies"]
        self.assertEqual(len(copies), 80)
        self.assertEqual(len({tuple(c["centre"]) for c in copies}), 80)
        half = 121
        for c in copies:
            x, y = c["centre"]
            self.assertFalse(B.in_gravel(x, y), c["id"])
            self.assertLess(abs(x), half)
            self.assertLess(abs(y), half)
            for b in c["boulders"]:
                self.assertEqual(b["diameter"], 3.0)
        kinds = [c["pattern"] for c in copies]
        self.assertEqual(kinds.count("single-boulder"), 32)
        self.assertEqual(kinds.count("two-boulders"), 48)

    def test_challenges_are_thirty_percent(self):
        rule = self.layout["challenge_rule"]
        self.assertEqual(rule["copies"], 80)
        self.assertEqual(rule["challenges"], B.challenge_count(80))
        self.assertEqual(rule["challenges"], 24)
        self.assertEqual(len(self.layout["challenges"]), rule["challenges"])
        arrows = {(c["pattern"], c["arrow"]) for c in self.layout["challenges"]}
        self.assertEqual(arrows, {("single-boulder", "arrow-1"), ("single-boulder", "arrow-2"),
                                  ("two-boulders", "arrow-1")})

    def footprint(self, copy):
        """Circles (centre, radius) a copy may cover: its boulders and the corridors of every
        arrow its pattern has, placed as the copy is."""
        out = [((b["x"], b["y"]), b["diameter"] / 2) for b in copy["boulders"]]
        for d in self.layout["challenge_designs"]:
            if d["pattern"] != copy["pattern"]:
                continue
            pts = [B.place(p, copy["centre"][0], copy["centre"][1], copy["rotation_degrees"]) for p in d["points"]]
            out += [(p, d["corridor_width"] / 2) for p in B.smooth(pts)]
        return out

    def test_corridors_clear_of_buildings_and_inside_the_map(self):
        half = self.layout["map"]["width"] / 2
        for ch in self.layout["challenges"]:
            for x, y in ch["centre_line"]:
                self.assertLessEqual(abs(x) + 1.5, half)
                self.assertLessEqual(abs(y) + 1.5, half)
                for r in self.layout["buildings"]:
                    self.assertGreaterEqual(B.rect_distance(x, y, (r["x"], r["y"], r["w"], r["h"])), 1.5)

    def test_every_copy_would_fit_as_a_challenge_with_any_of_its_arrows(self):
        # Not only the chosen challenges: every copy, with every arrow its pattern has, stays on
        # the road, inside the map and clear of the other copies, so the choice can change later.
        half = self.layout["map"]["width"] / 2
        rects = [(r["x"], r["y"], r["w"], r["h"]) for r in self.layout["buildings"]]
        copies = self.layout["pattern_copies"]
        prints = [self.footprint(c) for c in copies]
        for c, fp in zip(copies, prints):
            for (x, y), r in fp:
                self.assertLessEqual(abs(x) + r, half, c["id"])
                self.assertLessEqual(abs(y) + r, half, c["id"])
                near = [q for q in rects if B.rect_distance(x, y, q) < 3]
                for q in near:
                    self.assertGreaterEqual(B.rect_distance(x, y, q), r, c["id"])
        for i in range(len(copies)):
            for j in range(i + 1, len(copies)):
                ci, cj = copies[i]["centre"], copies[j]["centre"]
                if math.hypot(ci[0] - cj[0], ci[1] - cj[1]) > 30:
                    continue
                for (p, r1) in prints[i]:
                    for (q, r2) in prints[j]:
                        self.assertGreater(math.hypot(p[0] - q[0], p[1] - q[1]), r1 + r2,
                                           (copies[i]["id"], copies[j]["id"]))

    def test_the_car_starts_in_open_gravel(self):
        self.assertTrue(B.in_gravel(0, 0))
        for c in self.layout["pattern_copies"]:
            self.assertGreater(math.hypot(*c["centre"]), 40)


class WriteTest(unittest.TestCase):
    def test_write_leaves_the_sketches_unchanged(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            for pattern in B.FIT_CONTEXTS:
                shutil.copytree(B.SKETCH_DIR / pattern, tmp / pattern,
                                ignore=shutil.ignore_patterns("*.fitted.*", "*.driven.*"))
            before = {p: p.read_bytes() for p in tmp.rglob("*") if p.is_file()}
            # The 3 sketches (.json and .svg); any other files there (such as the T-021
            # check's .driven.* files) must be left alone too.
            self.assertEqual(len([p for p in before if "." not in p.name.split(".", 1)[0]
                                  and p.name.count(".") == 1]), 6)
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
