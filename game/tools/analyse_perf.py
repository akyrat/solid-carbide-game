"""Analyses a run's performance recording (task T-468) and prints what causes its frame drops.

A recording is a folder written by the game's perf recorder (game/scripts/perf/perf_recorder.gd)
when the game runs with --record-perf or SC_RECORD_PERF=1: frames.csv, trace.json, meta.json.
How to record and read it: game/docs/game-loop/perf-recorder.md.

Usage, from the repo root:
    python game/tools/analyse_perf.py                 # the newest recording in game/perf/
    python game/tools/analyse_perf.py game/perf/2026-10-31_15-10-00
    python game/tools/analyse_perf.py FOLDER --top 15 --spike-ms 25 --window 1.0
    python game/tools/analyse_perf.py FOLDER --check-trace   # also checks trace.json's nesting

It prints, in order: the recording and its frame times; the recorder's own overhead; the worst
spikes with their time in the run, the engine phases, the zones that took longer than usual and
the events around them; each zone's time in spike frames against normal frames; the zones that
grow with the minion count; how often each kind of event is followed by a spike; and a short
ranked list of likely causes.
"""
from __future__ import annotations

import argparse
import json
import math
import statistics
import sys
from dataclasses import dataclass, field
from pathlib import Path

PHASES = ["physics_step", "physics.scripts", "physics.engine", "process", "after_process", "render", "wait"]
PHASE_LABEL = {
    "physics.scripts": "physics scripts",
    "physics.engine": "physics engine",
    "process": "process scripts",
    "after_process": "deferred (draws, frees)",
    "render": "render",
    "wait": "wait (vsync, input)",
}
# Zones that are containers, not causes, when ranking (their self time is what is left over).
CONTAINERS = {"frame", "physics_step"}
# The recorder's own zone: reported on its own, never ranked as a cause of the game's drops.
RECORDER = "perf.recorder"
EXPLAIN = {
    "physics.engine": "Godot's physics server step, deferred calls and frees after the physics scripts",
    "physics.scripts": "_physics_process code that has no zone of its own",
    "process": "_process code that has no zone of its own",
    "after_process": "deferred calls (custom _draw() of nodes without a zone, queue_free, call_deferred)",
    "render": "the renderer (draw calls, canvas items, textures uploaded, shaders compiled)",
    "wait": "waiting on vsync / the GPU / the OS, or input handling, between frames",
    "perf.recorder": "the recorder itself",
}
COUNT_COLS = ["minions", "projectiles", "coins", "molotov_fires", "burning_enemies", "meteor_warnings",
              "boulders_standing", "gift_packages", "popups", "drift_smoke_puffs", "drift_mark_pieces"]


@dataclass
class Frame:
    index: int
    wall_s: float
    run_s: float
    paused: bool
    ms: float
    zone_calls: int
    values: dict
    zones: dict = field(default_factory=dict)  # name -> (incl_us, self_us, calls)

    def self_ms(self, zone: str) -> float:
        z = self.zones.get(zone)
        return z[1] / 1000.0 if z else 0.0

    def calls(self, zone: str) -> int:
        z = self.zones.get(zone)
        return z[2] if z else 0


@dataclass
class Marker:
    frame: int
    wall_s: float
    run_s: float
    name: str
    args: dict


@dataclass
class Recording:
    folder: Path
    meta: dict
    header: list
    frames: list
    markers: list
    zone_names: dict


def latest_recording(base: Path) -> Path | None:
    if not base.is_dir():
        return None
    dirs = sorted([d for d in base.iterdir() if d.is_dir() and (d / "frames.csv").exists()])
    return dirs[-1] if dirs else None


