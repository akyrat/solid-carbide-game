"""Tests for pixellab_client.py. They never call PixelLab: HTTP is faked.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""

import base64
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pixellab_client as pc  # noqa: E402

TOKEN = "test-token-1234567890"


def make_png(width: int, height: int) -> bytes:
    """A tiny valid RGBA PNG (all transparent)."""
    def chunk(ctype: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + ctype + body + struct.pack(">I", zlib.crc32(ctype + body) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    raw = b"".join(b"\x00" + b"\x00" * (width * 4) for _ in range(height))
    return pc.PNG_SIGNATURE + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")


def png_b64(width: int, height: int, data_url: bool = True) -> str:
    b64 = base64.b64encode(make_png(width, height)).decode()
    return f"data:image/png;base64,{b64}" if data_url else b64


class FakeHttp:
    """Returns queued (status, payload) responses and records each request."""

    def __init__(self, responses):
        self.token = TOKEN
        self.responses = list(responses)
        self.calls = []

    def request(self, method, path, body=None):
        self.calls.append((method, path, body))
        if not self.responses:
            raise AssertionError(f"Unexpected request {method} {path}")
        return self.responses.pop(0)


class FakeClock:
    def __init__(self):
        self.t = 0.0

    def __call__(self):
        return self.t

    def sleep(self, s):
        self.t += s


class TokenTests(unittest.TestCase):
    def test_parse_env_file(self):
        text = "# c\nGODOT_BIN=C:/x.exe\r\nPIXELLAB_API_KEY=\"abc\"\nEMPTY=\nX=1 # note\n"
        env = pc.parse_env_file(text)
        self.assertEqual(env["PIXELLAB_API_KEY"], "abc")
        self.assertEqual(env["GODOT_BIN"], "C:/x.exe")
        self.assertEqual(env["EMPTY"], "")
        self.assertEqual(env["X"], "1")

    def test_env_var_wins_over_file(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / ".env"
            f.write_text("PIXELLAB_API_KEY=fromfile\n")
            self.assertEqual(pc.load_token({"PIXELLAB_API_KEY": "fromenv"}, f), "fromenv")
            self.assertEqual(pc.load_token({}, f), "fromfile")

    def test_missing_token_errors(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / ".env"
            f.write_text("PIXELLAB_API_KEY=\n")
            with self.assertRaises(pc.PixelLabError):
                pc.load_token({}, f)

    def test_redact_and_assert_no_token(self):
        self.assertEqual(pc.redact(f"Bearer {TOKEN}", TOKEN), "Bearer [REDACTED]")
        with self.assertRaises(pc.PixelLabError):
            pc.assert_no_token({"a": [f"x{TOKEN}y"]}, TOKEN)
        pc.assert_no_token({"a": "clean"}, TOKEN)


class CliTests(unittest.TestCase):
    def test_normalize_endpoint(self):
        self.assertEqual(pc.normalize_endpoint("create-image-pixflux"), "/create-image-pixflux")
        self.assertEqual(pc.normalize_endpoint("/create-isometric-tile"), "/create-isometric-tile")


class PngTests(unittest.TestCase):
    def test_png_info_reads_size(self):
        info = pc.png_info(make_png(32, 16))
        self.assertEqual((info["width"], info["height"]), (32, 16))
        self.assertEqual(info["color_type"], 6)

    def test_decode_data_url_and_raw(self):
        self.assertEqual(pc.decode_base64_png(png_b64(8, 8)), make_png(8, 8))
        self.assertEqual(pc.decode_base64_png(png_b64(8, 8, data_url=False)), make_png(8, 8))

    def test_rejects_bad_data(self):
        with self.assertRaises(pc.PixelLabError):
            pc.png_info(b"not a png at all, definitely not a png")
        good = bytearray(make_png(4, 4))
        good[20] ^= 0xFF  # corrupt IHDR -> CRC mismatch
        with self.assertRaises(pc.PixelLabError):
            pc.png_info(bytes(good))
        with self.assertRaises(pc.PixelLabError):
            pc.png_info(make_png(4, 4)[:-6])  # truncated
        with self.assertRaises(pc.PixelLabError):
            pc.decode_base64_png("@@@not base64@@@")

    def test_extract_image(self):
        self.assertEqual(pc.extract_image_b64({"image": {"type": "base64", "base64": "abc"}}), "abc")
        self.assertEqual(pc.extract_image_b64({"last_response": {"image": {"base64": "xyz"}}}), "xyz")
        with self.assertRaises(pc.PixelLabError):
            pc.extract_image_b64({"usage": {}})


class PollTests(unittest.TestCase):
    def test_completes(self):
        http = FakeHttp([(200, {"status": "processing"}), (200, {"status": "completed", "id": "j"})])
        clock = FakeClock()
        job = pc.poll_job(http, "j", interval=5, timeout=600, clock=clock, sleep=clock.sleep)
        self.assertEqual(job["status"], "completed")
        self.assertEqual(clock.t, 5)

    def test_failed_raises(self):
        http = FakeHttp([(200, {"status": "failed", "last_response": {"error": "boom"}})])
        clock = FakeClock()
        with self.assertRaisesRegex(pc.PixelLabError, "failed"):
            pc.poll_job(http, "j", clock=clock, sleep=clock.sleep)

    def test_timeout_after_ten_minutes(self):
        http = FakeHttp([(200, {"status": "processing"})] * 1000)
        clock = FakeClock()
        with self.assertRaises(pc.PollTimeout):
            pc.poll_job(http, "j", interval=5, timeout=pc.POLL_TIMEOUT_SECONDS, clock=clock, sleep=clock.sleep)
        self.assertEqual(pc.POLL_TIMEOUT_SECONDS, 600)
        self.assertGreaterEqual(clock.t, 600)
        self.assertLess(clock.t, 610)

    def test_transient_poll_errors_keep_polling(self):
        http = FakeHttp([(429, None), (200, {"status": "completed"})])
        clock = FakeClock()
        self.assertEqual(pc.poll_job(http, "j", clock=clock, sleep=clock.sleep)["status"], "completed")

    def test_auth_error_stops(self):
        http = FakeHttp([(401, {"detail": "bad"})])
        clock = FakeClock()
        with self.assertRaises(pc.PixelLabError):
            pc.poll_job(http, "j", clock=clock, sleep=clock.sleep)


class GenerateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.log = self.dir / "log.jsonl"

    def tearDown(self):
        self.tmp.cleanup()

    def run_gen(self, http, endpoint, params, name="asset"):
        clock = FakeClock()
        return pc.generate(
            http, endpoint=endpoint, params=params, out_dir=self.dir / "out", name=name,
            consulted=["docs/visual-style.md"], task="T-TEST", log_path=self.log,
            poll_kwargs={"interval": 5, "clock": clock, "sleep": clock.sleep}, echo=lambda s: None,
        )

    def test_direct_endpoint(self):
        params = {"description": "a car", "image_size": {"width": 64, "height": 64}}
        http = FakeHttp([(200, {"image": {"base64": png_b64(64, 64)}, "usage": {"type": "usd", "usd": 0.01}})])
        rec = self.run_gen(http, "/create-image-pixflux", params)
        self.assertEqual(len(http.calls), 1)
        self.assertIsNone(rec["job_id"])
        self.assertEqual(rec["prompt"], "a car")
        self.assertEqual(rec["usage"]["usd"], 0.01)
        self.assertEqual((rec["image"]["width"], rec["image"]["height"]), (64, 64))
        on_disk = json.loads((self.dir / "out" / "asset.json").read_text())
        for field in ("endpoint", "request_params", "prompt", "job_id", "usage", "generated_at", "resources_consulted"):
            self.assertIn(field, on_disk)
        self.assertEqual(pc.png_info((self.dir / "out" / "asset.png").read_bytes())["width"], 64)
        log = [json.loads(l) for l in self.log.read_text().splitlines()]
        self.assertEqual(len(log), 1)
        self.assertEqual(log[0]["result"], "saved")

    def test_async_endpoint_fetches_tile(self):
        params = {"description": "road", "image_size": {"width": 32, "height": 32}}
        http = FakeHttp([
            (202, {"background_job_id": "job-1", "tile_id": "tile-1", "status": "processing", "usage": {"type": "generations", "generations": 1}}),
            (200, {"status": "processing"}),
            (200, {"status": "completed", "last_response": {"tile_id": "tile-1"}}),
            (200, {"image": {"base64": png_b64(32, 32)}}),
        ])
        rec = self.run_gen(http, "/create-isometric-tile", params)
        self.assertEqual(rec["job_id"], "job-1")
        self.assertEqual(rec["tile_id"], "tile-1")
        self.assertEqual(rec["usage"], {"type": "generations", "generations": 1})
        self.assertEqual(http.calls[-1][:2], ("GET", "/isometric-tiles/tile-1"))
        self.assertEqual(sum(1 for c in http.calls if c[0] == "POST"), 1)

    def test_async_endpoint_answering_directly(self):
        http = FakeHttp([(200, {"image": {"base64": png_b64(32, 32)}, "usage": {"type": "usd", "usd": 0.01}})])
        rec = self.run_gen(http, "/create-isometric-tile", {"description": "road", "image_size": {"width": 32, "height": 32}})
        self.assertEqual(len(http.calls), 1)
        self.assertEqual(rec["image"]["width"], 32)

    def test_failure_is_not_retried_and_is_logged(self):
        http = FakeHttp([(402, {"detail": "Insufficient credits"})])
        with self.assertRaises(pc.PixelLabError):
            self.run_gen(http, "/create-image-pixflux", {"description": "x", "image_size": {"width": 32, "height": 32}})
        self.assertEqual(len(http.calls), 1)
        self.assertFalse((self.dir / "out" / "asset.png").exists())
        log = [json.loads(l) for l in self.log.read_text().splitlines()]
        self.assertEqual(log[0]["result"], "error")

    def test_refuses_to_overwrite(self):
        out = self.dir / "out"
        out.mkdir()
        (out / "asset.png").write_bytes(make_png(4, 4))
        http = FakeHttp([])
        with self.assertRaisesRegex(pc.PixelLabError, "overwrite"):
            self.run_gen(http, "/create-image-pixflux", {"description": "x", "image_size": {"width": 32, "height": 32}})
        self.assertEqual(http.calls, [])

    def test_token_never_written(self):
        http = FakeHttp([(200, {"image": {"base64": png_b64(32, 32)}, "usage": None})])
        self.run_gen(http, "/create-image-pixflux", {"description": "x", "image_size": {"width": 32, "height": 32}})
        for f in list((self.dir / "out").iterdir()) + [self.log]:
            self.assertNotIn(TOKEN.encode(), f.read_bytes())

    def test_error_message_redacts_token(self):
        http = FakeHttp([(400, {"detail": f"echo {TOKEN}"})])
        with self.assertRaises(pc.PixelLabError) as ctx:
            self.run_gen(http, "/create-image-pixflux", {"description": "x", "image_size": {"width": 32, "height": 32}})
        self.assertNotIn(TOKEN, str(ctx.exception))
        self.assertNotIn(TOKEN, self.log.read_text())

    def test_unknown_endpoint_and_missing_fields(self):
        http = FakeHttp([])
        with self.assertRaises(pc.PixelLabError):
            self.run_gen(http, "/create-8-direction-object", {"description": "x"})
        with self.assertRaises(pc.PixelLabError):
            self.run_gen(http, "/create-image-pixflux", {"image_size": {"width": 32, "height": 32}})
        self.assertEqual(http.calls, [])


if __name__ == "__main__":
    unittest.main()
