---
id: T-380
title: Bug: minions get stuck on walls at the bottom end of ramps
status: done
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/level-design.md, game/docs/level/elevation-sample-map.md, game/scripts/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/scripts/level/, game/data/, game/tests/unit/, game/docs/enemies/, docs/enemies.md]
model: opus
qa_rounds: 2
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

The board's decision (Enemies, Decisions, "Minions don't get stuck on ramps", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**; a bug). The board: enemies get stuck on walls when they try to come to the car and go round a corner, mostly "on like the beginning of the ramp ... the bottom end of the ramp". Reproduce it on the elevation map (a scripted run with the car on a rooftop or past a ramp and minions chasing it), find why (for example the navigation or the ramp's wall at its tall end, a corner the path cuts, or a minion's radius against the ramp's side), fix it so they find their way round, and keep the fix general (any level from the level creator). Coordinate with the minions-twice-as-big ticket if it is in the same build: test with the bigger radius too.

The board's review: play a run on the elevation map and watch minions chase you round ramps.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test reproduces a minion stuck at the bottom end of a ramp before the fix (named in the result notes) and passes after it. (QA: pass)
- [ ] Over a scripted chase on the elevation map, no minion stays stuck against a wall for more than 2 seconds (test). (QA: pass)
- [ ] Enemies, Content and the game docs describe the cause and the fix. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the fix has its own tests. (QA: pass, round 2: 165 scripts, 2062 Godot tests; first run 2061, the one failure the known test_wreck revive flake, 23/23 on rerun alone; test_minions_round_ramps 13/13 and test_minions 53/53 alone; Python sets green per qa_check; qa_check's "documents: game/docs/enemies/ not changed" is a folder-path false positive, minions.md and ledges-and-rooftops.md did change)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F, on top of T-379's bigger minions.

### 2026-10-30, In progress → In QA

Fixed: minions now walk straight only when the way to the car is clear, otherwise by a path round ramps and corners; stuck minions in a scripted chase went from 8 to 0. GIF in art-archive/T-380/screenshots.

### 2026-10-30, In QA → Needs playtest

QA passed: stuck minions 8 to 0 in the scripted chase, all three test sets green. Play the elevation map and watch minions round ramps.

### 2026-10-30, Needs playtest → In progress

Sent back: fails on top of master's platforms and bigger minions (2 minions stuck at a building corner). Fixing, then QA again.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Enemy Behavior Agent, 2026-10-30.** Built on T-379's branch (minions `size_scale` 2, body radius 1; its 0.5 off ground edges kept).

**Reproduction.** A scan on the elevation map (car parked at 13 spots round both ramp pairs, 2 x 24 minions in rings, each chasing alone for 15 s) found 36 minions standing still more than 2 s away from the car, all at three kinds of place. The tests in `game/tests/unit/enemies/test_minions_round_ramps.gd` keep one of each with the old rule (`follower.by_sight = false`) and show it stuck:
- `test_reproduced_stuck_at_the_bottom_end_of_a_ramp_before_the_fix` (the board's case): car at (-66, -58) east of ramp-nw-0-3, minion from (-92, -58) west of it; it ends at about (-77, -54), the ramp's bottom end.
- `test_reproduced_stuck_in_the_pocket_of_a_ramp_side_and_its_rooftop_before_the_fix`: stands at about (-86.6, -65.4), the corner of the ramp's west side and roof-nw-3's south edge.
- `test_reproduced_stuck_on_a_building_side_before_the_fix`: stands on the building's east side at (-65, -36.8), 5 units short of its corner.
Each has a matching "no longer stuck" test (both detour sides) that passes with the fix.

**Root cause.** `enemy_path_follower.gd` sent an enemy straight at the car whenever both were on the same surface (the street, one rooftop, one ramp), even with a wall between them. (1) At a ramp's foot the minion stepped onto the low end of the ramp, which is another surface, got a path back to the foot's point, stepped back onto the street, walked straight again, and so went back and forth at the bottom end. (2) Walking head-on into a ramp's high side, `walk()`'s `detour_side` sent half of them north into the pocket where the side meets the rooftop's edge, where they stood still. (3) Against a building's side short of its corner, the slide along it came out just under `walk()`'s 0.5 threshold, so it detoured the other way and back on the spot. After the first fix, one more appeared: with the 1-unit body, taking a path's point at `REACH` 1 unit made it turn into a building's corner too early and jam there.

**Fix** (navigation only, minions only; the kaiju keeps the surface rule):
- `enemy_navigation.gd`: `line_clear(a, b, half_width)`. It samples the line on the 2-unit grid (and two lines 0.5 to either side) every 1 unit. Every cell must be open (the end cells excepted) and within `MAX_STEP` of the one before, the same rule as the grid's links, so a blocked line always has a path round.
- `enemy_path_follower.gd`: `by_sight`. The follower walks straight only while `line_clear` to the car is true (checked every 0.1 s), on any surface, and otherwise follows a path. With it, path points count as reached at `SIGHT_REACH` 0.5 instead of 1.
- `minion_spawner.gd`: sets `by_sight` on every minion.
The fix works on any map with heights, levels from the level creator included, since it reads only the navigation grid. Cost per minion: one grid line check every 0.1 s (at most 3 x about 40 array reads).

**Counts.** Scan: 36 stuck before, 0 after. Scripted chase test (`test_scripted_chase_no_minion_stuck_against_a_wall_over_2_seconds`): 14 car stops round both ramp pairs and the buildings beside them, a ring of 16 minions at each (110 in all), walking with pushing apart and the path budget, 6 s per stop. With the old rule 8 stood still more than 2 s; with the fix 0.

**Tests.** New: `game/tests/unit/enemies/test_minions_round_ramps.gd` (10 tests: the size check, 3 reproductions, 3 fixes, `line_clear`, the follower's sight rule, the scripted chase). All three sets pass:
- `bash game/tools/run_tests.sh`: 159 scripts, 1961 tests, 1961 passing.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 678 OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 579 OK.

**Recording.** `art-archive/T-380/screenshots/minions_round_ramp_foot.gif` shows six minions starting west of ramp-nw-0-3 (the old stuck spots) going round its foot to the car, with stills `frame_000.png`, `frame_083.png` and `frame_165.png`. Fixture: `game/tests/fixtures/minions_round_ramps_gif.tscn`, recorded with `--fixed-fps 50 --write-movie`, then `game/tools/frames_to_gif.py --skip 2 --crop 0.7 --shared --first 20`.

**Refused.** A hook refused one `python -` heredoc for the doc edits, because its text named the ticket's art-archive folder. I made those edits with the Edit tool instead. Nothing else was refused.

**Documents affected:** `docs/enemies.md` (Decisions, "Minions don't get stuck on ramps": built in T-380; Content, "Finding the way": the cause and the fix), `game/docs/enemies/minions.md` ("Round ramps and corners (T-380)"), `game/docs/enemies/ledges-and-rooftops.md` (`enemy_path_follower.gd`: `by_sight`, `line_clear`).
- 2026-10-30, needs-playtest → in-progress: Merging into master stopped (2026-10-30): with master's T-405 platforms, T-379 bigger minions and T-406 revive, test_minions_round_ramps test_no_longer_stuck_on_a_building_side_or_its_corner and test_scripted_chase (2 stuck at 94.57,40.55 near the south-east building's corner), test_minions test_minions_far_behind_are_removed and test_wreck test_in_the_run_a_sliding_wreck_picks_up_a_health_pickup_and_drives_again fail. Back to the enemy-behavior agent: merge master in and fix.

### 2026-10-30, the fix on top of master (T-405, T-379, T-406, T-408)

Merged master into the branch (no conflicts). Causes and fixes:

- **Stuck at the south-east short platform's corner** (test_no_longer_stuck_on_a_building_side_or_its_corner, the scripted chase: 2 stuck at (94.57, 40.55)). T-405 turned the short building block@66,12 into a height-3 platform at x 82.5..94.5, y 28.5..40.5. The navigation grid (2-unit cells) assumed every edge lies on even units, so the cells beside this platform have street heights at their centres while the platform reaches 0.5 into them. Two effects: `line_clear` saw a clear line past the corner, which the body (0.5 off an edge) could not walk; and a path's points sat 0.5 off the edge, where the body did not fit, and `walk()`'s detour side pointed it back north along the wall into the corner. Fix in `enemy_navigation.gd`: `rough` cells (an area's edge within BASE_MARGIN), where `line_clear` also samples the true ground every 0.25 units; and `off_edges()` on every found path, which moves a point in a rough cell 0.5 units away from higher ground found within 0.9 units (never a drop's landing point). Grid-aligned edges are 1 unit off every cell centre, so their paths are unchanged (tested).
- **test_minions_far_behind_are_removed.** Walking by sight, a far minion on the street gets a path just to go round a T-405 platform, and `_despawn_far()` kept every minion with a path (meant for minions on their way to a ramp: before T-380 a path meant "on another surface"). Fix in `minion_spawner.gd`: kept only with a path and on another surface than the car. The test's assumption is still right, unchanged.
- **test_wreck (sliding wreck picks up a health pickup):** not caused by this ticket. It failed once in my runs and passed on reruns (2 of 2, and in the full run); the Project Lead found it flaky on plain master (the gun kills minions near the wreck) and is giving it its own ticket. Not touched.

New tests in `test_minions_round_ramps.gd`: the line past the platform's corner is not clear, the path round it keeps its points 1 unit off, grid-aligned paths are unchanged, a far minion detouring on the car's surface is removed. No existing test was loosened.

Tests: game/tools 701 OK (1 skipped), tools 579 OK, GUT 2062 of 2062 passing.

Refused: a hook refused `export $(grep GODOT_BIN .env | xargs)` (it can't tell `export $SUB` won't write a ticket). I passed the path as `GODOT_BIN='...' bash game/tools/run_tests.sh` instead, which runs only the test script.

**Documents affected (this round):** `docs/enemies.md` (Content, "Finding the way"), `game/docs/enemies/minions.md` ("After T-405 and T-379"), `game/docs/enemies/ledges-and-rooftops.md` (`line_clear`, `off_edges`).
- 2026-10-30, in-progress → in-qa: Fixed on top of master: line_clear checks true ground near T-405's half-unit platform edges, paths keep off them, far-off keep only on another surface. All three test sets green. test_wreck flake not touched (own ticket).
- 2026-10-30, in-qa → needs-playtest: QA round 2 passed: ramp/corner tests, scripted chase and far-behind removal green on top of master; test_wreck flake passed on rerun alone.
- 2026-10-30, needs-playtest → done: Build F LGTM by the board; fixed on top of master's platforms and bigger minions, QA round 2 passed
