---
id: T-387
title: Start shows the tutorial slides before the run, unless hidden
status: in-qa
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

- [ ] With tutorial_hidden false, the main menu's Start shows the slides screen and no running run; a test checks the clock reads 8:00 and does not tick over several seconds of frames while the slides are up, and that the run starts when the slides' Start is pressed. (QA: pass)
- [ ] Pressing the slides' Start with the checkbox ticked saves tutorial_hidden as true; a test reloads the settings (as after a restart) and checks the next Start goes straight into the run; another test checks the checkbox unticked leaves it false and shows the slides again. (QA: pass)
- [ ] The pause screen's Restart starts a fresh run directly without the slides; a test covers it. (QA: pass)
- [ ] A screenshot of the slides shown after the main menu's Start is saved in art-archive/<task id>/screenshots/. (QA: pass)
- [ ] docs/game-loop-architecture.md, Decisions and its flow diagram, and game/docs/game-loop/screen-flow.md show the slides step between Start and the run. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Blocked → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-387.

### 2026-10-30, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Game Loop Agent, 2026-10-30. Done.

**What changed**
- `game/scripts/game/game_flow.gd`: the main menu's Start now calls `_on_menu_start()`. If `GameSettings.load_tutorial_hidden()` is false, `show_tutorial()` swaps the menu for `scenes/menu/tutorial_slides.tscn` (`game.tutorial`, new signal `tutorial_shown`). No run is created while the slides are up, so no clock runs. The slides' `start_pressed(dont_show_again)` goes to `_on_tutorial_start()`, which saves `tutorial_hidden = true` when the box is ticked and then calls `start_run()`. If the setting is already true, Start calls `start_run()` at once. `start_run()` never shows the slides, so the pause screen's Restart (`_on_pause_restart` → `start_run()`) still starts a fresh run directly. `_clear_screens()` also removes the slides.
- **Test seam:** `static var GameFlow.tutorial_enabled := true` (always true in the game). `game/tests/helpers/pre_run.gd` (not in files_expected_to_change) sets it to false for the GUT run. About 40 existing test files press the menu's Start to get a run, and each uses a fresh settings file, so without this they would all have landed on the slides. The new tests turn it on in before_each and off in after_each.
- **Screenshot fixtures:** `tests/fixtures/tutorial_from_menu_demo.tscn` and `_3.tscn` open the game with a fresh settings file (`user://t387_screenshot_settings.cfg`, never the real save) and press Start. Note for the Project Lead: the older screenshot fixtures press the menu's Start and run outside GUT on the real save. Until the board ticks "Don't show again" (or a fixture calls `game.start_run()`), those fixtures will now show the slides instead of a run. Nothing in the test sets depends on them.

**Tests:** `game/tests/unit/game/test_tutorial_flow.gd`, 8 tests, 49 asserts, all on test save files (T-148; one test checks `TestSave.touches_real_save()` is false):
- Start shows only the slides: no run and no run_state in the tree.
- The clock does not start while the slides are up: after 2 s plus 30 physics frames there is still no run, and the run then starts at 8:00 (time_left ≈ RUN_SECONDS).
- The slides' Start begins the run (run_shown, the slides freed, the clock running after 1 s).
- Ticked saves `tutorial_hidden` true in the test file. A new game instance, as after a restart, then goes straight into the run from Start. It also skips the slides after the pause screen's Exit sends the player back to the menu.
- Unticked leaves it false, and a new game shows the slides again.
- The pause screen's Restart starts a fresh run (8:00, 0 coins, unpaused) with no slides, and doesn't change the setting.

**Test sets (all pass):**
- GUT `bash game/tools/run_tests.sh`: 161 scripts, 1965/1965 tests passing, 1,246,681 asserts (516 s).
- `python -m unittest discover -s game/tools -p "test_*.py"`: 675 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 573 tests, OK.
- The test logs `art-archive/T-387/gut_full.log` and `py_game_tools.log` are left in the folder but not committed.

**Screenshots** (`art-archive/T-387/screenshots/`):
- `slides_after_start.png`: slide 1, shown right after the main menu's Start.
- `slides_after_start_slide3.png`: slide 3, with "Don't show again" and Go live.
- Both made with `bash game/tools/screenshot.sh res://tests/fixtures/tutorial_from_menu_demo[_3].tscn ... 20`.

**Documents affected:**
- `docs/game-loop-architecture.md`: a new Decision, "The tutorial slides come between Start and the run", pointing to HUD and menus for the slides themselves. The "One run" flowchart now goes Main menu → Tutorial hidden? → slides → Run starts. Content, "Screen flow" has the Start and Restart bullets updated.
- `game/docs/game-loop/screen-flow.md`: Start, `start_run()`, `tutorial_enabled`, the screens and signals, and the tutorial tests.

PixelLab: 0 generations. No player-facing text was added. No refusals.

**QA round 1 (qa-integration):** all six criteria pass. Reran: GUT full run exit 0, TESTS PASSED, test_tutorial_flow.gd 8/8; tools unittest 573 OK; game/tools unittest 675 OK (1 skipped). Both screenshots exist; docs mention the slides step (flow diagram lines 83-84). `python tools/qa_check.py` was refused (not pre-approved), so skipped.
