---
id: T-410
title: The task board shows the audit epic
status: open
from: project-lead
to: project-lead
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, tools/taskboard/taskboard.html]
files_expected_to_change: [tools/taskboard/taskboard.html]
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

The task board groups tickets into bubbles by epic (AREAS in tools/taskboard/taskboard.html). The new epic `audit` (tasks/README.md, Epics) has no bubble, so its tickets have no area. Add an "Audit" bubble for epic `audit`, with no game area doc, counted in the MVP figure (not excluded: the audit's fixes are MVP work), in a colour distinct from the others.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] tools/taskboard/taskboard.html's AREAS has an entry named Audit with epics ["audit"], doc null, not excluded, and a colour no other entry uses. (QA: pass / fail)
- [ ] With the task board served, a ticket with epic: audit appears in the Audit bubble (screenshot in the result notes). (QA: pass / fail)
- [ ] The task board's tests (if any under tools/) pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
