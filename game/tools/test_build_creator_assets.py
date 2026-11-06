"""Tests for build_creator_assets.py (T-232). Run: python -m unittest discover -s game/tools -p "test_*.py"."""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import build_creator_assets as bc  # noqa: E402

KINDS = {"ground", "road", "building", "boulder", "rooftop", "ramp", "prop", "crater", "alert", "rail"}  # crater: T-398; alert: T-441; rail: T-542


class CatalogueTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cat = bc.build()
        cls.entries = cls.cat["entries"]

    def test_deterministic(self):
        self.assertEqual(json.dumps(bc.build()), json.dumps(self.cat))

    def test_entry_fields(self):
        ids = set()
        for e in self.entries:
            self.assertNotIn(e["id"], ids)
            ids.add(e["id"])
            self.assertIn(e["kind"], KINDS)
            self.assertEqual(len(e["footprint_units"]), 2)
            self.assertTrue(e["views"])
            self.assertTrue(e["mirrors"])
            self.assertTrue(e["textures"])
            for t in e["textures"]:
                self.assertIn(t["view"], e["views"])
                self.assertIn(t["mirror"], e["mirrors"])

    def test_every_kind_present(self):
        self.assertEqual({e["kind"] for e in self.entries}, KINDS)

    def test_rooftops_and_ramps(self):
        roofs = sorted(e["height"] for e in self.entries if e["kind"] == "rooftop")
        self.assertEqual(roofs, [3, 6])
        ramps = sorted(e["heights"] for e in self.entries if e["kind"] == "ramp")
        self.assertEqual(ramps, [[0, 2], [0, 3], [0, 6], [3, 5], [3, 6], [6, 8]])

    def test_small_jump_ramps(self):
        # T-400: one tile (4 units) long, rising 2 from the street or a rooftop at 3 or 6, "jump"
        # (no rooftop at the top); the other ramps are not jump ramps.
        by_id = {e["id"]: e for e in self.entries}
        for eid, heights in (("ramp-0-2", [0, 2]), ("ramp-3-5", [3, 5]), ("ramp-6-8", [6, 8])):
            e = by_id[eid]
            self.assertEqual(e["heights"], heights)
            self.assertIs(e["jump"], True)
            self.assertEqual(e["length_units"], 4.0)
            self.assertEqual(e["footprint_units"], [10.0, 4.0])
            self.assertEqual(e["views"], ["north", "east", "south", "west"])
            self.assertTrue(bc.res_exists(e["textures"][0]["texture"]))
        for eid in ("ramp-0-3", "ramp-3-6", "ramp-0-6"):
            self.assertNotIn("jump", by_id[eid])

    def test_rooftops_and_ramps_are_resizable(self):
        # T-251: any even size from 4 x 4 for a rooftop; a ramp in four directions, its width
        # dragged from 4, its length fixed at 12 units per 3 of rise.
        for e in self.entries:
            if e["kind"] not in ("rooftop", "ramp"):
                continue
            self.assertTrue(e["resizable"], e["id"])
            self.assertTrue(bc.res_exists(e["style"]), e["style"])
            if e["kind"] == "rooftop":
                self.assertEqual(e["min_size_units"], [4.0, 4.0])
                self.assertEqual(e["views"], ["iso"])
            else:
                lo, hi = e["heights"]
                if not e.get("jump"):
                    self.assertEqual(e["length_units"], 12.0 * (hi - lo) / 3)
                self.assertEqual(e["min_width_units"], 4.0)
                self.assertEqual(e["views"], ["north", "east", "south", "west"])
                sides = {t["view"]: t["side"] for t in e["textures"]}
                self.assertEqual(sides, {"north": "south", "east": "west", "south": "north", "west": "east"})

    def test_counts(self):
        count = lambda k: sum(1 for e in self.entries if e["kind"] == k)
        self.assertEqual(count("building"), 6 + 4 + 2)
        self.assertEqual(count("boulder"), 2)
        self.assertEqual(count("ground"), 3 + 47)  # T-398: the 47 sidewalk curb pieces
        self.assertEqual(count("crater"), 3)

    def test_boulder_mirrors(self):
        for e in self.entries:
            if e["kind"] == "boulder":
                self.assertEqual(e["mirrors"], [False, True])

    def test_textures_exist(self):
        for t in bc.textures_of(self.cat):
            self.assertTrue(bc.res_exists(t), t)

    def test_building_textures_all_listed(self):
        sky = bc.load("art/buildings/skyscrapers.json")
        named = bc.textures_of(self.cat)
        for p in sky["bodies"] + sky["pavements"]:
            self.assertIn(p, named)
        # T-405: the low-rise shows its platform art (art/buildings/platforms/), one per short body.
        rec = bc.load("art/buildings/platforms/platforms.json")
        for p in sky["short"]["bodies"]:
            self.assertIn(rec["textures"][p]["full"], named)
            self.assertNotIn(p, named)

    def test_short_buildings_show_their_platform_art_with_its_anchor(self):
        """T-405: the low-rise, small and long buildings are platforms 3 high: every texture is its platform art,
        with the record's anchor and footprint."""
        rec = bc.load("art/buildings/platforms/platforms.json")
        fulls = {t["full"]: t for t in rec["textures"].values()}
        for e in self.entries:
            if e["id"].startswith("short-") or e["id"] in ("building-small", "building-long"):
                self.assertEqual(e["height_units"], 3.0, e["id"])
                for t in e["textures"]:
                    self.assertIn(t["texture"], fulls, e["id"])
                    self.assertEqual(t["anchor_art_px"], fulls[t["texture"]]["anchor_art_px"])
                    self.assertEqual(t["footprint_units"], fulls[t["texture"]]["footprint_units"])
            elif e["id"].startswith("skyscraper-"):
                self.assertEqual(e["height_units"], 30.0)

    def test_road_pieces_are_2_by_2_tiles_and_come_first_among_the_roads(self):
        """T-252: one entry per piece and rotation with a 4 x 4 footprint and its four tiles
        (single-tile `part` entries, not shown in the panel); the pieces come before the other roads."""
        roads = [e for e in self.entries if e["kind"] == "road"]
        pieces = [e for e in roads if "parts" in e]
        self.assertEqual(roads[:len(pieces)], pieces)
        for kind, n in (("corner_", 4), ("t_", 4), ("dead_", 4), ("cross", 1)):
            self.assertEqual(sum(1 for e in pieces if e["id"].startswith("road-piece_" + kind)), n, kind)
        self.assertEqual(len(pieces), 13)
        by_id = {e["id"]: e for e in self.entries}
        for e in pieces:
            self.assertEqual(e["footprint_units"], [4.0, 4.0])
            self.assertEqual(sorted((p["dx"], p["dy"]) for p in e["parts"]), [(0, 0), (0, 2), (2, 0), (2, 2)])
            for p in e["parts"]:
                tile = by_id[p["tile"]]
                self.assertTrue(tile["part"])
                self.assertEqual(tile["footprint_units"], [2.0, 2.0])
                self.assertGreaterEqual(tile["atlas_index"], 87)
            self.assertEqual(e["textures"][0]["region"][2:], [256, 128])
        self.assertEqual(sum(1 for e in self.entries if e.get("part") and e["id"].startswith("road-piece_")), 52)
        # T-263: the road brush's tiles are parts too (3 asphalts x 52 centre-line, 7 x 16 dead ends).
        self.assertEqual(sum(1 for e in self.entries if e.get("part") and e["id"].startswith("road-brush_")), 156 + 112)

    def test_old_ground_tiles_keep_their_atlas_index(self):
        for e in self.entries:
            if e["kind"] in ("ground", "road") and "atlas_index" in e and not e.get("part"):
                self.assertLess(e["atlas_index"], 87)


