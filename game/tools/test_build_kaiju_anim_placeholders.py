import unittest

from PIL import Image

import build_kaiju_anim_placeholders as b


def _walk_sheet():
    """A stand-in walk sheet: a 20 x 100 block standing on the feet's line in frame 0."""
    s = Image.new("RGBA", (b.FRAME * 2, b.FRAME), (0, 0, 0, 0))
    block = Image.new("RGBA", (20, 100), (40, 80, 70, 255))
    s.paste(block, (b.FEET_X - 10, b.FEET_Y - 100))
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

    def test_death_sinks_fades_and_ends_empty(self):
        _, death = b.build(_walk_sheet())
        frames = [death.crop((i * b.FRAME, 0, (i + 1) * b.FRAME, b.FRAME)) for i in range(b.DEATH_FRAMES)]
        self.assertIsNotNone(frames[0].getbbox())
        self.assertIsNone(frames[-1].getbbox(), "the last frame is empty: it has gone")
        mid = frames[b.DEATH_FRAMES // 2]
        self.assertLess(max(mid.getchannel("A").getdata()), 255, "fading")
        self.assertLessEqual(mid.getbbox()[3], b.FEET_Y + 2, "nothing below the ground line")

    def test_no_new_colours(self):
        src = _walk_sheet()
        colours = {p[:3] for p in src.getdata() if p[3] > 0}
        windup, death = b.build(src)
        for s in (windup, death):
            self.assertTrue({p[:3] for p in s.getdata() if p[3] > 0} <= colours)


if __name__ == "__main__":
    unittest.main()
