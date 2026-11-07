"""Tests for build_car_tilt.py (task T-555). Run: python -m unittest discover -s game/tools -p "test_*.py" """
import base64
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_car_tilt as b  # noqa: E402


def colours(img):
    return {tuple(c) for c in img[img[:, :, 3] > 0][:, :3]}


class TiltGeometryTests(unittest.TestCase):
    def test_front_left_goes_down_back_right_goes_up(self):
        u, v = b.WHEEL_U, b.WHEEL_V
        _, _, z_fl = b.tilt_local(np.array(u), np.array(v), np.array(b.PIVOT_Z), 20.0)
        _, _, z_br = b.tilt_local(np.array(-u), np.array(-v), np.array(b.PIVOT_Z), 20.0)
        self.assertLess(float(z_fl), b.PIVOT_Z - 0.1)
        self.assertGreater(float(z_br), b.PIVOT_Z + 0.1)

    def test_axis_wheels_stay(self):
        for su, sv in ((1, -1), (-1, 1)):   # front right and back left lie on the axis
            u2, v2, z2 = b.tilt_local(np.array(su * b.WHEEL_U), np.array(sv * b.WHEEL_V), np.array(b.PIVOT_Z), 20.0)
            self.assertAlmostEqual(float(u2), su * b.WHEEL_U, places=6)
            self.assertAlmostEqual(float(v2), sv * b.WHEEL_V, places=6)
            self.assertAlmostEqual(float(z2), b.PIVOT_Z, places=6)

    def test_zero_tilt_is_identity(self):
        frame = b.normal_frame(8)
        self.assertTrue(np.array_equal(b.warp_frame(frame, 8 * b.STEP_DEG, 0.0), frame))

    def test_steps_grow_to_the_held_pose(self):
        self.assertEqual(len(b.TILT_STEPS_DEG), 3)
        self.assertTrue(0 < b.TILT_STEPS_DEG[0] < b.TILT_STEPS_DEG[1] < b.TILT_STEPS_DEG[2])

    def test_front_left_corner_moves_down_on_screen(self):
        # Frame 8: nose down-left, the front left wheel near the viewer; its point drops on screen.
        h = 8 * b.STEP_DEG
        u, v, z = np.array(b.WHEEL_U), np.array(b.WHEEL_V), np.array(0.1)
        _, sy0, _ = b.project(u, v, z, h)
        _, sy1, _ = b.project(*b.tilt_local(u, v, z, 20.0), h)
        self.assertGreater(float(sy1), float(sy0) + 2)

    def test_pixellab_directions(self):
        self.assertEqual(b.pixellab_direction(0), "south-east")
        self.assertEqual(b.pixellab_direction(8), "south-west")
        self.assertEqual(b.pixellab_direction(24), "north-east")
        self.assertEqual(b.pixellab_direction(31), "south-east")
        self.assertEqual(b.pixellab_direction(30), "south-east")


