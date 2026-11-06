---
id: T-538
title: No frame drops with many minions alive
status: in-progress
from: project-lead
to: enemy-behavior
lead: Rails
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/docs/game-loop/perf-recorder.md, game/docs/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/tests/, game/tools/, game/docs/enemies/, docs/enemies.md]
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

Build Enemies, Decisions, "No slowdown from many minions". Write a repeatable stress measurement first (a script or test scene that spawns a run's worth of minions that are never killed, for example 100, 200 and 400, and reports the physics and process frame time; use the perf recorder's tools where they fit). Find what costs the most per minion (navigation, depth sorting, height lookups, collisions, the green spill and corpses from T-531) and make it cheaper without changing how minions behave. Only if that isn't enough, propose a cap on minions alive (in game/data/enemies.json, with what happens at the cap) and say so in the result notes. Record the before and after numbers.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging, letting minions pile up.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The stress measurement exists, is documented in game/docs/enemies/, and the result notes give before and after frame times at each minion count. (QA: pass / fail)
- [ ] With 200 minions alive the measured average frame time is under 16.6 ms, or the result notes explain why not and what the proposed cap gives. (QA: pass / fail)
- [ ] Existing minion behaviour tests still pass unchanged (QA's full run). (QA: pass / fail)
- [ ] docs/enemies.md Content describes the change and any cap. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A plot or screenshot in art-archive/T-538/screenshots/ shows frame time against minion count before and after. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees$t.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Enemy Behavior Agent, 2026-11-06: done

**Result.** The minions' work each step costs about half what it did. Nothing changed in how minions move, push apart, hit the car or are drawn: every shortcut is tested against the work it replaced, bit for bit where the old tests already checked that. With 200 minions alive in the game window, the average frame went from 14.3-15.6 ms to 8.6-10.4 ms (p99 at most 14.4 ms), under 16.6 ms. 400 alive is still over 16.6 ms (17.1-19.6 ms), so I propose raising the existing safety ceiling `max_minions_alive` from 100 to 200, not removing it (see Proposals).

**The stress measurement** (criterion 1): the T-444 benchmark `game/tools/minion_crowd_bench.sh` (Kaiju City, the parked car, N minions held alive round it, too tough to kill, topped up every frame), with two new options: `--window` (the game's window, vsync off, so drawing counts in the frame time; headless leaves it out) and `--csv=PATH --label=TEXT`. New `game/tools/minion_crowd_ab.sh` measures before (the enemy scripts at a git ref, `master`) and after in alternating rounds. I did it this way because other agents' test runs moved the numbers a lot (the CPU was about 85% busy during my runs). New `game/tools/plot_minion_crowd.py` draws the plot. Documented in `game/docs/enemies/minions.md`, "Performance, T-538".

**Before and after** (average frame ms, range over 3 rounds each, Kaiju City, 2026-11-05; CSVs in art-archive/T-538/crowd_headless.csv and crowd_window.csv):

| minions alive | headless before | headless after | window before | window after |
|---|---|---|---|---|
| 100 | 6.1-7.6 | 3.8-4.2 | 7.3-8.5 | 5.2-5.7 |
| 200 | 13.1-14.6 | 8.2-13.8 | 14.3-15.6 | 8.6-10.4 |
| 400 | 29.1-30.2 | 16.1-18.0 | 28.8-31.4 | 17.1-19.6 |

The headless 13.8 at 200 was one round hit by a burst of the machine's other work (its p99 was 38.7 ms; the other two rounds averaged 8.7 and 8.2). Window p99 at 200: before up to 19.3 ms, after up to 14.4 ms.

**Plot** (criterion 6): art-archive/T-538/screenshots/frame_time_vs_minions.png shows frame time against minions alive, before and after, headless and in the window, with the 16.6 ms line.

**What cost the most** (perf recorder zones, 200 alive, headless, before): walking 4.5 ms, placing the sprites with their depth order 4.1 ms, pushing apart 2.8 ms, paths and sight checks 1.6 ms, the loop and contact damage 1.2 ms, drawing 0.7 ms plus the redraws. The biggest single cause was the ground-height lookup: each minion did it about seven times a step, each through the ground index's `of()`, at about 4 microseconds each. The green spill and corpses (T-531/T-532) are not built yet, only planned, so there was nothing of theirs to measure. Minions are never killed in this measure anyway, as the ticket asks.

**What changed** (all exact; details in game/docs/enemies/minions.md):
- `minion.gd`: `ground_height()` is kept for the spot it was read at (keyed on position, ground and ground-index generation). `_ground_index()` is kept the same way. `_move()` makes a move over flat street at once (the case where `limit_motion` lets the move through whole) without building `limit_motion`'s answer.
- `enemy_ground_index.gd`: a static `generation` that every rebuild moves on. The spawner refreshes the index once a step (`_refresh_ground_index()`), so a ground changed between steps is read again.
- `enemy_depth.gd`: `begin_batch()`/`end_batch()` check the map's lists once for the whole crowd. When the cells round a minion hold nothing, its outline is not worked out. Buildings' and raised areas' outlines are kept with the grid, not rebuilt for every question.
- `minion_spawner.gd`: `_separation()` works out each pair once and adds it to both, in the same order of sums (bit-for-bit equal to `_separation_all_pairs()`, checked by the existing test). The car's surface is asked once a step and passed to each follower.
- `enemy_path_follower.gd`: `target(..., car_surface_now = -3)` is optional; the kaiju is unchanged.
- `minion_sprite.gd`: a sprite is redrawn only when `draw_key()` changes (direction, walk frame, size). While falling, landing, showing its shadow or without art, it is still redrawn every frame, as before.
- `kaiju_meteors.gd` not touched (T-539).

**Proposals for the playtest** (in data, where the code reads it):
- `max_minions_alive` 200 (was 100), in game/data/enemies.json `spawning`, with the reason in its `_comment`. The measure keeps 200 under 16.6 ms in the window (about 9-10 ms, p99 at most 14.4 ms), which leaves about 6 ms for weapons and effects; 400 is still over 16.6 ms. At the ceiling the timer waits until a minion dies or is left behind, as before. If 200 still drops frames, the fallback is 150. This doubles the largest crowd a player can face, so the board will see more minions in the late run. If the board would rather keep 100, only that number goes back and the speed-up stays.

**Tests** (criterion 5; I ran them in the foreground):
- New game/tests/unit/enemies/test_many_minions_performance.gd: 7/7 pass. It checks the height cache against the ground, and that it is read again after a rebuild; a minion's move against the old `limit_motion` move, over 600 moves near and away from rooftops and ramps; the batched depth order against each minion asked alone, and that a meteor boulder is seen at the next step; the follower with and without the given surface; the sprite's redraws.
- tests/unit/enemies (all, including T-444's exact-equality tests and every existing minion behaviour test, unchanged): 238/238 pass.
- tests/unit/weapons: 264 pass, 1 risky, 0 failing. The risky one, `test_offers_never_offer_a_weapon_at_its_last_tier`, does not assert; it was already like that and is not from this change.
- tests/unit/test_enemy_data.gd: 10/10 pass. Its ceiling check now expects 200 instead of 100: the only existing test changed, because the data number changed.
- game/tools/test_plot_minion_crowd.py: 4/4 pass.

**Notes for QA:** run the benchmark from the folder's root with `bash game/tools/minion_crowd_ab.sh --csv=<absolute path> --rounds=3 --window --counts=100,200,400 --seconds=5`. It opens a game window for each run. The numbers move with the machine's load, so compare before and after from the same run, not against my table.

**Documents affected:** docs/enemies.md (Content: the 200 ceiling under Spawning, and a new entry, "No slowdown from many minions (built in task T-538)"), game/docs/enemies/minions.md ("Performance, T-538", and the ceiling under Spawning), game/data/enemies.json (`max_minions_alive` and its `_comment`).
