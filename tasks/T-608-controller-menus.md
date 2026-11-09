---
id: T-608
title: Controller: every menu and screen
status: open
from: project-lead
to: ui
lead: Controller-support
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/keyboard-selection.md, game/scripts/ui/key_nav.gd]
files_expected_to_change: [game/project.godot, game/scripts/ui/key_nav.gd, game/scripts/ui/level_up_screen.gd, game/scripts/ui/power_up_screen.gd, game/scripts/ui/recap_screen.gd, game/scripts/ui/pause_screen.gd, game/scripts/menu/tutorial_slides.gd, game/scripts/menu/trick_list.gd, game/scripts/menu/settings_screen.gd, game/scripts/run/god_mode.gd, game/scripts/ui/hud_layout_editor.gd, game/docs/hud-and-menus/keyboard-selection.md, game/tests/]
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

Step 2 of controller support (HUD and menus, Decisions, "Controller support in the menus and prompts"; the board, 2026-11-09). Make every screen a run passes through usable with a controller, alongside the keyboard: main menu, Settings, garage, Cosmetics, tutorial slides, pause screen, trick list, god mode page, level-up, power-up and recap screens. Left stick and D-pad move the selection like the arrows and W A S D (KeyNav's first-press-selects rule holds for the controller too), A presses the selected button like Enter, B goes back or closes like Escape, Start resumes from the pause screen. Level-up, power-up and recap: left/right pick, A takes. Proposals for the playtest, as in the doc: LB/RB turn the tutorial's slides (on the trick slides the stick drives the practice car), a selected settings slider moves with left/right, the HUD layout editor stays mouse only with B as Done, the level creator is untouched. The cleanest way is probably to move the hard-coded key checks (KEY_W, KEY_ENTER, KEY_SPACE and the rest) to input actions (Godot's ui_* actions, plus any new ones such as slides_prev/slides_next) that carry both the keys and the controller buttons; every keyboard behaviour must stay exactly as it is. If you add actions to project.godot, add them after toggle_view at the end of the [input] section only (T-607 edits the car actions and pause in parallel). Stick motion must not repeat a move every frame: one move per push past the dead zone, then the keyboard's repeat while held. Update game/docs/hud-and-menus/keyboard-selection.md and the doc's Content where the screens' keys are described.
The board's review: go through the main menu, Settings, garage, Cosmetics, the tutorial, the pause screen and trick list, a level-up, a power-up and the recap with only a controller; the keyboard still works as before.
Board review files: art-archive/T-608/screenshots/

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] For each screen listed in the description, a GUT test drives it with controller events (D-pad or stick motion, A, B) and shows the selection moves, A presses the selected button and B goes back or closes, where the screen has those. (QA: pass / fail)
- [ ] A test shows a held stick moves the selection once, then repeats at the keyboard's repeat rate, not every frame. (QA: pass / fail)
- [ ] On a tutorial trick slide, a test shows the stick does not turn the slide and LB/RB do; on the level-up and power-up screens, left/right and A pick and take a card. (QA: pass / fail)
- [ ] The existing keyboard and mouse tests for these screens pass unchanged. (QA: pass / fail)
- [ ] keyboard-selection.md and HUD and menus, Content, describe the controller buttons for each screen. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-608/screenshots/ show at least the main menu, the pause screen and the level-up screen with a button selected by controller input. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
