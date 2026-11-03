#!/usr/bin/env python3
"""Runs the GUT test scripts in several headless Godot processes at once (T-487).

Called by game/tools/run_tests.sh (the one entry point) after the project import; run it through
that script. Standard library only.

  python run_tests_parallel.py --jobs N [--limit SECONDS] [--list] [--timings]

- Finds every game/tests/**/test_*.gd (the same files .gutconfig.json makes GUT run).
- Splits them into N shards, balanced by each script's last known time (game/tools/test_times.json,
  falling back to file size for a new script), and starts one Godot process per shard with
  -gtest=<its scripts>. Each process has its own process id, so RunPaths gives it its own user://
  test folder (tests/helpers/run_paths.gd) and no two processes touch the same file.
- Prints each shard's output only when the shard failed (all of it), then one summary: the total
  scripts, tests, passes, failures and the time. Exit code 0 only if every shard passed; the first
  non-zero shard code otherwise; 124 when the time limit stopped the run; 3 when a script failed to
  parse or load (GUT itself reports success for those).
- --timings reruns nothing: it writes a per-script time table. See measure_test_times.py's idea
  below: with --timings each shard also runs with per-script timing from GUT's own output and the
  table is merged into test_times.json (only done on request, never by a normal run).
"""
import argparse
import json
import os
import re
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parent
TESTS = GAME / "tests"
TIMES_FILE = HERE / "test_times.json"


def find_scripts():
    return sorted(p.relative_to(GAME).as_posix() for p in TESTS.rglob("test_*.gd"))


def load_times():
    try:
        return json.loads(TIMES_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def weight(script, times):
    if script in times:
        return float(times[script])
    try:
        # A script with no recorded time: guess from its size, a bit above the median so it is not starved.
        return max(1.0, (GAME / script).stat().st_size / 4000.0)
    except OSError:
        return 1.0


def shard(scripts, times, n):
    """Longest-processing-time-first: each script goes to the currently lightest shard."""
    n = max(1, min(n, len(scripts)))
    shards = [[0.0, []] for _ in range(n)]
    for s in sorted(scripts, key=lambda s: -weight(s, times)):
        lightest = min(shards, key=lambda sh: sh[0])
        lightest[0] += weight(s, times)
        lightest[1].append(s)
    return [sh[1] for sh in shards if sh[1]]


class Shard:
    def __init__(self, index, scripts):
        self.index = index
        self.scripts = scripts
        self.code = None
        self.output = ""
        self.seconds = 0.0
        self.proc = None


def run_shard(sh, godot, limit_left, extra):
    start = time.time()
    gtest = ",".join("res://" + s for s in sh.scripts)
    cmd = [godot, "--headless", "--path", str(GAME), "-s", "res://addons/gut/gut_cmdln.gd", "-gexit",
           # No config file: it would add the whole tests folder to every shard. Its settings are repeated here.
           "-gconfig=", "-gtest=" + gtest, "-glog=1", "-gdisable_colors",
           "-gpre_run_script=res://tests/helpers/pre_run.gd",
           "-gpost_run_script=res://tests/helpers/post_run.gd"] + extra
    try:
        sh.proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
    except OSError as e:
        sh.code = 2
        sh.output = "Could not start Godot (%s): %s" % (godot, e) + chr(10)
        return
    out = []

    def pump():
        for line in iter(sh.proc.stdout.readline, b""):
            out.append(line)

    t = threading.Thread(target=pump, daemon=True)
    t.start()
    try:
        sh.proc.wait(timeout=limit_left)
        sh.code = sh.proc.returncode
    except subprocess.TimeoutExpired:
        kill(sh.proc)
        sh.code = 124
    t.join(timeout=10)
    sh.output = b"".join(out).decode("utf-8", "replace")
    sh.seconds = time.time() - start


def kill(proc):
    if proc.poll() is None:
        if os.name == "nt":
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)], capture_output=True)
        else:
            proc.kill()


def count(output, label):
    m = re.search(r"^\s*" + label + r"\s+(\d+)\s*$", output, re.M)
    return int(m.group(1)) if m else 0


