---
id: T-453
title: The player moves the HUD's pieces from the pause screen
status: done
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-452, T-446]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/scripts/ui/pause_screen.gd, game/scripts/hud/hud_style.gd, tasks/T-431-the-hud-scales-with-the-window.md, tasks/T-446-unified-buttons.md]
files_expected_to_change: [game/scripts/hud/, game/scripts/ui/, game/tests/unit/, docs/hud-and-menus.md]
model: opus
qa_rounds: 1
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "The player can move the HUD's pieces"): from the pause screen the player opens a HUD layout editor, drags each HUD piece (timer, hearts, coins, likes bar, combo, weapons, viewers, the gift and subs panel, and the rest) to where they want it, can reset to the default layout, and finishes with Done; the layout is saved on this computer like the other settings (T-427's save-once pattern) and used in every run. Positions are stored relative to the screen (corner anchors or fractions) so they hold at any window size and with the HUD size slider (T-431). Pieces stay fully on screen; whether they snap to a grid or to edges is your proposal. The gift arrows and popups keep clearing the HUD parts at their new places. Use the shared button (T-446) for the editor's buttons and the text ticket's labels (T-452). Never write, move or commit anything in game/data/levels/.

The board's review: pause, open the editor, move several pieces, resize the window, restart the game: the layout is kept; then reset it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test moves a HUD piece in the editor, saves, rebuilds the HUD, and finds it at the new place. (QA: pass)
- [ ] A test shows the layout holds at two window sizes and two HUD size slider values, and pieces stay fully on screen. (QA: pass)
- [ ] A test shows Reset returns every piece to the default layout. (QA: pass)
- [ ] The gift arrows' HUD clearance test still passes with a moved piece. (QA: pass)
- [ ] Screenshots of the editor and of a run with a moved layout are saved and listed in the result notes. (QA: pass)
- [ ] docs/hud-and-menus.md (Content) describes the editor and where the layout is saved. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**UI Agent, 2026-10-31: built.**

What was built:
- `game/scripts/hud/hud_layout.gd` (new, `HudLayout`): the movable pieces (hearts, weapon icons, coins, clock, sub goal, viewers counter) and the maths. A moved piece is stored as `{ax, ay, dx, dy}` in layout pixels: its anchor (0 / 0.5 / 1 per axis, from the third of the screen its centre is in) and its distance from it. So a piece keeps its corner, edge or centre at any window size and HUD size, and is clamped to stay fully on screen.
- `game/scripts/hud/hud.gd`: `piece()`, `piece_rect()`, `layout`, `set_layout()`, `move_piece()` and `reset_layout()`. `_apply_layout()` runs on every resize and HUD size change. A moved piece is placed from its entry. A default piece gets its own offsets back, so its anchors are never touched. The sub goal's `keep_above` (T-431) runs only while it and the viewers counter are both at their defaults. A moved piece that grows (more hearts or weapons) is placed again so it stays on screen.
- `game/scripts/ui/hud_layout_editor.gd` (new, `HudLayoutEditor`): the overlay. It draws white frames round the pieces and lights up the one under the pointer and the one being dragged. A dark bar in the screen's middle holds T-452's hint, "Reset layout" and "Done" (the shared button, T-446, small). It only collects drags and hands them to `Hud.move_piece()`.
- `game/scripts/ui/pause_screen.gd`: an "Edit HUD layout" button (shared button), shown only when there is a HUD. It sits in the run buttons row after "Trick list". A row of its own made the strip end below half the screen, which failed `test_screen_flow`'s compact-strip test, so I moved it. Opening the editor hides the strip and the dim. Done, Escape or resume saves the layout once and brings the strip back. `pause_text(key)` reads the texts from `data/pause_text.json`; no script spells them out.
- `game/scripts/ui/game_settings.gd`: `load_hud_layout()` and `save_hud_layout()` save to `user://settings.cfg`, section `hud_layout`. An empty layout removes the section. `hud_layout_writes` counts the writes for tests.
- `game/scripts/game/game_flow.gd`: one line. `add_run()` applies the saved layout to the run's HUD, next to the HUD size (T-431's pattern).
- `game/scripts/run/gift_arrows.gd`: `hud_rects()` now merges the sub goal's label row into its rect, so the arrows keep clear of the subs label wherever the sub goal is moved. I made this small change outside UI files because the clearance criterion needs it.

