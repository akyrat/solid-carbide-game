---
id: T-036
title: The run: scene, 8-minute clock, car health, coins, win and loss
status: done
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-019, T-038]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, docs/level-design.md, tasks/T-012-godot-drift-prototype.md, tasks/T-019-build-mvp-map.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [a run scene and its scripts under game/scenes/run/ and game/scripts/run/, their tests, game/README.md, docs/game-loop-architecture.md]
model: opus
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-019 (the MVP map) and T-038 (the run's numbers) are done.**

This is the first task for the Game Loop Agent: the run itself, as Game loop architecture, Decisions describes it. It ties the existing pieces together and owns the run's state. Other agents' work plugs into it later through signals and functions this task defines.

1. **Run scene:** a scene that loads the MVP map (T-019) and places the T-012 car on it, at a start position you choose and note in the result notes. The camera follows the car as in the drift prototype. The drift prototype scene stays as it is, as a tuning tool.
2. **The clock:** the run starts at 8:00 and counts down.
   - When 7 minutes have passed (1:00 left), it sends a "boss time" signal. The Enemy Behavior Agent will spawn the kaiju on it (Game loop architecture, Decisions).
   - At 0:00 the run ends.
   - The clock stops while the game is paused.
3. **Car health:**
   - The run holds the car's health. It starts at the value in T-038's data.
   - Other agents call a public function to damage the car.
   - Health reaching 0 ends the run as a loss.
4. **Coins:** a public function adds coins collected in this run. The run keeps the total.
5. **Win and loss** (Game loop architecture, Decisions):
   - **Loss:** health reaches 0, or the clock reaches 0:00 while the kaiju is still alive.
   - **Win:** a public function the Enemy Behavior Agent calls when the kaiju is killed ends the run at once as a win.
   - On either, the run sends one "run ended" signal with the result (win or loss) and the coins collected. The coins are kept either way. Saving them is a Game Data task, which will listen to this signal.
   - Going back to the main menu is a later task (the screen flow), since the main menu doesn't exist yet. For now, after the run ends, nothing else needs to happen.
6. **Values for the HUD:** time left, health and max health, and coins this run, readable at any time, with a signal when each changes. The UI Agent will build the HUD from them later.
7. **Starting a run:** a function that starts a fresh run from the start: full health, 8:00, 0 coins.

Write the public functions and signals in `game/README.md` ("The run"), so the enemy, weapon, UI and data tasks can use them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test starts a run and shows: time 8:00, health equal to T-038's starting value, 0 coins, and the map and car loaded (QA: pass)
- [x] A test simulates time and shows the "boss time" signal fires once, when 7 minutes have passed, and the run ends as a loss at 0:00 if the kaiju is not killed (QA: pass)
- [x] A test damages the car to 0 health and shows the run ends once, as a loss, with the coins collected so far (QA: pass)
- [x] A test calls the kaiju-killed function and shows the run ends at once, as a win, with the coins collected (QA: pass)
- [x] A test shows the clock does not advance while the game is paused (QA: pass)
- [x] A test starts a second run after the first ends and shows everything is reset (QA: pass)
- [x] A screenshot of the run scene shows the car on the MVP map (QA: pass)
- [x] `game/README.md` documents the run's public functions and signals. `docs/game-loop-architecture.md` describes the run scene in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass, with the known T-087 exception; see QA round 1)

## Result notes

Written by the Game Loop Agent.

**Produced:**

- `game/scenes/run/run.tscn` with `game/scripts/run/run.gd`: the run scene. It loads the MVP map (`scenes/level/mvp_map.tscn`, isometric view), puts the T-012 car (`scripts/driving/car.gd`) on it with its sprite, and the camera follows the drawn car exactly as in the drift prototype (zoom 14.4, no rotation, no smoothing). The map checks its challenges against the car. The drift prototype scene is unchanged.
- `game/scripts/run/run_state.gd` (`RunState`, child node `RunState`, group `run_state`): the clock, health, coins, win and loss, with the public functions and signals listed in `game/README.md`, "The run": `start_run()`, `damage_car(amount)`, `add_coins(amount)`, `kaiju_killed()`, `advance(seconds)`; signals `run_started`, `boss_time`, `run_ended(result, coins)`, `time_left_changed`, `health_changed`, `coins_changed`.
- Tests: `game/tests/unit/run/test_run_state.gd` (10 tests) and `game/tests/unit/run/test_run_scene.gd` (4 tests).
- Docs: `game/README.md` (new section "The run", folder table) and `docs/game-loop-architecture.md` (new Content subsection "The run scene"; Summary, Decisions and Open questions unchanged).

**Where each criterion is shown:**

1. Fresh run: `test_run_scene.gd::test_run_starts_with_map_car_and_fresh_state` and `test_run_state.gd::test_fresh_run_values` (8:00, health = `RunData.starting_health()` = 100, 0 coins, map with its 4 challenges and the car loaded).
2. Boss time and clock loss: `test_boss_time_fires_once_at_seven_minutes`, `test_clock_runs_out_is_a_loss`, `test_big_step_still_sends_boss_time_and_ends`.
3. Damage to 0: `test_damage_to_zero_is_a_loss_once` (loss once, with the 5 coins collected).
4. Kaiju killed: `test_kaiju_killed_is_a_win_at_once` (win, 12 coins, the clock stops).
5. Pause: `test_clock_does_not_advance_while_paused` (real frames with `get_tree().paused = true`).
6. Second run: `test_run_state.gd::test_second_run_resets_everything` and `test_run_scene.gd::test_second_run_resets_world_and_state` (fresh map with every challenge open, car back at the start, standing still, state reset).
7. Screenshot: `bash game/tools/screenshot.sh res://scenes/run/run.tscn screenshots/T-036-run.png 30` shows the car in the gravel square of the MVP map, with boulders and buildings around it.

**Choices I made (the docs leave them open):**

- **Start position:** the centre of the map (0, 0 units), in the 28 x 28 gravel square, the one open space (nearest boulder edge 16.5 units away). Heading: nose along -y, the drift prototype's start (CarModel's default).
- **View:** isometric, the drift prototype's starting view; no V key to switch in the run.
- **Run length and boss time** are constants in `run_state.gd` (`RUN_SECONDS = 480`, `BOSS_TIME_LEFT = 60`), because they are Decisions in Game loop architecture, not balancing numbers. `run.json` holds only T-038's numbers. If the board wants them in data, it is a one-line move.
- **Pause** means Godot's `get_tree().paused`; the state node is pausable, so the clock stops on its own. T-015 (pause screen) and T-037 (level-up pause) should pause the run this way.
- **`time_left_changed`** fires when the shown whole second changes (and on start), not every frame; `time_left` is readable any time. The clock shows seconds rounded up ("0:01" in the last second, "1:00" exactly at boss time).
- **After the run ends,** `damage_car`, `add_coins` and `kaiju_killed` are ignored and the clock stops, so `run_ended` fires only once. Damage and coin amounts that are not positive are ignored.
- **`kaiju_killed()` before boss time** still ends the run as a win (the function does not check whether the kaiju exists; the Enemy Behavior Agent only calls it when it dies).
- **Starting a new run** (`run.start_run()`) replaces the map and car with fresh ones, so every challenge is open again and the car stands still at the start; it emits `world_rebuilt` first, so other code can pick up the new `run.map` and `run.car`. `RunState.start_run()` alone resets only the state.
- **Max health** = starting health from `run.json`; the garage HP upgrade will raise it in its own task.
- Clock comparisons allow a 0.000001 s rounding margin, so summed frame times still hit boss time and 0:00 exactly.

