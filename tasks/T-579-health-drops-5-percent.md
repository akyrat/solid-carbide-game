---
id: T-579
title: Health drops at 5%
status: open
from: project-lead
to: game-data
lead: Rails
epic: balance
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/data/enemies.json]
files_expected_to_change: [game/data/enemies.json, game/tests/, docs/enemies.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build Enemies, Decisions, "Health drops at 5%": set health_drops.drop_chance in game/data/enemies.json from 0.225 to 0.05 and update its _comment with the history (0.6, 0.3, 0.15, 0.225, now 0.05; board, 2026-11-08). Update any test that assumed 0.225, and docs/enemies.md Content ("Health pickups (built in T-220)") with the new number.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] enemies.json has drop_chance 0.05 with the history in its _comment. (QA: pass / fail)
- [ ] Tests that read the rate pass with the new number (tests). (QA: pass / fail)
- [ ] docs/enemies.md Content says 5%. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
