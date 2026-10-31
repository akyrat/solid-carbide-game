---
id: T-468
title: Record a run's performance so its frame drops can be traced to their cause
status: in-progress
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

- [ ] With the recorder off, no file is written and the game behaves as before (test). (QA: pass / fail)
- [ ] With it on, a run writes a recording with per-frame times, Performance monitors, run counts, nested zones and event markers (test on a short scripted run checks each kind is present). (QA: pass / fail)
- [ ] The recording opens as Chrome trace JSON (a test validates the trace format: every begin has an end, nested correctly). (QA: pass / fail)
- [ ] The recorder's own overhead is measured and in the result notes (frame time with and without it). (QA: pass / fail)
- [ ] The analysis script prints the worst spikes with their time in run and nearby events, and each zone's time in spike frames against normal frames (test on a fixture recording). (QA: pass / fail)
- [ ] A sample recording's analysis output is in the result notes. (QA: pass / fail)
- [ ] The recording folder is git-ignored, and docs/working-with-the-board.md says how the board records a run and that the Project Lead analyses it. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

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

**Sample recording** (criterion 6): `bash game/tools/perf_sample_run.sh --record-perf --seconds=150 --start-at=300` (vsync on, like the board; weapons from level-ups). The script's own numbers: 8877 frames, mean 16.7 ms, median 4.4, p95 42.1, p99 229, max 386, 645 frames over 25 ms, recording on. Its analysis (`python game/tools/analyse_perf.py --top 5 --check-trace`):

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

What the sample says (for the Project Lead, to compare with the board's run): on the game's map, in the debug build, the drops are the minions: from about 25 alive, a physics step costs more than its own 20 ms (`minions.walk` about 0.16 ms per minion, `minions.place_and_depth` (each sprite's depth among the buildings) and `minions.path` with `nav.find_path` bursts), so Godot runs up to 8 catch-up physics steps a frame and frames reach 200 to 350 ms (a spiral). Smaller contributors: `weapon.flamethrower`, `weapon.underglow`, `sounds.sync` (0.8 ms a step), `level.car_depth_sort` (0.6 ms a step), occasional `draw.popup` bursts (12 ms) and the flamethrower's first step after it is gained (33 ms, seen in a shorter all-weapons sample). T-444 is working on the minion costs.

**Tests:**

- New: `game/tests/unit/run/test_perf_zones.gd` (6: off records nothing, nesting and self time, each-zones summed into one block, blocks beside real children, a missed end, clearing), `game/tests/unit/run/test_perf_recorder.gd` (4: off writes nothing and adds no recorder; on, a run writes frames/monitors/counts/zones/markers and a trace whose every begin has its end, nested; a spike keeps the frames around it in detail and frames far away only as counters; a new run on the same scene gets its own recording), `game/tools/test_analyse_perf.py` (9, on a made-up recording: loading, worst spikes with run time and nearby events, spike against normal zones, minion growth, ranked causes, new pipeline compilations as a change, trace check incl. a broken and a cut-short trace, newest recording and `main`, a cut line skipped).
- All three sets pass: `python -m unittest discover -s game/tools -p "test_*.py"`: 776 tests OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 614 tests OK; `GUT_TIME_LIMIT=1500 ... bash game/tools/run_tests.sh`: 192 scripts, 2331/2331 tests passing, 1,274,008 asserts, TESTS PASSED. (The first full GUT run had 1 failure, `test_weapons_wreck.gd` `test_after_the_run_ends_no_later_weapon_damages_in_the_same_step`: its stand-in weapon has no `perf_zone`; `weapons.gd` now falls back to `&"weapon"` for such stand-ins, and the whole suite was run again: all pass.) The tests ran with the machine shared with other agents' Godot runs, hence the long times.

**Screenshots:** none; tooling with no picture (the sample's output above is the result to look at; the recording `game/perf/2026-10-31_15-26-18/trace.json` opens in https://ui.perfetto.dev as a flame graph, it is git-ignored and stays in this ticket's folder).

**Refusals:** one Bash command (an inline Python edit of `docs/working-with-the-board.md` and `game/docs/setup/folder-layout.md`) was refused by a hook that guards task files' `lead` (the text contained a link it read as a task file); those two doc edits were made with the Edit tool instead, as the hook suggested running such parts on their own. Nothing else was refused.

**Documents affected:** `docs/working-with-the-board.md` (how the board records a run and that the Project Lead analyses it). Also new/updated game docs: `game/docs/game-loop/perf-recorder.md` (new), `game/docs/setup/folder-layout.md`, `game/README.md` (index).
