---
id: T-468
title: Record a run's performance so its frame drops can be traced to their cause
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-443]
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, tasks/T-443-minions-spawn-on-timer.md, tasks/T-444-many-minions-performance.md, game/scripts/run/run.gd]
files_expected_to_change: [game/scripts/, game/tools/, game/tests/unit/, game/docs/, docs/working-with-the-board.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-10-31, after playing T-443 (minions on a timer): there are frame drops at certain points in a run. The board will play a run with recording on; the Project Lead then analyses the recording to find what causes the spikes. The recording must hold enough to answer that question later without another session.

1. **A recorder, off by default**, switched on for a run by a command-line option or environment variable (for example `--record-perf` or `SC_RECORD_PERF=1`), documented. When on, it writes one file per run into a git-ignored folder (for example `game/perf/<date-time>/`), and costs little enough not to cause drops itself (measure and report its overhead).
2. **What it records, every frame:** the frame time, Godot's own process and physics process times, the Performance monitors (FPS, process and physics time, draw calls, objects, nodes, orphan nodes, static and video memory, physics active objects and collision pairs, navigation if used), and the run's counts (minions alive, projectiles, flames and molotov fires, meteors and boulders, pickups and coins, popups, particles).
3. **Timed zones, nested, for a flame graph:** instrument the run's systems with cheap begin/end zones so each frame shows where its time went: minion spawning, path finding and path following, separation and steering, enemy depth sorting and height, enemy contact and damage, each weapon's update and hits, meteors, pickups and coins, the HUD and popups, the gift arrows, the car's physics and drift, the level's drawing (depth sorting of buildings), and anything else that costs time. Write them as Chrome trace events (JSON) so the file opens in Perfetto (ui.perfetto.dev) or chrome://tracing as a flame graph.
4. **Game events as markers** on the timeline: level-ups and gift pack drops, weapon gains, kaiju arrival, meteor attacks, missions if present, wreck and revive, pause, and the run's start and end, so a spike can be tied to what was happening.
5. **Spike capture:** any frame over a threshold (proposal: 25 ms) is flagged, with the frames around it kept in full detail.
6. **An analysis script** in game/tools/ (Python) that reads a recording and prints: the worst spikes with time in run, what happened around them, and each zone's time in spike frames compared with normal frames; the zones that grow with the minion count; and a short ranked list of likely causes. Its output is what the Project Lead reads.
7. Run a scripted run yourself with the recorder on (a few minutes, many minions), run the analysis on it, and put its output in the result notes as a sample, so the board's recording can be compared with it.

No gameplay change. Never write, move or commit anything in game/data/levels/.

The board's review: play a full run with the recorder on (the command is in the result notes and docs/working-with-the-board.md), then tell the Project Lead, who runs the analysis.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] With the recorder off, no file is written and the game behaves as before (test). (QA: pass - off: no file and no recorder, test_perf_recorder passes)
- [x] With it on, a run writes a recording with per-frame times, Performance monitors, run counts, nested zones and event markers (test on a short scripted run checks each kind is present). (QA: pass - on: frames, monitors, counts, zones, markers present in tests and sample)
- [x] The recording opens as Chrome trace JSON (a test validates the trace format: every begin has an end, nested correctly). (QA: pass - trace format test passes (balanced, nested); analyse --check-trace)
- [x] The recorder's own overhead is measured and in the result notes (frame time with and without it). (QA: pass - overhead 0.5 ms median / 1.4 ms mean, in notes)
- [x] The analysis script prints the worst spikes with their time in run and nearby events, and each zone's time in spike frames against normal frames (test on a fixture recording). (QA: pass - fixture test passes; ran on sample: spikes with run time, events, zone comparison)
- [x] A sample recording's analysis output is in the result notes. (QA: pass - sample analysis output in notes)
- [x] The recording folder is git-ignored, and docs/working-with-the-board.md says how the board records a run and that the Project Lead analyses it. (QA: pass - game/perf/ ignored (git check-ignore); working-with-the-board.md line 33)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - all three sets pass (qa_check PASS; counts in notes))
- [x] Nothing under game/data/levels/ is changed or committed. (QA: pass - no changes under game/data/levels vs master)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Game Loop Agent, 2026-10-31.** Built: the recorder, the zones in the game's systems, the analysis script, a scripted sample run, tests and docs. No gameplay change; nothing under `game/data/levels/` touched.

**How the board records a run** (also in `docs/working-with-the-board.md`, "How the board builds the game", and `game/docs/game-loop/perf-recorder.md`): from the repo root in PowerShell,

    powershell -ExecutionPolicy Bypass -File game/tools/play_with_perf.ps1

