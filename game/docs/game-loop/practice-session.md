# The practice session

(Task T-561, Game Loop Agent. What it is: Game loop architecture, Content, "The practice session (task T-561)"; the decision: HUD and menus, Decisions, "Interactive tutorial slides". The index is [../../README.md](../../README.md).)

`scenes/run/practice_session.tscn` (script `scripts/run/practice_session.gd`, class `PracticeSession`) is a tutorial practice window's live session: the real car on the practice playground, counting one trick 3 times, with the real mission notebook and, for the grind, the real power-up gift. The tutorial slide (T-562) adds it to a `SubViewport`.

## Using it from a slide

```gdscript
var session: PracticeSession = preload("res://scenes/run/practice_session.tscn").instantiate()
session.trick = "grind"          # or call setup("grind") after it is in the tree
viewport.add_child(session)      # builds the world, paused
session.completed.connect(_show_success)
session.start()                  # when the slide shows (the grind's Jump gift opens now)
session.set_focused(true)        # when the window gets the keyboard
session.pause()                  # when the slide is left
```

- `setup(trick)`: `"drift"`, `"alt_drift"`, `"air_spin"` or `"grind"` (`TRICKS`); starts the practice over for it.
- `start()`, `pause()`, `is_running()` (false while paused or while the gift is open), `is_completed()`.
- `restart()`: the same trick from 0, the combo and power-ups fresh, the gift ready again. `reset_car()`: only the car back to its start point (R does it while focused, `RESET_KEY`).
- `set_focused(on)`: sets the car's `input_enabled`. The car reads `Input` (the actions) directly, so without focus it must not drive; the session's R and the overlay's keys need the key events, which a `SubViewportContainer` passes to its viewport.
- `take_gift()`: takes the gift's highlighted card (the overlay's own keys and a click on the card work too).
- Signals: `trick_counted(trick_id, done)` (the car's trick id, for example `"air_three_sixty"`), `progress(done, goal)` (also sent with 0 on every `setup`/`restart`), `completed()` (the third success, after its `progress`), `car_reset()`, `gift_opened()`, `gift_taken(id)`. The drift (T-565) sends `seconds_progress(done, goal)` (seconds, also 0 on every `setup`/`restart`) instead of `trick_counted` and `progress`, and `completed()` when its total reaches 3 s.
- Values: `successes`, `GOAL` (3), `drift_seconds` and `DRIFT_SECONDS` (3.0, T-565), `trick`, `state` (a `RunState`), `missions` (the notebook's `RunMissions`), `notebook` (the `MissionPage`), `car`.

## How it works

- **The world** (`World` node) is built once from `layout_path` (`PLAYGROUND_PATH`): the map scene (`mvp_map.tscn`, no challenges, no alert signs) with its elevation layer (rooftops and ramps), the rails and their drawing, the car's shadow, and the car's drawing (`View`: the car sprite, drift smoke, boost, jump effect, rail sparks, the jump arrow, the trick popups and the camera), as `run.gd` builds them. The playground draws its own grid ground (its `"ground_style"`, T-560).
- **Pausing** sets `World.process_mode` to disabled (which also takes the bodies out of the physics space, so a test steps the car only after `start()`). Never the tree's pause: the slide around the window keeps working.
- **The combo:** a `RunState` (its process disabled, so the clock never runs and the run never ends) hears the car's tricks, airtime, grinds and crashes as in the run (`add_trick`, `add_airtime_trick`, `add_grind_trick`, `collision`); the trick popups follow it. Its own mission pack is unused.
- **The drift counts seconds (T-565):** `COUNTED["drift"]` is empty; after each car step in which `car.model.is_drifting` (the flag the run's drift counter reads), `add_drift_seconds(dt)` adds the step's seconds to `drift_seconds` (capped at `DRIFT_SECONDS`) and to the notebook goal `{"trick": "drift_seconds", "kind": "seconds", "amount": 3}` through `RunMissions.add_seconds` (no `trick_counted`, so no falling box: a proposal). The line shows the total with one decimal (`MissionPage.format_seconds`). Tests and fixtures can call `add_drift_seconds(seconds)` directly.
- **Counting:** `RunState.combo_trick` (what pays) is matched against `COUNTED[trick]`. Air spins count once per car step, so a landing that pays both an AIR 360! and an AIR 180! counts once. Each success calls the notebook tracker's `on_trick(GOAL_TRICK[trick])`.
- **The notebook:** the real `MissionPage`, on its own `CanvasLayer` (layer 10), bound to a `RunMissions` started with `start_with([[{"trick": GOAL_TRICK[trick], "kind": "count", "amount": 3}]])`. Its goal line comes from the page's `goal_templates` (T-561), so the run's own mission texts are untouched. Scaled with `UiScale.keep(root, NOTEBOOK_BASE)`, 70% of the HUD's layout page, at `NOTEBOOK_POS`.
- **The gift:** `PracticeOffers` (`scripts/run/practice_offers.gd`) is the real `PowerUpOffers` with two changes: it opens only through `offer_only(id)` (never from a mission) and pauses only the session (`pause_with`). The real `PowerUpScreen` shows it. `GIFT` says which practice opens with which power-up (the grind with Jump); it opens on the first `start()` after `setup`/`restart`.
- **The car** is rebuilt by `reset_car()` (no drift, grind or jump left over) at `start_point()`: the level's spawn for every trick (T-574, the board: one start for all slides; the per-trick start points of T-560 are no longer read). Leaving the map's rectangle (plus `AREA_MARGIN`) resets it on the next frame.

## The level and the texts (T-560 and T-559, both wired)

- **The playground (T-560, wired):** `PLAYGROUND_PATH` is `data/level/practice_playground.json` ([../level/practice-playground.md](../level/practice-playground.md)); every trick starts on the level's spawn (T-574). The stand-in this ticket used before (`practice_stand_in.json`) is removed.
- **The drift's seconds line (T-564):** `goal_template("drift")` reads `DRIFT_SECONDS_TEXT_KEYS`, `tutorial.goal.drift`, which T-564 rewrote in place ("Drift seconds {done}/{total}"); both numbers show with one decimal.
- **The goal lines (T-559, wired):** `GOAL_TEXT_KEYS` reads each goal line from `data/tutorial_text.json`, `tutorial.goal.drift`, `.altdrift`, `.airspin` and `.grind` (T-559's keys), each a template with `{done}` and `{total}`, word for word. No player text is in the code: a missing key logs an error and gives an empty line.
- **The falling box (T-563)** uses the same notebook: the goal's trick id is the car's own trick id (`extended_drift`, `alternate_drift`, `rail_grind`), except air spins, whose goal id is `air_spin` (two tricks); `trick_counted` gives the actual one.

## Tests and pictures

- `tests/unit/run/test_practice_session.gd`: the scene (no enemies, clock or damage), every slide on the spawn, counting for each trick and no other (and the third), on the real playground a drift, an alt drift, an air spin and a grind each driven from the spawn (the air spin and grind along scripted routes, T-574) and counted, the notebook's line and count, the Jump gift, pause, focus, R and leaving the playground.
- `tests/fixtures/practice_session_demo.tscn`: the session in a 704 x 440 window on a dark page; `PRACTICE_SHOT` = `drift`, `alt_drift`, `air_spin`, `grind_gift`, `grind` or `done`. `PRACTICE_SHOT=grind_gift bash game/tools/screenshot.sh res://tests/fixtures/practice_session_demo.tscn out.png 60`.

## The count overfills (T-574; the board, 2026-11-08: "i want the counter to be able to overfill (i.e. 5/3 alt drifts)")

- Past the goal the count goes on: `successes` and `drift_seconds` have no cap, and the notebook's line follows (5/3, 4.7/3.0). `completed()` is still sent once, at the goal, and the green check stamp stays.
- The tracker (`RunMissions`) stops at the goal and completes the mission, so past it the session tells the notebook itself, in the tracker's order: `MissionPage.drop_trick(goal, trick_id)` drops the trick's name box (it still falls and lands), then `MissionPage.show_progress(goal, done)` updates the line once the boxes in flight have landed. The run's notebook doesn't use them.

## Thread the needle in the practice windows (T-574 tweak 6; the board: "I had paired some of the obstacles. I want those pairings to be preserved in the tutorial as well.")

- The session builds the level's pairs as `run.gd` does: `needle` (`ThreadTheNeedle`, from the layout and `ComboData.needle_rules()`), its faint markers (`build_markers`, lifted and depth-sorted by the elevation layer) and `needle_flash` (`NeedleFlash`, under the paused World). After every car step it calls `touching(car.held_contacts())` and `observe(...)`; every `hit_obstacle` calls `touched(...)`; `threaded` pays `state.add_needle_trick()`, so the popup shows THREAD THE NEEDLE! with its amount and the combo goes up, on every slide. It counts toward no slide's goal (`COUNTED`).