class FamilyTest(unittest.TestCase):
    """T-262: one family per kind of piece, in six groups; every pose the old panel offered is a member."""

    @classmethod
    def setUpClass(cls):
        cls.cat = bc.build()
        cls.fams = cls.cat["families"]
        cls.by_id = {e["id"]: e for e in cls.cat["entries"]}

    def test_groups_and_order(self):
        self.assertEqual(self.cat["groups"], ["roads", "ground", "levels", "buildings", "obstacles", "decoration"])
        groups = [f["group"] for f in self.fams]
        self.assertEqual(groups, sorted(groups, key=self.cat["groups"].index))
        self.assertEqual([f["id"] for f in self.fams], bc.FAMILY_ORDER)
        self.assertEqual(len(self.fams), 27)  # T-398: sidewalk, meteor crater, parked car, broken car; T-441: alert sign and banner; T-542: rail

    def test_the_rail_is_a_levels_family_stepped_by_height(self):
        # T-542: one entry, four heights (auto first), a hint line for each key.
        rail = next(f for f in self.fams if f["id"] == "rail")
        self.assertEqual(rail["group"], "levels")
        self.assertEqual(rail["heights"], ["auto", "1", "3.1", "6.1"])
        self.assertEqual([m["height"] for m in rail["members"]], rail["heights"])
        texts = bc.load("data/level/creator_texts.json")
        for k in rail["hints"]:
            self.assertIn(k, texts)

    def test_labels_are_texts(self):
        texts = bc.load("data/level/creator_texts.json")
        for f in self.fams:
            self.assertTrue(f["label"].startswith("piece_"), f["id"])
            self.assertIn(f["label"], texts)

    def test_every_old_pose_is_a_member_once(self):
        # The old panel: a button per non-part entry, placed in each view and mirror its art has.
        seen = {}
        for f in self.fams:
            for m in f["members"]:
                key = (m["asset"], m["view"], m["mirror"], m["variant"])
                self.assertNotIn(key, seen, "a pose in two families")
                seen[key] = f["id"]
                e = self.by_id[m["asset"]]
                self.assertIn(m["view"], e["views"])
                self.assertIn(m["mirror"], e["mirrors"])
        for e in self.cat["entries"]:
            if e.get("part") or e["kind"] == "road":
                continue  # T-263: roads are painted with the brush; their tiles stay in the catalogue
            for t in e["textures"]:
                if e["id"].startswith("skyscraper-") or e["id"].startswith("alert-banner-") or e["id"] == "rail":
                    key = (e["id"], t["view"], t["mirror"], t["variant"])
                else:
                    key = (e["id"], t["view"], t["mirror"], "")
                self.assertIn(key, seen, e["id"])

    def test_poses_are_unique_within_a_family(self):
        for f in self.fams:
            keys = [(m["look"], m["turn"], m["flip"], m["height"]) for m in f["members"]]
            self.assertEqual(len(keys), len(set(keys)), f["id"])

    def test_steps(self):
        fams = {f["id"]: f for f in self.fams}
        self.assertEqual(fams["skyscraper"]["looks"], 12)
        self.assertEqual(fams["boulder"]["looks"], 2)
        self.assertEqual(fams["boulder"]["mirrors"], [False, True])
        self.assertEqual(fams["platform"]["heights"], ["3", "6"])
        self.assertEqual(fams["ramp"]["heights"], ["0-3", "3-6", "0-6", "0-2", "3-5", "6-8"])
        self.assertEqual(fams["ramp"]["turns"], 4)
        self.assertEqual(fams["road"]["turns"], 1)
        self.assertEqual(fams["barrier"]["turns"], 4)
        self.assertNotIn("pavement", fams)

    def test_road_brushes(self):
        """T-263: the road families are brushes; each look is an asphalt whose tiles all exist."""
        fams = {f["id"]: f for f in self.fams}
        self.assertEqual({fid: fams[fid].get("brush") for fid in ("road", "centre-line", "cracked-road", "zebra-crossing")},
                         {"road": "paint", "centre-line": "paint", "cracked-road": "paint", "zebra-crossing": "zebra"})
        self.assertNotIn("brush", fams["gravel"])
        self.assertEqual([m["asphalt"] for m in fams["road"]["members"]], ["a0", "a0m", "g6", "g9"])
        self.assertEqual([m["asphalt"] for m in fams["centre-line"]["members"]], ["a0", "a0m", "g6", "g9"])
        self.assertEqual([m["asphalt"] for m in fams["cracked-road"]["members"]], ["g4", "g5", "g7"])
        self.assertEqual(fams["road"]["mirrors"], [False, True])
        for fid in ("road", "centre-line", "cracked-road"):
            line = fid == "centre-line"
            for m in fams[fid]["members"]:
                a = m["asphalt"]
                names = ["y_plain_", "x_plain_", "y_zebra_e0_", "y_zebra_e1_", "x_zebra_e0_", "x_zebra_e1_"]
                if line:
                    names += ["y_line_r_", "y_line_l_", "x_line_r_", "x_line_l_"]
                for n in names:
                    self.assertIn("road-" + n + a, self.by_id, (fid, a, n))
                for piece in ("corner_ne", "t_nes", "cross", "dead_n", "dead_w"):
                    for cr in ("00", "10", "01", "11"):
                        if line:
                            aid = "road-piece_%s_%s" % (piece, cr) if a == "a0" else "road-brush_line_%s_%s_%s" % (piece, a, cr)
                        elif piece.startswith("dead_"):
                            aid = "road-brush_plain_%s_%s_%s" % (piece, a, cr)
                        else:
                            continue
                        self.assertIn(aid, self.by_id, (fid, a))
                        self.assertTrue(self.by_id[aid]["part"])


