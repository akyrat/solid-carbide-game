import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import record_tutorial_clips as rtc  # noqa: E402

CLIPS_DIR = rtc.GAME / "art" / "tutorial" / "clips"


class TestAssemble(unittest.TestCase):
    def test_crop_box_is_the_centre(self):
        self.assertEqual(rtc.crop_box(1152, 648), (336, 164, 816, 484))

    def test_assemble_keeps_every_second_frame_at_the_clip_size(self):
        from PIL import Image
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            for i in range(10):
                Image.new("RGB", (1152, 648), (i * 20, 50, 90)).save(d / ("f%08d.png" % i))
            out = d / "x.gif"
            n = rtc.assemble(d, out)
            self.assertEqual(n, 5)
            with Image.open(out) as im:
                self.assertEqual(im.size, rtc.CLIP_SIZE)
                # Identical neighbouring frames are merged into one that lasts longer.
                self.assertLessEqual(im.n_frames, 5)
                self.assertEqual(im.info["loop"], 0)
                total = 0
                for i in range(im.n_frames):
                    im.seek(i)
                    total += im.info["duration"]
                self.assertEqual(total, 5 * 40)

    def test_assemble_without_frames_fails(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(FileNotFoundError):
                rtc.assemble(Path(d), Path(d) / "x.gif")


class TestRecordedClips(unittest.TestCase):
    """The recorder's output in game/art/tutorial/clips/: four GIFs of the expected size, each with its record."""

    def test_four_clips_with_records(self):
        from PIL import Image
        for name in rtc.CLIPS:
            gif = CLIPS_DIR / f"{name}.gif"
            rec = CLIPS_DIR / f"{name}.json"
            self.assertTrue(gif.exists(), gif)
            self.assertTrue(rec.exists(), rec)
            self.assertLessEqual(gif.stat().st_size, rtc.MAX_BYTES, name)
            with Image.open(gif) as im:
                self.assertEqual(im.size, rtc.CLIP_SIZE, name)
                self.assertGreater(im.n_frames, 10 if name in rtc.CLIPS[8:] else 40, name)  # T-543: the three short clips
                self.assertEqual(im.info["loop"], 0, name)
                n_frames = im.n_frames
            data = json.loads(rec.read_text())
            self.assertEqual(data["clip"], name)
            self.assertLessEqual(n_frames, data["frames"])
            self.assertEqual(data["bytes"], gif.stat().st_size)

    def test_the_ramp_clip_has_hang_time_and_a_half_turn(self):
        import re
        data = json.loads((CLIPS_DIR / "ramp_jump.json").read_text())
        airtime = [float(m.group(1)) for l in data["air"] for m in [re.match(r"airtime ([0-9.]+) s", l)] if m]
        turned = [float(m.group(1)) for l in data["air"] for m in [re.search(r"turned (\d+) degrees", l)] if m]
        self.assertTrue(airtime and airtime[0] >= 0.3)
        self.assertTrue(turned and turned[0] >= 180.0)

    def test_the_alt_clip_has_the_trick(self):
        data = json.loads((CLIPS_DIR / "alt_drift.json").read_text())
        self.assertTrue(any("alternate_drift" in l for l in data["tricks"]))

    def test_new_clips_show_their_trick_and_nothing_unwanted(self):
        for name in ["three_sixty", "air_three_sixty", "airtime", "thread_the_needle"]:
            data = json.loads((CLIPS_DIR / f"{name}.json").read_text())
            self.assertEqual(data["problems"], [], name)
            self.assertEqual(rtc.check_expect(name, data["tricks"], data["air"]), [], name)
        hang = json.loads((CLIPS_DIR / "airtime.json").read_text())
        self.assertTrue(any("airtime" in l for l in hang["air"]))
        self.assertFalse(any("air_" in l for l in hang["tricks"]))

    def test_every_sheet_page_fits_the_web_limit(self):
        from PIL import Image
        for name in rtc.CLIPS:
            meta = json.loads((CLIPS_DIR / f"{name}_sheet.json").read_text())
            for page in meta["pages"]:
                with Image.open(CLIPS_DIR / page) as im:
                    self.assertLessEqual(max(im.size), 3840, page)

    def test_every_sheet_has_one_key_entry_per_frame(self):
        for name in rtc.CLIPS:
            meta = json.loads((CLIPS_DIR / f"{name}_sheet.json").read_text())
            keys = meta["keys_per_frame"]
            self.assertEqual(len(keys), meta["frames"], name)
            for k in keys:
                self.assertTrue(set(k) <= set("WASD"), (name, k))

    def test_alt_drift_keys_are_w_then_w_a_then_s_a_then_w(self):
        import itertools
        meta = json.loads((CLIPS_DIR / "alt_drift_sheet.json").read_text())
        runs = [k for k, _ in itertools.groupby(meta["keys_per_frame"])]
        # The script lets go of W for two physics steps before it presses S (one frame shows just A).
        runs = [r for r in runs if r != "A"]
        self.assertEqual(runs, ["W", "WA", "AS", "W"])

    def test_keys_per_frame_takes_the_step_at_each_frame(self):
        keys = ["W"] * 6 + ["WA"] * 6
        self.assertEqual(rtc.keys_per_frame(keys, 3, 4), ["W", "W", "WA", "WA"])
        self.assertEqual(rtc.keys_per_frame([], 3, 2), ["", ""])

    def test_the_sheet_keys_follow_merged_frames(self):
        sys.path.insert(0, str(Path(__file__).parent))
        import gif_to_sheet as g
        # Frames 1 and 2 were identical and merged into one 2-frame-long sheet frame.
        self.assertEqual(g.keys_for_sheet(["W", "W", "WA", "S"], [40, 80, 40], 0.16), ["W", "W", "S"])


if __name__ == "__main__":
    unittest.main()
