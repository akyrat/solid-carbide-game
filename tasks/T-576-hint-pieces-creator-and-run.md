---
id: T-576
title: Hint pieces in the level creator and in runs (placeholder art)
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
depends_on: [T-575]
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/practice-playground.md, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/scripts/level/mvp_map.gd]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/data/level/, game/tools/check_level.py, game/tools/, game/tests/, game/docs/level/, docs/level-design.md]
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

Build Level design, Decisions, "Hint pieces in the level creator", with placeholder art drawn by script (T-577 swaps in the PixelLab art): (1) the creator's side panel gets a hints category (labels from T-575) with five pieces: gas (W keycap), brake (S keycap), straight arrow, curved arrow (left or right, by Mirror), circular arrow (either direction, by Mirror); each placed either painted on the ground or as a standing sign (a toggle, labels from T-575); R steps the direction through the 8 directions for both kinds. (2) Placing, moving and deleting them like other pieces; they are saved in the level file (a new key, kept by older files and by check_level.py, which checks them) and load again. (3) In a run (and the practice playground, which uses the same map code), ground hints are drawn flat on the ground in their direction, under the car, minions and buildings, with no collision; signs stand upright, sorted with props, and block the car like a prop. The icons are made top-down and laid flat on the isometric ground by the engine, so one image per icon serves all 8 directions; the sign is one piece with the icon put on its face by script. Define the art's file names, sizes and where the engine reads them, so T-577 can drop the PixelLab files in; the placeholders follow the same names. Give a test level in the result notes for the board to try (in a temporary folder, never game/data/levels/).

The board's review: play it from C:\solid-carbide-worktrees\T-576: open the level creator (`"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path "C:\solid-carbide-worktrees\T-576\game" res://scenes/level_creator/level_creator.tscn`), place each hint both ways and in several directions, save, press Play.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The creator offers the five hints, each as a ground decal or a sign, with Mirror for the arrows and R through 8 directions (tests). (QA: pass / fail)
- [ ] Hints are saved, load again, and check_level.py accepts a level with them and refuses a bad one (tests). (QA: pass / fail)
- [ ] In a run, ground hints draw flat under the car with no collision, and signs stand and block the car (tests). (QA: pass / fail)
- [ ] Levels saved before load and play as before (tests). (QA: pass / fail)
- [ ] The art's file names and sizes are in game/docs/level/ for T-577, and docs/level-design.md Content describes the pieces. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-576/screenshots/ show the creator with hints of both kinds and a run with them. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
