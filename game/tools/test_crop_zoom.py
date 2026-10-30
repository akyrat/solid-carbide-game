import unittest

from PIL import Image

from crop_zoom import crop_zoom


class CropZoomTest(unittest.TestCase):
    def test_crops_and_enlarges_without_smoothing(self):
        img = Image.new("RGBA", (10, 10), (0, 0, 0, 255))
        img.putpixel((3, 4), (255, 0, 0, 255))
        out = crop_zoom(img, 3, 4, 2, 2, scale=3)
        self.assertEqual(out.size, (6, 6))
        for x in range(3):
            for y in range(3):
                self.assertEqual(out.getpixel((x, y)), (255, 0, 0, 255))
        self.assertEqual(out.getpixel((3, 0)), (0, 0, 0, 255))


if __name__ == "__main__":
    unittest.main()