which is the same as `"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path C:\solid-carbide-game\game -- --record-perf` (before the merge, from this ticket's folder: `--path C:\solid-carbide-worktrees\T-468\game`). `SC_RECORD_PERF=1` in the environment works too (e.g. before opening the editor). Every run played writes `game/perf/<date>_<time>/` (git-ignored, with a `.gdignore` so Godot does not import it). Then the Project Lead runs `python game/tools/analyse_perf.py` (the newest recording; `--top N`, `--check-trace`).

**What was built**

- `game/scripts/perf/perf.gd` (`Perf`): nested timed zones, `Perf.begin(&"x")` / `Perf.end(&"x")`; per-item work uses the guarded each form `if Perf.on: Perf.each_begin(&"x")`, summed per frame (total, self, calls) and shown as one block in the flame graph. Off by default: about 0.3 us per begin/end pair, 0.1 us for the guarded form. A missed end is closed by the next outer end and counted (`unbalanced_zones`, 0 in all tests and samples).
- `game/scripts/perf/perf_recorder.gd` (`PerfRecorder`): added by `run.gd` `_ready` only when recording is on (`--record-perf` or `SC_RECORD_PERF`), one recording per run. It cuts every frame into engine phases from Godot's own signals (physics steps, physics scripts, physics engine, process, deferred/draws, render, wait/vsync) and writes:
  - `frames.csv`: per frame the frame time, the run time, 26 Performance monitors (FPS, process/physics/navigation time, static/video/texture/buffer memory, objects, resources, nodes, orphan nodes, draw calls, primitives, render objects, physics active objects/pairs/islands, navigation maps, pipeline compilations), 26 run counts (minions alive/spawned/killed, paths found, coins, health pickups, projectiles with bullets and molotov fires, burning enemies, flame on, kaiju, meteor warnings, boulders, dust, gift helicopters and packages, popups, drift smoke puffs, drift mark pieces, wreck puffs, HUD reactions and viewer flights), and every zone's inclusive/self time and calls; `#marker` lines for events and `#spike` lines.
  - `trace.json`: Chrome trace events (Perfetto / chrome://tracing): counters every frame, the events as markers, `SPIKE` markers, and the frames around every spike (30 before, 30 after, plus 1 ordinary frame in 300) in full detail as B/E pairs, nested (capped at 12,000 detailed frames). The writing is spread over frames, 0.3 ms a frame.
  - `meta.json`: settings, machine, display, and at the end the summary and overhead.
  - Markers: run start/end, world rebuilt, level-up, gift helicopter/drop/landing/pickup, level-up screen opened/choice made, weapon gained/tier/reset, boss time, kaiju arrived/defeated, meteor attack/landing/boulder, car damaged, combo broken, wreck, revive, time up, pause/resume. Missions have no code yet; `PerfRecorder.mark(name, args)` adds one from anywhere when they do.
- Zones (about 85 one-line begin/end pairs in 57 files; full list in `game/docs/game-loop/perf-recorder.md`): car physics and its step listeners (sync view, car depth sort, see-through, drift likes, needle, car obstacles, drift marks and smoke), minions (prune, spawn, move > separation, per minion `minions.path` with `nav.find_path` and `minions.walk`, despawn, place and depth), enemy damage and death drops, kaiju, meteors, each weapon (`weapon.<id>`) and projectiles, pickup magnet, gift drops/arrows/helicopter/package, run clock, sounds, effects, every HUD widget and popup, the UI screens, map car update and see-through, and the `_draw()` of every custom-drawn node (minions, coins, kaiju, bullets, fires, platforms, buildings, HUD...). **For T-444's merge:** in the enemy files the changes are only one-line `Perf.begin/end` (or guarded `each_`) lines around existing code in `minion_spawner.gd` (`step`, `move_step`'s loop body, `_on_minion_died`, `_physics_process`), `minion.gd` (`take_damage`), `enemy_navigation.gd` (`find_path`, with each return value kept in `_perf_r` before the end), `kaiju.gd`, `kaiju_boss.gd`, `kaiju_meteors.gd`, `minion_sprite.gd`/`coin_sprite.gd`/`kaiju_sprite.gd`/`burn_flames.gd`/`health_pickup_sprite.gd` (`_draw`/`_process`); if T-444 rewrites those functions, the lines can be dropped or moved, nothing else depends on them.
- `game/tools/analyse_perf.py`: the analysis (output below). `--check-trace` checks the trace's nesting.
- `game/tools/perf_sample_run.gd` / `.sh`: the scripted run (game map, run clock moved on, fixed drift pattern, first card at every level-up, car kept alive, saves to `user://perf_sample_*`), options `--seconds`, `--start-at`, `--all-weapons`, `--no-vsync`, `--park`, `--no-weapons`. `game/tools/play_with_perf.ps1`: the board's launcher.
- `.gitignore`: `game/perf/`. `game/tests/helpers/pre_run.gd`: tests never record (`PerfRecorder.enabled_override = 0`).

**Overhead (criterion 4).** Same load both ways (`perf_sample_run.sh --seconds=20 --start-at=300 --no-vsync --park --no-weapons`: car parked, nothing shooting, 51 minions at the end every time), two runs each, frame times measured by the script itself:

| | frames | mean ms | median ms | p95 ms |
|---|---|---|---|---|
| recorder off | 4089 / 3905 | 4.41 / 4.62 | 1.19 / 1.18 | 17.9 / 16.9 |
| recorder on | 2949 / 3170 | 6.11 / 5.71 | 1.74 / 1.56 | 19.6 / 19.4 |

About +0.5 ms on the median frame and +1.4 ms on the mean (the mean is dominated by heavy many-minion frames, where per-minion zones add up). The recorder's own figures: 0.2 to 0.25 ms a frame writing, about 140 zone calls a frame at 1.76 us each (~0.25 ms), so about 3% of the 16 ms mean frame in the sample below; 0.8 ms in a spike frame (writing the detailed frames). That is small next to the spikes it finds (100 to 350 ms), but a 25 to 30 ms frame should be read with ~1 ms of recorder in it; the analysis reports the recorder separately and never ranks it as a cause.

**Sample recording, after T-444 (the current picture; criterion 6).** Master (with T-444's minion optimisation) merged into this branch on 2026-10-31; conflicts in `minion_spawner.gd` (`move_step`'s `may_drop` line) and `thread_the_needle.gd` (the marker's `_draw`, T-451's flash) resolved keeping both the new code and the zones. The same scripted run, `bash game/tools/perf_sample_run.sh --record-perf --seconds=150 --start-at=300` (vsync on, like the board; weapons from level-ups), recording `game/perf/2026-10-31_16-23-13/`. The script's own numbers: 35,020 frames, mean 4.2 ms, median 2.9, p95 10.3, p99 11.9, max 27.9, 4 frames over 25 ms (before T-444: 645), up to 95 minions alive. Its analysis (`python game/tools/analyse_perf.py --top 5 --check-trace`; after the merge the "catch-up physics" line needs more than one physics step per spike frame on average, so it no longer shows for single-step spikes at 240 Hz):

```
==============================================================================
Recording  C:\solid-carbide-worktrees\T-468\game\perf\2026-10-31_16-23-13
Machine    Intel(R) Core(TM) Ultra 9 275HX x24, NVIDIA GeForce RTX 5070 Laptop GPU; Godot 4.6.2-stable (official) (forward_plus), debug=True
Display    window (1152, 648), 240.0 Hz, vsync mode 1, max_fps 0, physics 50/s
Frames     35484 over 150.0 s; run time 5:00.4 to 7:30.2
Frame ms   mean 4.23  median 3.63  p95 9.34  p99 11.62  max 28.56
Spikes     4 frames at 25 ms or more (1.6 a minute); over 50 ms: 0; over 100 ms: 0
Overhead   recorder 0.123 ms a frame (max 16.81); zones 111 calls a frame x 1.57 us = ~0.175 ms; together ~7.0% of the mean frame

------------------------------------------------------------------------------
WORST SPIKES (the 4 longest frames; times are in the run, m:ss elapsed)

frame 11168  28.6 ms  at run 5:47.5 (wall 48.27 s)
  phases (ms): 1 physics step(s); physics scripts 24.3, physics engine 0.7, process scripts 0.7, deferred (draws, frees) 1.2, render 1.4, wait (vsync, input) 0.1
  where the time went (self ms; in brackets what those calls usually cost):
    weapon.flamethrower                10.12  (1 call: usually 0.55; +9.57)
    car.physics                         5.56  (1 call: usually 0.27; +5.29)
    minions.walk                        1.89  (94 calls: usually 2.03; -0.14)
    minions.place_and_depth             1.42  (1 call: usually 0.64; +0.78)
    render                              1.36  (1 call: usually 1.66; -0.30)
    minions.separation                  1.07  (1 call: usually 0.34; +0.73)
  counts: minions 94, coins 15, gift_packages 1, popups 2, drift_smoke_puffs 11, drift_mark_pieces 40
  monitors: draw_calls 688, render_objects 14739, nodes 1260, orphan_nodes 0, objects 3895, physics_pairs 45
  events within 1 s: gift_pack_picked_up -0.39s; level_up_screen_opened(level=3) -0.38s; paused -0.38s; weapon_gained(tier=1, weapon=flamethrower) -0.38s; level_up_choice_made(level=3) -0.38s; resumed -0.37s; combo_broken +0.01s; car_damaged(amount=1.0) +0.48s

frame 299  27.0 ms  at run 5:01.6 (wall 2.31 s)
  phases (ms): 1 physics step(s); physics scripts 24.1, physics engine 0.6, process scripts 0.4, deferred (draws, frees) 0.2, render 1.3, wait (vsync, input) 0.1
  where the time went (self ms; in brackets what those calls usually cost):
    car.physics                        22.25  (1 call: usually 0.27; +21.98)
    render                              1.28  (1 call: usually 1.66; -0.38)
    physics.engine                      0.61  (1 call: usually 0.29; +0.32)
    level.car_depth_sort                0.49  (1 call: usually 0.33; +0.16)
    sounds.sync                         0.32  (1 call: usually 0.58; -0.26)
    level.see_through                   0.18  (1 call: usually 0.12; +0.06)
  counts: minions 4, popups 2, drift_smoke_puffs 12, drift_mark_pieces 10
  monitors: draw_calls 625, render_objects 14659, nodes 793, orphan_nodes 0, objects 3081, physics_pairs 1
  events within 1 s: combo_broken +0.02s

frame 11131  26.6 ms  at run 5:47.2 (wall 47.91 s)
  phases (ms): 1 physics step(s); physics scripts 22.6, physics engine 0.7, process scripts 0.7, deferred (draws, frees) 1.1, render 1.2, wait (vsync, input) 0.1
  where the time went (self ms; in brackets what those calls usually cost):
    weapon.flamethrower                12.09  (1 call: usually 0.55; +11.54)
    minions.walk                        2.23  (93 calls: usually 2.01; +0.21)
    minions.separation                  1.63  (1 call: usually 0.34; +1.29)
    minions.place_and_depth             1.44  (1 call: usually 0.64; +0.80)
    render                              1.25  (1 call: usually 1.66; -0.41)
    minions.path                        1.12  (93 calls: usually 1.48; -0.36)
  counts: minions 93, coins 15, gift_packages 1, drift_smoke_puffs 14, drift_mark_pieces 38
  monitors: draw_calls 682, render_objects 14736, nodes 1251, orphan_nodes 0, objects 3880, physics_pairs 38
  events within 1 s: gift_pack_picked_up -0.03s; level_up_screen_opened(level=3) -0.03s; paused -0.02s; weapon_gained(tier=1, weapon=flamethrower) -0.02s; level_up_choice_made(level=3) -0.02s; resumed -0.01s; combo_broken +0.36s; car_damaged(amount=1.0) +0.84s

frame 11410  26.2 ms  at run 5:49.3 (wall 50.07 s)
  phases (ms): 1 physics step(s); physics scripts 22.1, physics engine 0.6, process scripts 0.7, deferred (draws, frees) 1.1, render 1.5, wait (vsync, input) 0.1
  where the time went (self ms; in brackets what those calls usually cost):
    weapon.flamethrower                 8.81  (1 call: usually 0.55; +8.26)
    car.physics                         5.50  (1 call: usually 0.27; +5.24)
    minions.walk                        1.58  (80 calls: usually 1.73; -0.15)
    render                              1.50  (1 call: usually 1.66; -0.16)
    minions.place_and_depth             1.19  (1 call: usually 0.64; +0.55)
    minions.separation                  0.87  (1 call: usually 0.34; +0.53)
  counts: minions 80, projectiles 1, coins 20, burning_enemies 1, gift_packages 2, popups 2, drift_smoke_puffs 9, drift_mark_pieces 40
  monitors: draw_calls 687, render_objects 14755, nodes 1234, orphan_nodes 0, objects 3852, physics_pairs 44
  events within 1 s: gift_helicopter_sent -0.08s; level_up(level=4) -0.08s; combo_broken +0.01s; car_damaged(amount=1.0) +0.31s

------------------------------------------------------------------------------
ZONES IN SPIKE FRAMES AGAINST NORMAL FRAMES (self ms a frame, mean; sorted by the difference)
  zone                                spike   normal     diff   calls spike/normal  top in N spikes
  car.physics                         8.391    0.056   +8.335       1.0/0.2        1
  weapon.flamethrower                 7.757    0.080   +7.677       0.8/0.1        3
  minions.walk                        1.449    0.167   +1.282      67.8/7.7        0
  minions.place_and_depth             1.034    0.135   +0.899       1.0/0.2        0
  minions.separation                  0.906    0.072   +0.834       1.0/0.2        0
  minions.path                        0.730    0.122   +0.607      67.8/7.7        0
  minions.spawn                       0.580    0.012   +0.568       1.0/0.2        0
  physics.engine                      0.593    0.061   +0.532       1.0/0.2        0
  sounds.sync                         0.598    0.123   +0.475       1.0/0.2        0
  minions.move                        0.444    0.048   +0.396       1.0/0.2        0
  level.car_depth_sort                0.374    0.069   +0.305       1.0/0.2        0
  map.car_obstacles                   0.157    0.034   +0.123       1.0/0.2        0
  draw.minion                         0.250    0.127   +0.122      68.5/35.9       0
  process                             0.249    0.130   +0.119       1.0/1.0        0
  after_process                       0.406    0.289   +0.116       1.0/1.0        0
  weapons.projectile                  0.121    0.011   +0.110       0.2/0.0        0
  level.see_through                   0.134    0.026   +0.108       1.0/0.2        0
  pickups.magnet                      0.092    0.025   +0.067       1.0/0.2        0
  physics.scripts                     0.072    0.015   +0.058       1.0/0.2        0
  run.sync_view                       0.071    0.014   +0.057       1.0/0.2        0

------------------------------------------------------------------------------
GROWTH WITH THE MINION COUNT (unpaused frames; 1 to 95 minions alive)
    minions  frames  mean ms  p95 ms  spikes
     0-24     11742     4.17    7.94       1
    25-49     16553     4.17    8.93       0
    50-74      4601     4.24   10.32       0
    75-99      2582     4.83   12.09       3
  frame time grows 0.71 ms per 100 minions (r=0.06)
  zones that grow most with the minions (self ms a frame added per 100 minions; at the peak; frames with one physics step):
    minions.walk                     + 1.956 ms/100  r=0.96  ~1.86 ms at 95
    minions.place_and_depth          + 1.379 ms/100  r=0.91  ~1.31 ms at 95
    minions.separation               + 1.084 ms/100  r=0.97  ~1.03 ms at 95
    minions.path                     + 1.023 ms/100  r=0.34  ~0.97 ms at 95
    minions.move                     + 0.516 ms/100  r=0.64  ~0.49 ms at 95

------------------------------------------------------------------------------
EVENTS FOLLOWED BY A SPIKE (within 1 s after the event; chance = spikes' share of the time)
  weapon_gained                   1 of 2    ( 50%; chance ~2%)  <-- more than chance
  gift_pack_picked_up             1 of 3    ( 33%; chance ~2%)
  level_up_screen_opened          1 of 3    ( 33%; chance ~2%)
  paused                          1 of 3    ( 33%; chance ~2%)
  level_up_choice_made            1 of 3    ( 33%; chance ~2%)
  resumed                         1 of 3    ( 33%; chance ~2%)
  gift_helicopter_sent            1 of 4    ( 25%; chance ~2%)
  level_up                        1 of 4    ( 25%; chance ~2%)
  weapon_reset                    0 of 5    (  0%; chance ~2%)
  world_rebuilt                   0 of 1    (  0%; chance ~2%)
  run_started                     0 of 1    (  0%; chance ~2%)
  combo_broken                    0 of 101  (  0%; chance ~2%)
  car_damaged                     0 of 84   (  0%; chance ~2%)
  gift_pack_dropped               0 of 4    (  0%; chance ~2%)
  gift_pack_landed                0 of 4    (  0%; chance ~2%)
  weapon_tier                     0 of 2    (  0%; chance ~2%)
  kaiju_arrived                   0 of 1    (  0%; chance ~2%)
  boss_time                       0 of 1    (  0%; chance ~2%)
  meteor_attack                   0 of 4    (  0%; chance ~2%)
  meteor_landed                   0 of 9    (  0%; chance ~2%)
  boulder_placed                  0 of 9    (  0%; chance ~2%)

------------------------------------------------------------------------------
LIKELY CAUSES (zones ranked by the time they add to a spike frame, then other signs)
  1. car.physics: 8.39 ms in a spike frame against 0.06 normally (+8.33); runs 1.0 times a spike frame against 0.2 normally; each call costs 8.39 ms in spikes against 0.27 usually; +8.13 ms beyond what its calls usually cost; the largest part of 1 of 4 spikes
  2. weapon.flamethrower: 7.76 ms in a spike frame against 0.08 normally (+7.68); runs 0.8 times a spike frame against 0.1 normally; each call costs 10.34 ms in spikes against 0.55 usually; +7.35 ms beyond what its calls usually cost; the largest part of 3 of 4 spikes
  3. minions.walk: 1.45 ms in a spike frame against 0.17 normally (+1.28); runs 67.8 times a spike frame against 7.7 normally; grows with the minions, +1.96 ms per 100 (r=0.96); the largest part of 0 of 4 spikes
  4. minions.place_and_depth: 1.03 ms in a spike frame against 0.14 normally (+0.90); runs 1.0 times a spike frame against 0.2 normally; each call costs 1.03 ms in spikes against 0.64 usually; grows with the minions, +1.38 ms per 100 (r=0.91); +0.53 ms beyond what its calls usually cost; the largest part of 0 of 4 spikes
  5. minions.separation: 0.91 ms in a spike frame against 0.07 normally (+0.83); runs 1.0 times a spike frame against 0.2 normally; each call costs 0.91 ms in spikes against 0.34 usually; grows with the minions, +1.08 ms per 100 (r=0.97); +0.64 ms beyond what its calls usually cost; the largest part of 0 of 4 spikes
  6. minions.path: 0.73 ms in a spike frame against 0.12 normally (+0.61); runs 67.8 times a spike frame against 7.7 normally; grows with the minions, +1.02 ms per 100 (r=0.34); the largest part of 0 of 4 spikes
  7. The event 'weapon_gained': 1 of 2 are followed by a spike within 1 s.
  (The recorder itself: 0.12 ms in a spike frame on average, 0.12 ms in a normal one.)
==============================================================================
trace OK (B: 14696, C: 106455, E: 14696, M: 2, i: 258)
```

What it says: the minion spiral is gone (frame time no longer grows with the minions: 4.2 ms mean at 0-24 minions, 4.8 ms at 75-99; no frame over 29 ms). The 4 remaining spikes (26 to 29 ms, each one physics step) are `weapon.flamethrower` (8 to 12 ms in the first steps after it is gained from a gift pack, 3 of 4 spikes; usually 0.55 ms) and `car.physics` (one 22 ms step at 5:01.6, and 5 ms in another; usually 0.27 ms). Those two are what to look for in the board's recording; the minions now cost about 2 ms per 100 for walking, 1.4 for depth, 1.1 for separation, 1 for paths, per physics step.

**Sample recording before T-444** (for comparison; same command, recording `game/perf/2026-10-31_15-26-18/`). The script's own numbers: 8877 frames, mean 16.7 ms, median 4.4, p95 42.1, p99 229, max 386, 645 frames over 25 ms, recording on. Its analysis (made before the catch-up fix above):

```
==============================================================================
Recording  C:\solid-carbide-worktrees\T-468\game\perf\2026-10-31_15-26-18
Machine    Intel(R) Core(TM) Ultra 9 275HX x24, NVIDIA GeForce RTX 5070 Laptop GPU; Godot 4.6.2-stable (official) (forward_plus), debug=True
Display    window (1152, 648), 240.0 Hz, vsync mode 1, max_fps 0, physics 50/s
Frames     9335 over 150.0 s; run time 5:00.4 to 7:15.9
Frame ms   mean 16.06  median 4.25  p95 41.20  p99 228.54  max 358.63
Spikes     646 frames at 25 ms or more (258.5 a minute); over 50 ms: 400; over 100 ms: 268
Overhead   recorder 0.242 ms a frame (max 9.78); zones 139 calls a frame x 1.76 us = ~0.244 ms; together ~3.0% of the mean frame

------------------------------------------------------------------------------
WORST SPIKES (the 5 longest frames; times are in the run, m:ss elapsed)

frame 7069  358.6 ms  at run 6:12.2 (wall 77.62 s)
  phases (ms): 8 physics step(s); physics scripts 350.4, physics engine 4.0, process scripts 0.6, deferred (draws, frees) 0.7, render 1.3, wait (vsync, input) 0.2
  where the time went (self ms; in brackets what those calls usually cost):
    minions.path                      220.19  (252 calls: usually 16.83; +203.36)
    minions.place_and_depth            39.51  (8 calls: usually 25.57; +13.94)
    minions.walk                       33.48  (252 calls: usually 41.52; -8.04)
    nav.find_path                      13.37  (4 calls: usually 1.05; +12.32)
    sounds.sync                         7.46  (8 calls: usually 5.92; +1.54)
    weapon.flamethrower                 6.74  (8 calls: usually 5.08; +1.67)
  counts: minions 31, coins 15, popups 2, drift_smoke_puffs 2, drift_mark_pieces 24
  monitors: draw_calls 605, render_objects 14623, nodes 1039, orphan_nodes 0, objects 3539, physics_pairs 1

frame 7044  353.4 ms  at run 6:08.2 (wall 71.02 s)
  phases (ms): 8 physics step(s); physics scripts 346.1, physics engine 2.8, process scripts 0.7, deferred (draws, frees) 0.9, render 1.3, wait (vsync, input) 0.2
  where the time went (self ms; in brackets what those calls usually cost):
    nav.find_path                      80.69  (32 calls: usually 8.44; +72.25)
    minions.path                       76.58  (364 calls: usually 24.30; +52.28)
    minions.walk                       67.71  (364 calls: usually 59.97; +7.74)
    minions.place_and_depth            63.07  (8 calls: usually 25.57; +37.51)
    car.physics                        16.34  (8 calls: usually 2.30; +14.04)
    minions.separation                  9.05  (8 calls: usually 3.81; +5.25)
  counts: minions 46, coins 15, popups 1, drift_mark_pieces 34
  monitors: draw_calls 631, render_objects 14721, nodes 1102, orphan_nodes 0, objects 3634, physics_pairs 2

frame 7056  333.0 ms  at run 6:10.1 (wall 74.44 s)
  phases (ms): 8 physics step(s); physics scripts 323.9, physics engine 3.4, process scripts 1.6, deferred (draws, frees) 1.1, render 1.3, wait (vsync, input) 0.2
  where the time went (self ms; in brackets what those calls usually cost):
    minions.walk                       78.15  (408 calls: usually 67.22; +10.93)
    minions.place_and_depth            70.74  (8 calls: usually 25.57; +45.17)
    nav.find_path                      58.12  (32 calls: usually 8.44; +49.68)
    minions.path                       57.59  (408 calls: usually 27.24; +30.35)
    minions.separation                 10.03  (8 calls: usually 3.81; +6.22)
    weapon.flamethrower                 8.15  (8 calls: usually 5.08; +3.07)
  counts: minions 51, coins 15, popups 1, drift_mark_pieces 30
  monitors: draw_calls 619, render_objects 14661, nodes 1121, orphan_nodes 0, objects 3675, physics_pairs 3

frame 7055  322.5 ms  at run 6:10.0 (wall 74.12 s)
  phases (ms): 8 physics step(s); physics scripts 299.7, physics engine 3.4, process scripts 2.7, deferred (draws, frees) 13.5, render 1.4, wait (vsync, input) 0.3
  where the time went (self ms; in brackets what those calls usually cost):
    minions.walk                       76.69  (408 calls: usually 67.22; +9.47)
    minions.place_and_depth            72.76  (8 calls: usually 25.57; +47.20)
    minions.path                       60.52  (408 calls: usually 27.24; +33.28)
    nav.find_path                      28.23  (13 calls: usually 3.43; +24.81)
    draw.popup                         12.50  (1 call: usually 0.03; +12.47)
    minions.separation                 10.36  (8 calls: usually 3.81; +6.55)
  counts: minions 51, coins 15, popups 1, drift_smoke_puffs 2, drift_mark_pieces 30
  monitors: draw_calls 626, render_objects 14678, nodes 1121, orphan_nodes 0, objects 3674, physics_pairs 0

frame 7045  319.1 ms  at run 6:08.4 (wall 71.37 s)
  phases (ms): 8 physics step(s); physics scripts 297.4, physics engine 3.2, process scripts 2.6, deferred (draws, frees) 12.6, render 1.4, wait (vsync, input) 0.2
  where the time went (self ms; in brackets what those calls usually cost):
    minions.path                       73.18  (368 calls: usually 24.57; +48.61)
    minions.walk                       68.85  (368 calls: usually 60.63; +8.23)
    minions.place_and_depth            64.01  (8 calls: usually 25.57; +38.44)
    nav.find_path                      40.50  (18 calls: usually 4.75; +35.76)
    draw.popup                         11.50  (1 call: usually 0.03; +11.47)
    minions.separation                  9.29  (8 calls: usually 3.81; +5.48)
  counts: minions 46, coins 15, popups 1, drift_smoke_puffs 5, drift_mark_pieces 32
  monitors: draw_calls 636, render_objects 14740, nodes 1103, orphan_nodes 0, objects 3639, physics_pairs 2

------------------------------------------------------------------------------
ZONES IN SPIKE FRAMES AGAINST NORMAL FRAMES (self ms a frame, mean; sorted by the difference)
  zone                                spike   normal     diff   calls spike/normal  top in N spikes
  minions.walk                       32.139    1.616  +30.523     191.9/9.8        490
  minions.place_and_depth            24.051    1.408  +22.643       4.6/0.4        17
  minions.path                       19.629    0.655  +18.974     191.9/9.8        93
  weapon.flamethrower                 5.406    0.183   +5.223       4.3/0.3        33
  minions.separation                  4.604    0.210   +4.394       4.6/0.4        0
  weapon.underglow                    4.100    0.183   +3.917       4.5/0.3        0
  sounds.sync                         3.767    0.326   +3.441       4.6/0.4        2
  nav.find_path                       1.915    0.017   +1.898       2.0/0.1        3
  physics.engine                      1.731    0.129   +1.602       4.6/0.4        0
  minions.move                        1.517    0.081   +1.436       4.6/0.4        2
  level.car_depth_sort                1.657    0.222   +1.435       4.6/0.4        0
  car.physics                         1.402    0.127   +1.275       4.6/0.4        2
  map.car_obstacles                   0.847    0.081   +0.766       4.6/0.4        0
  pickups.magnet                      0.704    0.060   +0.644       4.6/0.4        0
  weapons.projectile                  0.672    0.036   +0.636       0.7/0.1        0
  level.see_through                   0.727    0.092   +0.635       4.6/0.4        0
  perf.recorder                       0.809    0.199   +0.609       1.0/1.0        0
  car.stepped_listeners               0.524    0.045   +0.478       4.6/0.4        0
  effects.drift_marks_lay             0.416    0.039   +0.378       4.6/0.4        0
  physics.scripts                     0.403    0.037   +0.366       4.6/0.4        0

------------------------------------------------------------------------------
GROWTH WITH THE MINION COUNT (unpaused frames; 1 to 66 minions alive)
    minions  frames  mean ms  p95 ms  spikes
     0-24      6139     7.06   17.76      30
    25-49      3083    26.31  105.06     506
    50-74       107   236.09  271.93     107
  frame time grows 250.28 ms per 100 minions (r=0.62)
  zones that grow most with the minions (self ms a frame added per 100 minions; at the peak; frames with one physics step):
    minions.walk                     +16.397 ms/100  r=0.97  ~10.82 ms at 66
    minions.place_and_depth          + 8.478 ms/100  r=0.70  ~5.60 ms at 66
    minions.path                     + 5.661 ms/100  r=0.36  ~3.74 ms at 66
    minions.separation               + 2.263 ms/100  r=0.96  ~1.49 ms at 66
    weapon.underglow                 + 2.071 ms/100  r=0.56  ~1.37 ms at 66

------------------------------------------------------------------------------
EVENTS FOLLOWED BY A SPIKE (within 1 s after the event; chance = spikes' share of the time)
  gift_pack_dropped               3 of 3    (100%; chance ~65%)
  gift_pack_picked_up             2 of 2    (100%; chance ~65%)
  level_up_screen_opened          2 of 2    (100%; chance ~65%)
  paused                          4 of 4    (100%; chance ~65%)
  level_up_choice_made            2 of 2    (100%; chance ~65%)
  resumed                         4 of 4    (100%; chance ~65%)
  weapon_gained                   2 of 3    ( 67%; chance ~65%)
  gift_helicopter_sent            2 of 3    ( 67%; chance ~65%)
  level_up                        2 of 3    ( 67%; chance ~65%)
  gift_pack_landed                2 of 3    ( 67%; chance ~65%)
  car_damaged                    26 of 51   ( 51%; chance ~65%)
  combo_broken                   30 of 60   ( 50%; chance ~65%)
  weapon_reset                    0 of 5    (  0%; chance ~65%)
  world_rebuilt                   0 of 1    (  0%; chance ~65%)
  run_started                     0 of 1    (  0%; chance ~65%)
  kaiju_arrived                   0 of 1    (  0%; chance ~65%)
  boss_time                       0 of 1    (  0%; chance ~65%)
  meteor_attack                   0 of 2    (  0%; chance ~65%)
  meteor_landed                   0 of 3    (  0%; chance ~65%)
  boulder_placed                  0 of 3    (  0%; chance ~65%)

------------------------------------------------------------------------------
LIKELY CAUSES (zones ranked by the time they add to a spike frame, then other signs)
  1. minions.walk: 32.14 ms in a spike frame against 1.62 normally (+30.52); runs 191.9 times a spike frame against 9.8 normally; grows with the minions, +16.40 ms per 100 (r=0.97); +0.95 ms beyond what its calls usually cost; the largest part of 490 of 646 spikes
  2. minions.place_and_depth: 24.05 ms in a spike frame against 1.41 normally (+22.64); runs 4.6 times a spike frame against 0.4 normally; each call costs 5.26 ms in spikes against 3.20 usually; grows with the minions, +8.48 ms per 100 (r=0.70); +9.46 ms beyond what its calls usually cost; the largest part of 17 of 646 spikes
  3. minions.path: 19.63 ms in a spike frame against 0.66 normally (+18.97); runs 191.9 times a spike frame against 9.8 normally; each call costs 0.10 ms in spikes against 0.07 usually; grows with the minions, +5.66 ms per 100 (r=0.36); +8.30 ms beyond what its calls usually cost; the largest part of 93 of 646 spikes
  4. weapon.flamethrower: 5.41 ms in a spike frame against 0.18 normally (+5.22); runs 4.3 times a spike frame against 0.3 normally; each call costs 1.26 ms in spikes against 0.63 usually; +2.99 ms beyond what its calls usually cost; the largest part of 33 of 646 spikes
  5. minions.separation: 4.60 ms in a spike frame against 0.21 normally (+4.39); runs 4.6 times a spike frame against 0.4 normally; each call costs 1.01 ms in spikes against 0.48 usually; grows with the minions, +2.26 ms per 100 (r=0.96); +2.43 ms beyond what its calls usually cost; the largest part of 0 of 646 spikes
  6. weapon.underglow: 4.10 ms in a spike frame against 0.18 normally (+3.92); runs 4.5 times a spike frame against 0.3 normally; each call costs 0.90 ms in spikes against 0.54 usually; grows with the minions, +2.07 ms per 100 (r=0.56); +1.66 ms beyond what its calls usually cost; the largest part of 0 of 646 spikes
  7. Catch-up physics: 4.6 physics steps in a spike frame against 0.4 normally, 21.6 ms each (a step is 20 ms of game time); a slow frame makes the next one run more steps (Engine.max_physics_steps_per_frame). A physics step costs more than its own time here, so the game cannot catch up (a spiral).
  (The recorder itself: 0.81 ms in a spike frame on average, 0.20 ms in a normal one.)
==============================================================================
trace OK (B: 206059, C: 28008, E: 206059, M: 2, i: 806)
```

What the before-T-444 sample said: on the game's map, in the debug build, the drops are the minions: from about 25 alive, a physics step costs more than its own 20 ms (`minions.walk` about 0.16 ms per minion, `minions.place_and_depth` (each sprite's depth among the buildings) and `minions.path` with `nav.find_path` bursts), so Godot runs up to 8 catch-up physics steps a frame and frames reach 200 to 350 ms (a spiral). Smaller contributors: `weapon.flamethrower`, `weapon.underglow`, `sounds.sync` (0.8 ms a step), `level.car_depth_sort` (0.6 ms a step), occasional `draw.popup` bursts (12 ms) and the flamethrower's first step after it is gained (33 ms, seen in a shorter all-weapons sample). T-444 is working on the minion costs.