class StreetPiecesTest(unittest.TestCase):
    """T-398: sidewalks (a brush, a tile per curb piece), meteor craters and parked and broken cars."""

    @classmethod
    def setUpClass(cls):
        cls.cat = bc.build()
        cls.by_id = {e["id"]: e for e in cls.cat["entries"]}
        cls.fams = {f["id"]: f for f in cls.cat["families"]}

    def test_sidewalk_is_a_brush_under_ground(self):
        f = self.fams["sidewalk"]
        self.assertEqual((f["group"], f["label"], f["brush"]), ("ground", "piece_sidewalk", "sidewalk"))
        self.assertEqual([m["asset"] for m in f["members"]], ["sidewalk"])

    def test_every_curb_piece_has_an_entry_drawn_from_the_sheet(self):
        tiles = bc.load("art/ground/sidewalk_tiles.json")["tiles"]
        self.assertEqual(len(tiles), 47)
        for t in tiles:
            e = self.by_id[t["name"]]
            self.assertEqual(e["kind"], "ground")
            self.assertNotIn("atlas_index", e)
            self.assertEqual(e["sidewalk"], {"edges": t["edges"], "corners": t["corners"]})
            self.assertEqual(e["textures"][0]["region"], t["region"])

    def test_craters_are_ground_group_models(self):
        f = self.fams["meteor-crater"]
        self.assertEqual((f["group"], f["label"], f["looks"], f["counter"]), ("ground", "piece_meteor_crater", 3, "model_counter"))
        for i in (1, 2, 3):
            self.assertEqual(self.by_id["crater-%d" % i]["kind"], "crater")

    def test_cars_are_obstacles_with_models_and_four_facings(self):
        for fid, label, looks in (("parked-car", "piece_parked_car", 3), ("broken-car", "piece_broken_car", 2)):
            f = self.fams[fid]
            self.assertEqual((f["group"], f["label"], f["looks"], f["turns"]), ("obstacles", label, looks, 4))
            self.assertEqual(f["counter"], "model_counter")
            self.assertTrue(f["facing_labels"])
        order = [f["id"] for f in self.cat["families"] if f["group"] == "obstacles"]
        self.assertEqual(order, ["boulder", "barrier", "cones", "crates", "parked-car", "broken-car"])
        ground = [f["id"] for f in self.cat["families"] if f["group"] == "ground"]
        self.assertEqual(ground, ["gravel", "sidewalk", "meteor-crater"])

    def test_new_texts_exist(self):
        texts = bc.load("data/level/creator_texts.json")
        for k in ("piece_sidewalk", "piece_meteor_crater", "piece_parked_car", "piece_broken_car", "model_counter",
                  "facing_top_right", "facing_bottom_right", "facing_bottom_left", "facing_top_left"):
            self.assertIn(k, texts)


