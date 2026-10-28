---
id: T-353
title: Token spend: open tickets list the area docs instead of game/README.md
status: open
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-346]
documents_affected: []
files_to_read_first: [tasks/README.md, tasks/T-346-game-readme-split-into-area-folders.md, game/README.md]
files_expected_to_change: [tasks/]
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

Split out of T-346 (the Project Lead, 2026-10-28). T-346 split game/README.md into area files under game/docs/ with a short index, but its last step, rewriting `files_to_read_first` in the 33 open and blocked tickets so each lists the area files it needs instead of game/README.md, was refused by the guard (a script that edits many ticket files at once; 'inline code that names task files'). The agent did not work around it. The script it wrote is kept at C:\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\2c104619-72b8-44ca-a9af-e1e03eadc5a7\scratchpad\fix_tickets.py. Until this is done, tickets that list game/README.md still work: the README is now a small index that points to the area files. The board decides how this edit is allowed: (a) the board runs the script itself, (b) the guard learns a safe way to edit ticket headers other than status (a ticket for the guard), or (c) leave the old references, since the index already makes them cheap.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] No ticket that is not done or cancelled still lists `game/README.md` alone in `files_to_read_first`; each lists the area file(s) it needs. (QA: pass / fail)
- [ ] No ticket's status, lead or other header field changed except `files_to_read_first` (a diff check in the result notes). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
