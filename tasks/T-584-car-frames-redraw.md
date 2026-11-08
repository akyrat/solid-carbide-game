---
id: T-584
title: Art: redraw the car frames that point the wrong way (PixelLab)
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
depends_on: [T-583]
documents_affected: [docs/visual-style.md, docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/working-with-the-board.md, game/docs/art/, game/art/car/]
files_expected_to_change: [game/art/car/, art-archive/T-584/, game/data/, docs/visual-style.md, docs/drifting.md]
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

Build Visual style, Decisions, "Redrawn car frames": redraw the car sheet's frames 19 to 23, 2 and 3 with PixelLab so each points the way its heading goes on screen (T-580's frames_vs_ideal_arrow.png shows the target arrows), matching the rest of the sheet (same car, size, palette, lighting, outline). The board's go (2026-11-08): up to 28 generations in all, through the style loop (at most 3 refines per frame); write the planned calls and cost in the result notes first; 600 s HTTP timeout; keep every generation (game-ready in game/art/car/, the rest in art-archive/T-584/). The old frames stay in art-archive. Then re-measure the sheet with T-583's script so A's data matches the new frames, and run T-580's measurement again for none, A, C and A+C with the new art; add the table to the result notes and say which combination is best now. The tilt sheet (car_iso_tilt) is not redrawn here; note how far its frames are off for a later decision.

The board's review: play it from C:\solid-carbide-worktrees\T-584\game\project.godot; compare frames before and after in art-archive/T-584/screenshots/.

Read T-580's result notes first (tasks/T-580-facing-vs-velocity-investigation.md on branch task/T-580-facing-vs-velocity-investigation, already merged into your branch) and its measurement test, game/tests/unit/test_t580_facing_vs_travel.gd. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The seven frames are redrawn and in the car sheet; the old ones are in art-archive/T-584/. (QA: pass / fail)
- [ ] Each scores 8 or more in the style loop, or is noted for the playtest; no more than 28 generations, counted in the result notes. (QA: pass / fail)
- [ ] T-583's frame data is re-measured for the new sheet, and the table of none, A, C and A+C with the new art is in the result notes with the best combination. (QA: pass / fail)
- [ ] docs/visual-style.md records the redraw. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A before and after sheet with T-580's arrows is in art-archive/T-584/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
