---
id: T-401
title: Text: the level creator's name for the meteor crater
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/extended-narrative.md, tasks/T-396-creator-sidewalk-car-names.md]
files_expected_to_change: [docs/level-design.md]
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

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", Meteor craters, 2026-10-30): holes the meteors left in the ground, a ground piece in the level creator that the car drives over. Write its side-panel name (under Ground) in the same voice and length as T-396's names, in Level design, Content, "Level creator text", where T-398 copies it into `creator_texts.json`. The look strip reuses T-396's "Model {n} of {count}" label. Run it through the style loop.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Level design, Content, "Level creator text" lists the crater's name, with where it appears. (QA: pass / fail)
- [ ] The name went through the style loop, with its score in the Style review. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
