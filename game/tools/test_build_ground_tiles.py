"""Tests for build_ground_tiles.py (task T-103). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_ground_tiles as g  # noqa: E402
import build_road_tile as road  # noqa: E402

LAYOUT = json.loads(g.LAYOUT.read_text(encoding="utf-8"))
TILES, ATLAS, GROUND = g.build()
NAMES = [t[0] for t in TILES]


def cell_name(i, j):
    k = GROUND["cells"][j][i]
    return None if k < 0 else NAMES[k]


def units_of_cell(i, j):
    x0, y0 = GROUND["origin"]
    m = LAYOUT["map"]["rect"]
    out = set()
    for dy in range(g.CELL):
        for dx in range(g.CELL):
            ux, uy = x0 + i * g.CELL + dx, y0 + j * g.CELL + dy
            out.add(LAYOUT["ground_rows"][uy - int(m["y"])][ux - int(m["x"])])
    return out


class LayoutTests(unittest.TestCase):
    def test_grid_covers_the_map_exactly(self):
        m = LAYOUT["map"]["rect"]
        self.assertEqual(GROUND["origin"], [int(m["x"]), int(m["y"])])
        self.assertEqual(GROUND["cols"] * g.CELL, int(m["w"]))
        self.assertEqual(GROUND["rows"] * g.CELL, int(m["h"]))
        self.assertEqual(len(GROUND["cells"]), GROUND["rows"])
        self.assertTrue(all(len(r) == GROUND["cols"] for r in GROUND["cells"]))

    def test_every_cell_matches_the_map_layout(self):
        """Each 2 x 2 unit cell is one kind of ground; road and gravel cells have a tile
        (no gaps), building cells none."""
        for j in range(GROUND["rows"]):
            for i in range(GROUND["cols"]):
                kinds = units_of_cell(i, j)
                self.assertEqual(len(kinds), 1, (i, j, kinds))
                kind = kinds.pop()
                name = cell_name(i, j)
                if kind == "B":
                    self.assertIsNone(name, (i, j))
                elif kind == "G":
                    self.assertTrue(name and name.startswith("gravel"), (i, j, name))
                else:
                    self.assertTrue(name and name[:2] in ("x_", "y_"), (i, j, name))

    def test_road_bands_are_the_layout_roads(self):
        width = LAYOUT["road_width"]
        for a, b in GROUND["road_bands_x"] + GROUND["road_bands_y"]:
            self.assertEqual(b - a, width)
        self.assertEqual(len(GROUND["road_bands_x"]), 5)

    def test_every_junction_arm_has_a_full_zebra_crossing(self):
        """At every box where 3 or 4 roads meet, each arm has one row of zebra tiles right
        across the road (edge tiles at the two road edges)."""
        xs, ys = GROUND["road_bands_x"], GROUND["road_bands_y"]
        x0, y0 = GROUND["origin"]

        def kind(ux, uy):
            if not (x0 <= ux < x0 + GROUND["cols"] * g.CELL and y0 <= uy < y0 + GROUND["rows"] * g.CELL):
                return None
            return LAYOUT["ground_rows"][uy - y0][ux - x0]

        found = 0
        for vb in xs:
            for hb in ys:
                if kind(vb[0], hb[0]) != "R":
                    continue
                arms = []
                if kind(vb[0], hb[0] - 1) == "R":
                    arms.append(("y", vb, hb[0] - g.ZEBRA_GAP - g.CELL))
                if kind(vb[0], hb[1]) == "R":
                    arms.append(("y", vb, hb[1] + g.ZEBRA_GAP))
                if kind(vb[0] - 1, hb[0]) == "R":
                    arms.append(("x", hb, vb[0] - g.ZEBRA_GAP - g.CELL))
                if kind(vb[1], hb[0]) == "R":
                    arms.append(("x", hb, vb[1] + g.ZEBRA_GAP))
                if len(arms) < 3:
                    continue
                for axis, band, pos in arms:
                    kinds = []
                    for across in range(band[0], band[1], g.CELL):
                        ux, uy = (across, pos) if axis == "y" else (pos, across)
                        name = cell_name((ux - x0) // g.CELL, (uy - y0) // g.CELL)
                        kinds.append(name[2:].rsplit("_", 1)[0])
                    self.assertEqual(kinds[0], "zebra_e0", (axis, band, pos, kinds))
                    self.assertEqual(kinds[-1], "zebra_e1", (axis, band, pos, kinds))
                    self.assertTrue(all(k == "zebra" for k in kinds[1:-1]), kinds)
                    found += 1
        # 4 inner 4-way junctions, 4 inner 3-way ones beside the gravel, 12 edge 3-way ones
        self.assertEqual(found, 4 * 4 + 4 * 3 + 12 * 3)

    def test_centre_line_sits_on_the_road_centre(self):
        x0, y0 = GROUND["origin"]
        lines = 0
        for j in range(GROUND["rows"]):
            for i in range(GROUND["cols"]):
                name = cell_name(i, j)
                if not name or "_line_" not in name:
                    continue
                lines += 1
                ux, uy = x0 + i * g.CELL, y0 + j * g.CELL
                bands = GROUND["road_bands_x"] if name.startswith("y_") else GROUND["road_bands_y"]
                across = ux if name.startswith("y_") else uy
                band = g.in_band(across, [tuple(b) for b in bands])
                centre = (band[0] + band[1]) // 2
                if "_line_r_" in name:
                    self.assertEqual(across + g.CELL, centre, name)
                else:
                    self.assertEqual(across, centre, name)
        self.assertGreater(lines, 100)

    def test_variants_are_spread(self):
        bases = {}
        for row in GROUND["cells"]:
            for k in row:
                if k >= 0 and NAMES[k][:2] in ("x_", "y_"):
                    b = NAMES[k].rsplit("_", 1)[1]
                    bases[b] = bases.get(b, 0) + 1
        self.assertEqual(set(bases), set(g.BASE_WEIGHTS))


class TileTests(unittest.TestCase):
    def test_every_tile_fills_its_exact_footprint(self):
        """Opaque exactly on the tiling footprint, so neighbours join with no gap or overlap."""
        for k, name in enumerate(NAMES):
            t = g.atlas_tile(ATLAS, k)
            for y in range(g.H):
                for x in range(g.W):
                    self.assertEqual(bool(t[y][x][3]), road.footprint(x, y), (name, x, y))
        self.assertEqual(road.tiling_report(g.atlas_tile(ATLAS, 0)), (0, 0))

    def test_tiles_pass_the_technical_rules(self):
        for k, res in g.check_atlas(ATLAS, len(NAMES)):
            self.assertTrue(all(ok for _, ok, _ in res), (NAMES[k], res))

    def test_no_new_colours(self):
        sources = {p for r in road.load(g.APPROVED) for p in r}
        for i in g.GRAVEL_RAW + g.ASPHALT_RAW:
            sources |= {p for r in road.load(g.raw_path(i)) for p in r}
        used = {p for r in ATLAS for p in r if p[3]}
        self.assertLessEqual(used, sources)

    def test_x_tiles_are_the_y_tiles_mirrored(self):
        for k, name in enumerate(NAMES):
            if name.startswith("x_"):
                other = NAMES.index("y_" + name[2:])
                self.assertEqual(g.atlas_tile(ATLAS, k), g.flip(g.atlas_tile(ATLAS, other)))

    def test_plain_asphalt_has_no_line_and_zebra_has_stripes(self):
        def whites(name):
            t = g.atlas_tile(ATLAS, NAMES.index(name))
            return sum(1 for r in t for p in r if g.is_line(p))
        self.assertEqual(whites("y_plain_a0"), 0)
        self.assertGreater(whites("y_line_r_a0"), 8)
        self.assertGreater(whites("y_line_l_a0"), 8)
        self.assertGreater(whites("y_zebra_a0"), 2 * whites("y_zebra_e0_a0") * 0.9)
        self.assertGreater(whites("y_zebra_e0_a0"), 300)

    def test_flip_and_local_units(self):
        self.assertEqual(g.flip([[1, 2, 3]]), [[3, 2, 1]])
        wx, wy = g.local_units(63, 0)
        self.assertAlmostEqual(wx, wy, delta=0.05)
        wx, wy = g.local_units(126, 31)
        self.assertGreater(wx, 1.8)
        self.assertLess(wy, 0.2)

    def test_bands_and_pick(self):
        self.assertEqual(g.bands([(2, 4), (6, 8)], 0, 10), [(0, 2), (4, 6), (8, 10)])
        self.assertEqual(g.bands([(0, 4)], 0, 4), [])
        self.assertEqual(g.pick({"a": 1, "b": 1}, 3, 4, 1), g.pick({"a": 1, "b": 1}, 3, 4, 1))
        self.assertIn(g.pick({"a": 1, "b": 0}, 3, 4, 1), ("a",))


class FilesTests(unittest.TestCase):
    def test_committed_files_are_up_to_date(self):
        """The atlas, its record and the ground layout are what the script builds now."""
        self.assertEqual(road.load(g.ATLAS_PNG), ATLAS)
        self.assertEqual(json.loads(g.GROUND_JSON.read_text(encoding="utf-8")), json.loads(g.ground_text(GROUND)))
        self.assertEqual(json.loads(g.ATLAS_JSON.read_text(encoding="utf-8")), json.loads(g.dump(g.record(TILES))))


if __name__ == "__main__":
    unittest.main()
