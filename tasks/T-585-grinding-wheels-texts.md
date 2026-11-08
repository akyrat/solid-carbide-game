---
id: T-585
title: Texts: the Grinding Wheels power-up
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: power-ups
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/data/screen_texts.json]
files_expected_to_change: [game/data/screen_texts.json, docs/hud-and-menus.md]
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

Write the texts for Drifting, Decisions, "Grinding Wheels, a driving power-up", in the voice and length of the other driving power-ups' texts in game/data/screen_texts.json (for example Jump's name and tier lines): the name is the board's own, "Grinding Wheels" (no style loop for it); its tier 1 description for the gift card and the power-up overlay (the longer you grind, the hotter the sparks and the faster the launch), through the style loop. Use the same keys and places the other power-ups use, with _comment where the file has them; list them in the result notes for T-586.

The board's review: the Project Lead shows the texts with a screenshot; then in T-586's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The name and description exist in screen_texts.json in the same places as the other power-ups', listed in the result notes. (QA: pass / fail)
- [ ] The description scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists them. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-585/screenshots/ shows them as on a gift card. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
