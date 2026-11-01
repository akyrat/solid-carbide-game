---
id: T-475
title: The driving power-up overlay's cards are clicked directly, like the gift pack's
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-459, T-474]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-459-the-driving-power-up-overlay-a.md, tasks/T-474-level-up-clickable-cards.md]
files_expected_to_change: [game/scripts/ui/, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "Gift menu cards are clicked directly"): the rule applies to every gift menu. Goal G-009 built the driving power-up overlay (T-459) before this decision, so this ticket brings it in line with the level-up screen (T-474): no Take it (or equivalent) button on its cards, the whole card is clicked, hover and keyboard selection show it, and the keyboard keeps working. Build it after goal G-009 is merged into master; reuse T-474's card behaviour rather than writing a second one. Never write, move or commit anything in game/data/levels/.

The board's review: complete a mission in a run and pick a power-up with the mouse, then with the keyboard.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows no card on the power-up overlay has a take button, and clicking anywhere on a card takes it; a keyboard test does the same. (QA: pass)
- [ ] The overlay's cards share T-474's card behaviour (one implementation; say where in the result notes). (QA: pass)
- [ ] The existing power-up overlay tests still pass, changed only where they pressed the button. (QA: pass)
- [ ] Screenshots of the overlay with a hovered and a selected card are saved and listed in the result notes. (QA: pass)
- [ ] docs/hud-and-menus.md (Content) says the overlay's cards are clicked directly. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: power-up cards become clickable, like the gift pack's.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done by the UI agent.

- `game/scripts/ui/power_up_screen.gd`: the Take power-up button is gone. Each card gets `GiftCardClick.attach(panel, body, frame, take.bind(id))` (T-474's click area); the card dict now has `click` instead of `button`. The build-up turns the click areas off and on with `set_active`, as on the level-up screen. Dead button constants removed. Keyboard handling is unchanged.
- Shared card behaviour (one implementation): `game/scripts/ui/gift_card_click.gd` (`GiftCardClick`, hover tint, press drop, click anywhere on the card). Both `level_up_screen.gd` and `power_up_screen.gd` call `GiftCardClick.attach`.
- Tests (`game/tests/unit/test_power_up_screen.gd`): the button-text check became "no take button" (no `button` key, no `TakeButton` node); the button-press test now presses the card's click area; new tests: a real mouse click anywhere on a card takes it, cards ignore the mouse during the build-up, hover brightens the frame and press drops the card. Keyboard tests (Enter, Space, A/D, held key, echo) unchanged and pass.
- Docs: `docs/hud-and-menus.md` (Content, Power-up overlay: no button, whole card clicked; take_button text noted as unused) and `game/docs/hud-and-menus/level-up-screen.md` (card dict, input).
- Screenshots in `art-archive/T-475/screenshots/`: `power_up_hover.png` (right card hovered, left selected), `power_up_selected.png` (second card selected by keyboard). Fixtures: `game/tests/fixtures/t475_hover_demo.tscn`, `t475_selected_demo.tscn` (the existing `power_up_screen_demo.gd` got a `hover_card` option).
- The `power_ups.take_button` text stays in `data/screen_texts.json`, now unused (not mine to remove).
- Nothing under game/data/levels/ touched.
- Test counts: see below.
- Test counts: game/tools unittest 849 OK (1 skipped); tools unittest 633 OK; GUT 2505 of 2505 passing (the first full run had 1 failing test, my own real-click test, fixed; a later run hit the 1500 s limit only because it shared the machine with the Python sets; the last run alone passed).
- 2026-11-01, in-progress → in-qa: Power-up cards clicked directly via shared GiftCardClick; tests and screenshots done
- 2026-11-01, in-qa → needs-playtest: QA pass: no take button, shared GiftCardClick, 3 test sets green (849/633/2505)
