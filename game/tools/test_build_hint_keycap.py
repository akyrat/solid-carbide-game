"""Tests for build_hint_keycap.py (T-577)."""
from __future__ import annotations

import base64
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hint_keycap as k  # noqa: E402
import style_rules  # noqa: E402


def checks_ok(im: Image.Image) -> list:
    b = io.BytesIO()
    im.save(b, format="PNG")
    _, _, rows = style_rules.decode_png(b.getvalue())
    return [c for c in style_rules.art_checks(rows, (64, 64)) if not c["ok"]]


def colours(im: Image.Image) -> set:
    return {p for p in im.convert("RGBA").getdata() if p[3] > 0}


class TestKeycap(unittest.TestCase):
    def test_init_passes_the_script_rules(self):
        for letter in ("W", "S"):
            im = k.keycap(letter)
            self.assertEqual(im.size, (64, 64))
            self.assertEqual(checks_ok(im), [], letter)

    def test_init_has_the_tutorial_colours_and_a_letter(self):
        im = k.keycap("W")
        cs = colours(im)
        for c in (k.FACE, k.EDGE, k.BLUSH, k.INK, k.FACE_GLINT):
            self.assertIn(c, cs)
        # The letter fills a sensible share of the face and stays inside it.
        px = im.load()
        blush = [(x, y) for y in range(64) for x in range(64) if px[x, y] in (k.BLUSH, k.BLUSH_SHADE)]
        self.assertGreater(len(blush), 250)
        xs, ys = [p[0] for p in blush], [p[1] for p in blush]
        self.assertGreater(min(xs), k.FACE_BOX[0] + 2)
        self.assertLess(max(xs), k.FACE_BOX[2] - 2)
        self.assertGreater(min(ys), k.FACE_BOX[1] + 2)
        self.assertLess(max(ys), k.FACE_BOX[3] - 2)

    def test_w_is_symmetric_and_bold(self):
        rows = k.LETTERS["W"]
        for row in rows:
            self.assertEqual(row, row[::-1])
            self.assertEqual(len(row), len(rows[0]))
        # Strokes at least 3 cells (6 px) wide on the top rows.
        self.assertTrue(rows[0].startswith("111."))

    def test_request_body(self):
        body = k.request(b"png-bytes", "W", strength=450, seed=7)
        self.assertEqual(body["image_size"], {"width": 64, "height": 64})
        self.assertTrue(body["no_background"])
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), b"png-bytes")
        self.assertEqual(body["init_image_strength"], 450)
        self.assertEqual(body["seed"], 7)
        self.assertIn("letter W", body["description"])
        json.dumps(body)

    def test_finish_cleans_a_noisy_result(self):
        # A fake PixelLab result: the script keycap with soft alpha, stray pixels outside and a smeared letter.
        raw = k.keycap("W")
        px = raw.load()
        for y in range(64):
            for x in range(64):
                r, g, b, a = px[x, y]
                if a == 255 and (x + y) % 7 == 0:
                    px[x, y] = (r, g, b, 200)
        px[0, 0] = (255, 0, 0, 255)
        px[63, 63] = (0, 255, 0, 90)
        for y in range(20, 40):
            for x in range(20, 40):
                px[x, y] = (200 + (x % 5) * 10, 100 + (y % 7) * 10, 150, 255)
        out = k.finish(raw, "W")
        self.assertEqual(out.size, (64, 64))
        self.assertEqual(checks_ok(out), [])
        opx = out.load()
        self.assertEqual(opx[0, 0][3], 0)
        self.assertEqual(opx[63, 63][3], 0)
        clean = k.keycap("W").load()
        for (x, y) in k.letter_mask("W"):
            self.assertEqual(opx[x, y], clean[x, y])

    def test_finish_keeps_generated_pixels(self):
        raw = k.keycap("W")
        px = raw.load()
        px[10, 50] = (90, 100, 140, 255)   # a shading pixel PixelLab painted on the face, away from the letter
        out = k.finish(raw, "W", reduce=False)
        self.assertEqual(out.load()[10, 50], (90, 100, 140, 255))

    def test_cli(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            k.main(["init", str(d / "init.png")])
            k.main(["request", str(d / "req.json"), "--init", str(d / "init.png"), "--seed", "3"])
            k.main(["finish", str(d / "init.png"), str(d / "v1.png")])
            k.main(["preview", str(d / "v1.png"), str(d / "prev.png"), "--scale", "4"])
            body = json.loads((d / "req.json").read_text(encoding="utf-8"))
            self.assertEqual(body["seed"], 3)
            with Image.open(d / "v1.png") as im:
                self.assertEqual(im.mode, "RGBA")
                self.assertEqual(im.size, (64, 64))
            with Image.open(d / "prev.png") as pv:
                self.assertEqual(pv.size[1], 64 * 4 + 16)


if __name__ == "__main__":
    unittest.main()
