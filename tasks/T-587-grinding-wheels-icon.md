---
id: T-587
title: Art: the Grinding Wheels icon (PixelLab)
status: open
from: project-lead
to: asset-generation
lead: Rails
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-586]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/working-with-the-board.md, game/art/power_ups/]
files_expected_to_change: [game/art/power_ups/, art-archive/T-587/, docs/visual-style.md]
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

Make the icon of Visual style, Decisions, "Grinding Wheels icon": pixel art of a wheel grinding on a rail with sparks coming out of one side, matching the other driving power-up icons in game/art/power_ups/ (size, outline, palette). PixelLab, through the style loop: up to 4 generations (the board's request, 2026-11-08). Write the planned calls and cost in the result notes first; 600 s HTTP timeout; keep every generation (game-ready as game/art/power_ups/grinding_wheels.png, replacing T-586's placeholder; the rest in art-archive/T-587/).

The board's review: the icon next to the other power-up icons, and on a gift card in T-586's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/art/power_ups/grinding_wheels.png is the PixelLab icon, matching the others' size; the generations are in art-archive/T-587/. (QA: pass / fail)
- [ ] It scores 8 or more in the style loop, or is noted for the playtest; no more than 4 generations, counted in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md records it. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-587/screenshots/ shows it beside the other power-up icons and on a gift card. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
