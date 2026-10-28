---
id: T-353
title: Token spend: open tickets list the area docs instead of game/README.md
status: done
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
qa_rounds: 1
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

- [ ] No ticket that is not done or cancelled still lists `game/README.md` alone in `files_to_read_first`; each lists the area file(s) it needs. (QA: pass; checked by the Project Lead: the only one left is T-353 itself, which reads game/README.md to do this job)
- [ ] No ticket's status, lead or other header field changed except `files_to_read_first` (a diff check in the result notes). (QA: pass; git diff of the 27 tickets changes no line besides files_to_read_first)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, In QA → Done

Done: the board ran the script; 27 open tickets now list their area files instead of game/README.md. Committed on master.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done by the board, 2026-10-28, with no agent: the board ran the Tokens session's script (a checked copy of T-346's `fix_tickets.py`: main checkout only, open and blocked tickets only, every area path checked to exist, dry run unless `--write`) with `--write`. It replaced `game/README.md` in `files_to_read_first` with the area files on 27 tickets: T-066, T-067, T-078, T-088, T-098, T-099, T-100, T-134, T-135, T-283, T-285, T-317, T-319, T-320, T-325, T-326, T-327, T-328, T-329, T-330, T-334, T-336, T-337, T-338, T-341, T-351, T-352. Skipped: T-335 (needs-playtest at the time), T-339 and T-340 (done). Only that header line changed. No code, so no tests; nothing to picture.
- 2026-10-28, in-qa → done: QA by the Project Lead (board-run header edit, no agent).
