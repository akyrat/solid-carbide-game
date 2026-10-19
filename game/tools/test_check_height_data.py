import copy, json, subprocess, sys, tempfile, unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import check_height_data as c

ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / "game/tools/check_height_data.py"
FIXTURE = ROOT / "game/tests/fixtures/height/three_layers.json"
ELEVATION_TEST = ROOT / "game/data/level/elevation_test.json"


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def run_tool(path):
    return subprocess.run([sys.executable, str(TOOL), str(path)], capture_output=True, text=True)


class TestCheckHeightData(unittest.TestCase):
    def setUp(self):
        self.data = load(FIXTURE)
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, data):
        p = Path(self.tmp.name) / "data.json"
        p.write_text(json.dumps(data), encoding="utf-8")
        return p

    def ramp(self, rid):
        return next(r for r in self.data["ramps"] if r["id"] == rid)

    def platform(self, pid):
        return next(p for p in self.data["platforms"] if p["id"] == pid)

    def assert_rejected(self, data, *words):
        res = run_tool(self.write(data))
        self.assertNotEqual(res.returncode, 0, res.stdout)
        lines = [l for l in res.stdout.splitlines() if l.strip()]
        self.assertTrue(lines, "a message per problem")
        self.assertTrue(any(all(w in l for w in words) for l in lines), res.stdout)
        return lines

    # --- accepted files ---

    def test_elevation_test_file_is_valid(self):
        res = run_tool(ELEVATION_TEST)
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertEqual(res.stdout.strip(), "OK")

    def test_three_layer_fixture_is_valid(self):
        res = run_tool(FIXTURE)
        self.assertEqual(res.returncode, 0, res.stdout)

    def test_fixture_has_the_three_layers(self):
        self.assertEqual(self.platform("roof_low")["height"], 3.0)
        high = self.platform("roof_high")
        self.assertEqual((high["height"], high["on"]), (6.0, "roof_low"))
        self.assertEqual([(r["bottom_height"], r["top_height"]) for r in self.data["ramps"]],
                         [(0.0, 3.0), (3.0, 6.0)])

    def test_a_ramp_on_every_side_is_valid(self):
        area = {"id": "a", "x": 0, "y": 0, "w": 10, "h": 10, "height": 3}
        ramps = [
            {"id": "n", "platform": "a", "side": "north", "x": 2, "y": -6, "w": 4, "h": 6, "top_height": 3},
            {"id": "s", "platform": "a", "side": "south", "x": 2, "y": 10, "w": 4, "h": 6, "top_height": 3},
            {"id": "w", "platform": "a", "side": "west", "x": -6, "y": 2, "w": 6, "h": 4, "top_height": 3},
            {"id": "e", "platform": "a", "side": "east", "x": 10, "y": 2, "w": 6, "h": 4, "top_height": 3},
        ]
        self.assertEqual(c.check_data({"platforms": [area], "ramps": ramps}), [])

    def test_stacking_through_two_levels_is_valid(self):
        top = {"id": "roof_top", "on": "roof_high", "x": -8, "y": -8, "w": 4, "h": 4, "height": 9}
        self.data["platforms"].append(top)
        self.assertEqual(c.check_data(self.data), [])

    # --- rejected files (the acceptance criteria's four, then the rest) ---

    def test_rejects_overlap_without_stacking_field(self):
        del self.platform("roof_high")["on"]
        self.assert_rejected(self.data, "overlap", "roof_low", "roof_high")

    def test_rejects_ramp_top_not_touching_its_area(self):
        self.ramp("ramp_low_to_high")["x"] = 8.0  # 2 units short of roof_high's east side
        self.assert_rejected(self.data, "ramp_low_to_high", "doesn't touch", "roof_high")

    def test_rejects_ramp_top_beyond_the_side(self):
        r = self.ramp("ramp_low_to_high")
        r["y"], r["h"] = 2.0, 8.0  # reaches past roof_high's south-east corner (y 6)
        self.assert_rejected(self.data, "ramp_low_to_high", "doesn't touch")

    def test_rejects_bottom_height_not_matching_the_ground(self):
        self.ramp("ramp_low_to_high")["bottom_height"] = 0.0  # its foot is on roof_low (3)
        self.assert_rejected(self.data, "ramp_low_to_high", "bottom_height", "roof_low")
        self.data = load(FIXTURE)
        self.ramp("ramp_street_to_low")["bottom_height"] = 3.0  # its foot is on the street
        self.assert_rejected(self.data, "ramp_street_to_low", "bottom_height", "street")

    def test_rejects_top_height_not_matching_its_area(self):
        self.ramp("ramp_low_to_high")["top_height"] = 5.0
        self.assert_rejected(self.data, "ramp_low_to_high", "top_height", "roof_high")

    def test_rejects_unknown_side(self):
        self.ramp("ramp_street_to_low")["side"] = "up"
        self.assert_rejected(self.data, "ramp_street_to_low", "unknown side")

    def test_rejects_stacked_area_not_inside_its_base(self):
        self.platform("roof_high")["x"] = 10.0  # 10..26 sticks out of roof_low (-20..20)
        self.assert_rejected(self.data, "roof_high", "doesn't contain its whole footprint")

    def test_rejects_unknown_base_and_unknown_target(self):
        self.platform("roof_high")["on"] = "nowhere"
        self.ramp("ramp_street_to_low")["platform"] = "nothing"
        lines = self.assert_rejected(self.data, "unknown area", "nowhere")
        self.assertTrue(any("nothing" in l for l in lines))

    def test_rejects_ramp_half_on_an_area(self):
        data = {"platforms": [
            {"id": "a", "x": 0, "y": 0, "w": 10, "h": 10, "height": 3},
            {"id": "b", "x": 20, "y": 0, "w": 10, "h": 10, "height": 6},
        ], "ramps": [  # climbs b's west side; its foot (x 8..10) hangs half over a
            {"id": "r", "platform": "b", "side": "west", "x": 8, "y": 2, "w": 12, "h": 4,
             "bottom_height": 3, "top_height": 6},
        ]}
        self.assert_rejected(data, "'r'", "overlaps area 'a'")

    def test_rejects_ramp_overlapping_an_area_it_doesnt_stand_on(self):
        r = self.ramp("ramp_low_to_high")
        r["x"], r["w"] = 4.0, 14.0  # its top end now pokes 2 units into roof_high
        self.assert_rejected(self.data, "ramp_low_to_high")

    def test_rejects_bad_json(self):
        p = Path(self.tmp.name) / "bad.json"
        p.write_text("{ not json", encoding="utf-8")
        res = run_tool(p)
        self.assertNotEqual(res.returncode, 0)

    def test_check_data_one_problem_per_line(self):
        good = copy.deepcopy(self.data)
        del self.platform("roof_high")["on"]
        self.ramp("ramp_low_to_high")["top_height"] = 5.0
        self.assertEqual(len(c.check_data(self.data)), 2)
        self.assertEqual(c.check_data(good), [])


if __name__ == "__main__":
    unittest.main()
