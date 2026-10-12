"""Tests for build_car_sheet.py (task T-101). No PixelLab calls.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_sheet as b  # noqa: E402
import check_sprite_rules as rules  # noqa: E402

T = (0, 0, 0, 0)


class PaletteAndCentringTests(unittest.TestCase):
    def test_palette_mapping_keeps_transparency_and_uses_palette_colours(self):
        palette = [(10, 60, 30), (240, 240, 240)]
        rows = [[T, (12, 62, 33, 255)], [(230, 235, 250, 255), T]]
        out = b.map_to_palette(rows, palette)
        self.assertEqual(out, [[T, (10, 60, 30, 255)], [(240, 240, 240, 255), T]])

    def test_palette_colours_map_to_themselves(self):
        palette = [(1, 2, 3), (200, 100, 50), (90, 90, 90)]
        rows = [[c + (255,) for c in palette]]
        self.assertEqual(b.map_to_palette(rows, palette), rows)

    def test_centring_moves_bbox_centre_to_target(self):
        rows = [[T] * 10 for _ in range(10)]
        rows[1][1] = rows[2][2] = (5, 5, 5, 255)  # bbox (1, 1, 3, 3), centre (2, 2)
        dx, dy = b.centring_shift(rows, (5.0, 6.0))
        self.assertEqual((dx, dy), (3, 4))
        moved = b.shift(rows, dx, dy)
        self.assertEqual(b.bbox_centre(moved), (5.0, 6.0))

    def test_centring_never_pushes_pixels_out(self):
        rows = [[T] * 10 for _ in range(10)]
        rows[0][7] = rows[0][9] = (5, 5, 5, 255)
        dx, dy = b.centring_shift(rows, (9.5, 0.0))
        self.assertEqual(dx, 0)  # already touching the right edge
        self.assertEqual(dy, 0)  # already touching the top edge

    def test_iso_screen_angles_match_the_placeholder_convention(self):
        placeholder = json.loads((b.REPO / "game/art/placeholders/car/car_iso.json").read_text())
        for f in placeholder["frames"]:
            self.assertAlmostEqual(b.iso_screen_angle(f["heading_deg"]) % 360, f["nose_screen_angle_deg"] % 360, places=1)


class CommittedSheetTests(unittest.TestCase):
    def test_build_matches_committed_files(self):
        sheet, layout = b.build()
        _, _, committed = rules.decode_png((b.REPO / b.OUT_PNG).read_bytes())
        self.assertEqual(sheet, committed, "car_iso.png is what the script builds")
        on_disk = json.loads((b.REPO / b.OUT_JSON).read_text(encoding="utf-8"))
        self.assertEqual(json.loads(json.dumps(layout)), on_disk, "car_iso.json is what the script builds")

    def test_every_frame_passes_the_rules(self):
        for i, (results, info) in enumerate(rules.check_sheet(str(b.REPO / b.OUT_PNG), 16, 128, max_colors=33)):
            self.assertTrue(all(ok for _, ok, _ in results), f"frame {i}: {results}")

    def test_frame_4_is_unchanged(self):
        sheet, layout = b.build()
        _, _, ref = rules.decode_png((b.REPO / b.REFERENCE).read_bytes())
        self.assertEqual([r[4 * 128:5 * 128] for r in sheet], ref)
        self.assertEqual(layout["frames"][4]["shift_px"], {"x": 0, "y": 0})
        self.assertEqual(layout["frames"][4]["source"], b.REFERENCE)

    def test_every_source_has_a_pixellab_record(self):
        for i, (src, _, _) in b.SOURCES.items():
            rec = json.loads((b.REPO / src).with_suffix(".json").read_text(encoding="utf-8"))
            self.assertIn("endpoint", rec, src)
            self.assertIn(rec["task"], ("T-014", "T-101"), src)


if __name__ == "__main__":
    unittest.main()
