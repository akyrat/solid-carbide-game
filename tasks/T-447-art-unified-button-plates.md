---
id: T-447
title: Art: the shared button's plates for every state
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-446]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/art/level_up/button_plate.png, game/art/level_up/button_plate_pressed.png, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/art/ui/, game/tools/, art-archive/, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "One button style across the game"): the shared button from the linked ticket (this one depends on it) starts with a placeholder: the level-up plate tinted per state. Make its final art: a 9-slice button plate for each state (normal, hovered, keyboard-selected, pressed, disabled) that fits the HUD style sheet (Visual style, Content: outline, palette, bezel lit from the top left) and the game's pixel art, and swap it in for the placeholder in the shared button. Draw it by script first (free; a script in game/tools/ that builds the plates from the style sheet, like the T-430 redraws). Each plate goes through the style loop (tasks/README.md, "The style loop"). PixelLab only with the board's go: if you think the script can't reach 8, stop and say so in the result notes before any generation.

Never delete art: the placeholder stays where it is (it is the level-up screen's own art). Never write, move or commit anything in game/data/levels/.

The board's review: go through every screen and look at the buttons in each state.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A plate for each of the five states is in game/art/ui/ with its record, built by a script in game/tools/ that is committed and documented. (QA: pass / fail)
- [ ] Each plate's style loop score is in the result notes (8 or more, or noted for the playtest). (QA: pass / fail)
- [ ] The shared button uses the new plates (test or screenshot), and the six screens still show their buttons correctly. (QA: pass / fail)
- [ ] Screenshots of the buttons in each state on at least two screens are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md records the button plates. (QA: pass / fail)
- [ ] 0 PixelLab calls unless the board gave its go (in the result notes); nothing under game/data/levels/ is changed or committed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
