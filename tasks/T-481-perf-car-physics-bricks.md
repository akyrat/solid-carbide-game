---
id: T-481
title: Frame drops: car physics spikes to ~28 ms together with the bricks weapon
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/weapons/weapons.gd, game/scripts/driving/car.gd]
files_expected_to_change: [game/scripts/weapons/, game/scripts/driving/car.gd, game/tests/unit/, docs/weapons.md]
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

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder): the second cause is `car.physics`: about 28 ms in a spike frame against 0.37 ms usually, always in the same frames as `weapon.bricks` jumping from 0.01 ms to 6 to 17 ms, with the physics engine phase also at 25 to 50 ms, and a molotov fire alive. Every one of the 5 `weapon_reset` events was followed by a spike within 1 s.

Find why: likely the bricks weapon creating, moving or freeing physics bodies or shapes the car collides with (or something the car's physics step then rebuilds); check the reset too. Fix it so the car's physics step and the bricks weapon stay near their usual cost, with the weapon behaving and looking as today. Work with the Driving & Drift Agent's car.gd only as far as the cause needs. Measure before and after with the recorder or a scripted benchmark. Never write, move or commit anything in game/data/levels/.

The board's review: play a run with the bricks weapon and feel no hitches.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what made car.physics and weapon.bricks spike together, and what weapon_reset did, with the evidence. (QA: pass / fail)
- [ ] A measured before/after (recorder or scripted benchmark with the bricks weapon firing near the car) shows car.physics under 2 ms and weapon.bricks under 2 ms at their worst; numbers in the result notes. (QA: pass / fail)
- [ ] The existing weapon and car tests pass unchanged, so the bricks weapon and the car behave as before. (QA: pass / fail)
- [ ] docs/weapons.md notes anything about how the bricks weapon handles its bodies, if that changed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
