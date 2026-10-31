---
id: T-446
title: One button style and feel across every player-facing screen
status: in-qa
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

### 2026-10-31, Open → In progress

Started: the UI Agent builds the shared button in C:\solid-carbide-worktrees\T-446.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (UI Agent, 2026-10-31).** There is now one shared button, defined once in `game/scripts/hud/hud_style.gd` next to the HUD style sheet's values. The functions are `HudStyle.style_button(button, small := false)`, `HudStyle.style_checkbox(checkbox, icon_size, small := false)`, `HudStyle.button_padding()` (for the recap's square X), `HudStyle.check_icon()` and `HudStyle.is_shared_button()`. Every styled button carries the meta `hud_button`. There are two new label roles, `button` and `button_small`. No button's text, place, action, keys or focus mode changed, and the HUD size slider is untouched.

Where it is used (counted by the new test): main menu 3 (Start, Garage, Exit); garage 6 (5 Buy, Back); tutorial slides 4 (both arrows, Start, the Don't show again checkbox); level-up 1 per card (Take it); pause 6 (Trick list, Restart, Exit, the trick list's Back, the Camera smoothing and Dynamic camera checkboxes); recap 2 (Continue, the X).

**Proposals for the playtest (the look and feel):**
- Plate: the level-up "Take it" plate (`button_plate.png`, `button_plate_pressed.png`) as a 9-slice at 2x, **recoloured in code** from Greenbull's greens to the style sheet's steel ramp: outline (8, 8, 15), dark steel edge, mid steel bevel, light steel top glint, steel face. The reason is Visual style rule 6: placeholders never carry Greenbull's light green, and the menus are not Greenbull's things. So the level-up's Take it is now steel too, not green. If the board wants green there, it is a one-line change (the recolour table `HudStyle.BUTTON_RECOLOR`). The art ticket T-447 replaces the plate files and this recolour.
- Text: Bangers (in capitals), light label colour (235, 242, 255), near-black outline 6, size 28 everywhere. Before, sizes ran from 24 to 32 per screen, and Take it was 30 in black. The pause strip's small buttons are 16 with outline 4.
- States:
  - Hovered: the plate is 1.35 times brighter and the text turns white.
  - Keyboard-selected (focus): a 2 px white ring round the plate, and white text.
  - Pressed: the sunk pressed plate, with the text 2 px lower (the press-down).
  - Disabled: the plate darkened to 0.55 and grey text. The garage's Buy now shows this when the player has too few coins.
  - The mouse pointer becomes a hand over buttons.
- Tutorial arrows: the triangle is drawn in the button's text colour with a 3 px near-black outline, and drops 2 px when pressed. Recap X: white with a 2 px near-black outline (it was black on white).
- Checkbox: no plate. It has the same text and the same white focus ring, and a square with a light frame on dark steel, with a light mark when checked (16 px on the pause screen, 28 px on the tutorial slide).

**Out of scope, kept as they were:** the pause strip's Set min zoom and Set max zoom (the board's camera tuning tool), the level creator and the drift tuning panel.

**Tests.**
- New: `game/tests/unit/hud/test_shared_button.gd`, 12 tests. It walks all six screens, checks every button is the shared one and counts them per screen. It also checks:
  - the five states differ, with the press-down and the tints;
  - colours, font, outline and even sizes come from HudStyle;
  - the plate has no Greenbull colour and the right 9-slice margins;
  - text, actions and focus mode are unchanged;
  - the checkbox and the X's padding.
- Changed: two **look** assertions in `game/tests/unit/test_level_up_screen.gd`, the plate texture path and the Take it text being black, because the look changed on purpose. No test of actions, keyboard or mouse was changed. `test_pause_camera_controls.gd` passes unchanged (it checks the tuning buttons' frame and the checkbox icon's light frame and dark fill).
- `python -m unittest discover -s game/tools -p "test_*.py"`: 767 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 591 tests, OK.
- GUT (`run_tests.sh`): 191 scripts, 2326 tests, 2326 passing, TESTS PASSED. The full run takes longer than my shell tool's 10-minute foreground limit, so I ran it as a background command (GUT_TIME_LIMIT=2400) and waited for it to finish. Nothing is left running.

**Screenshots** (`art-archive/T-446/screenshots/`):
- `button_states.png`: the five states side by side (normal, hover, focus, pressed, disabled), a small pause-size button and the checkbox, on dark and on a light strip (fixture `game/tests/fixtures/t446_button_states_demo.tscn`). A still can't hover, so the hover button is drawn with the hover box.
- `main_menu.png`: Start shows the focus ring.
- `garage.png`: taken at 1600 x 900 with `t446_garage_wide_demo.tscn`. At 1152 x 648 the Buy buttons sit past the right edge of the screen. That was already so before this ticket (see T-370's screenshot) and is worth a separate look.
- `tutorial_slide1.png`, `tutorial_slide3.png`.
- `level_up.png` (`t446_level_up_demo.tscn`).
- `pause.png` (`pause_from_menu_demo.tscn`) and `pause_trick_list.png`.
- `recap.png` (`t446_recap_demo.tscn`).
- Note: the old `recap_screen_*_demo` fixture now lands on the tutorial slides, and the `t428_level_up_demo` fixture shows the pause screen on top of the level-up screen. So I added T-446's own fixtures (`t446_screens_demo.gd`).

**Documents affected:** `docs/hud-and-menus.md` (Content, new "The shared button (T-446; proposals for the playtest)").

Nothing under `game/data/levels/` was touched.

**Refusals:**
- A hook refused an inline `python -` edit of this ticket file. I didn't use that route again.
- The auto-mode classifier refused the first Edit of these result notes. The board said to retry once, and this retry is that Edit.
- 2026-10-31, in-progress → in-qa: Shared button built on all six screens; full report above. Tests: game/tools 767 OK, tools 591 OK, GUT 2326/2326. Screenshots in art-archive/T-446/screenshots/.
