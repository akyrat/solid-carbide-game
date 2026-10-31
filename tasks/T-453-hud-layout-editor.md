---
id: T-453
title: The player moves the HUD's pieces from the pause screen
status: in-progress
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "The player can move the HUD's pieces"): from the pause screen the player opens a HUD layout editor, drags each HUD piece (timer, hearts, coins, likes bar, combo, weapons, viewers, the gift and subs panel, and the rest) to where they want it, can reset to the default layout, and finishes with Done; the layout is saved on this computer like the other settings (T-427's save-once pattern) and used in every run. Positions are stored relative to the screen (corner anchors or fractions) so they hold at any window size and with the HUD size slider (T-431). Pieces stay fully on screen; whether they snap to a grid or to edges is your proposal. The gift arrows and popups keep clearing the HUD parts at their new places. Use the shared button (T-446) for the editor's buttons and the text ticket's labels (T-452). Never write, move or commit anything in game/data/levels/.

The board's review: pause, open the editor, move several pieces, resize the window, restart the game: the layout is kept; then reset it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test moves a HUD piece in the editor, saves, rebuilds the HUD, and finds it at the new place. (QA: pass / fail)
- [ ] A test shows the layout holds at two window sizes and two HUD size slider values, and pieces stay fully on screen. (QA: pass / fail)
- [ ] A test shows Reset returns every piece to the default layout. (QA: pass / fail)
- [ ] The gift arrows' HUD clearance test still passes with a moved piece. (QA: pass / fail)
- [ ] Screenshots of the editor and of a run with a moved layout are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) describes the editor and where the layout is saved. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
