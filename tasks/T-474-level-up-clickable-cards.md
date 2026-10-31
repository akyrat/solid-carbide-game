---
id: T-474
title: The level-up gift pack's cards are clicked directly, with no Take it button
status: open
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

Written by the agent when it finishes.
