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



class TestJumpRamps(unittest.TestCase):
    """T-400: a small jump ramp ("jump": true) climbs to no area; its top is open."""

    def level(self, **ramp):
        r = {"id": "jump-1", "platform": "", "side": "south", "x": 0.0, "y": 0.0, "w": 10.0, "h": 4.0,
             "bottom_height": 0.0, "top_height": 2.0, "jump": True}
        r.update(ramp)
        return {"platforms": [{"id": "roof", "x": 20.0, "y": 0.0, "w": 16.0, "h": 16.0, "height": 3.0}],
                "ramps": [r]}

    def test_a_jump_ramp_on_the_street_and_on_a_rooftop_is_valid(self):
        self.assertEqual(c.check_data(self.level()), [])
        for side in ("north", "east", "south", "west"):
            self.assertEqual(c.check_data(self.level(side=side)), [], side)
        on_roof = self.level(x=22.0, y=2.0, bottom_height=3.0, top_height=5.0)
        self.assertEqual(c.check_data(on_roof), [])

    def test_its_foot_must_still_match_the_ground(self):
        problems = c.check_data(self.level(x=22.0, y=2.0))  # on the 3 but from 0
        self.assertTrue(any("bottom_height" in p for p in problems), problems)

    def test_it_must_rise_and_names_no_area(self):
        self.assertTrue(any("must be above" in p for p in c.check_data(self.level(top_height=0.0))))
        self.assertTrue(any("climbs to no area" in p for p in c.check_data(self.level(platform="roof"))))

    def test_without_the_jump_flag_an_unlinked_ramp_is_still_refused(self):
        d = self.level()
        del d["ramps"][0]["jump"]
        self.assertTrue(any("unknown area" in p for p in c.check_data(d)))


TWO_ROOFTOPS = ROOT / "game/tests/fixtures/height/ramp_onto_two_rooftops.json"
# The board's own level (main checkout, untracked): read only, never changed. Skipped when absent.
BOARD_KAIJU_CITY = Path("C:/solid-carbide-game/game/data/levels/kaiju_city.json")


class TestRampOntoSeveralRooftops(unittest.TestCase):
    """T-549: a ramp whose top meets several areas of its top_height side by side is valid."""

    def setUp(self):
        self.data = load(TWO_ROOFTOPS)

    def ramp(self, rid):
        return next(r for r in self.data["ramps"] if r["id"] == rid)

    def test_the_fixture_with_empty_platforms_is_valid(self):
        self.assertEqual(c.check_data(self.data), [])
        self.assertEqual(run_tool(TWO_ROOFTOPS).stdout.strip(), "OK")

    def test_platform_may_name_either_rooftop(self):
        for rid, roofs in (("ramp-2", ("roof-6", "roof-7")), ("ramp-13", ("roof-3", "roof-6"))):
            for roof in roofs:
                d = load(TWO_ROOFTOPS)
                next(r for r in d["ramps"] if r["id"] == rid)["platform"] = roof
                self.assertEqual(c.check_data(d), [], "%s -> %s" % (rid, roof))

    def test_naming_an_area_off_its_top_is_refused(self):
        self.ramp("ramp-2")["platform"] = "roof-3"
        problems = c.check_data(self.data)
        self.assertTrue(any("ramp-2" in p and "doesn't touch" in p for p in problems), problems)

    def test_a_top_meeting_nothing_at_its_height_is_refused(self):
        self.ramp("ramp-2")["x"] = -90.0  # 2 units short of the rooftops' west sides
        self.ramp("ramp-2")["w"] = 12.0
        problems = c.check_data(self.data)
        self.assertTrue(any("ramp-2" in p and "unknown area" in p and "meets no area" in p for p in problems),
                        problems)

    def test_a_top_only_partly_covered_is_refused(self):
        self.ramp("ramp-2")["y"], self.ramp("ramp-2")["h"] = -112.0, 22.0  # 4 units north of roof-6
        problems = c.check_data(self.data)
        self.assertTrue(any("ramp-2" in p and "unknown area" in p for p in problems), problems)

    def test_a_top_meeting_rooftops_of_another_height_is_refused(self):
        self.ramp("ramp-2")["top_height"] = 5.0
        problems = c.check_data(self.data)
        self.assertTrue(any("ramp-2" in p and "meets no area at height 5" in p for p in problems), problems)

    def test_top_areas_lists_both_rooftops_and_covers(self):
        plats = [(p["id"], c._rect(p), float(p["height"])) for p in self.data["platforms"]]
        self.assertEqual(c.top_areas("west", c._rect(self.ramp("ramp-2")), plats, 6.0), (["roof-6", "roof-7"], True))
        self.assertEqual(c.top_areas("east", c._rect(self.ramp("ramp-13")), plats, 6.0), (["roof-3", "roof-6"], True))

    @unittest.skipUnless(BOARD_KAIJU_CITY.is_file(), "the board's Kaiju City is not on this computer")
    def test_the_boards_kaiju_city_passes_both_checks(self):
        res = run_tool(BOARD_KAIJU_CITY)
        self.assertEqual((res.returncode, res.stdout.strip()), (0, "OK"), res.stdout)
        level = subprocess.run([sys.executable, str(ROOT / "game/tools/check_level.py"), str(BOARD_KAIJU_CITY)],
                               capture_output=True, text=True)
        self.assertEqual((level.returncode, level.stdout.strip()), (0, "OK"), level.stdout)


if __name__ == "__main__":
    unittest.main()
