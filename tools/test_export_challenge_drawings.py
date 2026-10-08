"""Tests for export_challenge_drawings.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import export_challenge_drawings as ex  # noqa: E402

SQUARE_CW = [[0, -2], [2, 0], [0, 2], [-2, 0]]   # right, down, left, up on screen (y down)


def drawing(kind="challenge", arrow=SQUARE_CW):
    return {
        "name": "Single Boulder - arrow 1", "folder": "Single Boulder", "kind": kind,
        "width": 4, "height": 4, "rows": ["RRRR", "RGGR", "RGGR", "RRRR"],
        "obstacles": [{"id": "o1", "x": 0.5, "y": -0.5, "d": 3}],
        "groups": [{"id": "g1", "members": ["o1"], "challenge": True, "arrows": [arrow]}],
    }


class ExportTests(unittest.TestCase):
    def test_winding(self):
        self.assertEqual(ex.winding(SQUARE_CW), "clockwise")
        self.assertEqual(ex.winding(list(reversed(SQUARE_CW))), "counter-clockwise")
        self.assertEqual(ex.winding([[0, 0], [1, 1], [2, 2]]), "none")

    def test_turn_around_counts_signed_degrees(self):
        loop = [[3, 0], [0, 3], [-3, 0], [0, -3], [3, 0]]   # once around the origin, clockwise on screen
        self.assertAlmostEqual(ex.turn_around(loop, 0, 0), 360, places=6)
        self.assertAlmostEqual(ex.turn_around(list(reversed(loop)), 0, 0), -360, places=6)

    def test_clean_keeps_the_board_data(self):
        data = ex.clean(drawing())
        self.assertEqual(data["pattern"], "Single Boulder")
        self.assertEqual(data["boulders"], [{"x": 0.5, "y": -0.5, "diameter": 3}])
        self.assertEqual(data["arrow"]["points"], SQUARE_CW)
        self.assertEqual(data["arrow"]["corridor_width"], 3.0)
        self.assertEqual(data["arrow"]["around_boulders"][0]["direction"], "clockwise")

    def test_export_writes_json_and_svg_per_challenge_and_skips_maps(self):
        with tempfile.TemporaryDirectory() as src, tempfile.TemporaryDirectory() as out:
            Path(src, "a.json").write_text(json.dumps(drawing()), encoding="utf-8")
            Path(src, "b.json").write_text(json.dumps(drawing(kind="map")), encoding="utf-8")
            written = ex.export(src, out)
            self.assertEqual(len(written), 1)
            folder = Path(out, "single-boulder")
            self.assertTrue(folder.joinpath("arrow-1.json").exists())
            svg = folder.joinpath("arrow-1.svg").read_text(encoding="utf-8")
            self.assertIn("<svg", svg)
            self.assertIn('stroke-width="60.0"', svg)   # 3-unit corridor at 20 px per unit
            first = (folder / "arrow-1.json").read_bytes() + (folder / "arrow-1.svg").read_bytes()
            ex.export(src, out)
            self.assertEqual(first, (folder / "arrow-1.json").read_bytes() + (folder / "arrow-1.svg").read_bytes())


if __name__ == "__main__":
    unittest.main()
