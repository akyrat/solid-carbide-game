"""Tests for build_rain_splash_v3.py (T-509). Run: python game/tools/test_build_rain_splash_v3.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import build_rain_splash_v2 as v2  # noqa: E402
import build_rain_splash_v3 as b  # noqa: E402

SHEET = b.build_sheet()
FACTS = v2.facts(SHEET)


def px(f, x, y):
    return SHEET.getpixel((f * 12 + x, y))


def opaque(f):
    return [(x, y) for y in range(8) for x in range(12) if px(f, x, y)[3]]


def test_size_alpha_corners_colours():
    assert SHEET.size == (48, 8) and SHEET.mode == "RGBA"
    assert FACTS["colours_in_sheet"] <= 12
    for fr in FACTS["frames"]:
        assert fr["semi_transparent"] == 0 and fr["corners_clear"]
    for r, g, bl, _ in {p for p in SHEET.getdata() if p[3]}:
        if min(r, g, bl) < 240:
            assert bl > r and bl >= g >= r  # cool blues only


def test_impact_bottom_centre_and_symmetric():
    for fr in FACTS["frames"]:
        assert fr["bottom_centre_x5_or_6"], fr
    for fr in FACTS["frames"][:3]:
        assert fr["bottom_row_symmetric_about_5.5"], fr


def test_frame1_is_clearer():
    assert FACTS["frames"][0]["opaque"] >= 12


def test_frame3_ring_10_by_4():
    assert FACTS["frames"][2]["ring_box_rows_4_to_7"] == "10x4"


def test_far_edge_darkest_in_ring_frames():
    dark = b.PALETTE["9"]
    far_row = {0: 5, 1: 5, 2: 4}  # the ring's far (top) edge row in each frame
    for f in range(3):
        far = [px(f, x, far_row[f]) for x in range(12) if px(f, x, far_row[f])[3]]
        assert far and all(p == dark for p in far[1:-1]), f
        near = [sum(px(f, x, 7)[:3]) for x in range(12) if px(f, x, 7)[3]]
        assert min(near) > sum(dark[:3])


def test_droplets_are_separate():
    # every pixel above row 4 in frames 2 and 3 has no opaque 4-neighbour (single distinct droplets)
    for f in (1, 2):
        for x, y in opaque(f):
            if y < 4:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 12 and 0 <= ny < 8:
                        assert not px(f, nx, ny)[3], (f, x, y)


def test_frame4_fading():
    fr = FACTS["frames"][3]
    assert fr["colours"] == 3 and fr["opaque"] <= 10
    assert max(sum(px(3, x, y)[:3]) for x, y in opaque(3)) < 500


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} passed")
