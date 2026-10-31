---
id: T-443
title: Minions spawn on a timer from the screen's edges, faster as the run goes on, and move 30% slower
status: in-progress
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/minions.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, game/docs/enemies/minions.md, game/data/enemies.json, game/data/combo.json]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/tests/unit/, game/docs/enemies/minions.md, docs/enemies.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-10-31 (docs/enemies.md, Decisions, "Minions spawn on a timer, and 30% slower"): today the spawner keeps a wanted number of minions around the car (12 growing to 20) and only spawns when fewer are around, one every 0.5 s. That rewards not killing them: the fewer the player kills, the fewer come, so runs end with few likes and weapons.

Change it to a constant timer: minions spawn one after another on a timer, however many are already around, from just beyond the edges of the visible screen, as today (street only, clear of buildings and boulders, 3 units out). The timer speeds up over the run, so more come later. The combo's spawn multiplier (combo.json, spawning) still raises spawning, now by shortening the timer instead of raising a count. Minions move 30% slower: move_speed 6 becomes 4.2. The kaiju is unchanged.

Propose for the playtest, with your reasons in the result notes: the spawn interval at the run's start and at the kaiju's arrival (7 minutes) and how it changes in between, and a safety ceiling on minions alive at once if you think the game needs one (the board wants a constant flow, so a ceiling should be high and only there to protect the frame rate; say what number and why). Use the T-444 measurement idea (a minion count and frame time) informally if it helps choose. Put the numbers in game/data/enemies.json with a clear comment. Remove the old wanted-count numbers or mark them unused.

Never write, move or commit anything in game/data/levels/.

The board's review: play a full run; minions should keep coming from the screen's edges whether you kill them or not, more of them as the run goes on, and noticeably slower than before.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows minions keep spawning on the timer while many minions are already alive (no top-up to a wanted count). (QA: pass / fail)
- [ ] A test shows the spawn interval at the run's start, at 7 minutes and in between follows the numbers in enemies.json, and that the combo's multiplier shortens it. (QA: pass / fail)
- [ ] A test shows a new minion appears beyond the visible screen's edge, on the street, clear of buildings and boulders. (QA: pass / fail)
- [ ] A test shows minions move at 4.2 units per second (30% slower than 6), and the kaiju's speed is unchanged. (QA: pass / fail)
- [ ] The proposed spawn numbers and any ceiling, with reasons, are in the result notes and in enemies.json's comment. (QA: pass / fail)
- [ ] docs/enemies.md (Content, "Spawning") and game/docs/enemies/minions.md describe the timer. (QA: pass / fail)
- [ ] Screenshots of a run late on, with many minions, are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the Enemy Behavior Agent builds it in C:\solid-carbide-worktrees\T-443.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Enemy Behavior Agent, 2026-10-31: built.**

