---
id: T-544
title: Art: the minion's death animation, the full set, swapped into the game
status: blocked
from: project-lead
to: asset-generation
lead: Rails
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-531, T-532]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/enemies.md, game/docs/enemies/minions.md, tasks/T-532-minion-death-art.md]
files_expected_to_change: [game/art/minion/, art-archive/T-544/, game/tools/, game/tests/, docs/visual-style.md]
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

The board approved T-532's sample (south-east, 8 frames of 48x48, art-archive/T-532/minion_death_se.png, 6/10 after 4 generations) on 2026-11-06 and asked for the full set. Make the other drawn directions the death animation needs in the frame layout T-531 documents (game/docs/enemies/minions.md, "Death": minion_death_{e,se,s,ne,n}.png, 8 frames of 48x48 in a row, last frame the lying corpse; the other three directions are mirrored by the game, as for the walk). Start each from the minion's walk frame for that direction and match the approved sample's motion, frame count, size, palette and outline; no blood (the spill is code). Use the same style loop and the request builder T-532 moved to game/tools/pixellab_animate_req.py. The board's go: at most 4 generations per direction (1 plus up to 3 refines), so at most 16 for the 4 new directions; write the planned calls and cost in the result notes before calling; 600 s HTTP timeout. A direction that stays below 8 keeps its best version and is noted for the board (no extra calls). Then put the approved sample (south-east) and the four new sheets in game/art/minion/ under T-531's names, so the game shows them instead of the code placeholder, and check a death in a run in every direction. Keep every generation in art-archive/T-544/; never delete generated art.

The board's review: play a run in the ticket's folder, C:\solid-carbide-worktrees\T-544\game\project.godot, and watch minions die facing different ways; the strips are in art-archive/T-544/screenshots/.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] minion_death_e, _se, _s, _ne and _n sheets exist in game/art/minion/, each 8 frames of 48x48 in a row, transparent, within the palette rules (the style loop's script checks). (QA: pass / fail)
- [ ] At most 4 generations per new direction, the calls and their cost in the result notes; the Style review section shows each direction's scores. (QA: pass / fail)
- [ ] Every generated file is kept in art-archive/T-544/. (QA: pass / fail)
- [ ] In a run, a dying minion plays the art for its direction (the mirrored directions included) instead of the code placeholder (test that the sheets load for all 8 directions, plus screenshots). (QA: pass / fail)
- [ ] docs/visual-style.md Content records the set. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Enlarged strips of each direction on dark and light backgrounds, and screenshots of deaths in a run, are in art-archive/T-544/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
