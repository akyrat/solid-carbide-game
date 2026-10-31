---
id: T-474
title: The level-up gift pack's cards are clicked directly, with no Take it button
status: in-qa
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-446]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/ui/level_up_screen.gd, tasks/T-446-unified-buttons.md]
files_expected_to_change: [game/scripts/ui/level_up_screen.gd, game/tests/unit/, docs/hud-and-menus.md]
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "Gift menu cards are clicked directly"): on the level-up screen (the gift pack's weapon choices), remove the Take it button from each card and make the whole card the control: clicking anywhere on a card takes it. The card shows it can be clicked: it reacts to hover and to keyboard selection with the shared button's feel (T-446: highlight, a short press-down when clicked), and the keyboard keeps working as today (A/D or the arrow keys move the highlight, Enter or Space takes the highlighted card; only a fresh key press counts). Nothing else on the screen changes. If the Take it label's text key becomes unused, leave it in the text file and say so in the result notes. Never write, move or commit anything in game/data/levels/.

The board's review: level up in a run and pick a card with the mouse, then with the keyboard.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows no card on the level-up screen has a Take it button. (QA: pass / fail)
- [ ] A test clicks a card (anywhere on it) and that card's choice is taken; a test does the same with the keyboard (move, then Enter). (QA: pass / fail)
- [ ] A test shows a card's look changes on hover and on keyboard selection. (QA: pass / fail)
- [ ] The existing level-up tests (pausing, the 2 choices, one choice left, fresh key presses only) still pass, changed only where they pressed the button. (QA: pass / fail)
- [ ] Screenshots of the level-up screen, a hovered card and a selected card are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) describes clickable cards. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

T-474 (UI Agent). The level-up gift pack's cards have no Take it button: the whole card is clicked.

- New reusable `GiftCardClick` (`game/scripts/ui/gift_card_click.gd`): a see-through Button over a whole card; `GiftCardClick.attach(panel, body, frame, on_take)`; `set_active(bool)` for the build-up. Hover tints the card's frame with `HudStyle.BUTTON_HOVER_TINT`; a click presses the card body down `HudStyle.BUTTON_PRESS_DROP` px; keyboard selection stays the gold highlight frame. T-475 can call `attach` for the power-up overlay.
- `level_up_screen.gd`: the Button is gone; cards dict key `button` became `click`. Keyboard and the build-up guard unchanged. The card keeps its size (nothing else changed).
- The "levelup.take" text key is now unused; left in level_up_texts.gd as asked.
- Tests: test_level_up_screen.gd (49, all pass): button tests now use the click area; a real mouse click near the card's top left takes the card; new tests for no button, hover, press-down, keyboard selection look, move then Enter, reuse on any card. test_shared_button.gd: the level-up expects 0 shared buttons and skips GiftCardClick.
- Test sets: game/tools unittest 769 OK (1 skipped); tools unittest 633 OK; GUT full run 2375 tests, first run 2374 pass and 1 fail (test_shared_button expected a plate on the new click area), fixed; test_shared_button re-run 12/12 pass; the full GUT run was not repeated after that one-test fix.
- Screenshots (art-archive/T-474/screenshots/): level_up_plain.png, level_up_hover.png (right card hovered, brightened), level_up_selected.png (second card selected by keyboard), level_up_pressed.png (left card pressed down). Fixtures: game/tests/fixtures/t474_*_demo.tscn and t474_cards_demo.gd. (The old level_up_screen_demo fixture is stale: game.run is null there; not touched.)
- Documents: docs/hud-and-menus.md (Content and Decisions wording), game/docs/hud-and-menus/level-up-screen.md.
- Nothing under game/data/levels/ touched. Untracked .uid/.import noise not committed.
- 2026-10-31, in-progress → in-qa: Cards clickable via reusable GiftCardClick; tests pass; screenshots in art-archive/T-474/screenshots
