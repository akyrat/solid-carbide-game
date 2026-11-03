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
        self.assertEqual(bw.tier_radii(), [4.0, 8.4, 25.2])  # T-520: the 5-tier tree (radius x2.1, then the widest wave)
        self.assertEqual(bw.tier_waves()[25.2], 3, "tier 5: three rings (T-498)")
        self.assertEqual({r for r, n in bw.tier_waves().items() if n == 1}, {4.0, 8.4})

    def test_names_match_the_games_lookup(self):
        # bricks.gd BricksWave.art_path: the radius to one decimal, "." as "_".
        self.assertEqual(bw.sheet_name(4.0), "bricks_wave_r4_0")
        self.assertEqual(bw.sheet_name(4 * 1.4 * 1.5), "bricks_wave_r8_4")

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


class WidestWave(unittest.TestCase):
    """T-498: tier 8's three-ring wave, one sparse sheet."""

    @classmethod
    def setUpClass(cls):
        from PIL import Image
        import numpy as np
        path = bw.OUT_DIR / (bw.sheet_name(25.2) + ".png")
        cls.record = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
        cls.atlas = np.array(Image.open(path).convert("RGBA"))
        cls.frames = bw.frames_of(cls.atlas, cls.record)

    def test_timing(self):
        timing, total = bw.widest_timing(3, 0.15)
        self.assertEqual(total, 18)
        self.assertEqual([t[0] for t in timing], [0, 7, 10], "each ring sets off when the one inside reaches its radius")
        self.assertEqual(self.record["frames"], total)
        self.assertEqual(self.record["ring_radii_units"], [8.4, 16.8, 25.2])
        reach = self.record["ring_reach_seconds"]
        self.assertAlmostEqual(reach[1] - reach[0], bw.ring_interval())
        self.assertAlmostEqual(reach[2] - reach[1], bw.ring_interval())

    def _white_dists(self, f):
        import numpy as np
        fr = self.frames[f]
        cx, cy = self.record["centre"]
        ys, xs = np.nonzero((fr[:, :, 0] == bw.RING_WHITE[0]) & (fr[:, :, 1] == bw.RING_WHITE[1])
                            & (fr[:, :, 2] == bw.RING_WHITE[2]) & (fr[:, :, 3] == 255))
        a, b = (xs - cx) / bw.ART_PX, (ys - cy) / (bw.ART_PX / 2)
        return np.sqrt((a * a + b * b) / 2.0)

    def test_three_rings_drawn_inner_to_outer(self):
        # The furthest white ring core grows frame by frame until the outer ring is out.
        far = [float(self._white_dists(f).max()) for f in range(14)]
        self.assertEqual(far, sorted(far), far)
        self.assertLess(far[6], 8.5, "only the inner ring before 0.35 s")
        self.assertAlmostEqual(far[7], 8.4, delta=0.2)
        self.assertAlmostEqual(far[10], 16.8, delta=0.2)
        self.assertAlmostEqual(far[13], 25.2, delta=0.2)
        # At 0.55 s all three rings show: one at 8.4, one at 16.8, the outer one between.
        d = self._white_dists(11)
        for lo, hi in ((8.0, 8.5), (16.4, 16.9), (17.5, 25.0)):
            self.assertTrue(((d >= lo) & (d <= hi)).any(), (lo, hi))

    def test_inner_ring_is_the_tier_7_wave(self):
        from PIL import Image
        import numpy as np
        t7 = np.array(Image.open(bw.OUT_DIR / (bw.sheet_name(8.4) + ".png")).convert("RGBA"))
        w7, _, (cx7, cy7) = bw.frame_size(8.4)
        cx, cy = self.record["centre"]
        for f in (0, 3, 6):   # before the second ring leaves
            mine = self.frames[f][cy - cy7:cy - cy7 + t7.shape[0], cx - cx7:cx - cx7 + w7]
            self.assertTrue((mine == t7[:, f * w7:(f + 1) * w7]).all(), f)

    def test_the_sheet_keeps_the_rules_and_fits_a_texture(self):
        self.assertLessEqual(self.record["atlas_width"], 4096)
        self.assertLessEqual(self.record["atlas_height"], 4096)
        self.assertEqual(self.atlas.shape[:2], (self.record["atlas_height"], self.record["atlas_width"]))
        rows = [[tuple(int(v) for v in p) for p in r] for r in self.atlas[::7]]
        alphas = {p[3] for r in rows for p in r}
        self.assertLessEqual(alphas, {0, 255})
        cols = {p[:3] for r in rows for p in r if p[3] == 255}
        self.assertLessEqual(len(cols), 30)
        self.assertFalse([c for c in cols if rules.greenbull_colour(c)])


if __name__ == "__main__":
    unittest.main()
