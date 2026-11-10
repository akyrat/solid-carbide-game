---
id: T-617
title: Controller labels for the X and Back buttons
status: open
from: project-lead
to: narrative-theme
lead: Controller-support
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/data/controller_text.json]
files_expected_to_change: [game/data/controller_text.json, docs/hud-and-menus.md]
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

HUD and menus, Decisions, "The tutorial shows its controller buttons" (board, 2026-11-10): on a controller, the tutorial's Replay button is pressed with X and Skip demo with the Back/View button, and each shows its button's glyph. T-609's glyph block in game/data/controller_text.json has no label for those two buttons. Write, through the style loop, the glyph label for X and for the Back/View button, in the same style and length as T-609's labels (Xbox names, as T-609's proposal), add them to the glyph block with a _comment, and add them to the Controller texts subsection of HUD and menus, Content. T-610 draws them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/controller_text.json parses and its glyph block has a label for X and for the Back/View button, each with a _comment, no longer than the longest existing glyph label. (QA: pass / fail)
- [ ] The Style review records the style loop, with both labels scored 8 or more. (QA: pass / fail)
- [ ] HUD and menus, Content, Controller texts, lists both labels; the result notes say screenshots are not applicable (text only). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
