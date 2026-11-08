"""Tests for run_tests_parallel.py (task T-487): sharding, script discovery and the counting of GUT's summary."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import run_tests_parallel as rp


class ShardTests(unittest.TestCase):
    def test_every_script_lands_in_exactly_one_shard(self):
        scripts = ["tests/unit/test_%d.gd" % i for i in range(37)]
        times = {s: float(i % 7 + 1) for i, s in enumerate(scripts)}
        shards = rp.shard(scripts, times, 6)
        flat = [s for sh in shards for s in sh]
        self.assertEqual(sorted(flat), sorted(scripts))
        self.assertEqual(len(flat), len(set(flat)))

    def test_shards_are_balanced_by_time(self):
        scripts = ["a", "b", "c", "d", "e", "f"]
        times = {"a": 90, "b": 30, "c": 30, "d": 30, "e": 30, "f": 30}
        shards = rp.shard(scripts, times, 2)
        loads = sorted(sum(times[s] for s in sh) for sh in shards)
        self.assertLessEqual(loads[1] - loads[0], 30)

    def test_more_jobs_than_scripts_makes_one_shard_per_script(self):
        self.assertEqual(len(rp.shard(["a", "b"], {"a": 1, "b": 1}, 8)), 2)

    def test_finds_the_real_test_scripts(self):
        found = rp.find_scripts()
        self.assertTrue(found)
        self.assertTrue(all(s.startswith("tests/") and s.rsplit("/", 1)[1].startswith("test_") for s in found))

    def test_count_reads_the_gut_summary(self):
        out = "Totals\nScripts          3\nTests            41\nPassing Tests    40\nFailing Tests    1\n"
        self.assertEqual(rp.count(out, "Tests"), 41)
        self.assertEqual(rp.count(out, "Passing Tests"), 40)
        self.assertEqual(rp.count(out, "Failing Tests"), 1)
        self.assertEqual(rp.count(out, "Risky/Pending"), 0)


class RecordTests(unittest.TestCase):
    TOTALS = {"Scripts": 5, "Tests": 41, "Passing Tests": 40, "Failing Tests": 1, "Risky/Pending": 2}

    def test_record_is_written_with_the_run_numbers(self):
        import json, tempfile
        from pathlib import Path
        path = Path(tempfile.mkdtemp()) / "rec.json"
        rec = rp.write_record(274.6, 12, self.TOTALS, False, path)
        on_disk = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(rec, on_disk)
        self.assertEqual(on_disk["wall_seconds"], 274.6)
        self.assertEqual(on_disk["processes"], 12)
        self.assertEqual((on_disk["scripts"], on_disk["tests"], on_disk["passing"], on_disk["failing"], on_disk["risky_pending"]), (5, 41, 40, 1, 2))
        self.assertIs(on_disk["passed"], False)
        self.assertTrue(on_disk["time"])

    def test_record_file_is_not_a_shard_weight_and_comment_keys_are_skipped(self):
        self.assertNotEqual(rp.RECORD_FILE, rp.TIMES_FILE)
        self.assertTrue(all(not k.startswith("_") for k in rp.load_times()))
        self.assertIn("SINGLE-PROCESS", rp.TIMES_NOTE)

    def test_shards_ignore_comment_keys(self):
        scripts = ["a", "b", "c"]
        times = {"a": 5, "b": 5, "c": 5, "_note": "x"}
        self.assertEqual(rp.shard(scripts, times, 3), rp.shard(scripts, {k: v for k, v in times.items() if k != "_note"}, 3))

    def test_final_line_names_wall_time_and_processes(self):
        self.assertEqual(rp.final_line(True, 0, 274.6, 12), "TESTS PASSED (275 s on 12 processes)")
        line = rp.final_line(False, 124, 1500.2, 12)
        self.assertTrue(line.startswith("TESTS FAILED (exit 124"))
        self.assertIn("12 processes", line)


if __name__ == "__main__":
    unittest.main()
