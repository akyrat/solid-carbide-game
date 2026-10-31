---
id: T-438
title: A wall hit ends the drift
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
