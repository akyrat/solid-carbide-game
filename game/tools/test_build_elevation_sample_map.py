"""Tests for build_elevation_sample_map.py (task T-194).
Run: python -m unittest discover -s game/tools -p "test_*.py"."""

import json
import tempfile
import unittest
from pathlib import Path

import build_elevation_sample_map as E
import check_height_data as checker

ROOT = Path(__file__).resolve().parents[2]
SAMPLE = ROOT / "game" / "data" / "level" / "elevation_sample_map.json"
MVP = ROOT / "game" / "data" / "level" / "mvp_map.json"


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


class CommittedFileTest(unittest.TestCase):
    """Checks the committed game/data/level/elevation_sample_map.json itself."""

    @classmethod
    def setUpClass(cls):
        cls.data = load(SAMPLE)
        cls.mvp = load(MVP)
        cls.platforms = cls.data["platforms"]
        cls.ramps = cls.data["ramps"]

    def test_matches_a_rebuild_and_the_check_mode_says_so(self):
        self.assertEqual(E.check_committed(), [])
        self.assertEqual(E.main(["--check"]), 0)

    def test_the_validator_accepts_it(self):
        self.assertEqual(checker.check_file(str(SAMPLE)), [])
        self.assertEqual(checker.main(["check_height_data.py", str(SAMPLE)]), 0)

    def test_heights_used_are_exactly_0_3_and_6(self):
        used = {0.0}
        used |= {float(p["height"]) for p in self.platforms}
        for r in self.ramps:
            used |= {float(r["bottom_height"]), float(r["top_height"])}
        self.assertEqual(used, {0.0, 3.0, 6.0})

    def test_at_least_one_area_at_3_and_one_at_6(self):
        heights = [p["height"] for p in self.platforms]
        self.assertIn(3, heights)
        self.assertIn(6, heights)

    def test_a_0_to_3_ramp_and_a_3_to_6_ramp(self):
        pairs = {(r["bottom_height"], r["top_height"]) for r in self.ramps}
        self.assertIn((0, 3), pairs)
        self.assertIn((3, 6), pairs)

    def test_every_height_6_area_is_reachable_from_the_street_by_ramps(self):
        reach = E.reachable_areas(self.platforms, self.ramps)
        for p in self.platforms:
            if p["height"] == 6:
                self.assertIn(p["id"], reach)
        # Every area, in fact.
        self.assertEqual(reach, {"street"} | {p["id"] for p in self.platforms})

    def test_no_ramp_foot_is_blocked(self):
        m = E.rect_of(self.data["map"]["rect"])
        boulders = [b for c in self.data["pattern_copies"] for b in c["boulders"]]
        for r in self.ramps:
            for rect in (E.rect_of(r), E.foot_strip(r)):
                self.assertTrue(E.rect_inside(rect, m), r["id"])
                for b in self.data["buildings"]:
                    self.assertFalse(E.rects_overlap(rect, E.rect_of(b)), (r["id"], b))
                for b in boulders:
                    self.assertFalse(E.circle_overlaps_rect(b["x"], b["y"], b["diameter"] / 2, rect), (r["id"], b))
            # The strip in front of the foot is on the ground the ramp starts from, and not on
            # a higher area (so the car drives straight onto the ramp's foot).
            strip = E.foot_strip(r)
            _, below = E.ground_under(strip, self.platforms)
            self.assertEqual(below, r["bottom_height"], r["id"])
            for p in self.platforms:
                if p["height"] > r["bottom_height"]:
                    self.assertFalse(E.rects_overlap(strip, E.rect_of(p)), (r["id"], p["id"]))

    def test_no_boulder_on_a_raised_area_or_a_ramp(self):
        rects = [E.rect_of(p) for p in self.platforms] + [E.rect_of(r) for r in self.ramps]
        for c in self.data["pattern_copies"]:
            self.assertTrue(c["boulders"], c["id"])
            for b in c["boulders"]:
                for rect in rects:
                    self.assertFalse(E.circle_overlaps_rect(b["x"], b["y"], b["diameter"] / 2, rect), (c["id"], b))

    def test_no_building_inside_a_raised_area(self):
        for b in self.data["buildings"]:
            for p in self.platforms:
                self.assertFalse(E.rects_overlap(E.rect_of(b), E.rect_of(p)), (b, p["id"]))

    def test_keeps_the_mvp_size_and_the_keys_mvp_map_reads(self):
        for key in ("map", "gravel", "buildings", "pattern_copies", "challenges", "challenge_designs",
                    "ground_rows", "legend", "px_per_unit", "road_width", "block_size", "perimeter_road_width"):
            self.assertIn(key, self.data, key)
        self.assertEqual(self.data["map"], self.mvp["map"])
        self.assertEqual(self.data["gravel"], self.mvp["gravel"])
        self.assertEqual(self.data["challenge_designs"], self.mvp["challenge_designs"])
        self.assertEqual(len(self.data["ground_rows"]), 240)
        self.assertTrue(all(len(row) == 240 for row in self.data["ground_rows"]))

    def test_only_buildings_under_rooftops_are_left_out(self):
        roofs = [E.rect_of(p) for p in self.platforms]
        expected = [b for b in self.mvp["buildings"] if not any(E.rects_overlap(E.rect_of(b), r) for r in roofs)]
        self.assertEqual(self.data["buildings"], expected)
        self.assertLess(len(self.data["buildings"]), len(self.mvp["buildings"]))

    def test_only_boulders_on_rooftops_ramps_or_ramp_feet_are_left_out(self):
        blocked = E.blocked_footprints(self.platforms, self.ramps)
        kept = {(b["x"], b["y"]) for c in self.data["pattern_copies"] for b in c["boulders"]}
        for c in self.mvp["pattern_copies"]:
            for b in c["boulders"]:
                hit = any(E.circle_overlaps_rect(b["x"], b["y"], b["diameter"] / 2, r) for r in blocked)
                self.assertEqual((b["x"], b["y"]) in kept, not hit, b)

    def test_challenges_only_on_untouched_copies(self):
        copies = {c["id"]: c for c in self.data["pattern_copies"]}
        mvp_copies = {c["id"]: c for c in self.mvp["pattern_copies"]}
        for ch in self.data["challenges"]:
            self.assertIn(ch["copy"], copies)
            self.assertEqual(copies[ch["copy"]]["boulders"], mvp_copies[ch["copy"]]["boulders"])
        self.assertEqual(self.data["challenge_rule"]["copies"], len(self.data["pattern_copies"]))
        self.assertEqual(self.data["challenge_rule"]["challenges"], len(self.data["challenges"]))


