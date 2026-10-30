import copy, json, subprocess, sys, tempfile, unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import check_level as c

ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / "game/tools/check_level.py"
SAMPLE = ROOT / "game/data/level/elevation_sample_map.json"


def small_level():
    """A valid 20 x 20 level: a building, a rooftop with a ramp, a boulder."""
    return {
        "map": {"width": 20, "height": 20, "rect": {"x": -10.0, "y": -10.0, "w": 20, "h": 20}},
        "legend": {"R": "road", "B": "building"},
        "ground_rows": ["R" * 20 for _ in range(20)],
        "buildings": [{"x": -8.0, "y": -8.0, "w": 4.0, "h": 4.0}],
        "pattern_copies": [{"id": "copy-01", "boulders": [{"x": 6.0, "y": 6.0, "diameter": 3.0}]}],
        "platforms": [{"id": "roof", "x": 0.0, "y": -8.0, "w": 6.0, "h": 6.0, "height": 3.0}],
        "ramps": [{"id": "ramp", "platform": "roof", "side": "south", "x": 2.0, "y": -2.0, "w": 2.0,
                   "h": 4.0, "bottom_height": 0.0, "top_height": 3.0}],
        "spawn": {"x": -5.0, "y": 1.0, "heading": 270},
    }


def run_tool(path):
    return subprocess.run([sys.executable, str(TOOL), str(path)], capture_output=True, text=True)


class TestCheckLevel(unittest.TestCase):
    def setUp(self):
        self.data = small_level()
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, data):
        p = Path(self.tmp.name) / "level.json"
        p.write_text(json.dumps(data), encoding="utf-8")
        return p

    def assert_rejected(self, *words):
        res = run_tool(self.write(self.data))
        self.assertEqual(res.returncode, 1, res.stdout)
        lines = [l for l in res.stdout.splitlines() if l.strip()]
        self.assertTrue(any(all(w in l for w in words) for l in lines), res.stdout)

    # --- accepted ---

    def test_valid_small_level(self):
        self.assertEqual(c.check_level(self.data), [])
        res = run_tool(self.write(self.data))
        self.assertEqual((res.returncode, res.stdout.strip()), (0, "OK"))

    def test_elevation_sample_map_is_valid(self):
        res = run_tool(SAMPLE)
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertEqual(res.stdout.strip(), "OK")

    def test_touching_the_map_edge_is_inside(self):
        self.data["buildings"][0].update(x=-10.0, y=-10.0)
        self.assertEqual(c.check_level(self.data), [])

    # --- rejected ---

    def test_rejects_building_outside_the_map(self):
        self.data["buildings"][0]["x"] = 8.0  # 8..12, past the east edge (10)
        self.assert_rejected("building", "outside the map")

    def test_rejects_rooftop_outside_the_map(self):
        self.data["platforms"][0].update(x=6.0, w=6.0)
        self.assert_rejected("rooftop", "'roof'", "outside the map")

    def test_rejects_ramp_outside_the_map(self):
        # The rooftop stays inside (y 6..10); its south ramp (y 10..14) hangs off the map.
        self.data["platforms"][0].update(y=6.0, h=4.0)
        self.data["ramps"][0].update(y=10.0, h=4.0)
        self.assert_rejected("ramp", "outside the map")

    def test_rejects_boulder_outside_the_map(self):
        self.data["pattern_copies"][0]["boulders"][0].update(x=9.0)  # 7.5..10.5
        self.assert_rejected("boulder", "outside the map")

    def test_rejects_odd_building_edge(self):
        self.data["buildings"][0]["x"] = -7.0
        self.assert_rejected("building", "odd unit")

    def test_rejects_odd_rooftop_edge(self):
        self.data["platforms"][0]["w"] = 5.0
        self.assert_rejected("rooftop", "odd unit")

    def test_rejects_odd_ramp_edge(self):
        self.data["ramps"][0].update(x=3.0, w=1.0)
        self.assert_rejected("ramp", "odd unit")

    def test_rejects_too_few_rows(self):
        self.data["ground_rows"].pop()
        self.assert_rejected("ground_rows", "19 rows")

    def test_rejects_a_short_row(self):
        self.data["ground_rows"][3] = "R" * 19
        self.assert_rejected("ground_rows", "row 3", "19 columns")

    def test_rejects_a_height_data_problem(self):
        self.data["ramps"][0]["top_height"] = 5.0
        self.assert_rejected("ramp", "top_height")

    def test_rejects_bad_json(self):
        p = Path(self.tmp.name) / "bad.json"
        p.write_text("{ nope", encoding="utf-8")
        self.assertEqual(run_tool(p).returncode, 1)

    def test_one_line_per_problem(self):
        good = copy.deepcopy(self.data)
        self.data["buildings"][0]["x"] = 8.0
        self.data["ground_rows"].pop()
        self.assertEqual(len(c.check_level(self.data)), 2)  # a building outside, too few rows
        self.assertEqual(c.check_level(good), [])


