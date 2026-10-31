---
id: T-438
title: A wall hit ends the drift
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-435]
documents_affected: [docs/drifting.md, game/docs/driving/collisions.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, game/docs/driving/collisions.md, tasks/T-435-wall-bounce-not-stick.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd]
files_expected_to_change: [game/scripts/driving/car_model.gd, game/scripts/driving/car.gd, game/tests/unit/, game/docs/driving/collisions.md, docs/drifting.md]
model: sonnet
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

The board, 2026-10-31, after playing T-435 (the wall bounce): a wall hit ends the drift (docs/drifting.md, Decisions, "A wall hit ends the drift"). Today a drift carries on through a wall hit with only the 50% combo cut, so a car drifting into a wall kept its drift climbing.

At the moment the car hits a wall, a building, a raised area's side, the map's edge or a boulder, a drift in progress ends, exactly as if the player had ended it: it pays once for the time it lasted up to the hit (Game loop architecture, Decisions, "A crash pays the trick in progress"), with its usual LONG DRIFT! popup, and then the hit's 50% combo cut applies as before. A new drift can start right after the bounce if the player keeps drifting. Everything else about the bounce (T-435) stays as it is. Whether the drift's payment comes before or after the combo cut follows what the code does today for crashes (T-315); say which in the result notes. Anything the docs leave open is a proposal for the playtest.

Never write, move or commit anything in game/data/levels/ (the board's level files).

The board's review: drift into walls, head-on and glancing, and see the drift end and pay at the hit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test drives the real car into a wall while drifting and asserts the drift ends on the hit step: the drift stops counting time, it pays once for the time up to the hit, and the hit's combo cut is still applied once. (QA: pass / fail)
- [ ] A test shows a drift that never touches a wall behaves as before (ends and pays when the player ends it). (QA: pass / fail)
- [ ] A test shows the player can start a new drift after the bounce. (QA: pass / fail)
- [ ] The T-435 wall bounce tests still pass unchanged. (QA: pass / fail)
- [ ] docs/drifting.md (Content) and game/docs/driving/collisions.md describe that a wall hit ends the drift. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the Driving & Drift Agent builds it in C:\solid-carbide-worktrees\T-438.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### Driving & Drift Agent, 2026-10-31

Built. `car.gd`: new `_end_drift_on_hit(impact)`, called in `_bounce()` and `_bounce_off_side()` right after `hit_obstacle` is emitted: any bounce with a speed into the surface clears `model.is_drifting` on that step. Drift amount fades as when the player lets go; keys untouched, so holding W+A starts a new drift on the next step. No change to `car_model.gd`.

- Order (asked in the ticket): today's crash code (T-315) pays the trick first, then cuts the combo (`crash_pays_trick_first` true). Unchanged: in a run, `hit_obstacle` -> `collision()` -> `crashed` -> `settle_tricks()` pays the drift, then the 50% cut applies once. Without a run, the trick detector pays when it sees the drift end on the same step. Either way it pays once, for the time of the steps up to the hit (the hit step itself is not counted).
- Proposal for the playtest: it ends on any bounce with speed into the wall, including a re-touch of the same wall while a bounce runs (no second `hit_obstacle`, so no second cut, but the new drift would end again). A knockback into a wall ends it too.
- Tests: new `game/tests/unit/test_wall_hit_ends_drift.gd` (3 tests, real car + RunState wired as run.gd does): drift ends on the hit step, pays once for the time up to the hit, combo cut once, run drift seconds reset; a new drift starts on the step after the bounce; a drift with no wall pays once when the player lets go. `test_wall_bounce.gd` unchanged and passing (14/14).
- Test sets: game/tools python 767 tests OK (1 skipped); tools python 585 OK; GUT 189 scripts, 2302 tests, all pass, 1271201 asserts.
- Docs: `docs/drifting.md` (Content, Collisions; crash-pays section) and `game/docs/driving/collisions.md` (Bounce). The Decision line was already in place.
- Screenshots: not captured (headless only; no movie run). Skipped; the board plays it directly.
- Nothing under game/data/levels/ touched.
- 2026-10-31, in-progress → in-qa: Built; all three test sets pass; ready for QA.

Screenshots (added before QA): `art-archive/T-438/screenshots/wall_hit_ends_drift_frame1.png` (1 frame after the hit: the drift has ended, the car bounced off the boulder, LONG DRIFT! and COMBO BROKEN! both shown) and `wall_hit_ends_drift_frame10.png` (10 frames after the hit, popups stacked, tyre marks of the drift stop at the hit). Fixture: `game/tests/fixtures/wall_hit_drift.tscn` (the T-315 crash fixture with the tutorial slides off); the log shows the LONG DRIFT! payment (1.72 s) and COMBO BROKEN on the same step as the hit.
