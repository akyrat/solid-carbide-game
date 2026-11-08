---
id: T-577
title: Art: the hint pieces' icons and sign (PixelLab)
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
depends_on: [T-576]
documents_affected: [docs/visual-style.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/level-design.md, docs/working-with-the-board.md, game/docs/level/]
files_expected_to_change: [game/art/, art-archive/T-577/, docs/visual-style.md, docs/level-design.md]
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

Make the art for Level design, Decisions, "Hint pieces in the level creator", with PixelLab. The board's go (2026-11-08): up to 30 generations in all for this ticket, through the style loop (at most 3 refines per asset). Sample first: make the W keycap icon as the sample, then stop and hand back for the board's review before the rest. Assets: five flat top-down icons (W keycap and S keycap in the tutorial's keycap look, a straight arrow, a curved turn arrow, a circular arrow; the other directions come from mirroring in the engine) that read clearly when the engine lays them flat on the isometric ground, like road markings; and one small roadside sign the icons are put on by script. Use the file names, sizes and places T-576 defined, replacing its placeholders. Write the planned calls and their cost in the result notes before calling; use a 600 s HTTP timeout. Keep every generation (game-ready art in game/art/, the rest in art-archive/T-577/). Colours follow Visual style.

The board's review: the sample first, then the full set in the level creator and a run from C:\solid-carbide-worktrees\T-577.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The sample was shown to the board before the rest (result notes). (QA: pass / fail)
- [ ] The five icons and the sign are in the places T-576 defined and show in the creator and in a run (screenshots). (QA: pass / fail)
- [ ] Each asset scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] No more than 30 generations were used, counted in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md records the assets. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-577/screenshots/ show every icon on the ground and the sign in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