def measure(scripts, godot, jobs, limit):
    """Times each script in its own Godot process (about 3 s of that is start-up) and saves the table."""
    results = {}
    queue = list(scripts)
    lock = threading.Lock()

    def worker():
        while True:
            with lock:
                if not queue:
                    return
                s = queue.pop()
            sh = Shard(0, [s])
            run_shard(sh, godot, limit, [])
            with lock:
                results[s] = round(sh.seconds, 1)
                print("%6.1f s  exit %s  %s" % (sh.seconds, sh.code, s), flush=True)

    ts = [threading.Thread(target=worker) for _ in range(jobs)]
    for t in ts:
        t.start()
    for t in ts:
        t.join()
    TIMES_FILE.write_text(json.dumps(dict(sorted(results.items())), indent=1) + "\n", encoding="utf-8")
    print("\nWrote %s (%d scripts, %.0f s of work in total)" % (TIMES_FILE, len(results), sum(results.values())))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=0)
    ap.add_argument("--limit", type=float, default=1500)
    ap.add_argument("--list", action="store_true", help="print the shards and exit")
    ap.add_argument("--measure", action="store_true",
                    help="run every script alone (--jobs at a time), print the slowest and write test_times.json")
    ap.add_argument("extra", nargs="*", help="extra GUT arguments for every shard")
    a = ap.parse_args()

    godot = os.environ.get("GODOT_BIN")
    if not godot:
        print("GODOT_BIN is not set.", file=sys.stderr)
        return 2
    scripts = find_scripts()
    times = load_times()
    jobs = a.jobs if a.jobs > 0 else min(12, os.cpu_count() or 4)
    shards = [Shard(i + 1, s) for i, s in enumerate(shard(scripts, times, jobs))]
    if a.measure:
        return measure(scripts, godot, jobs, a.limit)
    if a.list:
        for sh in shards:
            print("shard %d: %d scripts, ~%.0f s" % (sh.index, len(sh.scripts), sum(weight(s, times) for s in sh.scripts)))
        return 0

    print("Running %d test scripts in %d parallel Godot processes." % (len(scripts), len(shards)), flush=True)
    start = time.time()
    threads = []
    for sh in shards:
        t = threading.Thread(target=run_shard, args=(sh, godot, a.limit, a.extra))
        t.start()
        threads.append(t)
    for t in threads:
        t.join()
    total = time.time() - start

    timed_out = any(sh.code == 124 for sh in shards)
    code = 0
    for sh in shards:
        c = sh.code
        if c == 0 and re.search(r"Parse Error|Failed to load script", sh.output):
            sh.output += "\nA script failed to parse or load (see SCRIPT ERROR above). Treating the run as failed.\n"
            c = 3
        if c == 0 and "Tests" not in sh.output:
            sh.output += "\nGUT printed no summary for this shard. Treating the run as failed.\n"
            c = 4
        sh.code = c
        if c != 0:
            print("\n===== shard %d FAILED (exit %d), %d scripts =====" % (sh.index, c, len(sh.scripts)))
            print(sh.output)
            if code == 0:
                code = c

    totals = {k: sum(count(sh.output, k) for sh in shards) for k in ("Scripts", "Tests", "Passing Tests", "Failing Tests", "Risky/Pending")}
    print("\n=== Summary of %d parallel processes (%.0f s; slowest process %.0f s) ===" % (
        len(shards), total, max(sh.seconds for sh in shards)))
    print("Scripts          %d" % totals["Scripts"])
    print("Tests            %d" % totals["Tests"])
    print("Passing Tests    %d" % totals["Passing Tests"])
    print("Failing Tests    %d" % totals["Failing Tests"])
    print("Risky/Pending    %d" % totals["Risky/Pending"])
    if timed_out:
        print("TIME LIMIT: the test run went past %d seconds and was stopped (set GUT_TIME_LIMIT to change the limit). Treating the run as failed." % a.limit, file=sys.stderr)
        return 124
    return code


if __name__ == "__main__":
    sys.exit(main())
