---
id: T-555
title: Art: the car's mid-air tilt, 3 transition frames in 16 directions
status: open
from: project-lead
to: asset-generation
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-551]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/art/car/car_iso.json]
files_expected_to_change: [game/art/car/, art-archive/T-555/, game/scripts/driving/, docs/visual-style.md]
model: opus
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

Make the art for Drifting, Decisions, "The grind overhaul", the tilt: for each of the car's 16 directions (game/art/car/car_iso.json), 3 frames from the normal car to the tilted pose, where the car's own front left wheel goes down and its back right wheel goes up (a tilt about the car's diagonal, not a turn: the car keeps facing the same way). The last frame is the held pose. Same car, palette, outline and size as the approved car. PixelLab is approved for this ticket (the board's go, 2026-11-07): the grind overhaul's cap is 250 generations, of which this ticket may use up to 200, with generous trial and error; write planned calls and running totals in the result notes and use a 600 s HTTP timeout. Free script fixes before paid calls. Start with one direction, judge it in the style loop, then build the rest from what worked. Swap the art in for T-551's placeholder through its hook, and never delete generated art (unused in art-archive/T-555/). This ticket may go through up to 10 QA rounds (the board, 2026-11-07) before it is flagged.

The board's review: in the combined build (playtest/grind-overhaul), hold Space in the air and watch the car tilt and come back.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] 16 directions x 3 frames are in game/art/car/ with their sheet data, and the game shows them through T-551's hook instead of the placeholder (test). (QA: pass / fail)
- [ ] In each direction the last frame shows the front left wheel lowered and the back right wheel raised, with the car still facing the same way (QA looks at a contact sheet in art-archive/T-555/). (QA: pass / fail)
- [ ] Same size, outline and palette as the normal car (the style loop's scores, 8 or more, or noted for the playtest). (QA: pass / fail)
- [ ] PixelLab calls and totals are in the result notes, within 200. (QA: pass / fail)
- [ ] docs/visual-style.md Content describes the tilt art and how it was made. (QA: pass / fail)
- [ ] QA's full test run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-555/screenshots/ shows the tilt in and out in the game in several directions. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
