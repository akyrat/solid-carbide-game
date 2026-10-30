---
id: T-420
title: Thread the needle while scraping, and level data guards
status: open
from: project-lead
to: level-challenge
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, game/scripts/level/thread_the_needle.gd, game/scripts/driving/car.gd, game/scripts/level/ground_height.gd, game/scripts/level/level_spawn.gd, game/scripts/run/run.gd]
files_expected_to_change: [game/scripts/level/thread_the_needle.gd, game/scripts/level/ground_height.gd, game/scripts/run/run.gd]
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

Code holes, no new decisions. 1) Level design, Decisions, "Thread the needle": a touch within half a second before the crossing voids the pass. But touched() only runs on a new contact (car.gd hit_obstacle fires once per contact), so scraping along a paired barrier for more than 0.5 s and crossing while still touching pays. 2) ground_height.gd reads p.x, p.height and r.top_height without defaults (a missing key is a script error with half-loaded ground), an unknown ramp side falls through the match (a flat ramp), and a ramp with zero width or height divides by zero (NaN reaches car.height). 3) run.gd starts a level with no spawn at (0,0), while level_spawn.gd says the map's centre snapped to a cell, and never runs LevelSpawn.problem().

The board's review: scrape along a paired barrier through its gap and see no pass paid.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Crossing the gap line while still in contact with a paired obstacle pays nothing, however long the contact. (QA: pass / fail)
- [ ] A level file with a missing key, an unknown ramp side or a zero-size ramp loads with a clear error naming the piece, and no NaN height (test with bad level files). (QA: pass / fail)
- [ ] A level with no spawn starts the car where level_spawn.gd says; a spawn inside geometry is reported. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
