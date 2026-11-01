"""Tests for analyse_perf.py (task T-468) on a small made-up recording in the recorder's format."""
import io
import json
import tempfile
import unittest
from pathlib import Path

import analyse_perf as ap

ZONES = ["frame", "physics_step", "minions.walk", "nav.find_path", "render", "perf.recorder"]
SPIKES = {300: 30000, 450: 32000}  # frame -> nav.find_path usec


def write_recording(folder: Path) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    header = ["frame", "wall_s", "run_s", "paused", "frame_ms", "zone_calls", "fps", "draw_calls", "nodes",
              "pipeline_canvas", "minions", "projectiles", "coins", "zones"]
    lines = [",".join(header)]
    for i, z in enumerate(ZONES):
        lines.append(f"#zone,{i},{z}")
    wall = 0.0
    for f in range(600):
        minions = f // 3  # 0 to 199
        walk = 20 * minions
        path = SPIKES.get(f, 100)
        render = 1500
        rec = 150
        step = walk + path + 200
        frame_us = 16700 if f not in SPIKES else 16700 + path
        zones = [
            (0, frame_us, frame_us - step - render - rec, 1),
            (1, step, 200, 1),
            (2, walk, walk, minions),
            (3, path, path, 1),
            (4, render, render, 1),
            (5, rec, rec, 1),
        ]
        zt = ";".join(f"{a}:{b}:{c}:{d}" for a, b, c, d in zones if d > 0 or a == 2)
        comp = 3 if f < 450 else 4  # a running total: one new compilation at frame 450
        lines.append(",".join(str(x) for x in [f, f"{wall:.6f}", f"{300 + wall:.3f}", 0, f"{frame_us / 1000:.3f}",
                                              6 + minions, 60, 500, 900, comp, minions, 2, 5, zt]))
        if f == 299:
            lines.append(f"#marker,{f},{wall:.6f},{300 + wall:.3f},level_up,{json.dumps({'level': 3})}")
        if f == 100:
            lines.append(f"#marker,{f},{wall:.6f},{300 + wall:.3f},boss_time,{{}}")
        if f in SPIKES:
            lines.append(f"#spike,{f},{frame_us / 1000:.3f}")
        wall += frame_us / 1e6
    (folder / "frames.csv").write_text("\n".join(lines) + "\n", encoding="utf-8")
    meta = {"spike_ms": 25.0, "pair_cost_us": 1.5, "cpu": "test cpu", "physics_ticks_per_second": 50}
    (folder / "meta.json").write_text(json.dumps(meta), encoding="utf-8")
    trace = {"traceEvents": [
        {"name": "frame", "ph": "B", "ts": 0, "pid": 1, "tid": 1},
        {"name": "physics_step", "ph": "B", "ts": 1, "pid": 1, "tid": 1},
        {"name": "physics_step", "ph": "E", "ts": 5, "pid": 1, "tid": 1},
        {"name": "level_up", "ph": "i", "s": "g", "ts": 6, "pid": 1, "tid": 1},
        {"name": "frame", "ph": "E", "ts": 10, "pid": 1, "tid": 1},
    ]}
    (folder / "trace.json").write_text(json.dumps(trace), encoding="utf-8")


class AnalysePerfTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = Path(self.tmp.name) / "2026-10-31_12-00-00"
        write_recording(self.folder)
        self.rec = ap.load(self.folder)
        self.out = io.StringIO()
        self.found = ap.analyse(self.rec, top=5, out=self.out)
        self.text = self.out.getvalue()

    def tearDown(self):
        self.tmp.cleanup()

    def test_loads_frames_zones_and_markers(self):
        self.assertEqual(len(self.rec.frames), 600)
        self.assertEqual(self.rec.frames[10].zones["minions.walk"][2], 3)
        self.assertEqual([m.name for m in self.rec.markers], ["boss_time", "level_up"])

    def test_worst_spikes_with_time_in_run_and_nearby_events(self):
        worst = [f.index for f in self.found["worst"]]
        self.assertEqual(worst[:2], [450, 300])
        self.assertIn("frame 300", self.text)
        self.assertIn("at run 5:0", self.text)  # 300 s in plus about 5 s of frames: 5:05
        block = self.text[self.text.index("frame 300"):]
        block = block[:block.index("\n\n") if "\n\n" in block else len(block)]
        self.assertIn("level_up(level=3)", block)
        self.assertIn("nav.find_path", block)

    def test_zone_time_in_spike_frames_against_normal_frames(self):
        self.assertIn("ZONES IN SPIKE FRAMES AGAINST NORMAL FRAMES", self.text)
        top = self.found["zone_rows"][0]
        self.assertEqual(top[1], "nav.find_path")
        self.assertAlmostEqual(top[2], 31.0, delta=0.1)  # mean ms in the two spikes
        self.assertAlmostEqual(top[3], 0.1, delta=0.01)  # in normal frames

    def test_zones_that_grow_with_the_minions(self):
        names = [g[1] for g in self.found["growth"]]
        self.assertEqual(names[0], "minions.walk")
        self.assertNotIn("nav.find_path", names)
        self.assertIn("+ 2.000 ms/100", self.text)  # 20 usec a minion

    def test_ranked_causes_start_with_the_real_one(self):
        self.assertEqual(self.found["causes"][0][1], "nav.find_path")
        self.assertIn("LIKELY CAUSES", self.text)
        self.assertNotIn("1. perf.recorder", self.text)

    def test_new_pipeline_compilations_are_the_change_not_the_total(self):
        block = self.text[self.text.index("frame 450"):]
        self.assertIn("NEW PIPELINE COMPILATIONS 1", block[:block.index("\n\n")])
        block = self.text[self.text.index("frame 300"):]
        self.assertNotIn("PIPELINE", block[:block.index("\n\n")])

    def test_check_trace(self):
        ok, msg = ap.check_trace(self.folder / "trace.json")
        self.assertTrue(ok, msg)
        bad = Path(self.tmp.name) / "bad.json"
        bad.write_text(json.dumps({"traceEvents": [
            {"name": "a", "ph": "B", "ts": 0}, {"name": "b", "ph": "B", "ts": 1},
            {"name": "a", "ph": "E", "ts": 2}, {"name": "b", "ph": "E", "ts": 3}]}), encoding="utf-8")
        ok, msg = ap.check_trace(bad)
        self.assertFalse(ok)
        self.assertIn("ends while", msg)
        cut = Path(self.tmp.name) / "cut.json"
        cut.write_text('{"traceEvents":[\n{"name":"a","ph":"B","ts":0},\n{"name":"a","ph":"E","ts":1}', encoding="utf-8")
        ok, msg = ap.check_trace(cut)
        self.assertTrue(ok, "a trace cut short when the game closed is still read")

    def test_latest_recording_and_main(self):
        older = Path(self.tmp.name) / "2026-10-30_09-00-00"
        write_recording(older)
        self.assertEqual(ap.latest_recording(Path(self.tmp.name)), self.folder)
        buf = io.StringIO()
        import contextlib
        with contextlib.redirect_stdout(buf):
            code = ap.main([str(self.folder), "--top", "2", "--check-trace"])
        self.assertEqual(code, 0)
        self.assertIn("trace OK", buf.getvalue())

    def test_a_line_cut_short_is_skipped(self):
        with open(self.folder / "frames.csv", "a", encoding="utf-8") as f:
            f.write("600,10.0,310.0,0,16.7")
        rec = ap.load(self.folder)
        self.assertEqual(len(rec.frames), 600)


if __name__ == "__main__":
    unittest.main()
