"""Tests for measure_car_facing.py (task T-583). Run: python -m unittest game/tools/test_measure_car_facing.py"""
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import measure_car_facing as m  # noqa: E402


class MeasureCarFacingTest(unittest.TestCase):
    def test_parse_frames(self):
        self.assertEqual(m.parse_frames("19-23,2,3", 32), [2, 3, 19, 20, 21, 22, 23])
        with self.assertRaises(SystemExit):
            m.parse_frames("40", 32)

    def test_nose_end_picks_the_end_near_the_ideal(self):
        self.assertAlmostEqual(m.nose_end(90.0, 270.0), 270.0)
        self.assertAlmostEqual(m.nose_end(90.0, 100.0), 90.0)
        self.assertAlmostEqual(m.nose_end(10.0, 350.0), 10.0)

    def test_calibration_adds_the_neighbours_bias(self):
        measured = [0.0, 90.0, 180.0, 270.0]
        recorded = [10.0, 100.0, 190.0, 280.0]
        self.assertAlmostEqual(m.calibrated(measured, recorded, [0, 2, 3], 1), 100.0)

    def test_the_car_sheet_measures_close_to_its_recorded_angles(self):
        layout = json.loads(m.LAYOUT.read_text(encoding="utf-8"))
        errs = m.leave_one_out(m.SHEET, layout)
        self.assertEqual(len(errs), 32)
        self.assertLess(sum(abs(e) for e in errs) / 32, 5.0)
        self.assertLess(max(abs(e) for e in errs), 15.0)

    def test_write_changes_only_the_named_frames(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            js = tmp / "car.json"
            shutil.copy(m.LAYOUT, js)
            before = json.loads(js.read_text(encoding="utf-8"))
            m.main(["--json", str(js), "--frames", "22", "--set", "23=300", "--write"])
            after = json.loads(js.read_text(encoding="utf-8"))
            self.assertEqual(after["frames"][23][m.FIELD], 300.0)
            self.assertIn("by eye", after["frames"][23][m.SOURCE])
            self.assertIn("measure_car_facing", after["frames"][22][m.SOURCE])
            for i in range(32):
                if i not in (22, 23):
                    self.assertEqual(after["frames"][i], before["frames"][i])
            self.assertEqual({k: v for k, v in after.items() if k != "frames"},
                             {k: v for k, v in before.items() if k != "frames"})
        finally:
            shutil.rmtree(tmp)


if __name__ == "__main__":
    unittest.main()
