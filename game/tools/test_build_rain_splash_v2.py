"""Tests for build_rain_splash_v2.py (T-509). Run: python game/tools/test_build_rain_splash_v2.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_rain_splash_v2 as b  # noqa: E402

SHEET = b.build_sheet()
FACTS = b.facts(SHEET)


def test_size_alpha_corners():
    assert SHEET.size == (48, 8) and SHEET.mode == "RGBA"
    for fr in FACTS["frames"]:
        assert fr["semi_transparent"] == 0 and fr["corners_clear"]


def test_colours():
    assert FACTS["colours_in_sheet"] <= 12
    for r, g, bl, _ in {p for p in SHEET.getdata() if p[3]}:
        if min(r, g, bl) < 240:
            assert bl > r and bl >= g >= r  # cool blues only, no green or yellow


def test_every_frame_bottom_centre_and_symmetric_where_whole():
    for fr in FACTS["frames"]:
        assert fr["bottom_centre_x5_or_6"], fr
    for fr in FACTS["frames"][:3]:
        assert fr["bottom_row_symmetric_about_5.5"], fr


def test_frame3_ring_is_10_by_4_with_no_2x2_blocks():
    assert FACTS["frames"][2]["ring_box_rows_4_to_7"] == "10x4"
    for y in range(4, 7):
        for x in range(11):
            block = [SHEET.getpixel((24 + x + dx, y + dy))[3] for dx in (0, 1) for dy in (0, 1)]
            assert not all(block), (x, y)


def test_frame4_broken_dark_three_tones():
    fr = FACTS["frames"][3]
    assert fr["opaque"] <= 10 and fr["colours"] == 3
    assert fr["opaque"] < FACTS["frames"][2]["opaque"]
    assert max(sum(SHEET.getpixel((36 + x, y))[:3]) for x in range(12) for y in range(8)
               if SHEET.getpixel((36 + x, y))[3]) < 500


def test_crown_droplets_above_ring():
    assert FACTS["frames"][1]["pixels_above_ring"] >= 3
    assert 1 <= sum(1 for y in range(4) for x in range(12) if SHEET.getpixel((24 + x, y))[3]) <= 2


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} passed")