**Tests run:** full GUT suite: 114 of 114 pass (13 scripts), `TESTS PASSED`.

**Python tool tests: 3 fail, and the failures are not from this task.** `python -m unittest discover -s game/tools -p "test_*.py"`: 51 run, 1 failure and 2 errors, all in `test_build_mvp_map.py`, and the same 3 fail on `master` (fbb424b). Cause: `build_mvp_map.py` reads every `docs/level-design/<pattern>/arrow-*.json`, and that now includes the `arrow-*.driven.json` files that `check_challenge --save` wrote (T-021), which have no `boulders` (`KeyError: 'boulders'`, and 12 sketches found instead of 6). The fix belongs to the Level/Challenge Design Agent's tool (for example, only read `arrow-<n>.json`), so I did not change it. This task's criterion "all Python tool tests pass" cannot pass until that is fixed.

### QA round 1

Checked by the QA/Integration Agent on 2026-10-10, in `C:\solid-carbide-worktrees\T-036` on `task/T-036-run-scene-and-state` (HEAD 2d97a2f). Result: **every criterion passes.**

1. **Fresh run: pass.** `test_run_scene.gd::test_run_starts_with_map_car_and_fresh_state` and `test_run_state.gd::test_fresh_run_values` pass: 8:00, health = `RunData.new().starting_health()`, 0 coins, the map (4 challenges) and the T-012 car loaded. Starting health comes from `game/data/run.json` (`car.starting_health` = 100) through `RunData`; `run_state.gd` has no hard-coded health.
2. **Boss time and clock loss: pass.** `test_boss_time_fires_once_at_seven_minutes` (no signal at 1:01, one at 1:00, none after), `test_clock_runs_out_is_a_loss` (one `run_ended("loss", 7)` at 0:00) and `test_big_step_still_sends_boss_time_and_ends` pass. Code matches Game loop architecture, Decisions: `RUN_SECONDS = 480`, `BOSS_TIME_LEFT = 60`.
3. **Damage to 0: pass.** `test_damage_to_zero_is_a_loss_once`: loss once with the 5 coins collected; later damage, kaiju kill and clock time do not end it again.
4. **Kaiju killed: pass.** `test_kaiju_killed_is_a_win_at_once`: `run_ended("win", 12)` at once, the clock stops.
5. **Pause: pass.** `test_clock_does_not_advance_while_paused` uses real frames with `get_tree().paused = true`; the clock is frozen while paused and runs before and after.
6. **Second run: pass.** `test_second_run_resets_everything` (state, boss time fires again) and `test_second_run_resets_world_and_state` (fresh map with every challenge open, car back at the start and still, 8:00, full health, 0 coins).
7. **Screenshot: pass.** My own screenshot, `bash game/tools/screenshot.sh res://scenes/run/run.tscn screenshots/T-036-qa-run.png 30` (exit 0, 1152x648, git-ignored), shows the placeholder car in the centre of the gravel square of the MVP map, with boulders and buildings around it.
8. **Docs: pass.** `game/README.md` has a new section "The run" listing every public function, value and signal (`start_run`, `damage_car`, `add_coins`, `kaiju_killed`, `advance`, ...; `run_started`, `boss_time`, `run_ended`, `time_left_changed`, `health_changed`, `coins_changed`, plus the scene's `world_rebuilt`). `git diff master...HEAD -- docs/game-loop-architecture.md` only adds the Content subsection "The run scene"; Summary, Decisions and Open questions are unchanged, and the new text agrees with Decisions (win on kaiju killed; loss on health 0 or the clock running out; coins kept either way).
9. **Tests: pass, with the known exception.** Full GUT suite: 114 of 114 pass in 13 scripts, `TESTS PASSED`, exit 0; that includes the drift prototype's tests (`test_drift_model.gd`, `test_drift_prototype.gd`, `test_car_sheets.gd`), and `git diff master...HEAD` shows no change to `scripts/driving/` or `scenes/drift_prototype/`, so the prototype works as before. `python -m unittest discover -s tools -p "test_*.py"`: 72 run, OK. `python -m unittest discover -s game/tools -p "test_*.py"`: 51 run, 3 fail, all in `test_build_mvp_map.py` (`KeyError: 'boulders'` in `FittedTest` and `MapTest` setup, `12 != 6` in `WriteTest`). They fail identically on `master` (158135f), so they are the pre-existing issue tracked in T-087, not this task's; as instructed, this criterion counts as a pass because every other test passes.

**Notes for the Project Lead (not failures):** the worktree has uncommitted Godot re-import changes to 35 `.import` files (GUT fonts and icons, test-run art and audio); they are not part of this task and I left them as they are.

### Board review

Merged on QA's pass (no board review needed), 2026-10-10.
