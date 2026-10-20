---
id: T-211
title: The board describes the tutorial levels
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: level-challenges
milestone: final-release
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [docs/level-design.md, docs/drifting.md]
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

**Not a request now (board, 2026-10-20).** The board wants short tutorial levels that show the player the tricks, one trick at a time (Level design, Decisions, "Tutorial levels"). Nothing is built until the board describes them.

When the board picks this up (drag to Planning), the Project Lead asks:

- which tricks get a tutorial;
- what each level looks like;
- how the player is told what to do (which needs a Narrative Theme text task);
- when the tutorials are played (before the first run, or from a menu);
- whether they come before or after the arrow-key tricks are built.

The answers go into Level design, then into tickets for the agents.

## Acceptance criteria

- [ ] Level design has the board's description of each tutorial level (QA: pass / fail)
- [ ] Tickets for building them exist, linked to this one (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
