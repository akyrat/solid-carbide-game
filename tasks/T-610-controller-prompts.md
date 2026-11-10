---
id: T-610
title: Button prompts follow the controller
status: open
from: project-lead
to: ui
lead: Controller-support
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-609]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/menu/key_pad.gd, game/scripts/menu/trick_list.gd, game/scripts/menu/tutorial_slides.gd, game/data/controller_text.json]
files_expected_to_change: [game/scripts/ui/input_method.gd, game/scripts/menu/key_pad.gd, game/scripts/menu/trick_list.gd, game/scripts/menu/tutorial_slides.gd, game/project.godot, game/docs/hud-and-menus/, game/tests/]
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

Step 3 of controller support (HUD and menus, Decisions, "Controller support in the menus and prompts"; the button layout: Drifting, Decisions, "Controller support"). Built for mobile later (HUD and menus, Decisions, "Controller support: local first, browser last, built for mobile later"; board, 2026-11-10): track the player's current input method in one autoload (for example InputMethod, with methods keyboard_mouse and controller, and room for touch later as one more method; a controller button press or a stick moved past the dead zone switches to controller, a key press switches back to keyboard_mouse; mouse motion changes nothing) and emit a signal when it changes. Every prompt asks that one autoload for the method and draws from a per-method glyph and text set (keyboard keycaps, controller buttons), so a later touch set is added in one place and no screen checks for a controller itself. This ticket's branch is made from the board's local controller build (playtest/controller: T-607 and T-608 together, not yet merged), so the board plays all three together; it merges after them. While it is the controller, every place that shows keys shows the controller's buttons instead, live, without reopening the screen: the tutorial's practice key pads and lines, the trick list's keycap recipes and live pads in the clips, and every line T-609 gave a controller version. The glyphs are drawn in code in the keycaps' own style (key_pad.gd): a round stick, the D-pad, LT and RT, A, B, Y, LB, RB and Start, labelled with T-609's glyph labels, lit when held exactly as the keycaps are (a recorded clip's W lights RT, S lights LT, A/D light the stick tilted left/right, Space lights A). Use exactly T-609's text from game/data/controller_text.json, no wording of your own. No PixelLab art. Record how it is built in game/docs/hud-and-menus/.
The board's review: with a controller, open the tutorial and the trick list and check the buttons shown and lit match what to press; press a key and see them switch back to the keys.
Board review files: art-archive/T-610/screenshots/

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows the input method switches to controller on a joypad button or a stick push past the dead zone, back to keyboard on a key press, and not on mouse motion, with one signal per change. (QA: pass / fail)
- [ ] The prompts read the method only from the one autoload and draw from a per-method set: QA greps the changed screens and finds no check of InputEventJoypad* or Input.get_connected_joypads outside the autoload, and the result notes say where a touch set would be added. (QA: pass / fail)
- [ ] Tests show the tutorial's practice pad, the trick list's recipes and live pads, and each line T-609 lists switch to the controller version when the device changes, and back, without reopening the screen. (QA: pass / fail)
- [ ] A test shows a recorded clip lights the controller glyphs that match the keys it lights (W to RT, S to LT, A/D to the stick left/right, Space to A). (QA: pass / fail)
- [ ] Every controller label and line shown comes from game/data/controller_text.json (QA greps the changed scripts for hard-coded button words). (QA: pass / fail)
- [ ] Screenshots in art-archive/T-610/screenshots/ show the tutorial's practice window and the trick list in both keyboard and controller modes. (QA: pass / fail)
- [ ] HUD and menus, Content, describes the device switch and where the controller glyphs show. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open

Paused by the board (2026-11-09). Starts after T-608 is merged.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