class TestCheckProps(unittest.TestCase):
    """T-253: props lie inside the map, name a known prop and rotation, and have its turned footprint."""

    def level(self, *props):
        d = small_level()
        d["props"] = list(props)
        return d

    def prop(self, asset="prop-barrier", rotation="north", x=0.0, y=0.0, w=4.0, h=1.0):
        return {"id": "prop-1", "asset": asset, "rotation": rotation, "x": x, "y": y, "w": w, "h": h}

    def test_a_valid_prop(self):
        self.assertEqual(c.check_level(self.level(self.prop())), [])

    def test_east_swaps_the_footprint(self):
        self.assertEqual(c.check_level(self.level(self.prop(rotation="east", w=1.0, h=4.0))), [])
        problems = c.check_level(self.level(self.prop(rotation="east")))
        self.assertTrue(any("footprint" in p for p in problems), problems)

    def test_rejects_a_prop_outside_the_map(self):
        problems = c.check_level(self.level(self.prop(x=8.0)))
        self.assertTrue(any("prop 'prop-1'" in p and "outside the map" in p for p in problems), problems)

    def test_rejects_an_unknown_prop_and_rotation(self):
        self.assertTrue(any("unknown prop" in p for p in c.check_level(self.level(self.prop(asset="prop-x")))))
        self.assertTrue(any("unknown rotation" in p for p in c.check_level(self.level(self.prop(rotation="up")))))

    def test_rejects_a_prop_without_numbers(self):
        bad = self.prop()
        del bad["w"]
        self.assertTrue(any("needs numbers" in p for p in c.check_level(self.level(bad))))

    def test_a_level_without_props_is_valid(self):
        self.assertEqual(c.check_level(small_level()), [])


