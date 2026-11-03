"""Tests for run_tests_parallel.py (task T-487): sharding, script discovery and the counting of GUT's summary."""
import unittest

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


if __name__ == "__main__":
    unittest.main()
