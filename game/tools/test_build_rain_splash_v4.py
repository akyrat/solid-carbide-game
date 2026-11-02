"""Tests for build_rain_splash_v4.py (T-509). Run: python game/tools/test_build_rain_splash_v4.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_rain_splash_v2 as v2  # noqa: E402
import build_rain_splash_v3 as v3  # noqa: E402
import build_rain_splash_v4 as b  # noqa: E402

SHEET = b.build_sheet()
FACTS = v2.facts(SHEET)


def px(f, x, y):
    return SHEET.getpixel((f * 12 + x, y))


def test_basics():
    assert SHEET.size == (48, 8) and SHEET.mode == "RGBA"
    assert FACTS["colours_in_sheet"] <= 12
    for fr in FACTS["frames"]:
        assert fr["semi_transparent"] == 0 and fr["corners_clear"] and fr["bottom_centre_x5_or_6"]
    for fr in FACTS["frames"][:3]:
        assert fr["bottom_row_symmetric_about_5.5"]


def test_frame1_small_dot_with_tiny_ring():
    fr = FACTS["frames"][0]
    assert 5 <= fr["opaque"] <= 8
    assert fr["ring_box_rows_4_to_7"] == "4x3"
    assert sum(px(0, 5, 6)[:3]) > 700  # near-white dot
    assert px(0, 5, 5) == b.PALETTE["9"]  # darkest far edge


def test_growth_then_fade():
    n = [fr["opaque"] for fr in FACTS["frames"]]
    assert n[0] < n[1] <= n[2] and n[3] < n[2]
    assert n[1] - n[0] >= 8


def test_crown_droplets_visible_above_ring():
    above = [(x, y) for y in range(4) for x in range(12) if px(1, x, y)[3]]
    assert len(above) >= 3
    assert all(sum(px(1, x, y)[:3]) > 650 for x, y in above)  # bright, read on dark streets


def test_frames_2_to_4_unchanged_from_v3():
    old = v3.build_sheet()
    for x in range(12, 48):
        for y in range(8):
            assert SHEET.getpixel((x, y)) == old.getpixel((x, y))


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} passed")
