---
id: T-468
title: Record a run's performance so its frame drops can be traced to their cause
status: open
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
