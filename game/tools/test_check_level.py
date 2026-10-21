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


if __name__ == "__main__":
    unittest.main()
