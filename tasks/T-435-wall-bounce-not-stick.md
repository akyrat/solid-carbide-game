---
id: T-435
title: The car bounces off walls instead of sticking to them
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/docs/driving/collisions.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/collisions.md, docs/game-loop-architecture.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd]
files_expected_to_change: [game/scripts/driving/car.gd, game/tests/unit/, game/docs/driving/collisions.md, docs/drifting.md]
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

The board, 2026-10-30, after playing master: the car sticks to any wall while W is held ("the wall grabs me when I keep accelerating on it"); drifting into a wall with W and a steering key held, the car stays stuck on the wall and the drift keeps climbing. Cause, from the docs (confirm it in the code): the bounce sends the car back at 0.25 of its speed, but W snaps the car back to cruise speed the next frame, so it is pressed against the wall (docs/drifting.md, Decisions, 2026-10-10, which the board has now replaced).

The board's new rule (docs/drifting.md, Decisions, "The car bounces off walls", 2026-10-30): the car really bounces off walls, buildings, platform and ramp sides, the map's edge and boulders, even with W held. The bounce scales with how hard the car hits (its speed into the wall), up to a maximum, so a very fast hit is not a comically big bounce. Not a throttle cut: the board rejected disabling the throttle for a time after a hit. How to make the bounce win over W (for example W not snapping the speed back while the bounce's own speed lasts), the scale and the cap are the agent's proposals for the playtest, on the tuning panel next to "Wall bounce".

What a wall hit does to a drift: not decided by the board yet (asked 2026-10-30: end the drift, or keep it with the 50% combo cut). Leave it as it is today unless the Project Lead adds the answer here.

Never write, move or commit anything in game/data/levels/ (the board's level files). Test against the map files read-only.

The board's review: drive into walls at slow, cruise and top speed, head-on, glancing and while drifting, holding W.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The cause of the sticking is in the result notes, confirmed in the code. (QA: pass / fail)
- [ ] Tests drive the real car into a building side, a raised platform's side from the street, the map edge and a boulder, head-on, at about 45 degrees and while drifting into it, with W held throughout, and assert that the car moves away from the wall after the hit (its distance from the wall grows for at least a short time) instead of staying against it. They fail on master before the fix (shown in the result notes) and pass after. (QA: pass / fail)
- [ ] A test shows the bounce grows with the hit speed and stops growing at the cap: a harder hit bounces further than a slow one, and hits above the cap's speed bounce the same distance. (QA: pass / fail)
- [ ] There is no time after a hit during which W does nothing (code read; the throttle is never disabled by a timer). (QA: pass / fail)
- [ ] The scale and the cap are on the tuning panel's Collisions group, with their defaults in the result notes as proposals for the playtest. (QA: pass / fail)
- [ ] docs/drifting.md (Content, Collisions) and game/docs/driving/collisions.md describe the new bounce. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Filed from your playtest: the car really bounces off walls even with W held, scaled by the hit, capped. Driving & Drift agent started.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Driving & Drift Agent, 2026-10-30.**

**Cause, confirmed in the code.** `car_model.gd`, `update_velocity()`, step 5: with W held and the forward speed below cruise speed, the forward speed is snapped straight to cruise (`fwd = cruise`). `car.gd` bounces the car (`_reflect()`, the speed into the wall reversed x 0.25) only *after* the step's move, so the next step's `update_velocity()` sees the bounced velocity and the snap overwrites it before the car moves: head-on, the forward speed -2.75 becomes +11 into the wall again; glancing or drifting, the forward speed has dropped below cruise after the hit and is snapped back along the nose, which points into the wall. The car never moves away (master: the new tests measure 0 to -0.03 units "away" after every hit, see below), and a held drift keeps climbing on the wall because nothing about the drift changes.

**What changed.**
- `game/scripts/driving/car_model.gd`: new `bounce_normal`. While it is set and the nose points into that wall, W held below cruise speed does not snap: it speeds the forward speed up toward cruise at `tuning.wall_bounce_pull`. So the bounce first carries the car away, W slows it and brings it back (a smaller bounce on the next touch, like a ball). It ends, and W snaps as before, when the forward speed is back at cruise, W is let go or S reverses, the car is in the air, or the nose turns away from the wall. No timer anywhere; W acts on every step (test `test_w_still_acts_on_the_step_right_after_a_hit`).
- `game/scripts/driving/car.gd`, `_reflect()`: the car leaves the wall at `wall_bounce x min(hit speed, wall_bounce_max_hit_speed)` (speed along the wall kept) and sets `model.bounce_normal`. Same for walls/buildings/map edge/boulders (physics bodies) and raised areas' sides (`_bounce_off_side`).
- Hit counting (proposal): coming back onto the same wall during the bounce cycle is the same hit, so W held into a wall is still one crash (one combo cut), as before. The wall counts again once the player has really left it: W let go, the nose turned away, the car in the air, or it got further away than the furthest bounce (`_update_bounce_rearm`). Placing the car (setting `ground`) clears it.
- `game/scripts/driving/car_tuning.gd`: two new settings on the tuning panel's Collisions group, next to "Wall bounce" (the panel builds its sliders from `COLLISION_SETTINGS`, no panel code changed).
- What a wall hit does to a drift: unchanged (drift amount and keys untouched).

**Proposals for the playtest (defaults).**
| Slider (Collisions group) | Key | Default |
| --- | --- | --- |
| Wall bounce | `wall_bounce` | 0.4 (was 0.25) |
| Wall bounce: hardest hit | `wall_bounce_max_hit_speed` | 16.5 units/s (the top speed) |
| Wall bounce: W pull-back | `wall_bounce_pull` | 12 units/s per s |

Measured with W held (real car, flat wall): head-on at cruise 11 bounces 0.91 units away, then a second small hop (0.13); head-on at 16.5 and at 30 both bounce 1.75 units (the cap); 45 degrees at 11 bounces 0.38 then slides along the wall; drifting in, it bounces off and carries on round its drift circle.

**Tests.** New `game/tests/unit/test_wall_bounce.gd` (14 tests): the real car into a building side, the map's edge (long wall), a 3-unit boulder and the elevation test platform's north side from the street (data/level/elevation_test.json, read only), each head-on, at about 45 degrees and while drifting (W + A), W held throughout; each asserts the distance from the hit point grows for 3 steps and reaches at least 0.15 units. Plus the cap test (cruise < halfway < cap+1, and cap+1 == cap+15 within 1e-3) and the W-acts test. **On master (before the fix): 13 of 14 failed** (every bounce case: away distance about -0.0006 to -0.03 units, max never above 0; the cap test errored on the missing setting); only the W-acts test passed, as it should. After the fix: 14/14.
Updated existing tests: `test_car_collisions.gd` (default 0.4; top-speed hit now capped at 16.5 x 0.4 = 6.6; the full-bounce case checked on the hit step and then that the car leaves the wall; new `test_bounce_cap_and_pull_sliders`), `test_car_footprint_height.gd` (`test_at_45_degrees_no_corner_enters`: the car now bounces off the platform's side and meets the ramp's north side further on, a second, different wall; the test allows that second hit and checks both are north sides).

**Test sets (all in the worktree):** GUT 2207/2207 passed (`TESTS PASSED`; test_kaiju_path_size.gd passed too); `python -m unittest discover -s game/tools -p "test_*.py"`: 752 OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 582 OK.

**Screenshots:** `art-archive/T-435/screenshots/bounce_distance_w_held.png`, a plot from the real car (distance from the wall vs time after the hit, W held) for head-on at 11, 16.5 and 30, 45 degrees and drifting, with master's "stuck at 0" line.

**Nothing under game/data/levels/** was written, moved or committed.

**Documents affected:** `docs/drifting.md` (Content, Collisions, task T-033 paragraph), `game/docs/driving/collisions.md` ("Bounce": the cause, how the bounce wins over W, the settings table; "Knockback" sentence).
- 2026-10-30, in-progress → in-qa: Done: W no longer snaps the car back into a wall it bounced off; bounce = 0.4 x hit speed capped at 16.5, W pulls back at 12 u/s2 (proposals). Tests: GUT 2207/2207, game/tools 752 OK, tools 582 OK. Details in result notes.