def load(folder: Path) -> Recording:
    meta = {}
    if (folder / "meta.json").exists():
        try:
            meta = json.loads((folder / "meta.json").read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            meta = {}
    header: list = []
    frames: list = []
    markers: list = []
    names: dict = {}
    with open(folder / "frames.csv", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            if not line:
                continue
            if not header:
                header = line.split(",")
                continue
            if line.startswith("#zone,"):
                _, zid, zname = line.split(",", 2)
                names[int(zid)] = zname
                continue
            if line.startswith("#marker,"):
                parts = line.split(",", 5)
                try:
                    args = json.loads(parts[5]) if len(parts) > 5 else {}
                except json.JSONDecodeError:
                    args = {}
                markers.append(Marker(int(parts[1]), float(parts[2]), float(parts[3]), parts[4], args))
                continue
            if line.startswith("#"):
                continue
            cols = line.split(",")
            if len(cols) != len(header):
                continue  # a line cut short when the game closed
            row = dict(zip(header, cols))
            values = {}
            for k in header[6:-1]:
                try:
                    values[k] = float(row[k])
                except ValueError:
                    values[k] = -1.0
            fr = Frame(int(row["frame"]), float(row["wall_s"]), float(row["run_s"]), row["paused"] == "1",
                       float(row["frame_ms"]), int(row["zone_calls"]), values)
            zt = row["zones"]
            if zt:
                for part in zt.split(";"):
                    zid, incl, slf, calls = part.split(":")
                    fr.zones[int(zid)] = (int(incl), int(slf), int(calls))
            frames.append(fr)
    # Zone ids to names (names may be listed after their first use).
    for fr in frames:
        fr.zones = {names.get(k, f"zone#{k}"): v for k, v in fr.zones.items()}
    return Recording(folder, meta, header, frames, markers, names)


def pct(values: list, p: float) -> float:
    if not values:
        return 0.0
    s = sorted(values)
    k = min(len(s) - 1, max(0, int(round(p / 100.0 * (len(s) - 1)))))
    return s[k]


def mmss(run_s: float) -> str:
    if run_s < 0:
        return "  -  "
    m = int(run_s // 60)
    return f"{m}:{run_s - 60 * m:04.1f}"


def check_trace(path: Path) -> tuple[bool, str]:
    """True when trace.json is valid JSON whose B/E events nest: every begin has its end, in order."""
    text = path.read_text(encoding="utf-8")
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        try:
            data = json.loads(text.rstrip().rstrip(",") + "\n]}")  # cut short when the game closed
        except json.JSONDecodeError as e:
            return False, f"not JSON: {e}"
    events = data.get("traceEvents", data if isinstance(data, list) else [])
    stack: list = []
    last = -math.inf
    counts: dict = {}
    for e in events:
        ph = e.get("ph")
        counts[ph] = counts.get(ph, 0) + 1
        if ph not in ("B", "E"):
            continue
        ts = float(e["ts"])
        if ts < last:
            return False, f"time goes back at {e}"
        last = ts
        if ph == "B":
            stack.append(e)
        else:
            if not stack:
                return False, f"an end with no begin: {e}"
            b = stack.pop()
            if b["name"] != e["name"]:
                return False, f"{e['name']} ends while {b['name']} is open"
    if stack:
        return False, f"{len(stack)} zones never end"
    summary = ", ".join(f"{k}: {v}" for k, v in sorted(counts.items(), key=lambda kv: str(kv[0])))
    return True, f"trace OK ({summary})"


def linear_fit(xs: list, ys: list) -> tuple[float, float]:
    """Slope and correlation of ys against xs."""
    n = len(xs)
    if n < 3:
        return 0.0, 0.0
    mx = sum(xs) / n
    my = sum(ys) / n
    sxx = sum((x - mx) ** 2 for x in xs)
    syy = sum((y - my) ** 2 for y in ys)
    sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    if sxx <= 0:
        return 0.0, 0.0
    slope = sxy / sxx
    r = sxy / math.sqrt(sxx * syy) if syy > 0 else 0.0
    return slope, r


def analyse(rec: Recording, top: int = 10, spike_ms: float | None = None, window: float = 1.0,
            out=None) -> dict:
    """Prints the analysis; returns the main findings (for tests)."""
    out = out if out is not None else sys.stdout
    def p(*a):
        print(*a, file=out)

    frames = [f for f in rec.frames if f.index > 0]  # frame 0 holds the run's set-up
    if not frames:
        p("No frames in", rec.folder)
        return {}
    threshold = spike_ms if spike_ms is not None else float(rec.meta.get("spike_ms", 25.0) or 25.0)
    ms = [f.ms for f in frames]
    spikes = [f for f in frames if f.ms >= threshold]
    normal = [f for f in frames if f.ms < threshold]
    duration = frames[-1].wall_s - frames[0].wall_s + frames[-1].ms / 1000.0
    zones = sorted({z for f in frames for z in f.zones})
    has = lambda col: col in rec.header

    p("=" * 78)
    p(f"Recording  {rec.folder}")
    m = rec.meta
    if m:
        p(f"Machine    {m.get('cpu', '?')} x{m.get('cpu_count', '?')}, {m.get('gpu', '?')}; "
          f"Godot {m.get('godot', '?')} ({m.get('renderer', '?')}), debug={m.get('debug_build', '?')}")
        p(f"Display    window {m.get('window_size', '?')}, {m.get('refresh_rate', '?')} Hz, vsync mode "
          f"{m.get('vsync_mode', '?')}, max_fps {m.get('max_fps', '?')}, physics {m.get('physics_ticks_per_second', '?')}/s")
    p(f"Frames     {len(frames)} over {duration:.1f} s; run time {mmss(frames[0].run_s)} to {mmss(frames[-1].run_s)}")
    p(f"Frame ms   mean {statistics.fmean(ms):.2f}  median {pct(ms, 50):.2f}  p95 {pct(ms, 95):.2f}  "
      f"p99 {pct(ms, 99):.2f}  max {max(ms):.2f}")
    per_min = len(spikes) / (duration / 60.0) if duration > 0 else 0.0
    p(f"Spikes     {len(spikes)} frames at {threshold:g} ms or more ({per_min:.1f} a minute); "
      f"over 50 ms: {sum(1 for x in ms if x >= 50)}; over 100 ms: {sum(1 for x in ms if x >= 100)}")

    # The recorder's own overhead.
    rec_ms = [f.self_ms("perf.recorder") for f in frames]
    pair = float(m.get("pair_cost_us", 0.0) or 0.0)
    calls = [f.zone_calls for f in frames]
    est_zones = pair * statistics.fmean(calls) / 1000.0 if calls else 0.0
    p(f"Overhead   recorder {statistics.fmean(rec_ms):.3f} ms a frame (max {max(rec_ms):.2f}); zones "
      f"{statistics.fmean(calls):.0f} calls a frame x {pair:.2f} us = ~{est_zones:.3f} ms; together "
      f"~{100.0 * (statistics.fmean(rec_ms) + est_zones) / max(statistics.fmean(ms), 0.001):.1f}% of the mean frame")
    if m.get("unbalanced_zones"):
        p(f"Warning    {m['unbalanced_zones']} zones were left open (a begin without its end)")

    # Usual cost per call of each zone (self ms, normal frames): a frame with two physics steps
    # or 300 minions is expected to spend that many calls' worth; the excess is the rest.
    per_call = {}
    for z in zones:
        tot = sum(f.self_ms(z) for f in normal)
        n = sum(f.calls(z) for f in normal)
        per_call[z] = tot / n if n else 0.0
    normal_mean = {z: (statistics.fmean([f.self_ms(z) for f in normal]) if normal else 0.0) for z in zones}

    def expected(f: Frame, z: str) -> float:
        return per_call[z] * f.calls(z)

    def excess(f: Frame) -> list:
        return sorted(((f.self_ms(z) - expected(f, z), z) for z in f.zones
                       if z not in CONTAINERS and z != RECORDER), reverse=True)

    # Pipeline (shader) compilations are running totals: per frame, the change.
    comp_cols = [c for c in rec.header if c.startswith("pipeline_")]
    comp_new: dict = {}
    prev = None
    for f in rec.frames:
        tot = sum(max(f.values.get(c, 0), 0) for c in comp_cols)
        comp_new[f.index] = max(tot - prev, 0) if prev is not None else 0
        prev = tot

    # Worst spikes.
    p("")
    p("-" * 78)
    p(f"WORST SPIKES (the {min(top, len(spikes))} longest frames; times are in the run, m:ss elapsed)")
    worst = sorted(spikes, key=lambda f: f.ms, reverse=True)[:top]
    # The zone that adds the most to each spike frame (its self time against its normal mean).
    top_contrib: dict = {}
    for f in spikes:
        adds = [(f.self_ms(z) - normal_mean[z], z) for z in f.zones if z not in CONTAINERS and z != RECORDER]
        if adds:
            z = max(adds)[1]
            top_contrib[z] = top_contrib.get(z, 0) + 1
    for f in worst:
        steps = f.calls("physics_step")
        phase_txt = ", ".join(f"{PHASE_LABEL[z]} {f.zones.get(z, (0, 0, 0))[0] / 1000.0:.1f}"
                              for z in PHASES[1:] if z in f.zones)
        p("")
        p(f"frame {f.index}  {f.ms:.1f} ms  at run {mmss(f.run_s)} (wall {f.wall_s:.2f} s){'  PAUSED' if f.paused else ''}")
        p(f"  phases (ms): {steps} physics step(s); {phase_txt}")
        p("  where the time went (self ms; in brackets what those calls usually cost):")
        own = sorted(((f.self_ms(z), z) for z in f.zones if z not in CONTAINERS), reverse=True)
        for v, z in own[:6]:
            if v < 0.05:
                break
            calls_txt = f"{f.calls(z)} calls" if f.calls(z) != 1 else "1 call"
            p(f"    {z:<32} {v:7.2f}  ({calls_txt}: usually {expected(f, z):.2f}; {v - expected(f, z):+.2f})")
        cnt = ", ".join(f"{c} {int(f.values[c])}" for c in COUNT_COLS if has(c) and f.values.get(c, -1) > 0)
        if cnt:
            p(f"  counts: {cnt}")
        mon = []
        for c in ("draw_calls", "render_objects", "nodes", "orphan_nodes", "objects", "physics_pairs"):
            if has(c):
                mon.append(f"{c} {int(f.values[c])}")
        if comp_new.get(f.index, 0) > 0:
            mon.append(f"NEW PIPELINE COMPILATIONS {int(comp_new[f.index])}")
        if mon:
            p(f"  monitors: {', '.join(mon)}")
        near = [mk for mk in rec.markers if abs(mk.wall_s - f.wall_s) <= window and not mk.name.startswith("recording_")]
        if near:
            near_txt = "; ".join(f"{mk.name}{_args(mk.args)} {mk.wall_s - f.wall_s:+.2f}s" for mk in near[:8])
            more = f" (+{len(near) - 8} more)" if len(near) > 8 else ""
            p(f"  events within {window:g} s: {near_txt}{more}")

    # Zones: spike frames against normal frames.
    p("")
    p("-" * 78)
    p("ZONES IN SPIKE FRAMES AGAINST NORMAL FRAMES (self ms a frame, mean; sorted by the difference)")
    rows = []
    for z in zones:
        sm = statistics.fmean([f.self_ms(z) for f in spikes]) if spikes else 0.0
        nm = normal_mean[z]
        sc = statistics.fmean([f.calls(z) for f in spikes]) if spikes else 0.0
        nc = statistics.fmean([f.calls(z) for f in normal]) if normal else 0.0
        rows.append((sm - nm, z, sm, nm, sc, nc))
    rows.sort(reverse=True)
    p(f"  {'zone':<32} {'spike':>8} {'normal':>8} {'diff':>8} {'calls spike/normal':>20}  top in N spikes")
    for d, z, sm, nm, sc, nc in rows[:max(top * 2, 20)]:
        p(f"  {z:<32} {sm:8.3f} {nm:8.3f} {d:+8.3f} {sc:9.1f}/{nc:<9.1f}  {top_contrib.get(z, 0)}")

    # Growth with the minion count.
    p("")
    p("-" * 78)
    growth = []
    if has("minions"):
        live = [f for f in frames if not f.paused and f.values.get("minions", -1) >= 0]
        xs = [f.values["minions"] for f in live]
        if live and max(xs) > min(xs):
            peak = max(xs)
            p(f"GROWTH WITH THE MINION COUNT (unpaused frames; {int(min(xs))} to {int(peak)} minions alive)")
            buckets: dict = {}
            for f in live:
                b = int(f.values["minions"] // 25) * 25
                buckets.setdefault(b, []).append(f)
            p(f"  {'minions':>9} {'frames':>7} {'mean ms':>8} {'p95 ms':>7} {'spikes':>7}")
            for b in sorted(buckets):
                fs = buckets[b]
                fm = [f.ms for f in fs]
                p(f"  {b:>4}-{b + 24:<4} {len(fs):7} {statistics.fmean(fm):8.2f} {pct(fm, 95):7.2f} "
                  f"{sum(1 for x in fm if x >= threshold):7}")
            fit = linear_fit(xs, [f.ms for f in live])
            p(f"  frame time grows {fit[0] * 100:.2f} ms per 100 minions (r={fit[1]:.2f})")
            # Per zone, on frames with exactly one physics step, so more steps do not pass for growth.
            one = [f for f in live if f.calls("physics_step") == 1]
            base = one if len(one) >= 50 and max(f.values["minions"] for f in one) > min(xs) else live
            bx = [f.values["minions"] for f in base]
            p(f"  zones that grow most with the minions (self ms a frame added per 100 minions; at the peak; "
              f"{'frames with one physics step' if base is one else 'all frames'}):")
            for z in zones:
                if z in CONTAINERS:
                    continue
                slope, r = linear_fit(bx, [f.self_ms(z) for f in base])
                if slope > 0 and r > 0.3:
                    growth.append((slope * peak, z, slope * 100, r))
            growth.sort(reverse=True)
            for at_peak, z, per100, r in growth[:top]:
                p(f"    {z:<32} +{per100:6.3f} ms/100  r={r:.2f}  ~{at_peak:.2f} ms at {int(peak)}")
        else:
            p("GROWTH WITH THE MINION COUNT: the count did not change in this recording")

    # Events followed by a spike.
    p("")
    p("-" * 78)
    p(f"EVENTS FOLLOWED BY A SPIKE (within {window:g} s after the event; chance = spikes' share of the time)")
    spike_times = sorted(f.wall_s for f in spikes)
    # Chance: the share of moments in the recording (every 0.1 s) with a spike within the window after.
    chance = 0.0
    if spike_times and duration > 0:
        import bisect
        t0 = frames[0].wall_s
        grid = [t0 + 0.1 * i for i in range(int(duration / 0.1) + 1)]
        hits = 0
        for t in grid:
            i = bisect.bisect_left(spike_times, t)
            if i < len(spike_times) and spike_times[i] - t <= window:
                hits += 1
        chance = hits / len(grid)
    by_kind: dict = {}
    for mk in rec.markers:
        if mk.name.startswith("recording_"):
            continue
        hit = any(0 <= t - mk.wall_s <= window for t in spike_times)
        k = by_kind.setdefault(mk.name, [0, 0])
        k[0] += 1
        k[1] += 1 if hit else 0
    event_links = []
    for name, (n, hit) in sorted(by_kind.items(), key=lambda kv: -kv[1][1] / max(kv[1][0], 1)):
        share = hit / n if n else 0.0
        flag = "  <-- more than chance" if n >= 2 and share >= max(0.5, 2 * chance) else ""
        if flag:
            event_links.append((share, name, n, hit))
        p(f"  {name:<28} {hit:4} of {n:<4} ({share * 100:3.0f}%; chance ~{chance * 100:.0f}%){flag}")

    # Likely causes.
    p("")
    p("-" * 78)
    p("LIKELY CAUSES (zones ranked by the time they add to a spike frame, then other signs)")
    causes = []
    if spikes:
        steps_sp = statistics.fmean([f.calls("physics_step") for f in spikes])
        steps_n = statistics.fmean([f.calls("physics_step") for f in normal]) if normal else 0.0
        grows = {z: (per100, r) for _, z, per100, r in growth}
        unusual: dict = {}
        for f in spikes:
            for d, z in excess(f):
                if d > 0:
                    unusual[z] = unusual.get(z, 0.0) + d / len(spikes)
        rank = 1
        for d, z, sm, nm, sc, nc in rows:
            if z == RECORDER or z in CONTAINERS or d <= 0.1 or rank > 6:
                continue
            notes = []
            if nc > 0 and sc > 1.5 * nc:
                notes.append(f"runs {sc:.1f} times a spike frame against {nc:.1f} normally")
            pc_sp = sm / sc if sc else 0.0
            if per_call.get(z, 0) > 0 and pc_sp > 1.5 * per_call[z]:
                notes.append(f"each call costs {pc_sp:.2f} ms in spikes against {per_call[z]:.2f} usually")
            if z in grows:
                notes.append(f"grows with the minions, +{grows[z][0]:.2f} ms per 100 (r={grows[z][1]:.2f})")
            if unusual.get(z, 0) > 0.5:
                notes.append(f"+{unusual[z]:.2f} ms beyond what its calls usually cost")
            notes.append(f"the largest part of {top_contrib.get(z, 0)} of {len(spikes)} spikes")
            why = EXPLAIN.get(z)
            if why:
                notes.append(why)
            causes.append((d, z))
            p(f"  {rank}. {z}: {sm:.2f} ms in a spike frame against {nm:.2f} normally (+{d:.2f}); " + "; ".join(notes))
            rank += 1
        if steps_sp > steps_n + 0.3:
            step_ms = statistics.fmean([f.zones["physics_step"][0] / 1000.0 / max(f.calls("physics_step"), 1)
                                        for f in spikes if "physics_step" in f.zones] or [0.0])
            budget = 1000.0 / float(rec.meta.get("physics_ticks_per_second", 50) or 50)
            spiral = " A physics step costs more than its own time here, so the game cannot catch up (a spiral)."                 if step_ms > budget else ""
            p(f"  {rank}. Catch-up physics: {steps_sp:.1f} physics steps in a spike frame against {steps_n:.1f} "
              f"normally, {step_ms:.1f} ms each (a step is {budget:.0f} ms of game time); a slow frame makes the next "
              f"one run more steps (Engine.max_physics_steps_per_frame).{spiral}")
            rank += 1
        comp = [f for f in spikes if comp_new.get(f.index, 0) > 0 or comp_new.get(f.index - 1, 0) > 0]
        if comp:
            p(f"  {rank}. Shader/pipeline compilation in {len(comp)} of {len(spikes)} spike frames (first use of a "
              f"material or effect).")
            rank += 1
        for share, name, n, hit in sorted(event_links, reverse=True)[:3]:
            p(f"  {rank}. The event '{name}': {hit} of {n} are followed by a spike within {window:g} s.")
            rank += 1
        rec_sp = statistics.fmean([f.self_ms(RECORDER) for f in spikes])
        p(f"  (The recorder itself: {rec_sp:.2f} ms in a spike frame on average, "
          f"{statistics.fmean([f.self_ms(RECORDER) for f in normal]) if normal else 0.0:.2f} ms in a normal one.)")
    else:
        p("  No spikes in this recording.")
    p("=" * 78)
    return {
        "spikes": spikes,
        "worst": worst,
        "causes": causes,
        "growth": growth,
        "zone_rows": rows,
        "event_links": event_links,
    }


def _args(a: dict) -> str:
    keep = {k: v for k, v in a.items() if k not in ("frame", "run_s")}
    if not keep:
        return ""
    return "(" + ", ".join(f"{k}={v}" for k, v in keep.items()) + ")"


def main(argv: list | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("folder", nargs="?", help="a recording folder (default: the newest in game/perf/)")
    ap.add_argument("--top", type=int, default=10, help="how many spikes and zones to list")
    ap.add_argument("--spike-ms", type=float, default=None, help="spike threshold (default: the recording's)")
    ap.add_argument("--window", type=float, default=1.0, help="seconds around a spike to look for events")
    ap.add_argument("--check-trace", action="store_true", help="also check trace.json's begin/end nesting")
    a = ap.parse_args(argv)
    if a.folder:
        folder = Path(a.folder)
    else:
        base = Path(__file__).resolve().parent.parent / "perf"
        folder = latest_recording(base)
        if folder is None:
            print(f"No recording in {base}. Play with --record-perf first (game/docs/game-loop/perf-recorder.md).")
            return 1
    if not (folder / "frames.csv").exists():
        print(f"{folder} has no frames.csv")
        return 1
    rec = load(folder)
    analyse(rec, top=a.top, spike_ms=a.spike_ms, window=a.window)
    if a.check_trace:
        ok, msg = check_trace(folder / "trace.json")
        print(msg)
        return 0 if ok else 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