My proposals for the playtest:
- **Movable pieces:** the six above. The airtime and drift counters (shown only in the air or in a drift), the reactions and the trick popups stay where they are.
- **Snapping:** a 4 layout-pixel grid. A piece also snaps to the 16 px edge margin when it comes within 12 px of an edge. A piece can never be partly off screen.
- **Controls:** drag with the left mouse button. Escape is the same as Done. There is no keyboard nudge.
- **Overlaps:** pieces may overlap if the player stacks them.
- **Editor bar:** placed in the middle of the screen.

Tests:
- New file `game/tests/unit/hud/test_hud_layout_editor.gd` (13 tests):
  - HudLayout's entries, snapping and cleaning.
  - The texts and shared buttons. `test_shared_button.gd` now counts 9 shared pause buttons (it counted 6): Edit HUD layout, Reset layout and Done are new.
  - Opening the editor and Done; Escape works as Done.
  - Criterion 1: a drag in the editor, then Done, saves the layout, and a new HUD finds the piece at its new place while the others stay at their defaults.
  - Criterion 2: the layout holds at 1920 x 1080 and 960 x 540, each at HUD size 50 and 125, with every piece fully on screen and the moved pieces keeping their corner or centre.
  - A moved piece that grows stays on screen.
  - Criterion 3: Reset returns every piece to its default, and Done then removes the saved section. Reset also works at HUD size 125, with the sub goal kept clear of the viewers counter.
  - A run started by GameFlow uses the saved layout.
- New test in `game/tests/unit/run/test_gift_drops.gd`, `test_t453_arrows_stay_clear_of_moved_hud_pieces` (criterion 4): the viewers counter, clock, sub goal and coins are moved, and arrows in 32 directions at 4 window sizes stay clear of them. The existing clearance tests still pass.

Test runs:
- `python -m unittest discover -s game/tools -p "test_*.py"`: 767 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 633 tests, OK.
- GUT (`GUT_TIME_LIMIT=1500 ... run_tests.sh`): 194 scripts, 2362 tests, 2362 passing, 0 failing, TESTS PASSED (970 s).

Screenshots are in `art-archive/T-453/screenshots/`, written by the fixture `game/tests/fixtures/t453_hud_layout_demo.gd` (scenes `t453_editor.tscn`, `t453_run.tscn`, `t453_run_1920.tscn`, `t453_run_small_big.tscn`):
- `pause_screen_with_button.png`: the pause screen with the new button.
- `editor_1152x648.png`: the editor open, with four pieces moved and the hearts mid-drag.
- `run_moved_layout_1152x648.png`: the next run with the saved layout. The clock is at the top centre, the viewers counter on the right edge's middle, the sub goal at the bottom left beside the weapons, and the coins at the bottom centre.
- `run_moved_layout_1920x1080.png`: the same layout at full HD.
- `run_moved_layout_960x540_hud125.png`: the same layout in a small window at HUD size 125.

Board review files: art-archive/T-453/screenshots/pause_screen_with_button.png, art-archive/T-453/screenshots/editor_1152x648.png, art-archive/T-453/screenshots/run_moved_layout_1152x648.png, art-archive/T-453/screenshots/run_moved_layout_1920x1080.png, art-archive/T-453/screenshots/run_moved_layout_960x540_hud125.png

Documents affected:
- `docs/hud-and-menus.md`: new Content section, "The HUD layout editor". It describes the editor, the pieces, the controls, the snapping, how positions are kept and where the layout is saved.
- `game/docs/hud-and-menus/hud.md`: new paragraph, "The HUD layout".
- `game/docs/hud-and-menus/pause-screen.md`: new bullet, "HUD layout editor".

Nothing under `game/data/levels/` was touched. The new scripts' `.uid` files and Godot's `.import` noise were not committed.
- QA, 2026-10-31, round 1: all 8 criteria pass. qa_check: 3 test sets pass (GUT full run), documents changed, 5 screenshots present; docs/hud-and-menus.md has "The HUD layout editor" naming settings.cfg; nothing under game/data/levels/ differs from master.
- 2026-10-31, in-progress → in-qa: Built: HUD layout editor from the pause screen (drag, snap, Reset, Done saves to settings.cfg hud_layout). All three test sets pass (GUT 2362/2362). Screenshots in art-archive/T-453/screenshots/.
- 2026-10-31, in-qa → needs-playtest: QA passed
- 2026-10-31, needs-playtest → done: LGTM (the board, 2026-10-31, swipe review)
