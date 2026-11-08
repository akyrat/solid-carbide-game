"""Tests for build_hint_sign.py (T-577)."""
from __future__ import annotations

import base64
import io
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_hint_sign as s  # noqa: E402
import style_rules  # noqa: E402


def failed_checks(im: Image.Image) -> list:
    b = io.BytesIO()
    im.save(b, format="PNG")
    _, _, rows = style_rules.decode_png(b.getvalue())
    return [c for c in style_rules.art_checks(rows, (64, 96)) if not c["ok"]]


def colours(im: Image.Image) -> set:
    return {p[:3] for p in im.convert("RGBA").getdata() if p[3] > 0}


class TestSign(unittest.TestCase):
    def test_size_corners_and_foot(self):
        im = s.sign()
        self.assertEqual(im.size, (64, 96))
        px = im.load()
        for p in ((0, 0), (63, 0), (0, 95), (63, 95), (3, 70), (60, 70)):
            self.assertEqual(px[p][3], 0, p)
        self.assertEqual(px[s.FOOT], s.INK)          # the post's foot is the base's bottom outline pixel
        self.assertEqual(px[32, 94][3], 255)

    def test_board_fills_face_px_with_a_blank_face(self):
        px = s.sign().load()
        for p in ((8, 8), (55, 8), (8, 55), (55, 55)):
            self.assertEqual(px[p][3], 255, p)
            self.assertNotEqual(px[p], s.INK, p)      # the frame, not the outline, at the face box's corners
        for p in ((7, 9), (56, 54), (7, 30), (30, 56)):
            self.assertEqual(px[p], s.INK, p)
        self.assertEqual(px[7, 7][3], 0)             # the outline's corners are rounded
        for y in range(11, 54):
            for x in range(11, 54):
                self.assertEqual(px[x, y], s.FACE, (x, y))
        self.assertEqual(px[8, 30], s.FRAME_LIT)
        self.assertEqual(px[55, 30], s.FRAME_DARK)

    def test_post_runs_from_the_board_to_the_base(self):
        px = s.sign().load()
        for y in range(61, 84):
            self.assertEqual(px[28, y], s.INK, y)
            self.assertEqual(px[35, y], s.INK, y)
            self.assertEqual(px[32, y][3], 255, y)
        self.assertEqual(px[32, 75], s.AMBER)
        self.assertEqual(px[26, 91][3], 255)        # the base plate reaches past the post

    def test_rules_1_3_and_6(self):
        im = s.sign()
        self.assertEqual(failed_checks(im), [])
        self.assertLessEqual(len(colours(im)), 30)
        self.assertIn(s.GLINT[:3], colours(im))
        self.assertEqual(s.sign().load()[12, 7], s.GLINT)   # a highlight breaks the outline (rule 2)

    def test_request_body(self):
        body = s.request(b"png-bytes", strength=450, seed=7)
        self.assertEqual(body["image_size"], {"width": 64, "height": 96})
        self.assertTrue(body["no_background"])
        self.assertEqual(body["init_image_strength"], 450)
        self.assertEqual(body["seed"], 7)
        self.assertEqual(base64.b64decode(body["init_image"]["base64"]), b"png-bytes")
        self.assertNotIn("seed", s.request(b"x"))
        for word in ("green", "yellow", "text", "icon"):
            self.assertIn(word, body["negative_description"])

    def test_finish_clears_outside_blanks_the_face_and_repaints_the_outline(self):
        raw = Image.new("RGBA", (64, 96), (200, 40, 40, 255))      # PixelLab painted everything red
        px = raw.load()
        px[30, 30] = (200, 40, 40, 90)                             # a half pixel on the face
        px[32, 95] = (0, 0, 0, 0)                                  # and it lost the foot
        out = s.finish(raw)
        opx = out.load()
        self.assertEqual(opx[0, 0][3], 0)
        self.assertEqual(opx[3, 70][3], 0)
        self.assertEqual(opx[30, 30], s.FACE)
        self.assertEqual(opx[32, 95], s.INK)
        self.assertEqual(opx[7, 30], s.INK)
        self.assertEqual(opx[12, 7], s.GLINT)
        self.assertEqual(opx[32, 70], (200, 40, 40, 255))          # PixelLab's post pixels stay
        self.assertEqual(failed_checks(out), [])
        kept = s.finish(raw, do_polish=False, keep_face=True)
        self.assertEqual(kept.load()[30, 30], s.FACE)              # the half pixel, refilled from the script
        self.assertEqual(kept.load()[31, 31], (200, 40, 40, 255))
        self.assertEqual(kept.load()[7, 30], (200, 40, 40, 255))

    def test_roles_cover_every_opaque_pixel(self):
        for strong in (False, True):
            r = s.roles(strong)
            self.assertNotIn("other", r)
            im = s.sign_strong() if strong else s.sign()
            self.assertEqual(sum(r.values()), sum(1 for p in im.getdata() if p[3] == 255))

    def test_strong_sign_keeps_the_brief_and_adds_what_the_reason_named(self):
        im = s.sign_strong()
        px = im.load()
        self.assertEqual(failed_checks(im), [])
        self.assertLessEqual(len(colours(im)), 30)
        self.assertEqual(px[s.FOOT], s.INK)
        for p in ((0, 0), (63, 0), (0, 95), (63, 95), (3, 70), (62, 30)):
            self.assertEqual(px[p][3], 0, p)
        for p in ((8, 8), (55, 8), (8, 55), (55, 55)):         # the board still fills face_px
            self.assertEqual(px[p][3], 255, p)
            self.assertNotEqual(px[p], s.INK, p)
        for y in range(11, 53):                                # the face is still blank slate
            for x in range(11, 53):
                self.assertEqual(px[x, y], s.FACE, (x, y))
        self.assertEqual(px[57, 30], s.EDGE)                   # the shadow column on the board's right
        self.assertEqual(px[58, 30], s.INK)
        self.assertEqual(px[35, 75], s.EDGE_DEEP)              # and on the post
        self.assertEqual(px[27, 75], s.INK)                    # the thicker post's outline columns
        self.assertEqual(px[36, 75], s.INK)
        self.assertEqual(px[27, 67], s.GLINT)                  # glints breaking the post's outline
        self.assertEqual(px[12, 7], s.GLINT)                   # and the board's
        self.assertEqual(px[7, 31], s.GLINT)
        self.assertEqual(px[8, 8], s.GLINT_BRIGHT)
        self.assertEqual(px[8, 30], s.FRAME_HI)                # the two-step bevel
        self.assertEqual(px[9, 30], s.FRAME_LIT)
        self.assertEqual(px[54, 54], s.STEEL_LIT)              # a rivet
        self.assertEqual(px[30, 76], s.AMBER)
        self.assertEqual(px[33, 76], s.AMBER_DARK)
        self.assertEqual(px[19, 90][3], 255)                   # the wider base plate

    def test_polish_strong_keeps_pixellab_body_pixels_and_repaints_the_roles(self):
        v1 = s.finish(Image.new("RGBA", (64, 96), (70, 80, 100, 255)))   # a PixelLab-like render, finished
        out = s.polish_strong(v1)
        px = out.load()
        self.assertEqual(px[31, 80], (70, 80, 100, 255))       # the post's body keeps PixelLab's pixel
        self.assertEqual(px[35, 80], s.EDGE_DEEP)              # the roles are the script's
        self.assertEqual(px[27, 67], s.GLINT)
        self.assertEqual(px[30, 30], s.FACE)
        self.assertEqual(px[57, 30], s.EDGE)
        self.assertEqual(px[0, 0][3], 0)
        self.assertEqual(failed_checks(out), [])
        # Where v1 had a script role (the old outline at column 28) the new body takes the script's steel.
        self.assertEqual(px[28, 80], s.GLINT)
        self.assertNotEqual(px[29, 75], s.INK)


if __name__ == "__main__":
    unittest.main()