**What changed**
- `game/scripts/enemies/minion_spawner.gd`: the wanted count is gone (`minions_wanted_now()` removed). `_spawn_step()` spawns one minion every `spawn_interval()` seconds however many are alive; only the safety ceiling (`max_minions_alive()`) holds the timer. `spawn_interval()` now reads the run's time and the combo (it sets `spawn_multiplier`, as `minions_wanted_now()` did; the `combo_raises_spawning` switch is unchanged). The spawn point is unchanged (ring 3 units beyond the visible screen, inside the map, on the street, clear of buildings, boulders and props). When no free spot is found the spawn retries on the next physics step instead of waiting a whole interval. New counter `spawned_total` (since the last `clear()`).
- `game/scripts/data/enemy_data.gd`: `minions_wanted()` replaced by `spawn_interval(run_seconds, multiplier)` (and the static `interval_from(section, ...)`), plus `max_minions_alive()`.
- `game/data/enemies.json`: `spawning` is now `spawn_interval_at_start_seconds` 1.2, `spawn_interval_at_boss_time_seconds` 0.3, `growth_until_seconds` 420, `max_minions_alive` 100, `spawn_margin_units` 3, with a comment that gives the reasons. The old `minions_at_start`, `minions_at_boss_time` and `spawn_interval_seconds` are removed. `minion.move_speed` goes from 6 to 4.2. The kaiju is unchanged (3).
- Docs: `docs/enemies.md` (Content: "Spawning", "Movement", "The combo raises spawning", and the kaiju's "half a minion's speed" corrected to "a little under three quarters") and `game/docs/enemies/minions.md` ("Spawning", "The combo raises spawning", "Movement", "Tests").

**Proposals for the playtest, with reasons**
- **Interval at the start: 1.2 s.** The starting gun fires one bullet every 1.2 s (`base_fire_interval`), and one bullet kills one minion. A player who shoots roughly keeps up, and a player who doesn't sees a crowd build. Old runs started with 12 minions arriving at once (one every 0.5 s); this start is gentler, but it never stops.
- **Interval at 7:00 (the kaiju's arrival): 0.3 s, i.e. 4 a second, then held during the kaiju's minute.** That is twice the old refill's top rate (one every 0.5 s, and only while under the count) and more than a mid-run gun kills alone (tier 4: about 3 bullets per 1 s volley), so the late run is crowded and the area weapons (flame, molotov, wiper) matter.
- **In between:** the rate (minions per second) grows in a straight line, not the interval. A straight line in the interval would put most of the growth in the last minute, because the rate is 1/interval. A straight line in the rate makes the number per minute grow evenly: 50 a minute at the start, 125 at 3:30 (0.48 s), 200 at 7:00. That is about 875 minions over the 7 minutes with no combo.
- **Combo:** unchanged data (`combo.json` spawning, up to x1.75). It multiplies the rate, so it divides the interval (0.3 s becomes about 0.17 s at the top combo).
- **Safety ceiling: 100 alive at once.** It is five times the old top count (20), so it should not be reached while the player drives and shoots (minions a whole screen behind are still removed). It is lower than I'd like for a "constant flow" because of the informal measurement below: the spawner's step costs about 0.2 ms per minion before T-444, so 100 alive is already about a whole 50 Hz physics frame. Once T-444 makes the crowd cheaper, its measurement should be used to raise the ceiling (only a data change).

**Informal measurement (T-444's idea; temporary test, not committed; this machine was busy with other Godot runs):** `last_step_usec` averaged over 130 physics steps on Kaiju City, with N minions placed 4 to 30 units round a parked car:

| alive | avg ms/step | worst ms/step |
|---|---|---|
| 20 | 2.9 | 3.6 |
| 50 | 8.7 | 19.3 |
| 100 | 19.7 | 37.9 |
| 150 | 30.8 | 60.4 |
| 200 | 40.7 | 68.3 |
| 300 | 67.4 | 112.9 |

Roughly linear, about 0.2 ms per minion per step. Separation is O(n^2), but the paths and walking dominate at these counts. This is T-444's job.

**Tests** (new or changed):
- `game/tests/unit/enemies/test_minions.gd`:
  - `test_spawning_follows_the_timer_not_a_wanted_count`.
  - `test_minions_keep_spawning_while_many_are_alive`: 40 alive, still about one per interval over 10 intervals (AC 1).
  - `test_spawn_interval_at_the_start_at_7_minutes_and_between`: 1.2 s, 0.48 s at 3:30, 0.3 s at 7:00 and held, 11 spawns in the first 10 intervals at 7:00, never slowing down. Together with `test_a_high_combo_shortens_the_interval_by_the_data_amount` (interval / 1.75 and really spawning about 17 in 10 base intervals) and `test_no_combo_means_no_extra_spawning`, this covers AC 2.
  - `test_a_new_minion_appears_beyond_the_screen_edge_on_the_street`: real spawns on the ring beyond the visible screen, on the street (`is_street`), clear of buildings and boulders (AC 3).
  - `test_the_safety_ceiling_holds_the_timer`.
  - `test_minions_move_30_percent_slower_and_the_kaiju_is_unchanged`: 4.2 = 6 x 0.7, the kaiju 3, and a spawned minion walks at 4.2 (AC 4; `test_minion_moves_towards_the_car` still checks the actual walking distance at the data's speed).
  - The building walk test now gets 30 s instead of 20 s (slower minion).
- `game/tests/unit/test_enemy_data.gd`: keys, `test_spawning_speeds_up_over_the_7_minutes`, `test_combo_shortens_the_interval`.
- `game/tests/unit/enemies/test_meteors_minions_pickups.gd`: the fallback-to-default test for the new keys.
- `game/tests/unit/enemies/test_enemies_on_heights.gd`: `CLIMB_LIMIT_SECONDS` 40 changed to 60 (40 / 0.7 = 57), because the two rooftop climb tests failed at the slower speed, as expected.

**Test results:**
- `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 767, OK (skipped=1).
- `python -m unittest discover -s tools -p "test_*.py"`: Ran 591, OK.
- GUT: all 190 test scripts, 2318 tests, 2318 passing. Other agents' Godot runs kept the machine busy, and a single foreground call is capped at 10 minutes, so I ran `game/tools/run_tests.sh` (with `GODOT_BIN` set) in six foreground chunks that together cover every script under `res://tests/`:
  - enemies + weapons + game: 34 scripts, 524 tests
  - hud + level_creator + helpers: 44 scripts, 486 tests
  - run: 29 scripts, 377 tests
  - the 83 top-level unit scripts, through `-gdir=res://tests/fixtures -gtest=...`: 3 + 37 + 43 scripts, 58 + 410 + 463 tests

  Two attempts to run the 83 top-level scripts in larger chunks hit my 590 s limit. These were not failures: one ran the whole suite by mistake because `-gtest` alone adds to the config's dirs.

**Screenshots** (`art-archive/T-443/screenshots/`, fixture `game/tests/fixtures/minions_timer_demo.tscn` and `minions_timer_early_demo.tscn`: the run's clock is moved forward, then the spawner's timer runs 15 s with the car parked and no shooting):
- `late_run_6m40_48_minions.png`: clock at 6:40 (interval 0.31 s), 48 minions came in from the edges in 15 s and crowd the car.
- `early_run_0m05_14_minions.png`: clock at 0:05 (interval 1.16 s), 14 minions in the same 15 s.

**Documents affected:** `docs/enemies.md`, `game/docs/enemies/minions.md` (and the data comment in `game/data/enemies.json`). The long GDD still has the old Spawning text and is regenerated at merge.

Nothing under `game/data/levels/` was touched. No refused actions.