**Tests:**

- New: `game/tests/unit/run/test_perf_zones.gd` (6: off records nothing, nesting and self time, each-zones summed into one block, blocks beside real children, a missed end, clearing), `game/tests/unit/run/test_perf_recorder.gd` (4: off writes nothing and adds no recorder; on, a run writes frames/monitors/counts/zones/markers and a trace whose every begin has its end, nested; a spike keeps the frames around it in detail and frames far away only as counters; a new run on the same scene gets its own recording), `game/tools/test_analyse_perf.py` (9, on a made-up recording: loading, worst spikes with run time and nearby events, spike against normal zones, minion growth, ranked causes, new pipeline compilations as a change, trace check incl. a broken and a cut-short trace, newest recording and `main`, a cut line skipped).
- All three sets pass: `python -m unittest discover -s game/tools -p "test_*.py"`: 776 tests OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 614 tests OK; `GUT_TIME_LIMIT=1500 ... bash game/tools/run_tests.sh`: 192 scripts, 2331/2331 tests passing, 1,274,008 asserts, TESTS PASSED. (The first full GUT run had 1 failure, `test_weapons_wreck.gd` `test_after_the_run_ends_no_later_weapon_damages_in_the_same_step`: its stand-in weapon has no `perf_zone`; `weapons.gd` now falls back to `&"weapon"` for such stand-ins, and the whole suite was run again: all pass.) The tests ran with the machine shared with other agents' Godot runs, hence the long times.
- After merging master (T-444) on 2026-10-31, all three sets again: game/tools 776 tests OK (1 skipped); tools 614 tests OK; GUT 194 scripts, 2346/2346 tests passing, 1,274,140 asserts, TESTS PASSED.