class TiltImageTests(unittest.TestCase):
    def test_warp_uses_only_the_frames_own_pixels(self):
        frame = b.normal_frame(12)
        out = b.warp_frame(frame, 12 * b.STEP_DEG, 20.0)
        self.assertEqual(out.shape, (128, 128, 4))
        self.assertTrue(colours(out) <= colours(frame))
        self.assertTrue(set(np.unique(out[:, :, 3])) <= {0, 255})
        self.assertFalse(np.array_equal(out, frame))

    def test_shear_keeps_every_pixel_and_tilts_left_down_right_up(self):
        frame = b.normal_frame(8)
        out = b.shear_frame(frame, 20.0)
        self.assertEqual(out.shape, frame.shape)
        self.assertEqual(colours(out), colours(frame))
        self.assertEqual(int((out[:, :, 3] > 0).sum()), int((frame[:, :, 3] > 0).sum()))
        cols = np.nonzero(frame[:, :, 3].any(axis=0))[0]
        left, right = cols.min(), cols.max()
        top = lambda img, x: np.nonzero(img[:, x, 3])[0].min()
        self.assertGreater(top(out, left), top(frame, left))     # front left corner lowered
        self.assertLess(top(out, right), top(frame, right))      # back right corner raised

    def test_shear_offsets_grow_with_the_step(self):
        steps = [abs(b.shear_offsets(128, 64.0, 50.0, int(round(b.SHEAR_RADIUS_PX * np.sin(np.radians(d)))))).max()
                 for d in b.TILT_STEPS_DEG]
        self.assertEqual(steps, sorted(steps))
        self.assertGreater(steps[0], 0)

    def test_clean_maps_to_palette_and_centres(self):
        ref = b.normal_frame(4)
        noisy = b.shift(ref, 5, -3).astype(int)
        noisy[:, :, :3] = np.clip(noisy[:, :, :3] + 3, 0, 255)
        noisy[:, :, 3] = np.where(noisy[:, :, 3] > 0, 200, 40)
        out = b.clean(noisy.astype(np.uint8), ref)
        pal = {tuple(c) for c in b.car_palette()}
        self.assertTrue(colours(out) <= pal)
        self.assertTrue(set(np.unique(out[:, :, 3])) <= {0, 255})
        self.assertEqual(b.bbox_center(out), b.bbox_center(ref))

    def test_remove_specks(self):
        img = np.zeros((128, 128, 4), np.uint8)
        img[10:30, 10:30] = (1, 2, 3, 255)
        img[100, 100] = (1, 2, 3, 255)
        out = b.remove_specks(img)
        self.assertEqual(out[100, 100, 3], 0)
        self.assertEqual(out[20, 20, 3], 255)

    def test_rotate_request(self):
        with tempfile.TemporaryDirectory() as d:
            gd = Path(d)
            b.save_rgba(b.normal_frame(8), gd / b.frame_name(8, 3))
            body = b.rotate_request(8, 3, 450, 555001, gd)
        self.assertEqual(body["from_direction"], "south-west")
        self.assertEqual(body["to_direction"], "south-west")
        self.assertEqual(body["init_image_strength"], 450)
        self.assertTrue(body["isometric"])
        with Image.open(io.BytesIO(base64.b64decode(body["init_image"]["base64"]))) as img:
            self.assertEqual(img.size, (128, 128))


