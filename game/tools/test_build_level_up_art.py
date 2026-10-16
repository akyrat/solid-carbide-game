"""Tests for build_level_up_art.py (task T-140)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_level_up_art as art  # noqa: E402


def test_every_piece_passes_the_rules(tmp_path, monkeypatch):
    monkeypatch.setattr(art, "OUT", tmp_path)
    art.build()
    for name in art.FILES:
        results, size = art.check_png(tmp_path / (name + ".png"))
        assert all(r[1] for r in results), (name, results)
        assert (tmp_path / (name + ".json")).exists()


def test_sizes(tmp_path, monkeypatch):
    monkeypatch.setattr(art, "OUT", tmp_path)
    art.build()
    sizes = {n: art.check_png(tmp_path / (n + ".png"))[1] for n in art.FILES}
    assert sizes["card_frame"] == (180, 150)
    assert sizes["header_ribbon"] == (380, 44)
    assert sizes["gift_pack_emblem"] == (128, 128)


def test_build_is_byte_identical(tmp_path, monkeypatch):
    monkeypatch.setattr(art, "OUT", tmp_path / "a")
    art.build()
    monkeypatch.setattr(art, "OUT", tmp_path / "b")
    art.build()
    for name in art.FILES:
        assert (tmp_path / "a" / (name + ".png")).read_bytes() == (tmp_path / "b" / (name + ".png")).read_bytes()


def test_raw_gift_box_is_left_alone():
    before = art.RAW_BOX.read_bytes()
    art.gift_pack_emblem()
    assert art.RAW_BOX.read_bytes() == before