**Screenshots:** none; tooling with no picture (the sample's output above is the result to look at; the recording `game/perf/2026-10-31_15-26-18/trace.json` opens in https://ui.perfetto.dev as a flame graph, it is git-ignored and stays in this ticket's folder).

**Refusals:** one Bash command (an inline Python edit of `docs/working-with-the-board.md` and `game/docs/setup/folder-layout.md`) was refused by a hook that guards task files' `lead` (the text contained a link it read as a task file); those two doc edits were made with the Edit tool instead, as the hook suggested running such parts on their own. Nothing else was refused.

**Documents affected:** `docs/working-with-the-board.md` (how the board records a run and that the Project Lead analyses it). Also new/updated game docs: `game/docs/game-loop/perf-recorder.md` (new), `game/docs/setup/folder-layout.md`, `game/README.md` (index).
- 2026-10-31, in-progress → in-qa: Recorder, zones, analysis, sample run and docs done; board's command in the result notes; all three test sets pass.

**QA round 1 (QA agent, 2026-10-31).** All 9 criteria pass (marked above). `qa_check`: tests PASS (3 sets), documents PASS, screenshots FAIL (paperwork): no image in `art-archive/T-468/screenshots/`. The ticket says none (tooling), which `tasks/README.md` "Screenshots" allows, but the check requires one because the ticket has a `The board's review:` line. Status left at in-qa for the Project Lead to waive or to have an image (e.g. a spike plot) added. The analysis script ran on the newest sample recording without error; the recorder is off by default.