class HelperTest(unittest.TestCase):
    def test_foot_strip_is_on_the_far_side_from_the_area(self):
        r = {"x": 0, "y": 0, "w": 12, "h": 10, "side": "west"}    # rises eastward, foot at x 0
        self.assertEqual(E.foot_strip(r, 6), (-6, 0, 0, 10))
        r = {"x": 0, "y": 0, "w": 12, "h": 10, "side": "east"}    # rises westward, foot at x 12
        self.assertEqual(E.foot_strip(r, 6), (12, 0, 18, 10))
        r = {"x": 0, "y": 0, "w": 10, "h": 12, "side": "north"}   # rises southward, foot at y 0
        self.assertEqual(E.foot_strip(r, 6), (0, -6, 10, 0))
        r = {"x": 0, "y": 0, "w": 10, "h": 12, "side": "south"}   # rises northward, foot at y 12
        self.assertEqual(E.foot_strip(r, 6), (0, 12, 10, 18))

    def test_reachability_misses_an_area_with_no_ramp_up(self):
        platforms = [{"id": "a", "x": 0, "y": 0, "w": 40, "h": 40, "height": 3},
                     {"id": "b", "x": 10, "y": 10, "w": 10, "h": 10, "height": 6, "on": "a"}]
        ramps = [{"id": "r", "platform": "a", "side": "east", "x": 40, "y": 0, "w": 12, "h": 8}]
        self.assertEqual(E.reachable_areas(platforms, ramps), {"street", "a"})
        ramps.append({"id": "r2", "platform": "b", "side": "east", "x": 20, "y": 10, "w": 12, "h": 8})
        self.assertEqual(E.reachable_areas(platforms, ramps), {"street", "a", "b"})

    def test_circle_and_rect_touching_is_not_overlap(self):
        self.assertFalse(E.circle_overlaps_rect(-1.5, 5, 1.5, (0, 0, 10, 10)))
        self.assertTrue(E.circle_overlaps_rect(-1.4, 5, 1.5, (0, 0, 10, 10)))


class BuildTest(unittest.TestCase):
    def test_build_does_not_change_its_input_and_is_repeatable(self):
        mvp = load(MVP)
        before = json.dumps(mvp, sort_keys=True)
        a = E.render_text(E.build(mvp))
        self.assertEqual(json.dumps(mvp, sort_keys=True), before)
        self.assertEqual(a, E.render_text(E.build(load(MVP))))

    def test_check_mode_finds_a_changed_file(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "map.json"
            self.assertTrue(E.check_committed(out=out))          # missing
            out.write_text(SAMPLE.read_text(encoding="utf-8").replace('"height": 6', '"height": 7', 1),
                           encoding="utf-8", newline="\n")
            self.assertTrue(E.check_committed(out=out))          # differs
            out.write_text(SAMPLE.read_text(encoding="utf-8"), encoding="utf-8", newline="\n")
            self.assertEqual(E.check_committed(out=out), [])

    def test_write_produces_the_file_and_a_png(self):
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "map.json"
            pic = Path(d) / "map.png"
            E.write(out=out, pictures=(pic,))
            self.assertEqual(out.read_text(encoding="utf-8"), SAMPLE.read_text(encoding="utf-8"))
            self.assertEqual(pic.read_bytes()[:8], b"\x89PNG\r\n\x1a\n")

    def test_the_picture_uses_different_colours_for_0_3_and_6(self):
        layout = load(SAMPLE)
        w, h, img = E.draw(layout)
        colours = {px for row in img for px in row}
        for c in (E.C_STREET, E.C_H3, E.C_H6, E.C_ARROW):
            self.assertIn(c, colours)
        self.assertEqual(len({E.C_STREET, E.C_H3, E.C_H6}), 3)


if __name__ == "__main__":
    unittest.main()
