"""Tests for scaling_report.py (task T-493): the coverage maths and the flagging, on plain data."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import scaling_report as sr  # noqa: E402


def piece(path, rect, cls="Label"):
    return {"path": path, "class": cls, "rect": list(rect)}


class CoverageTest(unittest.TestCase):
    def test_bbox_union(self):
        self.assertEqual(sr.bbox([[10, 10, 20, 20], [50, 0, 10, 10]]), (10, 0, 50, 30))
        self.assertIsNone(sr.bbox([]))

    def test_coverage_share(self):
        self.assertAlmostEqual(sr.coverage([piece("a", (0, 0, 640, 360))], (1280, 720)), 0.25)
        self.assertEqual(sr.coverage([], (1280, 720)), 0.0)

    def test_content_share_skips_panels(self):
        ps = [piece("a", (0, 0, 640, 360)), piece("p", (0, 0, 1280, 720), "Panel")]
        self.assertAlmostEqual(sr.content_share(ps, (1280, 720)), 0.25)

    def test_ratio_with_zero_base(self):
        self.assertEqual(sr.ratio(0.5, 0), 1.0)


class FlagTest(unittest.TestCase):
    def pieces(self, scale):
        return [piece("Game/Title", (100 * scale, 100 * scale, 200 * scale, 50 * scale)), piece("Game/Btn", (100 * scale, 200 * scale, 200 * scale, 50 * scale), "Button")]

    def test_fixed_pixel_size_is_flagged(self):
        r = sr.screen_result({(1280, 720): self.pieces(1), (2560, 1440): self.pieces(1)})
        self.assertTrue(r["flagged"])
        self.assertAlmostEqual(r["worst_ratio"], 0.25, places=2)
        self.assertEqual({e["path"] for e in r["shrinking_pieces"]}, {"Game/Title", "Game/Btn"})

    def test_scaling_content_is_not_flagged(self):
        r = sr.screen_result({(1280, 720): self.pieces(1), (2560, 1440): self.pieces(2)})
        self.assertFalse(r["flagged"])
        self.assertEqual(r["shrinking_pieces"], [])

    def test_actual_window_is_used(self):
        # a window clamped to 2130 high: the same pieces cover a bit more of it
        r = sr.screen_result({(1280, 720): self.pieces(1), (3840, 2160): self.pieces(3)}, {(3840, 2160): (3840, 2130)})
        self.assertAlmostEqual(r["ratios"]["3840x2160"], 2160 / 2130, places=2)

    def test_tiny_pieces_ignored(self):
        tiny = [piece("dot", (0, 0, 4, 4))]
        r = sr.screen_result({(1280, 720): tiny, (2560, 1440): tiny})
        self.assertEqual(r["shrinking_pieces"], [])

    def test_report_orders_worst_first_and_writes(self):
        def man(scale):
            return {"screens": [{"name": "ok", "pieces": self.pieces(scale), "image_size": [1280 * scale, 720 * scale]},
                                {"name": "bad", "pieces": self.pieces(1), "image_size": [1280 * scale, 720 * scale]}]}
        rep = sr.build_report({(1280, 720): man(1), (2560, 1440): man(2)})
        self.assertEqual(rep["order"], ["bad", "ok"])
        with tempfile.TemporaryDirectory() as d:
            sr.write_markdown(rep, Path(d) / "r.md")
            sr.save_json(rep, Path(d) / "r.json")
            self.assertIn("**bad**", (Path(d) / "r.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
