---
id: T-411
title: The car's height uses its whole footprint, not its centre
status: open
from: project-lead
to: driving-drift
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car_height.gd, game/scripts/driving/car.gd, game/scripts/driving/drift_marks.gd]
files_expected_to_change: [game/scripts/driving/car_height.gd]
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

Bug. The car's height model treats the car as one point at its centre (car_height.gd _walk), while buildings stop its 1x1 body (car.gd) and it is drawn 3 units long. Against a rooftop or ramp side, the front half sits inside the raised area before it bounces; on a rooftop the car hangs up to about 1.5 units over the edge before it falls; tyre marks streak down the wall at roof edges (drift_marks.gd lifts each tyre by its own height). The board asked for an assessment of the root cause and the best approach first: a Driving & Drift agent is assessing it read-only, and its findings and the acceptance criteria are added here before work starts. Must fit the board's ramp decision of the same day (every ramp launches the car off its top, faster means higher) and short buildings as platforms (T-405).

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Criteria to be written by the Project Lead from the assessment, before the ticket leaves planning. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
