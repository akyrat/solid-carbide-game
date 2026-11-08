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

    def test_slim_sign_is_a_long_slim_pole_on_a_flat_base_with_a_clear_frame(self):
        im = s.sign_slim()
        px = im.load()
        self.assertEqual(failed_checks(im), [])
        self.assertLessEqual(len(colours(im)), 30)
        self.assertEqual(px[s.FOOT], s.INK)
        for p in ((0, 0), (63, 0), (0, 95), (63, 95), (3, 70), (62, 30), (20, 80), (44, 80)):
            self.assertEqual(px[p][3], 0, p)
        for p in ((8, 8), (55, 8), (8, 55), (55, 55)):         # the board still fills face_px
            self.assertEqual(px[p][3], 255, p)
            self.assertNotEqual(px[p], s.INK, p)
        for y in range(11, 53):                                # the face is blank slate in three steps
            for x in range(11, 53):
                self.assertIn(px[x, y], (s.FACE, s.FACE_HI, s.FACE_DEEP), (x, y))
        self.assertEqual(px[12, 12], s.FACE_HI)
        self.assertEqual(px[32, 32], s.FACE)
        self.assertEqual(px[50, 50], s.FACE_DEEP)
        # The pole: 5 px of steel on columns 30..34, outlined at 29 and 35, from under the bracket to the base.
        for y in range(61, 89):
            self.assertEqual(px[35, y], s.INK, y)
            self.assertIn(px[29, y], (s.INK, s.GLINT_BRIGHT), y)
            self.assertEqual(px[28, y][3], 0, y)
            self.assertEqual(px[36, y][3], 0, y)
        self.assertEqual(px[34, 70], s.EDGE_DEEP)              # the shadow column
        self.assertEqual(px[30, 70], s.STEEL_LIT)              # the lit step
        self.assertEqual(px[29, 64], s.GLINT_BRIGHT)           # glints breaking the pole's outline
        self.assertEqual(px[29, 80], s.GLINT_BRIGHT)
        self.assertEqual(px[31, 75], s.AMBER)
        # A flat base: 7 rows, and a wider frame highlight than the strong pass.
        self.assertEqual(px[23, 88][3], 0)
        self.assertEqual(px[23, 92][3], 255)
        self.assertEqual(px[8, 30], s.GLINT)
        self.assertEqual(px[9, 30], s.FRAME_HI)
        self.assertEqual(px[55, 30], s.FRAME_DARK)
        self.assertEqual(px[54, 30], s.FRAME)
        self.assertEqual(px[12, 7], s.GLINT_BRIGHT)
        self.assertEqual(px[57, 30], s.EDGE)                   # the thickness shadow stays

    def test_bold_sign_has_highlights_that_read_at_native_size_and_a_blank_face(self):
        im = s.sign_bold()
        px = im.load()
        self.assertEqual(failed_checks(im), [])
        self.assertLessEqual(len(colours(im)), 30)
        self.assertEqual(px[s.FOOT], s.INK)
        for p in ((8, 8), (55, 8), (8, 55), (55, 55)):         # the board still fills face_px
            self.assertEqual(px[p][3], 255, p)
            self.assertNotEqual(px[p], s.INK, p)
        for y in range(11, 53):                                # the face: five stepped slate bands, no marks
            for x in range(11, 53):
                self.assertIn(px[x, y], (s.FACE, s.FACE_HI, s.FACE_HI_2, s.FACE_DEEP, s.FACE_DEEP_2), (x, y))
        self.assertEqual(px[11, 11], s.FACE_HI_2)
        self.assertEqual(px[32, 32], s.FACE)
        self.assertEqual(px[52, 52], s.FACE_DEEP_2)
        # Near-white runs two pixels wide break the outline on the frame, the pole and the base.
        for p in ((12, 7), (12, 8), (7, 12), (8, 12), (29, 64), (29, 80), (22, 92), (23, 91)):
            self.assertEqual(px[p], s.WHITE, p)
        self.assertEqual(px[30, 64], s.GLINT_BRIGHT)
        self.assertEqual(px[29, 70], s.INK)                    # the outline is still there between runs
        self.assertEqual(px[7, 25], s.INK)
        # Rivets and scuffs on the frame; a two-column dark right side on the pole; the base's right in shadow.
        self.assertEqual(px[32, 9], s.WHITE)
        self.assertEqual(px[32, 54], s.GLINT)
        self.assertEqual(px[24, 8], s.FRAME_DARK)
        self.assertEqual(px[33, 70], s.STEEL_DEEP)
        self.assertEqual(px[34, 70], s.EDGE_DEEP)
        self.assertEqual(px[40, 93], s.EDGE_DEEP)
        self.assertEqual(px[31, 75], s.AMBER)
        self.assertEqual(s.roles("bold").get("other"), None)
        out = s.polish_pass(s.finish(Image.new("RGBA", (64, 96), (70, 80, 100, 255))), "bold")
        self.assertEqual(out.load()[32, 80], (70, 80, 100, 255))
        self.assertEqual(out.load()[29, 80], s.WHITE)

    def test_polish_slim_keeps_pixellab_body_pixels(self):
        v1 = s.finish(Image.new("RGBA", (64, 96), (70, 80, 100, 255)))
        out = s.polish_slim(v1)
        px = out.load()
        self.assertEqual(px[32, 80], (70, 80, 100, 255))       # the pole's body keeps PixelLab's pixel
        self.assertEqual(px[34, 80], s.EDGE_DEEP)
        self.assertEqual(px[28, 80][3], 0)                     # v1's wider post is gone
        self.assertEqual(px[32, 32], s.FACE)
        self.assertEqual(failed_checks(out), [])
        self.assertEqual(s.roles("slim").get("other"), None)

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
