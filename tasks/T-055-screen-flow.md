---
id: T-055
title: Screen flow: main menu, run, garage, back to the menu
status: needs-playtest
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-054, T-036]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, tasks/T-036-run-scene-and-state.md, tasks/T-054-main-menu.md, game/README.md]
files_expected_to_change: [the scene flow code, game/project.godot (main scene), tests, docs/game-loop-architecture.md, game/README.md]
model: opus
qa_rounds: 1
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

T-054 (the main menu) and T-036 (the run) are done. The garage screen isn't built yet: the board wants the bare playable loop first (2026-10-10), so the Garage button is left unwired here and wired in T-089.

Connect the screens as Game loop architecture, Decisions describes:
- The game opens on the main menu. Make it the project's main scene. The drift prototype stays available as a tool; say how to open it in `game/README.md`.
- **Start** begins a fresh run (T-036).
- When a run ends, win or loss, the game goes straight back to the main menu, with no message.
- **Garage** does nothing yet (T-089 wires it to the garage screen later).
- **Exit** closes the game.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test starts the game and shows the main menu is the first screen (QA: pass)
- [x] A test presses Start and shows a fresh run begins (QA: pass)
- [x] A test ends a run as a win and as a loss and shows both return to the main menu (QA: pass)
- [x] A test presses Garage and shows the main menu stays as it is, with no error (QA: pass)
- [x] `game/project.godot`'s main scene is the main menu, and `game/README.md` says how to open the drift prototype (QA: pass)
- [x] `docs/game-loop-architecture.md` describes the flow in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Game Loop Agent, 2026-10-10.

**Built:**
- `game/scenes/game/game.tscn` with `game/scripts/game/game_flow.gd` (`GameFlow`): the project's main scene (`game/project.godot`). It opens on the main menu; Start replaces the menu with a fresh run (`scenes/run/run.tscn`); the run's `run_ended` (win or loss) removes the run and shows the main menu again, deferred, with no message; Exit calls `get_tree().quit()` (through `quit_game`, which tests replace); Garage is left unconnected (T-089). One screen at a time, as the only child of `Game`.
- Escape during a run started from the menu: the flow adds the existing pause screen (T-015) to each run, and the run's zoom starts from the saved setting. A run ending while paused still comes back unpaused.
- Minimal run scene change (`game/scripts/run/run.gd`), so the pause screen's zoom slider works on the run: a `zoom` variable (default the old `ZOOM`), `set_zoom()`, and `panel = null`. `run.tscn` itself is unchanged, and the pause screen is not added inside the run scene, to stay clear of T-090.

**Tests:** `game/tests/unit/game/test_screen_flow.gd` (16 tests): main scene setting, the menu as first screen, Start gives a fresh run, a win / a loss on health / a loss on the clock each return to the menu, a second run is fresh, Garage leaves the same menu with no error, Exit, Escape pauses and resumes a run (directly and through the input system), Escape on the menu does nothing, the pause zoom slider and the saved zoom. Full GUT suite: 193/193 passed (`bash game/tools/run_tests.sh`, TESTS PASSED; the 57 orphans reported are from the existing run scene test, also on master). Python tool tests: 62 OK. Screenshot of the main scene shows the main menu (`screenshots/t055_game.png`, not committed).

**For QA:** criteria 1 to 4: `bash game/tools/run_tests.sh -gselect=test_screen_flow`. Criterion 5: `game/project.godot` line `run/main_scene`, and `game/README.md`, "Drift prototype", "Run it". Criterion 6: `docs/game-loop-architecture.md`, Content, new "Screen flow" subsection (and one sentence in "The run scene" updated); Summary, Decisions and Open questions untouched.

**Documents affected (updated):** `docs/game-loop-architecture.md` (Content), `game/README.md` (new "Screen flow" section; "Folder layout", "Main menu", "Drift prototype" and "The run" updated). Also my working copy, `agent-notes/game-loop.md`.

### QA round 1

QA/Integration Agent, 2026-10-10. Checked in the T-055 worktree, branch `task/T-055-screen-flow`. Result: **all 7 criteria pass.**

1. **Main menu is the first screen: pass.** `test_the_game_opens_on_the_main_menu` passes. In a separate check, a QA driver script started the project's own main scene (read from `run/main_scene`) in a real window: the main menu was the only screen (screenshot `screenshots/qa_t055/01_launch_menu.png`: title, "(work in progress)", Start, Garage, Exit).
2. **Start begins a fresh run: pass.** `test_start_begins_a_fresh_run` and `test_a_second_run_from_the_menu_is_fresh` pass. In the live window, a real mouse click on Start replaced the menu with the run: running, 0 coins, full health, clock counting down (479.8 s after 40 frames) (`02_after_start_run.png`). The second run started after a win was fresh too.
3. **Win and loss return to the menu: pass.** The win test, the loss-on-health test and the loss-on-the-clock test all pass. In the live window, all three endings went straight back to the main menu as the only screen, with no message (`04_after_win_menu.png`).
4. **Garage does nothing, no error: pass.** `test_garage_does_nothing_yet` passes. In the live window, a real click on Garage left the same menu on screen with no run, and the log had no errors (`05_after_garage.png`).
5. **Main scene and drift prototype instructions: pass.** `game/project.godot` has `run/main_scene="res://scenes/game/game.tscn"` (the screen flow, which opens on the main menu). `game/README.md`, "Drift prototype", "Run it", gives the editor (F6) and command-line ways to open it. The documented command (`--path game res://scenes/drift_prototype/drift_prototype.tscn`) ran for 90 frames, exited with code 0 and logged no errors. A screenshot of the scene shows the drift prototype (`06_drift_prototype.png`).
6. **Game loop architecture doc: pass.** In `git diff master...HEAD -- docs/game-loop-architecture.md`, the only changes are in Content: one sentence in "The run scene" and a new "Screen flow" subsection. Summary, Decisions and Open questions are unchanged.
7. **Full test suites: pass.** Full GUT suite (`bash game/tools/run_tests.sh`): 193/193, TESTS PASSED, exit 0. The 57 orphans and one GUT warning (inner class `TestRoom` skipped) are already on master. Python: `game/tools` 62 tests OK, `tools` 75 tests OK.

Other checks in the live window, beyond the criteria: a real Escape key press paused the run and showed the pause screen (`03_paused.png`), and a second press resumed it. A real click on Exit closed the game: the process exited with code 0. The log for the whole session (launch, 3 runs, pause, Garage, Exit) had no errors or warnings. Screenshots are in the worktree's git-ignored `screenshots/qa_t055/`. The QA driver script was kept outside the repo.

Notes for the Project Lead, not failures:
- Exit's real `get_tree().quit()` isn't covered by a GUT test. `test_the_default_exit_quits_the_tree` only checks that the callable is valid. The live check above covers it.
- The run has no HUD yet (no timer on screen), so for now the board can't see the clock during a playtest. That's outside T-055.
- This task has no `The board's review:` line. Under `tasks/README.md`, "Status rules", that would mean `done`. Status is set to `needs-playtest` as the Project Lead asked, since this is the board's first playable build.