class AlertSignsTest(unittest.TestCase):
    """T-441: the standing kaiju alert sign and the alert banner, each in both designs, with T-130's art."""

    @classmethod
    def setUpClass(cls):
        cls.cat = bc.build()
        cls.by_id = {e["id"]: e for e in cls.cat["entries"]}
        cls.fams = {f["id"]: f for f in cls.cat["families"]}

    def test_entries(self):
        for design, shape in (("head", "triangle"), ("body", "circle")):
            s = self.by_id["alert-sign-" + design]
            self.assertEqual((s["kind"], s["alert"], s["design"]), ("alert", "sign", design))
            self.assertEqual(s["mirrors"], [False, True])
            self.assertEqual(s["footprint_units"], [2.0, 2.0])
            self.assertEqual({t["texture"] for t in s["textures"]}, {"res://art/banners/kaiju_%s_%s_sign.png" % (design, shape)})
            b = self.by_id["alert-banner-" + design]
            self.assertEqual((b["kind"], b["alert"], b["design"]), ("alert", "banner", design))
            self.assertEqual(b["views"], ["south", "east"])
            self.assertEqual(b["heights_units"], [3, 6, 9, 12, 15])
            self.assertEqual({t["texture"] for t in b["textures"]},
                             {"res://art/banners/kaiju_%s_%s_building_wall.png" % (design, shape)})
            for t in s["textures"] + b["textures"]:
                self.assertTrue(bc.res_exists(t["texture"]))

    def test_families_under_decoration_with_the_text_tickets_labels(self):
        texts = bc.load("data/level/creator_texts.json")
        sign = self.fams["alert-sign"]
        banner = self.fams["alert-banner"]
        self.assertEqual((sign["group"], sign["label"]), ("decoration", "piece_alert_sign"))
        self.assertEqual((banner["group"], banner["label"]), ("decoration", "piece_alert_banner"))
        self.assertEqual((sign["looks"], sign["turns"], sign["mirrors"]), (2, 1, [False, True]))
        self.assertEqual((banner["looks"], banner["turns"], banner["heights"]), (2, 2, ["3", "6", "9", "12", "15"]))
        for f in (sign, banner):
            self.assertEqual(f["look_labels"], ["alert_design_head", "alert_design_body"])
            for k in f["look_labels"] + f.get("hints", []):
                self.assertIn(k, texts)
        self.assertEqual(banner["hints"], ["banner_wall_hint", "banner_height_hint"])
        self.assertNotIn("hints", sign)


if __name__ == "__main__":
    unittest.main()
