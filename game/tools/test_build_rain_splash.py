"""Tests for build_rain_splash.py (T-509). Run: python -m pytest game/tools/test_build_rain_splash.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_rain_splash as b  # noqa: E402

SHEET = b.build_sheet()


def frame_pixels(f):
    out = []
    for y in range(b.FRAME_H):
        for x in range(b.FRAME_W):
            p = SHEET.getpixel((f * b.FRAME_W + x, y))
            if p[3]:
                out.append((x, y, p))
    return out


def test_size_and_mode():
    assert SHEET.size == (48, 8) and SHEET.mode == "RGBA"


def test_alpha_is_binary_and_corners_clear():
    for p in SHEET.getdata():
        assert p[3] in (0, 255)
    for f in range(4):
        for x, y in ((0, 0), (11, 0), (0, 7), (11, 7)):
            assert SHEET.getpixel((f * 12 + x, y))[3] == 0


def test_colour_count_and_no_greenbull():
    cols = {p for p in SHEET.getdata() if p[3]}
    assert len(cols) <= 12
    for r, g, bl, _ in cols:
        if min(r, g, bl) >= 240:
            continue  # near white
        assert bl >= g >= r and bl > r  # cool blues only, no green or yellow


def test_every_frame_touches_bottom_row_centre_area():
    for f in range(3):
        bottom = [x for x, y, _ in frame_pixels(f) if y == 7]
        assert 5 in bottom or 6 in bottom


def test_frame3_ring_is_widest_10_by_4():
    xs = [x for x, y, _ in frame_pixels(2) if y >= 4]
    ys = [y for x, y, _ in frame_pixels(2) if y >= 4]
    assert max(xs) - min(xs) + 1 == 10 and max(ys) - min(ys) + 1 == 4


def test_fading_frame_has_fewest_and_darkest_pixels():
    counts = [len(frame_pixels(f)) for f in range(4)]
    assert counts[3] < counts[2] and counts[3] <= 10
    assert max(sum(p[:3]) for _, _, p in frame_pixels(3)) < 500


def test_crown_has_droplets_above_ring():
    assert len([1 for x, y, _ in frame_pixels(1) if y <= 2]) >= 2


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} passed")
