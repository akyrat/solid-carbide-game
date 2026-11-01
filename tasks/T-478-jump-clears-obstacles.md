---
id: T-478
title: Jump: the Space hop clears obstacles lower than the car
status: in-progress
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/driving/jump_power_up.gd, game/data/power_ups.json, tasks/T-461-jump-space-makes-a-small-hop.md]
files_expected_to_change: [game/scripts/driving/, game/tests/unit/, docs/drifting.md]
model: sonnet
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

The board, 2026-11-01 (Drifting, Decisions, "The Jump clears obstacles"): with the Jump power-up, the car can hop over obstacles with Space. Today every obstacle (physics layer 1: boulders, buildings, walls, the map's edge) blocks the car at any height (car.gd, LAYER_OBSTACLES), so the hop (about 1 unit high at tier 1) can't clear anything. Enemies already work: the board confirmed the car takes no damage while above them.

Make the car pass over an obstacle while its height is above that obstacle's top, and meet it as a wall (the bounce, as today) when it is lower. The map's edge always blocks. Buildings and walls taller than the hop keep blocking. Find each obstacle's height where the game already has it (the ground's heights, boulder records); where an obstacle has none, propose one in the result notes and say which obstacles a tier-1 hop clears and which it doesn't. The car never lands inside an obstacle (as Content, "Elevation: the platform's sides", for platforms). Keep the jump's numbers. Never write, move or commit anything in game/data/levels/.

The board's review: own the Jump, hop over a boulder, and hit a tall building.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows the car hopping (Jump power-up, tier 1) over a boulder lower than the hop's height, with no bounce and no hit_obstacle. (QA: pass / fail)
- [ ] A test shows the same car, too low or on the ground, bouncing off that boulder as today. (QA: pass / fail)
- [ ] A test shows a building taller than the hop still blocks the car in the air, and the map's edge always does. (QA: pass / fail)
- [ ] A test shows the car never ends a physics step inside an obstacle when it lands. (QA: pass / fail)
- [ ] The result notes list each obstacle kind with its height and whether each Jump tier clears it. (QA: pass / fail)
- [ ] A GIF or screenshots of the car hopping over a boulder are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/drifting.md (Content) describes how the hop clears obstacles. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the Jump clears obstacles lower than the car.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (Driving & Drift Agent).** Findings first: the pass-over-by-height machinery already existed (T-405: `mvp_map.gd` `update_car_obstacles`, props and boulders as collision exceptions by height). What stopped the hop was the numbers: a boulder's height was its 3-unit diameter and the tier 1 hop peaks at 1.04, so nothing but the smallest props was clearable, and a car that landed over an obstacle was left inside it, sliding out.

**How it works now**
- Boulders (the map's and the meteors') are **0.8 units high** (`BOULDER_HEIGHT_UNITS`, proposal; width stays the 3-unit diameter), lower than the car's 1. The car passes over an obstacle once its height is at the top (minus 0.05) or above; lower, it meets it as a wall with the bounce and `hit_obstacle`, as before. Walls (skyscrapers) and the map's edge block at any height; 3-unit platforms (short buildings) keep their side-wall rule.
- Never landing inside (proposal): `mvp_map.gd obstacle_floor()` gives the top of the obstacle the car overlaps and is over; car.gd's `floor_query` asks it just before the height step, and `car_height.gd` (`floor_height`, `set_floor`) lands the car on that top, lets it drive along it, and makes it fall when it leaves the edge. Wired in run.gd and elevation_sample_map.gd.
- Jump numbers unchanged. Timing at tier 1: the hop reaches 0.75 about 0.2 s after Space, so Space must be pressed roughly 6 to 7 units short of a boulder at speed; later, it bounces (tested).

**Obstacle table** (hop peaks: tier 1 1.04, tier 2 1.5, tier 3 2.04, tier 4 2.67)
| Obstacle | Height | Clears |
|---|---|---|
| Boulder (map and meteor) | 0.8 (proposed) | all tiers |
| Props 0.9, 0.95 (creator_assets.json height_units) | 0.9, 0.95 | all tiers |
| Props 1.2 to 1.5 | 1.2 to 1.5 | tier 2 and up (1.5 is borderline at tier 2) |
| Prop 2.2 | 2.2 | tier 4 |
| Props 3.3 and 5.35 | 3.3, 5.35 | none |
| Short buildings (platforms) | 3.0 | none (side is a wall below 3) |
| Skyscrapers | 30 (wall) | none |
| Map's edge | infinite | never |

**Tests:** new `game/tests/unit/test_jump_clears_obstacles.gd` (8 tests: hop clears boulder with no hit and never inside; ground and too-late and no-power-up bounce; lands on top; wall and edge block in the air; table). Counts: GUT 2326/2326 (191 scripts); `game/tools` unittest 849 OK (1 skipped); `tools` unittest 633 OK.
**Files:** car.gd, car_height.gd, mvp_map.gd, run.gd, elevation_sample_map.gd, tests/fixtures/jump_boulder_demo.gd and jump_boulder_gif.tscn, docs/drifting.md (Content, "The Jump clears obstacles (task T-478)").
**GIF and screenshots:** `art-archive/T-478/screenshots/jump_over_boulder.gif`, `jump_over_boulder_montage.png`.
**Note for the board's playtest:** the boulder is drawn big (3 wide, taller than 0.8 looks), so a hop over it reads as flying over a tall rock; the car's sprite also draws behind the boulder sprite for a moment mid-hop (depth order, not changed here). If 0.8 feels wrong, it is one constant.
