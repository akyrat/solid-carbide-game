import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import power_up_icon_sheet as s  # noqa: E402
from PIL import Image  # noqa: E402


class SheetTest(unittest.TestCase):
    def test_sheet_has_four_icons_on_two_backgrounds(self):
        with tempfile.TemporaryDirectory() as d:
            for name in s.IDS:
                Image.new("RGBA", (32, 32), (255, 0, 0, 255)).save(Path(d) / f"{name}.png")
            img = s.build_sheet(Path(d))
        self.assertEqual(img.size, (32 * s.SCALE * 4, 32 * s.SCALE * 2))

    def test_real_icons_are_32x32_with_transparency(self):
        for name in s.IDS:
            img = Image.open(s.ROOT / "game/art/power_ups" / f"{name}.png").convert("RGBA")
            self.assertEqual(img.size, (32, 32), name)
            self.assertEqual(img.getpixel((0, 0))[3], 0, name)


if __name__ == "__main__":
    unittest.main()
