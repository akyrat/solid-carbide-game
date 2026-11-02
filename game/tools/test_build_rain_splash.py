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


def frame_pixels_of(sheet, f):
    return [(x, y, sheet.getpixel((f * b.FRAME_W + x, y))) for y in range(b.FRAME_H)
            for x in range(b.FRAME_W) if sheet.getpixel((f * b.FRAME_W + x, y))[3]]


def test_v2_fade_has_three_tones_darkest_on_far_edge():
    f4 = frame_pixels_of(b.build_sheet(2), 3)
    tones = {p for _, _, p in f4}
    assert len(tones) == 3
    darkest = min(tones, key=lambda p: sum(p[:3]))
    top = min(y for _, y, _ in f4)
    assert all(p == darkest for x, y, p in f4 if y == top)
    assert sum(darkest[:3]) < sum(b.PALETTE["8"][:3])


def test_v4_frame1_is_small_dot_with_tiny_ring():
    f1 = frame_pixels(0)
    assert 6 <= len(f1) <= 8
    assert any(sum(p[:3]) > 700 for x, y, p in f1 if x in (5, 6))


def test_v4_fade_keeps_darkest_far_edge_and_two_dim_droplets():
    f4 = frame_pixels(3)
    ring_top = [p for x, y, p in f4 if y == 4 and x in (4, 7)]
    assert ring_top == [b.PALETTE["9"]] * 2
    drops = [(x, y) for x, y, p in f4 if p == b.PALETTE["4"]]
    assert len(drops) == 2
    assert len({p for _, _, p in f4}) == 4


def test_v1_still_builds_unchanged_frame4():
    v1 = b.build_sheet(1)
    assert v1.getpixel((36 + 4, 4)) == b.PALETTE["8"]
    assert SHEET.getpixel((36 + 4, 4)) == b.PALETTE["9"]


def test_v3_frame1_is_dot_inside_tiny_ring():
    px = {(x, y): p for x, y, p in frame_pixels_of(b.build_sheet(3), 0)}
    xs = [x for x, _ in px]
    ys = [y for _, y in px]
    assert max(xs) - min(xs) + 1 == 6 and max(ys) - min(ys) + 1 == 3
    assert (5, 6) in px and (6, 6) in px          # the bright dot in the middle
    assert (4, 6) not in px and (7, 6) not in px  # gap between dot and ring sides
    assert sum(px[(5, 6)][:3]) > 700              # dot is near white


def test_crown_has_2_to_4_droplets_detached_from_ring():
    drops = [(x, y) for x, y, _ in frame_pixels(1) if y <= 2]
    assert 2 <= len(drops) <= 4


def test_frame3_has_1_or_2_falling_droplets_above_ring():
    drops = [(x, y) for x, y, _ in frame_pixels(2) if y < 4]
    assert 1 <= len(drops) <= 2


def test_v2_still_builds_old_frame1():
    assert b.build_sheet(2).getpixel((4, 6)) == b.PALETTE["4"]


def test_ascii_map_matches_sheet():
    text = b.ascii_map(3)
    assert text.count("frame ") == 4 and "....8888...." in text
    assert "....9..9.4.." in b.ascii_map(4)


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} passed")