class TiltRound2Tests(unittest.TestCase):
    def test_fit_puts_volume_on_the_silhouette(self):
        frame = b.normal_frame(8)
        cs, cp, sc = b.frame_fit(frame[:, :, 3] > 0, 8 * b.STEP_DEG)
        self.assertTrue(np.all(sc > 0.3) and np.all(sc < 3.0))
        self.assertAlmostEqual(float(cs[0]), b.bbox_center(frame)[0])

    def test_splat_is_closed_and_uses_own_pixels(self):
        frame = b.normal_frame(8)
        out = b.splat_frame(frame, 8 * b.STEP_DEG, 30.0)
        self.assertTrue(colours(out) <= colours(frame))
        self.assertTrue(set(np.unique(out[:, :, 3])) <= {0, 255})
        self.assertTrue(np.array_equal(b.remove_specks(out), out))   # no loose fragments
        self.assertGreater((out[:, :, 3] > 0).sum(), 0.8 * (frame[:, :, 3] > 0).sum())

    def test_splat_lowers_the_front_left_and_raises_the_back_right(self):
        # Frame 8: nose down-left; the front left corner is the bottom-left of the car, the back right the top-right.
        frame = b.normal_frame(8)
        out = b.splat_frame(frame, 8 * b.STEP_DEG, 30.0)

        def edge(img, cols, top):
            rows = np.nonzero((img[:, cols, 3] > 0).any(axis=1))[0]
            return rows.min() if top else rows.max()
        xs = np.nonzero((frame[:, :, 3] > 0).any(axis=0))[0]
        left, right = slice(xs.min(), xs.min() + 20), slice(xs.max() - 20, xs.max() + 1)
        self.assertGreater(edge(out, left, False), edge(frame, left, False))   # front left goes down
        self.assertLess(edge(out, right, True), edge(frame, right, True))      # back right goes up

    def test_zero_tilt_splat_is_identity(self):
        frame = b.normal_frame(3)
        self.assertTrue(np.array_equal(b.splat_frame(frame, 3 * b.STEP_DEG, 0.0), frame))

    def test_generate_set_calls_once_per_missing_frame_and_caps(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            guides, raw, frames = d / "g", d / "raw", d / "f"
            for s in (1, 2, 3):
                b.save_rgba(b.normal_frame(5), guides / b.frame_name(5, s))
            calls = []

            def fake_run(cmd):
                name = cmd[cmd.index("--name") + 1]
                calls.append(name)
                b.save_rgba(b.normal_frame(5), raw / f"{name}.png")
                return 0
            old_log, old_archive = b.CALLS_LOG, b.ARCHIVE
            b.CALLS_LOG, b.ARCHIVE = d / "calls.md", d
            try:
                got = b.generate_set([5], [2, 3], 500, 1, guides, raw, frames, "t", 1, run=fake_run)
                self.assertEqual(got, ["d05_s2_st500_t"])
                got = b.generate_set([5], [2, 3], 500, 1, guides, raw, frames, "t", 5, run=fake_run)
                self.assertEqual(got, ["d05_s3_st500_t"])     # the first frame's raw exists: not paid again
                self.assertTrue((frames / b.frame_name(5, 2)).is_file())
                self.assertTrue((frames / b.frame_name(5, 3)).is_file())
                self.assertEqual(len((d / "calls.md").read_text(encoding="utf-8").splitlines()), 2)
            finally:
                b.CALLS_LOG, b.ARCHIVE = old_log, old_archive
            self.assertEqual(calls, ["d05_s2_st500_t", "d05_s3_st500_t"])


class TiltSheetTests(unittest.TestCase):
    def test_assemble_sheet_layout(self):
        with tempfile.TemporaryDirectory() as d:
            fd = Path(d) / "frames"
            frame = b.normal_frame(0)
            for i in range(b.DIRECTIONS):
                for s in (1, 2, 3):
                    b.save_rgba(frame, fd / b.frame_name(i, s))
            layout = b.assemble_sheet(fd, Path(d) / "car_iso_tilt")
            with Image.open(Path(d) / "car_iso_tilt.png") as im:
                size = im.size
            saved = json.loads((Path(d) / "car_iso_tilt.json").read_text(encoding="utf-8"))
        self.assertEqual(size, (32 * 128, 3 * 128))
        self.assertEqual(saved["columns"], 32)
        self.assertEqual(saved["rows"], 3)
        self.assertEqual(saved["frame_count"], 32)
        self.assertEqual(saved["center_px"], {"x": 64.5, "y": 65.5})
        self.assertEqual(saved["px_per_unit"], 32.0)
        self.assertEqual(layout["file"], "car_iso_tilt.png")

    def test_assemble_refuses_missing_frames(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(SystemExit):
                b.assemble_sheet(Path(d), Path(d) / "x")

    def test_committed_sheet_if_present(self):
        png = b.CAR_DIR / "car_iso_tilt.png"
        if not png.is_file():
            self.skipTest("no tilt sheet yet")
        img = np.array(Image.open(png).convert("RGBA"))
        self.assertEqual(img.shape, (3 * 128, 32 * 128, 4))
        self.assertTrue(set(np.unique(img[:, :, 3])) <= {0, 255})
        for s in range(3):
            for i in range(32):
                tile = img[s * 128:(s + 1) * 128, i * 128:(i + 1) * 128]
                self.assertGreater(int((tile[:, :, 3] > 0).sum()), 2000, f"step {s + 1} dir {i} nearly empty")


if __name__ == "__main__":
    unittest.main()
