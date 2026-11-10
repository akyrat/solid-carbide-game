import unittest

from PIL import Image

import build_kaiju_anim_placeholders as b


def _walk_sheet():
    """A stand-in walk sheet: a 100 x 160 block (about the kaiju's build) standing on the feet's
    line in frame 0."""
    s = Image.new("RGBA", (b.FRAME * 2, b.FRAME), (0, 0, 0, 0))
    block = Image.new("RGBA", (100, 160), (40, 80, 70, 255))
    s.paste(block, (b.FEET_X - 50, b.FEET_Y - 160))
    return s


class BuildKaijuAnimPlaceholdersTest(unittest.TestCase):
    def test_sheets_are_rows_of_224_frames_with_the_data_counts(self):
        windup, death = b.build(_walk_sheet())
        self.assertEqual(windup.size, (b.FRAME * b.WINDUP_FRAMES, b.FRAME))
        self.assertEqual(death.size, (b.FRAME * b.DEATH_FRAMES, b.FRAME))

    def test_windup_rears_up_about_the_feet(self):
        windup, _ = b.build(_walk_sheet())
        first = windup.crop((0, 0, b.FRAME, b.FRAME)).getbbox()
        last = windup.crop((b.FRAME * (b.WINDUP_FRAMES - 1), 0, b.FRAME * b.WINDUP_FRAMES, b.FRAME)).getbbox()
        self.assertLess(last[1], first[1], "taller at the peak")
        self.assertEqual(last[3], first[3], "feet stay on their line")

    def test_death_buckles_kneels_and_topples_to_lie_on_the_ground(self):
        _, death = b.build(_walk_sheet())
        frames = [death.crop((i * b.FRAME, 0, (i + 1) * b.FRAME, b.FRAME)) for i in range(b.DEATH_FRAMES)]
        for f in frames:
            self.assertIsNotNone(f.getbbox(), "never empty: it stays to fall")
            self.assertLessEqual(f.getbbox()[3], b.FEET_Y + 2, "nothing below the ground line")
        first, last = frames[0].getbbox(), frames[-1].getbbox()
        self.assertGreater(last[2] - last[0], last[3] - last[1], "lying: wider than tall")
        self.assertLess(first[2] - first[0], first[3] - first[1], "standing at first")
        self.assertEqual(last[3], b.FEET_Y + 2, "resting on the ground line")
        self.assertEqual(b.DEATH_FRAMES, 16)

    def test_no_new_colours(self):
        src = _walk_sheet()
        colours = {p[:3] for p in src.getdata() if p[3] > 0}
        windup, death = b.build(src)
        for s in (windup, death):
            self.assertTrue({p[:3] for p in s.getdata() if p[3] > 0} <= colours)


if __name__ == "__main__":
    unittest.main()
