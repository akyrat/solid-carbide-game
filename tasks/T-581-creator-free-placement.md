---
id: T-581
title: Free placement in the level creator, Shift to snap
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/snapping.gd, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/tools/check_level.py]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/enemies/, game/tools/check_level.py, game/tools/check_height_data.py, game/tools/, game/tests/, game/docs/level/, docs/level-design.md]
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

Build Level design, Decisions, "Free placement in the level creator". Every piece (props and boulders, buildings, rooftops and ramps, rails, and the hint pieces once T-576 adds them) follows the mouse freely and is placed where it is dropped; holding Shift (a proposal) gives today's snapping (the 2 x 2 tile grid and the neighbour and ramp-to-rooftop snaps, snapping.gd). Rotation and views are unchanged; ground and road tiles stay painted on tiles. Moving a placed piece works the same way. Propose and explain the finest step (for example a quarter unit or one screen pixel) so saved files stay tidy. The hard part is the rest of the game: today every building, rooftop and ramp edge lies on even units because the enemies' navigation (enemy_navigation.gd, CELL 2) and check_level.py rely on it. Make collision, rooftops and ramps (the ramp still links only when its top end reaches its rooftop's side; propose how close counts without Shift), the enemies' paths, check_level.py and check_height_data.py work with pieces off the grid, and say what you changed. Levels saved before (on the grid) load and play the same; read the board's levels in game/data/levels/ only to check they still load and pass check_level.py, never write there. Rails and hint pieces already use their own positions; keep them consistent.

The board's review: play it from C:\solid-carbide-worktrees\T-581: open the level creator (`"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path "C:\solid-carbide-worktrees\T-581\game" res://scenes/level_creator/level_creator.tscn`), place pieces freely and with Shift, save, press Play.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; you may read them to check they still load). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Without Shift, each kind of piece is placed where the mouse drops it, at the proposed step; with Shift it snaps as today (tests for each kind). (QA: pass / fail)
- [ ] A ramp off the grid links to its rooftop when its top end reaches the side, and the car drives up it (tests). (QA: pass / fail)
- [ ] Off-grid buildings and rooftops block the car and are walked round by minions; check_level.py and check_height_data.py accept a good off-grid level and still refuse bad ones (tests). (QA: pass / fail)
- [ ] Levels saved before load, pass check_level.py and play as before, including the board's levels in game/data/levels/ (read only; listed in the result notes). (QA: pass / fail)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots or a GIF in art-archive/T-581/screenshots/ show pieces placed off the grid, with and without Shift, and a run on that level. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
