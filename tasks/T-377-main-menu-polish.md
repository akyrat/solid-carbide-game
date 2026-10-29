---
id: T-377
title: Main menu polish: a pixel-art title and a splash cover behind the menu
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/docs/hud-and-menus/main-menu.md, game/scripts/menu/main_menu.gd]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/fonts/, game/tests/unit/, game/docs/hud-and-menus/, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "Main menu polish", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**). The title "SOLID CARBIDE" in a **pixel-art font** (an open-licence pixel font, its licence recorded, or the HUD style sheet's font if T-375 has chosen one), the "(work in progress)" line kept and styled to match. Behind the menu, the **splash cover** (the linked art ticket): show `game/art/menu/splash.png` filling the screen (cropped, not stretched, hard pixel edges) when it exists, and a plain dark placeholder when it doesn't, so the art ticket only adds its file. The buttons stay readable over the image (for example a dark band or shadow behind them; your proposal). No new text; the texts stay as they are.

The board's review: open the game and look at the main menu.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The title uses a pixel-art font with its licence recorded, and "(work in progress)" is kept and styled to match (screenshot). (QA: pass / fail)
- [ ] The menu shows game/art/menu/splash.png filling the screen when it exists and a placeholder when it doesn't, at 1152 x 648 and at a wide window (tests with and without the file). (QA: pass / fail)
- [ ] The buttons stay readable and work as before (tests). (QA: pass / fail)
- [ ] HUD and menus, Content, "Main menu" and game/docs/hud-and-menus/main-menu.md describe it. (QA: pass / fail)
- [ ] Screenshots of the main menu (placeholder, and with a test image) are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
