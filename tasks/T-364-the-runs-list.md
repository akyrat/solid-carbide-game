---
id: T-364
title: The runs list: a main menu button opens your past runs
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: final-release
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-320, T-362, T-363]
documents_affected: [docs/hud-and-menus.md, docs/game-loop-architecture.md, game/docs/hud-and-menus/main-menu.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md, tasks/T-320-the-recap-screen.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/ui/, game/scenes/, game/scripts/game/game_flow.gd, game/tests/unit/, game/docs/hud-and-menus/, docs/hud-and-menus.md, docs/game-loop-architecture.md, art-archive/]
model: sonnet
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

The board's decision (HUD and menus, Decisions, "The runs list", 2026-10-29): a new button on the main menu (with Start, Garage and Exit) opens a list of the player's past runs from the saved history (T-363), newest first. Each row shows the run's key stats (a proposal: the date, win or loss, the time survived, the highest combo, and the enemies slain or likes); selecting a row opens that run's full recap in T-320's recap screen (read-only; its Continue and X go back to the list) if that's cheap, otherwise the row shows more (your proposal for the playtest). A line shows when there are no runs yet. Back (or an X at the top right, like the recap) returns to the main menu. It scrolls when the list is long. The game's comic look (white rounded panels, black borders, the Bangers font, hard pixel edges). All text from T-362, word for word.

The board's review: play two runs, then open the runs list from the main menu and look through them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu has the new button, and it opens the runs list; back and the X return to the main menu (tests). (QA: pass / fail)
- [ ] The list shows every saved run newest first with its stats, scrolls when long, and shows the empty line with no runs (tests with a saved history in a test file). (QA: pass / fail)
- [ ] Every label comes from T-362's data file; no text is written in the code. (QA: pass / fail)
- [ ] HUD and menus, Content, Game loop architecture's screen flow and game/docs/hud-and-menus/main-menu.md describe it. (QA: pass / fail)
- [ ] Screenshots of the main menu with the button, the list with a few runs and the empty list are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
