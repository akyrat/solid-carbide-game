---
id: T-492
title: Arrow keys work in the main menu and the garage
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
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/garage-design.md, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/scripts/garage/, game/scenes/garage/, game/tests/unit/, docs/hud-and-menus.md, docs/garage-design.md]
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

The board, 2026-11-02 (HUD and menus, Decisions, "Arrow keys in the main menu and the garage"): after playing the itch.io build, the board wants the main menu and the garage usable with the arrow keys alone. Up, down, left and right move the keyboard selection between the buttons (and the garage's upgrade cards or rows, in the direction that matches the layout), Enter or Space presses the selected one, and the selection always shows with the shared button's focus plate (T-446). When a screen opens, its first button is selected, so the first arrow press does something. The mouse works as before; a key already held when the screen opens doesn't act (only fresh presses count, as on the other screens). Find where each screen's focus neighbours come from and make them explicit where Godot's automatic ones go wrong.

The board reviews this in the Project Lead's swipe deck (board, 2026-11-02): no QA agent round. Save screenshots of each screen with the keyboard selection on a few different items under art-archive/T-NNN/screenshots/ (1280 x 720) and list them in the result notes. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests show the arrow keys move the selection through every button of the main menu, and through the garage's upgrades and its Buy and Back buttons, in a sensible order, and Enter and Space press the selected one. (QA: pass / fail)
- [ ] Tests show a screen opens with its first button selected, and a key held when it opens does nothing. (QA: pass / fail)
- [ ] The selection is visible on every focusable item (screenshots listed in the result notes). (QA: pass / fail)
- [ ] The mouse still works (the existing main menu and garage tests pass). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Main menu) and docs/garage-design.md say how the keyboard works there. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent, with -gselect), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
