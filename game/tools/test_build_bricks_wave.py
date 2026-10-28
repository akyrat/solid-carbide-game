"""Tests for build_bricks_wave.py (task T-325): Bricks' impact wave sheets."""
import json
import math
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_bricks_wave as bw  # noqa: E402
import style_rules as rules  # noqa: E402


class TierRadii(unittest.TestCase):
    def test_radii_follow_the_tiers_multipliers(self):
        self.assertEqual(bw.tier_radii(), [4.0, 4.8, 6.0, 7.8])

    def test_names_match_the_games_lookup(self):
        # bricks.gd BricksWave.art_path: the radius to one decimal, "." as "_".
        self.assertEqual(bw.sheet_name(4.0), "bricks_wave_r4_0")
        self.assertEqual(bw.sheet_name(4 * 1.2 * 1.25 * 1.3), "bricks_wave_r7_8")

    def test_timing_matches_bricks_gd(self):
        gd = (bw.GAME / "scripts" / "weapons" / "bricks.gd").read_text(encoding="utf-8")
        for name, value in (("FRAME_SECONDS", bw.FRAME_SECONDS), ("RING_SECONDS", bw.RING_SECONDS),
                            ("START_RADIUS", bw.START_RADIUS), ("FRAMES", bw.FRAMES), ("ART_TOP", bw.TOP)):
            self.assertRegex(gd, r"const %s := %s\b" % (name, repr(value).rstrip("0").rstrip(".")
                                                          if isinstance(value, float) else value))
        self.assertAlmostEqual(bw.FRAMES * bw.FRAME_SECONDS, 0.6)


class Drawing(unittest.TestCase):
    def test_ring_grows_to_the_radius_and_stays(self):
        rs = [bw.ring_radius(f, 4.0) for f in range(bw.FRAMES)]
        self.assertAlmostEqual(rs[0], bw.START_RADIUS)
        self.assertEqual(rs, sorted(rs))
        self.assertAlmostEqual(rs[7], 4.0)
        self.assertAlmostEqual(rs[-1], 4.0)

    def test_ground_distance_inverts_the_iso_projection(self):
        for u, v in ((1, 0), (0, 2), (1.5, -0.5), (-3, 1)):
            x, y = bw.iso(u, v)
            self.assertAlmostEqual(bw.ground_dist(x, y), math.hypot(u, v))

    def test_frame_holds_the_full_ring(self):
        for r in bw.tier_radii():
            w, h, (cx, cy) = bw.frame_size(r)
            self.assertGreaterEqual(cx, r * math.sqrt(2) * bw.ART_PX)
            self.assertGreaterEqual(h - cy, r * math.sqrt(2) * bw.ART_PX / 2)
            self.assertEqual(cy, (h + bw.TOP) // 2)

    def test_a_sheet_keeps_the_pixel_rules_and_is_deterministic(self):
        with tempfile.TemporaryDirectory() as d:
            a, b = Path(d) / "a.png", Path(d) / "b.png"
            bw.write_sheet(4.0, a)
            bw.write_sheet(4.0, b)
            self.assertEqual(a.read_bytes(), b.read_bytes())
            _, _, rows = rules.decode_png(a.read_bytes())
            record = json.loads(a.with_suffix(".json").read_text(encoding="utf-8"))
            self.assertNotIn("endpoint", record)
            for name, ok, detail in bw.check_rows(rows, record):
                self.assertTrue(ok, "%s: %s" % (name, detail))
            # Every frame draws something, and the last is lighter than the first full one.
            fw = record["frame_width"]
            counts = [sum(1 for r in rows for p in r[i * fw:(i + 1) * fw] if p[3]) for i in range(bw.FRAMES)]
            self.assertTrue(all(c > 0 for c in counts), counts)
            self.assertLess(counts[-1], counts[3])

    def test_no_colour_is_greenbulls(self):
        for c in bw.COLOURS:
            self.assertFalse(rules.greenbull_colour(c), c)


class Committed(unittest.TestCase):
    def test_every_tier_sheet_is_committed_and_keeps_the_rules(self):
        for r in bw.tier_radii():
            path = bw.OUT_DIR / (bw.sheet_name(r) + ".png")
            self.assertTrue(path.is_file(), path)
            _, _, rows = rules.decode_png(path.read_bytes())
            record = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
            self.assertAlmostEqual(record["radius_units"], r)
            for name, ok, detail in bw.check_rows(rows, record):
                self.assertTrue(ok, "%s %s: %s" % (path.name, name, detail))

    def test_committed_first_sheet_is_what_the_script_draws(self):
        path = bw.OUT_DIR / (bw.sheet_name(4.0) + ".png")
        with tempfile.TemporaryDirectory() as d:
            fresh = Path(d) / "x.png"
            bw.write_sheet(4.0, fresh)
            self.assertEqual(fresh.read_bytes(), path.read_bytes())


if __name__ == "__main__":
    unittest.main()
