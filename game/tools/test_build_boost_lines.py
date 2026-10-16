"""Tests for build_boost_lines.py (task T-009): the game sheet follows the rules
and is rebuilt identically from the archived PixelLab frames."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from PIL import Image, ImageChops

import build_boost_lines as bbl


def test_committed_sheet_passes_the_rules():
    rec = json.loads(bbl.RECORD.read_text(encoding="utf-8"))
    res = bbl.check_sheet(Image.open(bbl.SHEET).convert("RGBA"), rec["frames"])
    assert res["pass"], res
    assert res["semi_transparent_pixels"] == 0
    assert res["closest_to_redgull_red"] > 0.5
    assert rec["frames"] == 5 and rec["directions"] == 16 and rec["frame_size"] == 80


def test_record_points_at_archived_pixellab_frames():
    rec = json.loads(bbl.RECORD.read_text(encoding="utf-8"))
    for src, pl in zip(rec["sources"], rec["pixellab_records"]):
        assert (bbl.REPO / src).is_file()
        pl_rec = json.loads((bbl.REPO / pl).read_text(encoding="utf-8"))
        assert pl_rec["endpoint"] == "/animate-with-text-v3"


def test_build_reproduces_the_committed_sheet(tmp_path, monkeypatch):
    committed = Image.open(bbl.SHEET).convert("RGBA")
    rec = json.loads(bbl.RECORD.read_text(encoding="utf-8"))
    ids = [int(Path(s).stem.split("_")[3]) for s in rec["sources"]]
    monkeypatch.setattr(bbl, "OUT_DIR", tmp_path)
    monkeypatch.setattr(bbl, "SHEET", tmp_path / "boost_lines.png")
    monkeypatch.setattr(bbl, "RECORD", tmp_path / "boost_lines.json")
    bbl.build(ids)
    rebuilt = Image.open(tmp_path / "boost_lines.png").convert("RGBA")
    assert rebuilt.size == committed.size
    assert ImageChops.difference(rebuilt, committed).getbbox() is None


def test_rotation_adds_no_colours():
    im = bbl.draw_first_frame()
    before = {p[:3] for p in im.getdata() if p[3]}
    for deg in (0, 22.5, 45, 90, 157.5):
        turned = bbl.rotate_nearest(im, deg)
        after = {p[:3] for p in turned.getdata() if p[3]}
        assert after <= before and after
        assert all(p[3] in (0, 255) for p in turned.getdata())


def test_first_frame_matches_the_one_sent_to_pixellab():
    sent = Image.open(bbl.FIRST_FRAME).convert("RGBA")
    assert ImageChops.difference(bbl.draw_first_frame(), sent).getbbox() is None


def test_rotation_turns_clockwise_on_screen():
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    im.putpixel((60, 32), (255, 255, 255, 255))  # a dot to the right of centre
    turned = bbl.rotate_nearest(im, 90)  # clockwise on screen (y down): right -> down
    xs = [(x, y) for y in range(bbl.CELL) for x in range(bbl.CELL) if turned.getpixel((x, y))[3]]
    assert xs and all(y > bbl.CELL / 2 + 20 for _, y in xs)
