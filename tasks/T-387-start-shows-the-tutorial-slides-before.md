---
id: T-387
title: Start shows the tutorial slides before the run, unless hidden
status: blocked
from: project-lead
to: game-loop
lead: Goal-G-007
epic: game-loop
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-382]
documents_affected: [docs/game-loop-architecture.md, game/docs/game-loop/screen-flow.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/game-loop/screen-flow.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/game/game_flow.gd, game/scripts/menu/main_menu.gd, game/scripts/ui/game_settings.gd, game/tests/unit/game/test_screen_flow.gd, game/tests/unit/game/test_pause_restart_exit.gd, game/tests/helpers/test_save.gd]
files_expected_to_change: [game/scripts/game/game_flow.gd, game/tests/unit/game/test_tutorial_flow.gd, docs/game-loop-architecture.md, game/docs/game-loop/screen-flow.md]
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

HUD and menus, Decisions, 'Tutorial slides before the first run' (board, 2026-10-29): when the player presses Start, the slides come before the run. With tutorial_hidden false (game_settings.gd), the main menu's Start shows game/scenes/menu/tutorial_slides.tscn; the run is created, or its clock starts, only when the slides' Start is pressed. If the checkbox was ticked, save tutorial_hidden as true, so the next Start (also after restarting the game) goes straight into the run. The pause screen's Restart still starts a fresh run directly, without the slides (the decision says 'when the player presses Start'). Tests must not read the player's real save (T-148, tests/helpers/test_save.gd). Update Game loop architecture, Decisions and its flow diagram with the slides step between Start and the run, and screen-flow.md.

The board's review: Press Start from the main menu, go through the slides, tick 'Don't show again', and check the next Start skips them.

## Acceptance criteria

- [ ] With tutorial_hidden false, the main menu's Start shows the slides screen and no running run; a test checks the clock reads 8:00 and does not tick over several seconds of frames while the slides are up, and that the run starts when the slides' Start is pressed. (QA: pass / fail)
- [ ] Pressing the slides' Start with the checkbox ticked saves tutorial_hidden as true; a test reloads the settings (as after a restart) and checks the next Start goes straight into the run; another test checks the checkbox unticked leaves it false and shows the slides again. (QA: pass / fail)
- [ ] The pause screen's Restart starts a fresh run directly without the slides; a test covers it. (QA: pass / fail)
- [ ] A screenshot of the slides shown after the main menu's Start is saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/game-loop-architecture.md, Decisions and its flow diagram, and game/docs/game-loop/screen-flow.md show the slides step between Start and the run. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