class TestCheckPairs(unittest.TestCase):
    """T-272: every pair names two different existing obstacles; T-394: an obstacle can be in several
    pairs, the same two obstacles in one pair at most."""

    def level(self, *pairs):
        d = small_level()
        d["pattern_copies"].append({"id": "copy-02", "boulders": [
            {"x": -6.0, "y": 6.0, "diameter": 3.0}, {"x": -2.0, "y": 6.0, "diameter": 3.0}]})
        d["props"] = [
            {"id": "prop-1", "asset": "prop-barrier", "rotation": "north", "x": 0.0, "y": 0.0, "w": 4.0, "h": 1.0},
            {"id": "prop-2", "asset": "prop-street-lamp", "rotation": "north", "x": 4.0, "y": 0.0, "w": 2.0, "h": 2.0},
            {"id": "prop-3", "asset": "prop-cones", "rotation": "north", "x": 6.0, "y": -8.0, "w": 2.0, "h": 2.0},
        ]
        d["pairs"] = list(pairs)
        return d

    def pair(self, a, b, pid="pair-1"):
        return {"id": pid, "a": a, "b": b}

    def test_the_obstacles_are_the_obstacles_groups_props(self):
        self.assertEqual(c.obstacle_props(), {"prop-barrier", "prop-cones", "prop-crates"})

    def test_valid_pairs(self):
        d = self.level(self.pair("copy-01", "prop-1"), self.pair("copy-02/0", "copy-02/1", "pair-2"))
        self.assertEqual(c.check_level(d), [])

    def test_a_level_without_pairs_is_valid(self):
        self.assertEqual(c.check_level(self.level()), [])

    def test_the_elevation_sample_map_has_no_pairs_and_passes(self):
        data = json.loads(SAMPLE.read_text(encoding="utf-8"))
        self.assertNotIn("pairs", data)
        self.assertEqual(c.check_pairs(data), [])

    def test_rejects_a_pair_naming_a_missing_obstacle(self):
        problems = c.check_level(self.level(self.pair("copy-01", "prop-9")))
        self.assertTrue(any("pair 'pair-1'" in p and "'prop-9'" in p and "no such obstacle" in p for p in problems), problems)
        problems = c.check_level(self.level(self.pair("copy-77", "prop-1")))
        self.assertTrue(any("'copy-77'" in p for p in problems), problems)
        problems = c.check_level(self.level(self.pair("copy-02/5", "prop-1")))
        self.assertTrue(any("no boulder 5" in p for p in problems), problems)

    def test_rejects_a_prop_that_is_not_an_obstacle(self):
        problems = c.check_level(self.level(self.pair("copy-01", "prop-2")))
        self.assertTrue(any("not an obstacle" in p for p in problems), problems)

    def test_a_copy_of_several_boulders_needs_an_index(self):
        problems = c.check_level(self.level(self.pair("copy-02", "prop-1")))
        self.assertTrue(any("holds 2 boulders" in p for p in problems), problems)

    def test_rejects_an_obstacle_with_itself(self):
        problems = c.check_level(self.level(self.pair("prop-1", "prop-1")))
        self.assertTrue(any("with itself" in p for p in problems), problems)

    def test_accepts_an_obstacle_in_several_pairs_a_chain(self):
        """T-394: a row paired as a chain, A-B, B-C, C-D: the middle obstacles are in two pairs."""
        d = self.level(self.pair("copy-01", "prop-1"), self.pair("prop-1", "prop-3", "pair-2"),
                       self.pair("prop-3", "copy-02/0", "pair-3"), self.pair("copy-02/0", "copy-02/1", "pair-4"))
        self.assertEqual(c.check_level(d), [])

    def test_rejects_the_same_two_obstacles_paired_twice(self):
        problems = c.check_level(self.level(self.pair("copy-01", "prop-1"), self.pair("prop-1", "copy-01", "pair-2")))
        self.assertTrue(any("pair 'pair-2'" in p and "again" in p and "pair 'pair-1'" in p for p in problems), problems)

    def test_rejects_pairs_that_are_not_a_list(self):
        d = self.level()
        d["pairs"] = {"a": 1}
        self.assertIn("pairs: must be a list", c.check_level(d))

    def test_the_tool_refuses_a_missing_obstacle(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "level.json"
            p.write_text(json.dumps(self.level(self.pair("copy-01", "prop-9"))), encoding="utf-8")
            res = run_tool(p)
        self.assertEqual(res.returncode, 1, res.stdout)
        self.assertIn("no such obstacle", res.stdout)


class TestSpawn(unittest.TestCase):
    """T-280: every level has a spawn point a car can stand on."""

    def level(self, **spawn):
        d = small_level()
        d["spawn"].update(spawn)
        return d

    def problems(self, d):
        return [p for p in c.check_level(d) if p.startswith("spawn")]

    def test_valid_spawn_points(self):
        self.assertEqual(self.problems(self.level()), [])
        for h in range(0, 360, 45):
            self.assertEqual(self.problems(self.level(heading=h)), [])

    def test_a_spawn_on_a_rooftop_or_a_ramp_is_fine(self):
        self.assertEqual(self.problems(self.level(x=3.0, y=-5.0)), [])  # on the rooftop
        self.assertEqual(self.problems(self.level(x=3.0, y=-1.0)), [])  # on the ramp

    def test_a_spawn_on_a_short_building_is_fine(self):
        """T-405: a low-rise, small or long building is a platform the car can stand on; a skyscraper is not."""
        d = self.level(x=-5.0, y=7.0)
        d["buildings"].append({"x": -8.0, "y": 4.0, "w": 6.0, "h": 6.0, "asset": "building-small", "look": 0})
        self.assertEqual(self.problems(d), [])
        d["buildings"][-1]["asset"] = "skyscraper-1"
        self.assertTrue(any("building" in p for p in self.problems(d)))

    def test_a_missing_spawn_is_refused(self):
        d = small_level()
        del d["spawn"]
        self.assertTrue(any("spawn: missing" in p for p in c.check_level(d)))
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "level.json"
            p.write_text(json.dumps(d), encoding="utf-8")
            res = run_tool(p)
        self.assertEqual(res.returncode, 1, res.stdout)
        self.assertIn("spawn: missing", res.stdout)

    def test_the_games_own_map_needs_none(self):
        self.assertEqual(run_tool(SAMPLE).returncode, 0)
        d = small_level()
        del d["spawn"]
        self.assertEqual(c.check_level(d, require_spawn=False), [])

    def test_refused_off_the_map_or_in_a_building_prop_or_boulder(self):
        self.assertTrue(any("outside the map" in p for p in self.problems(self.level(x=11.0))))
        self.assertTrue(any("outside the map" in p for p in self.problems(self.level(y=-10.5))))
        self.assertTrue(any("building" in p for p in self.problems(self.level(x=-6.0, y=-6.0))))
        d = self.level(x=-7.0, y=-3.0)  # the cell beside the building (a clear cell) is fine
        self.assertEqual(self.problems(d), [])
        d = self.level(x=6.0, y=6.0)
        self.assertTrue(any("boulder" in p for p in self.problems(d)))
        d = self.level(x=-1.0, y=5.0)
        d["props"] = [{"id": "prop-1", "asset": "prop-barrier", "rotation": "north", "x": -2.0, "y": 4.0, "w": 2.0, "h": 2.0}]
        self.assertTrue(any("prop" in p and "can't stand" in p for p in self.problems(d)))

    def test_refused_for_a_bad_heading_or_missing_numbers(self):
        self.assertTrue(any("heading" in p for p in self.problems(self.level(heading=30))))
        self.assertTrue(any("heading" in p for p in self.problems(self.level(heading="north"))))
        d = small_level()
        d["spawn"] = {"y": 1.0, "heading": 0}
        self.assertTrue(any("needs numbers" in p for p in self.problems(d)))



class TestJumpRampLevel(unittest.TestCase):
    """T-400: a level with a small jump ramp on the street and one on its rooftop passes."""

    def test_a_level_with_jump_ramps_passes(self):
        d = small_level()
        d["ramps"].append({"id": "ramp-2", "platform": "", "side": "west", "x": -8.0, "y": 2.0, "w": 4.0,
                           "h": 6.0, "bottom_height": 0.0, "top_height": 2.0, "arrows": "up", "jump": True})
        d["ramps"].append({"id": "ramp-3", "platform": "", "side": "north", "x": 0.0, "y": -8.0, "w": 4.0,
                           "h": 4.0, "bottom_height": 3.0, "top_height": 5.0, "arrows": "up", "jump": True})
        self.assertEqual(c.check_level(d), [])
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "level.json"
            p.write_text(json.dumps(d), encoding="utf-8")
            res = run_tool(p)
        self.assertEqual((res.returncode, res.stdout.strip()), (0, "OK"))


if __name__ == "__main__":
    unittest.main()
