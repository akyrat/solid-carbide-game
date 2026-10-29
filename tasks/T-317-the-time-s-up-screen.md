---
id: T-317
title: The 3-second animated time's up screen when the timer runs out
status: in-progress
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-316]
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/docs/game-loop/the-run.md, game/docs/game-loop/screen-flow.md, game/scripts/run/run_state.gd, game/scripts/game/game_flow.gd, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/ui/, game/scenes/, game/scripts/game/game_flow.gd, game/tests/unit/, game/README.md, docs/hud-and-menus.md]
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

The board's decision (Game loop architecture, Decisions, "Time's up screen", 2026-10-28): when the 8-minute timer runs out and the kaiju has survived it (a loss), a **3-second animated failure screen** plays, then the run ends as today (straight to the main menu, or to the recap screen once T-320 is merged).

Build it in the game's comic look (the trick popups, the combo broken popup, the level-up screen: white rounded panel, black border, the Bangers font, hard pixel edges), with T-316's text, word for word. The animation is your proposal for the playtest: for example the headline slamming in and shaking, cracked like the COMBO BROKEN! popup, over the dimmed, frozen run. The run stops when the timer hits 0:00 (no damage, no likes, no pickups during the 3 seconds), and the screen can't be skipped (a proposal; say if a key to skip is cheap). Only the timer's loss shows it: losing all health has its own 3-second wreck instead (T-360; board, 2026-10-29), so leave the health loss alone here. Placeholder look in code is fine; no PixelLab.

The board's review: let a run reach 8:00 without killing the kaiju and watch the time's up screen.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When the timer reaches 0:00 with the kaiju alive, the screen shows T-316's text for 3 seconds (±0.1 s), animated, then the run ends with the same result as before (test with the run's time advanced to the end). (QA: pass / fail)
- [ ] During the 3 seconds the run is frozen: the timer, enemies, damage and pickups don't change (test). (QA: pass / fail)
- [ ] Killing the kaiju, and losing all health, end the run exactly as before, without this screen (tests). (QA: pass / fail)
- [ ] Every label comes from T-316's data file; no text is written in the code. (QA: pass / fail)
- [ ] HUD and menus, Content, "Time's up screen" and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-317/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF shows the whole 3 seconds. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started (build B): the UI Agent is building the 3-second time's up screen with your approved headline.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**UI Agent, 2026-10-29: done, ready for QA.** Build and docs: `game/docs/hud-and-menus/time-up-screen.md`.

What it does: at 0:00 with the kaiju alive the run is lost and frozen (the scene tree paused), the time's up screen plays for 3 s, then the same `run_ended("loss", coins)` as before is sent, so whatever follows it (main menu now, the recap later) follows it. A kaiju kill ends at once as before; a health loss keeps its T-360 wreck, with no screen.

- **Hold, in `game/scripts/run/run_state.gd`** (small addition next to the wreck, since `run_ended` must come after the screen): `_time_up()` decides the loss at 0:00, pauses the tree, sets the state alone to `PROCESS_MODE_ALWAYS` and sends the new signal `time_up_started(seconds)`. `advance()` counts `time_up_left` down; at 0 it restores the process mode, unpauses and sends `run_ended`. `is_timed_out()`. `start_run()` during it unfreezes. The 3 s are data: `game/data/run.json` `time_up.seconds` (new section) via `RunData.time_up_seconds()`. 0 ends at once as before.
- **Screen:** `game/scripts/ui/time_up_screen.gd` (`TimeUpScreen`, CanvasLayer 16, plays while paused). `game/scripts/game/game_flow.gd`: 5 self-contained lines in `add_run()` add it as `TimeUpScreenLayer` and bind it to the state (no change to `_on_run_ended`). Text from `game/data/screen_texts.json` `time_up.headline`, word for word, none in code (tested).
- **Pause screen:** `toggle()` ignores Escape during the hold, so it can't pause or unfreeze it.
- **Look (placeholder in code, no PixelLab):** the COMBO BROKEN! cracked red-orange card (`ComboBrokenArt`), 2x on the default window, nearest filter, over a 55 % black dim. I added an optional `in_gap` argument to `ComboBrokenArt.textures()/bake()` so the crack runs through the space between "OVER," and "KAIJU". At first it ran through the J of KAIJU. The combo broken popup is unchanged (its tests pass).
- **Animation proposal (for the playtest; also in HUD and menus, Content):** 0 to 0.25 s dim in. 0 to 0.18 s slam in from 2.6x size. 0.18 to 0.6 s impact shake dying away. 0.9 to 1.3 s the crack opens (halves part, right half drops 6 px and tilts 5 degrees). It holds to 3 s. Stepped at 30 fps.
- **Skip:** none (the proposal). A skip key would be cheap: an input handler calling a state method that ends the hold at once.
- **Notes for QA and the Project Lead:** a run scene used on its own (without `GameFlow.add_run`) still freezes 3 s but has no screen. The dim covers the HUD too, so 0:00 shows dimmed. T-320 handoff: the coordinator says T-320 wants `GameFlow.show_recap(summary)` called when the 3 s end. Not wired here, as briefed. Since the hold ends with `run_ended`, the recap can follow `run_ended` the same way it does for the wreck.

Tests: new `game/tests/unit/test_time_up_screen.gd` (16 tests). These tests ran the clock out and expected an instant end, so they now let the 3 s play: `run/test_run_state.gd` (2), `run/test_wreck.gd` (1, renamed), `game/test_screen_flow.gd`, `level_creator/test_play_level.gd`.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 657 tests OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 573 tests OK.
- `bash game/tools/run_tests.sh`: 1870/1870 passed, 152 scripts.

Screenshots: `art-archive/T-317/screenshots/time_up.png` (1.5 s in, crack open, run frozen at 0:00) and `time_up.gif` (from just before 0:00, the whole 3 s, then the main menu). Made by `bash game/tools/record_time_up.sh` with the fixture `game/tests/fixtures/time_up_demo.tscn`.

Documents affected: `docs/hud-and-menus.md` (Content, "Time's up screen"), `docs/game-loop-architecture.md` (the wreck's "decided at once" line no longer says the time's up ends at once), `game/README.md` (index line), `game/docs/hud-and-menus/time-up-screen.md` (new), `game/docs/game-loop/the-run.md` (same correction).
