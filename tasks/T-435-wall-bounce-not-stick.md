---
id: T-435
title: The car bounces off walls instead of sticking to them
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
