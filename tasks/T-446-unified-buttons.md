---
id: T-446
title: One button style and feel across every player-facing screen
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/scripts/hud/hud_style.gd, game/scripts/menu/main_menu.gd, game/scripts/menu/garage_screen.gd, game/scripts/menu/tutorial_slides.gd, game/scripts/ui/level_up_screen.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/recap_screen.gd]
files_expected_to_change: [game/scripts/hud/, game/scripts/menu/, game/scripts/ui/, game/tests/unit/, docs/hud-and-menus.md]
model: opus
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "One button style across the game"): every button the player meets should look and feel the same, matching the game. Today each screen styles its buttons its own way.

Make one shared button (a script, scene or theme the screens use, defined once beside the HUD style sheet in game/scripts/hud/hud_style.gd) and use it for every button on the main menu, the garage, the tutorial slides (arrows and Start, the Don't show again checkbox styled to match), the level-up screen's Take it buttons, the pause screen and the end-of-run recap. It covers: the shape and art (a 9-slice plate), the font (Bangers, capitals), colours and outline from the HUD style sheet (Visual style, Content), and the states normal, hovered, keyboard-selected (focus), pressed and disabled, with a short, snappy feel (for example a slight press-down and a highlight; your proposal for the playtest). Keyboard and mouse both work as today; no button's text, place or action changes, and the HUD size slider still scales everything.

The art starts as a placeholder: the level-up screen's existing plate (game/art/level_up/button_plate.png and button_plate_pressed.png) as the 9-slice, with the other states made by tinting it. The linked art ticket (it depends on this one) makes the final art and swaps it in. The board's tools (the level creator and the tuning panel) are out of scope.

Never write, move or commit anything in game/data/levels/.

The board's review: go through every screen (menu, garage, slides, a run with a level-up, pause, the recap at the end) and press buttons with the mouse and the keyboard.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every button on the six screens is the shared button; a test walks each screen and finds no button with its own style (or lists the shared button's instances per screen). (QA: pass / fail)
- [ ] A test shows the shared button's five states (normal, hovered, focus, pressed, disabled) each look different, and their colours, font and outline come from the HUD style sheet. (QA: pass / fail)
- [ ] The existing tests for each screen's buttons (actions, keyboard, mouse) still pass unchanged. (QA: pass / fail)
- [ ] Screenshots of each of the six screens with their buttons, and of one button in each state, are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) describes the shared button and where it is defined. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
