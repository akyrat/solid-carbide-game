"""Tests for build_ground_tiles.py (task T-103). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import hashlib
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


# What the game's ground was before T-252 (hashes): its cell indexes and the names of the first
# tiles. Appending the pieces' tiles to the atlas must not change them.
OLD_CELLS_SHA = "5954f97b5cda6608"
OLD_NAMES_SHA = "798d47a1b283e12a"
PIECE_TILE_NAMES = ["piece_%s_%d%d" % (n, c, r) for n in g.PIECES for r in range(2) for c in range(2)]
# The straight tile whose line lies on each tile edge (the two-tile-wide roads' centre line).
STRAIGHT_OF_EDGE = {"x2": "y_line_r_a0", "x0": "y_line_l_a0", "y2": "x_line_r_a0", "y0": "x_line_l_a0"}


def sha16(text):
    return hashlib.sha256(text.encode()).hexdigest()[:16]


def tile(name):
    return g.atlas_tile(ATLAS, NAMES.index(name))


def white_pixels(t):
    return {(x, y) for y, r in enumerate(t) for x, p in enumerate(r) if g.is_line(p)}


def edge_keys(name, c, r):
    """The tile edges of piece tile (c, r) that carry a centre line (from the piece's open sides)."""
    return [key for a in g.PIECES[name] for cc, rr, key in g.ARM_SEGMENTS[a] if (cc, rr) == (c, r)]


class RoadPieceTests(unittest.TestCase):
    """T-252: corners, T-junctions, crossroads and dead ends, 2 x 2 tiles (4 x 4 units) at the
    two-tile-wide roads' size, drawn from the straight tiles' own pixels."""

    def test_pieces_come_last_and_old_tiles_are_unchanged(self):
        # T-263's brush tiles come after them (BrushTileTests).
        self.assertEqual(NAMES[g.OLD_TILES:g.OLD_TILES + len(PIECE_TILE_NAMES)], PIECE_TILE_NAMES)
        self.assertEqual(len(PIECE_TILE_NAMES), 13 * 4)
        self.assertEqual(sha16(json.dumps(GROUND["cells"])), OLD_CELLS_SHA)
        self.assertEqual(sha16(json.dumps(NAMES[:g.OLD_TILES])), OLD_NAMES_SHA)
        used = {k for row in GROUND["cells"] for k in row}
        self.assertTrue(all(k < g.OLD_TILES for k in used), "the game's ground never uses a piece")

    def test_every_rotation_exists(self):
        arms = {n: set(a) for n, a in g.PIECES.items()}
        for kind, count in (("corner", 2), ("t", 3), ("dead", 1)):
            sets = [a for n, a in arms.items() if n.startswith(kind + "_")]
            self.assertEqual(len({frozenset(a) for a in sets}), 4, kind)
            self.assertTrue(all(len(a) == count for a in sets), kind)
        for n, a in arms.items():
            if n.startswith("corner_"):
                self.assertNotIn(a, (set("ns"), set("ew")))
        self.assertEqual(arms["cross"], set("nesw"))

    def test_lines_continue_the_straight_tiles(self):
        """On every open side the two tiles next to the road carry exactly the straight tiles'
        line pixels (line_r and line_l, along y or x), so the centre line runs on across the join
        with the same pixels and dash phase; asphalt is the plain a0 tile."""
        a0 = tile("y_plain_a0")
        for name, arm_set in g.PIECES.items():
            closed = len(arm_set) == 1
            for r in range(2):
                for c in range(2):
                    t = tile("piece_%s_%d%d" % (name, c, r))
                    want = set()
                    for key in edge_keys(name, c, r):
                        want |= white_pixels(tile(STRAIGHT_OF_EDGE[key]))
                    got = white_pixels(t)
                    if closed:
                        self.assertLessEqual(want, got, (name, c, r))
                    else:
                        self.assertEqual(got, want, (name, c, r))
                        for y in range(g.H):
                            for x in range(g.W):
                                if (x, y) not in got:
                                    self.assertEqual(t[y][x], a0[y][x], (name, c, r, x, y))

    def test_each_open_side_has_the_pair_of_straight_tiles(self):
        """The line reaches the piece's edge: an open side's two tiles hold line pixels within
        0.2 units of that side, and a closed side has none (corners, T-junctions, crossroads)."""
        near = {"n": lambda u, v: v < 0.2, "s": lambda u, v: v > 3.8, "w": lambda u, v: u < 0.2,
                "e": lambda u, v: u > 3.8}
        for name, arm_set in g.PIECES.items():
            if name.startswith("dead_"):
                continue
            for side, test in near.items():
                touching = False
                for r in range(2):
                    for c in range(2):
                        for x, y in white_pixels(tile("piece_%s_%d%d" % (name, c, r))):
                            wx, wy = g.local_units(x, y)
                            touching |= test(2 * c + wx, 2 * r + wy)
                self.assertEqual(touching, side in arm_set, (name, side))

    def test_dead_end_has_a_kerb_across_the_road_and_gravel_beyond(self):
        gravel = tile("gravel0")
        for name, arm_set in g.PIECES.items():
            if not name.startswith("dead_"):
                continue
            closed = {"n": "s", "s": "n", "e": "w", "w": "e"}[arm_set]
            kerb = gravel_px = 0
            for r in range(2):
                for c in range(2):
                    t = tile("piece_%s_%d%d" % (name, c, r))
                    for y in range(g.H):
                        for x in range(g.W):
                            if not road.footprint(x, y):
                                continue
                            wx, wy = g.local_units(x, y)
                            u, v = 2 * c + wx, 2 * r + wy
                            d = {"s": 4 - v, "n": v, "e": 4 - u, "w": u}[closed]
                            if d <= g.KERB_FROM:
                                gravel_px += 1
                                self.assertEqual(t[y][x], gravel[y][x], (name, c, r, x, y))
                            elif d <= g.KERB_TO:
                                kerb += 1
                                self.assertEqual(t[y][x], g.WHITE, (name, c, r, x, y))
            self.assertGreater(kerb, 800, name)  # a band across the whole 4-unit road
            self.assertGreater(gravel_px, 1000, name)

    def test_pieces_pass_check_sprite_rules(self):
        import check_sprite_rules as rules
        for n in PIECE_TILE_NAMES:
            t = tile(n)
            padded = [list(r) for r in t] + [[(0, 0, 0, 0)] * g.W for _ in range(g.W - g.H)]
            results, _ = rules.check_rows(padded, size=128, max_colors=30)
            self.assertTrue(all(ok for _, ok, _ in results), (n, results))
            self.assertEqual(road.tiling_report(t), (0, 0), n)

    def test_the_sheet_draws_each_piece_from_its_tiles(self):
        sheet = road.load(g.SHEET_PNG)
        rec = json.loads(g.dump(g.record(TILES)))
        self.assertEqual(len(rec["pieces"]), 13)
        for p in rec["pieces"]:
            x0, y0 = p["sheet_xy"]
            self.assertEqual(p["sheet_size"], [256, 128])
            self.assertEqual(len(p["tiles"]), 2)
            canvas = [[g.T] * g.PIECE_W for _ in range(g.PIECE_H)]
            for r in range(2):
                for c in range(2):
                    road.blit(canvas, tile(p["tiles"][r][c]), 64 + (c - r) * 64, (c + r) * 32)
            region = [row[x0:x0 + 256] for row in sheet[y0:y0 + 128]]
            self.assertEqual(region, canvas, p["name"])


BRUSH_LINE_NAMES = [g.brush_line_name(n, a, c, r) for a in g.BRUSH_LINE_ASPHALTS for n in g.PIECES
                    for r in range(2) for c in range(2)]
BRUSH_DEAD_NAMES = [g.brush_dead_name(n, a, c, r) for a in g.BASE_WEIGHTS for n in g.DEAD_ENDS
                    for r in range(2) for c in range(2)]


class BrushTileTests(unittest.TestCase):
    """T-263: the road brush's pieces: T-252's centre-line pieces on the other asphalts of the
    Road kind, and the dead ends of roads without a centre line on every asphalt."""

    def test_brush_tiles_come_after_the_pieces(self):
        start = g.OLD_TILES + len(PIECE_TILE_NAMES)
        self.assertEqual(NAMES[start:], BRUSH_LINE_NAMES + BRUSH_DEAD_NAMES)
        self.assertEqual(len(BRUSH_LINE_NAMES), 3 * 13 * 4)
        self.assertEqual(len(BRUSH_DEAD_NAMES), 7 * 4 * 4)
        rec = json.loads(g.dump(g.record(TILES)))
        self.assertTrue(all(t.get("piece") for t in rec["tiles"][g.OLD_TILES:]))
        self.assertEqual(len(rec["pieces"]), 13, "the sheet keeps T-252's pieces only")

    def test_line_pieces_carry_the_straight_tiles_line_on_their_asphalt(self):
        """Like T-252's: every open side's tiles hold exactly the straight tiles' line pixels (of
        that asphalt's line_r and line_l), so the line joins across every piece without a gap, and
        the rest is that asphalt's plain tile."""
        for a in g.BRUSH_LINE_ASPHALTS:
            plain = tile("y_plain_" + a)
            for name, arm_set in g.PIECES.items():
                closed = len(arm_set) == 1
                for r in range(2):
                    for c in range(2):
                        t = tile(g.brush_line_name(name, a, c, r))
                        want = set()
                        for key in edge_keys(name, c, r):
                            want |= white_pixels(tile(STRAIGHT_OF_EDGE[key].replace("_a0", "_" + a)))
                        got = white_pixels(t)
                        if closed:
                            self.assertLessEqual(want, got, (a, name, c, r))
                            continue
                        self.assertEqual(got - white_pixels(plain), want - white_pixels(plain), (a, name, c, r))
                        for y in range(g.H):
                            for x in range(g.W):
                                if (x, y) not in want:
                                    self.assertEqual(t[y][x], plain[y][x], (a, name, c, r, x, y))

    def test_plain_dead_ends_have_a_kerb_and_no_line(self):
        gravel = tile("gravel0")
        for a in g.BASE_WEIGHTS:
            plain = tile("y_plain_" + a)
            for name, arm_set in g.DEAD_ENDS.items():
                closed = {"n": "s", "s": "n", "e": "w", "w": "e"}[arm_set]
                kerb = 0
                for r in range(2):
                    for c in range(2):
                        t = tile(g.brush_dead_name(name, a, c, r))
                        for y in range(g.H):
                            for x in range(g.W):
                                if not road.footprint(x, y):
                                    continue
                                wx, wy = g.local_units(x, y)
                                u, v = 2 * c + wx, 2 * r + wy
                                d = {"s": 4 - v, "n": v, "e": 4 - u, "w": u}[closed]
                                if d <= g.KERB_FROM:
                                    self.assertEqual(t[y][x], gravel[y][x])
                                elif d <= g.KERB_TO:
                                    kerb += 1
                                    self.assertEqual(t[y][x], g.WHITE)
                                else:
                                    self.assertEqual(t[y][x], plain[y][x], "no centre line: the plain asphalt")
                self.assertGreater(kerb, 800, (a, name))

    def test_brush_tiles_pass_check_sprite_rules(self):
        import check_sprite_rules as rules
        for n in BRUSH_LINE_NAMES + BRUSH_DEAD_NAMES:
            t = tile(n)
            padded = [list(r) for r in t] + [[(0, 0, 0, 0)] * g.W for _ in range(g.W - g.H)]
            results, _ = rules.check_rows(padded, size=128, max_colors=30)
            self.assertTrue(all(ok for _, ok, _ in results), (n, results))


class FilesTests(unittest.TestCase):
    def test_committed_files_are_up_to_date(self):
        """The atlas, its record and the ground layout are what the script builds now."""
        self.assertEqual(road.load(g.ATLAS_PNG), ATLAS)
        self.assertEqual(json.loads(g.GROUND_JSON.read_text(encoding="utf-8")), json.loads(g.ground_text(GROUND)))
        self.assertEqual(json.loads(g.ATLAS_JSON.read_text(encoding="utf-8")), json.loads(g.dump(g.record(TILES))))


if __name__ == "__main__":
    unittest.main()
