---
id: T-410
title: The task board shows the audit epic
status: in-qa
from: project-lead
to: project-lead
lead: Greenbull
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

- [ ] tools/taskboard/taskboard.html's AREAS has an entry named Audit with epics ["audit"], doc null, not excluded, and a colour no other entry uses. (QA: pass)
- [ ] With the task board served, a ticket with epic: audit appears in the Audit bubble (screenshot in the result notes). (QA: fail: paperwork - no screenshot in the result notes; serving a copy on port 8799 was refused by the command guard so QA could not take one. Code check: areaOf matches epic "audit" to the Audit bubble and T-410 has epic: audit)
- [ ] The task board's tests (if any under tools/) pass, with the counts in the result notes. (QA: pass - 582 tests OK, rerun by QA; tools/test_taskboard_areas.py 3 tests OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: tooling, merges after QA.

### 2026-10-30, In progress → In QA

Audit bubble added to the task board (counted in MVP), tests added, 582 pass.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

- Added `{ name: "Audit", doc: null, epics: ["audit"], color: "#f2e55c" }` to AREAS in tools/taskboard/taskboard.html (before Tooling; not excluded, so it counts in the MVP figure; the colour is used by no other area).
- New tests: tools/test_taskboard_areas.py (Audit entry shape, unique colours, no epic in two areas).
- `python -m unittest discover -s tools -p "test_*.py"`: 582 tests, OK.
- No screenshot taken: the running board on port 8765 was left alone and no browser was driven; the bubble comes from the same areaOf/AREAS code as every other epic, so QA can confirm it on a served copy.
