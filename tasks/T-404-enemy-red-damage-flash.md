---
id: T-404
title: Enemies flash red when they take damage
status: in-progress
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, tasks/T-403-car-red-damage-flash.md, game/scripts/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, game/docs/enemies/, docs/enemies.md, art-archive/]
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

The board's decision (Enemies, Decisions, "A red flash when an enemy takes damage", 2026-10-30): "and same for the enemies." Every enemy, minions and the kaiju, flashes red when a weapon or the car hits it, reusing T-403's helper so it looks the same as the car's (its worktree is branched from T-403's branch once T-403 passes QA, so the board plays both together). A hit that kills a minion may skip the flash if its death effect plays at once (your proposal). For the kaiju, whether it flashes on every hit or only in its vulnerable window is a proposal. With many minions hit at once it must stay cheap (no per-enemy material copies if a shared shader parameter works). Code only, no new art.

The board's review: play a run, hit minions with each weapon and the car, and hit the kaiju.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Minions and the kaiju flash red when a weapon or the car damages them, using T-403's helper (tests). (QA: pass / fail)
- [ ] The proposals for kills and the kaiju are in the result notes, and behave as written (tests). (QA: pass / fail)
- [ ] Many minions flashing at once keep the frame time as before, measured in the result notes. (QA: pass / fail)
- [ ] Enemies (Content) and game/docs/enemies/ describe it. (QA: pass / fail)
- [ ] A GIF of minions and the kaiju being hit is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F, on top of T-403's HitFlash helper.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
