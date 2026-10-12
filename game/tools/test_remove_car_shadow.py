import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import check_sprite_rules as c
import remove_car_shadow as r

ART = Path(__file__).resolve().parents[1] / "art" / "car"


class T(unittest.TestCase):
    def test_only_shadow_colours_below_the_edge_become_transparent(self):
        _, _, rows = c.decode_png((ART / "car_sw_front.png").read_bytes())
        out, gone = r.remove_shadow(rows)
        self.assertGreater(len(gone), 300)
        for y, row in enumerate(rows):
            for x, p in enumerate(row):
                if (x, y) in gone:
                    self.assertEqual(out[y][x], (0, 0, 0, 0))
                    self.assertIn(p[:3], r.SHADOW_COLORS)
                    self.assertGreater(y, r.edge_y(x))
                    self.assertFalse(r.in_wheel(x, y))
                else:
                    self.assertEqual(out[y][x], p)

    def test_committed_file_matches_the_script(self):
        _, _, rows = c.decode_png((ART / "car_sw_front.png").read_bytes())
        _, _, got = c.decode_png((ART / "car_sw_front_noshadow.png").read_bytes())
        self.assertEqual(r.remove_shadow(rows)[0], got)


if __name__ == "__main__":
    unittest.main()
