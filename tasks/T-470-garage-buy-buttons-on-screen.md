---
id: T-470
title: The garage's Buy buttons are on screen at every window size
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
depends_on: [T-446]
documents_affected: [docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/hud-and-menus.md, game/scripts/menu/garage_screen.gd, tasks/T-446-unified-buttons.md, tasks/T-431-the-hud-scales-with-the-window.md]
files_expected_to_change: [game/scripts/menu/garage_screen.gd, game/tests/unit/, docs/garage-design.md]
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

A bug found during T-446 (the shared button), and the board asked for a fix (2026-10-31): the garage's Buy buttons are off screen at the game's base window size, 1152 x 648, and likely at other sizes too. Every Buy button, and the rest of the garage (the upgrades, their prices and levels, the coins, Back), must be fully on screen and usable at any window size, ultrawide and small windows included, scaling like the HUD (T-431). Keep the garage's look and its shared buttons (T-446, which this depends on). Never write, move or commit anything in game/data/levels/.

The board's review: open the garage at the default window size, then resize the window and go fullscreen, and buy an upgrade.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test opens the garage at 1152 x 648, 1920 x 1080, 2560 x 1080 and a small window (for example 960 x 540), and finds every Buy button and Back fully inside the screen and clickable. (QA: pass)
- [ ] The existing garage tests (buying, prices, saving) still pass. (QA: pass)
- [ ] Screenshots of the garage at those window sizes are saved and listed in the result notes. (QA: pass)
- [ ] docs/garage-design.md (Content) says how the garage fits the window. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Fix.** The garage's column (heading, coins, five rows, Back) is now a plain VBox scaled and centred by `GarageScreen.fit()` to the largest scale that fits its natural size in the window, refit on every resize; nearest filtering. Descriptions now wrap (300 px) so a long one no longer widens the row and pushes Buy off screen (the cause at 1152 x 648). Look and shared buttons (T-446) unchanged.

**Tests.** New `game/tests/unit/test_garage_fit.gd` (3 tests): at 1152x648, 1920x1080, 2560x1080 and 960x540 every Buy button, Back, coins and title are fully inside the screen (corners taken through the scaled transform), every Buy is clickable and buys, and a resize refits. Existing garage tests pass. Counts: GUT 2372/2372; game/tools unittest 769 OK (1 skipped); tools unittest 633 OK.

**Screenshots** (art-archive/T-470/screenshots/): garage_1152x648.png, garage_1920x1080.png, garage_2560x1080.png, garage_960x540.png, taken with the new fixture game/tests/fixtures/t470_garage_size_demo.tscn (size from env GARAGE_SHOT_SIZE).

**Documents updated:** docs/garage-design.md (new section "How the garage fits the window (T-470)"). Nothing under game/data/levels/ touched.
- 2026-10-31, in-progress → in-qa: Garage column scales to fit the window; tests and screenshots at 4 sizes

**QA round 1 (2026-10-31): all six criteria pass.** qa_check: three test sets passed, documents changed (garage-design.md has the new section), 4 screenshots present, test_garage_fit covers the four sizes, game/data/levels unchanged.
- 2026-10-31, in-qa → needs-playtest: QA passed
