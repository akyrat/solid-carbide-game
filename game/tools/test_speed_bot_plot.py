import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import speed_bot_plot  # noqa: E402


class SpeedBotPlotTest(unittest.TestCase):
    def test_reads_the_csv_and_draws_both_pngs_even_with_inf(self):
        with tempfile.TemporaryDirectory() as d:
            src = os.path.join(d, "s.csv")
            with open(src, "w") as f:
                f.write("time,tier1,tier2\n0.00,11.0,11.0\n0.02,12.0,inf\n0.04,inf,inf\n")
            t, a, b = speed_bot_plot.read(src)
            self.assertEqual(len(t), 3)
            self.assertEqual(a[0], 11.0)
            out = os.path.join(d, "o.png")
            self.assertEqual(speed_bot_plot.main(["x", src, out, "t"]), 0)
            self.assertTrue(os.path.exists(out))
            self.assertTrue(os.path.exists(os.path.join(d, "o_light.png")))


if __name__ == "__main__":
    unittest.main()
