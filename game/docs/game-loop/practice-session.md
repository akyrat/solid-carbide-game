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
- Signals: `trick_counted(trick_id, done)` (the car's trick id, for example `"air_three_sixty"`), `progress(done, goal)` (also sent with 0 on every `setup`/`restart`), `completed()` (the third success, after its `progress`), `car_reset()`, `gift_opened()`, `gift_taken(id)`.
- Values: `successes`, `GOAL` (3), `trick`, `state` (a `RunState`), `missions` (the notebook's `RunMissions`), `notebook` (the `MissionPage`), `car`.

## How it works

- **The world** (`World` node) is built once from `layout_path` (`PLAYGROUND_PATH`): the map scene (`mvp_map.tscn`, no challenges, no alert signs) with its elevation layer (rooftops and ramps), the rails and their drawing, the car's shadow, and the car's drawing (`View`: the car sprite, drift smoke, boost, jump effect, rail sparks, the jump arrow, the trick popups and the camera), as `run.gd` builds them. A level with no painted `"ground"` hides the map's ground and draws `ground_grid.gd` under it, with the playground's edge outlined.
- **Pausing** sets `World.process_mode` to disabled (which also takes the bodies out of the physics space, so a test steps the car only after `start()`). Never the tree's pause: the slide around the window keeps working.
- **The combo:** a `RunState` (its process disabled, so the clock never runs and the run never ends) hears the car's tricks, airtime, grinds and crashes as in the run (`add_trick`, `add_airtime_trick`, `add_grind_trick`, `collision`); the trick popups follow it. Its own mission pack is unused.
- **Counting:** `RunState.combo_trick` (what pays) is matched against `COUNTED[trick]`. Air spins count once per car step, so a landing that pays both an AIR 360! and an AIR 180! counts once. Each success calls the notebook tracker's `on_trick(GOAL_TRICK[trick])`.
- **The notebook:** the real `MissionPage`, on its own `CanvasLayer` (layer 10), bound to a `RunMissions` started with `start_with([[{"trick": GOAL_TRICK[trick], "kind": "count", "amount": 3}]])`. Its goal line comes from the page's `goal_templates` (T-561), so the run's own mission texts are untouched. Scaled with `UiScale.keep(root, NOTEBOOK_BASE)`, 70% of the HUD's layout page, at `NOTEBOOK_POS`.
- **The gift:** `PracticeOffers` (`scripts/run/practice_offers.gd`) is the real `PowerUpOffers` with two changes: it opens only through `offer_only(id)` (never from a mission) and pauses only the session (`pause_with`). The real `PowerUpScreen` shows it. `GIFT` says which practice opens with which power-up (the grind with Jump); it opens on the first `start()` after `setup`/`restart`.
- **The car** is rebuilt by `reset_car()` (no drift, grind or jump left over) at `start_point()`: the level's `"practice_starts"[trick]` (`{x, y, heading}`, like `"spawn"`), else the level's spawn. Leaving the map's rectangle (plus `AREA_MARGIN`) resets it on the next frame.

## Seams for T-560 and T-559

- **The playground (T-560):** `PLAYGROUND_PATH` is the stand-in `data/level/practice_stand_in.json` (a 100 x 100 square, a ramp up to a short rooftop, one rail at height 1, no painted ground) until T-560's level is in; then point it at that file. The start points are read from the level's `"practice_starts"` (`drift`, `alt_drift`, `air_spin`, `grind`), so T-560's level gives them there (or the session's `start_point()` is changed to where T-560 puts them).
- **The goal lines (T-559):** `GOAL_TEXT_KEYS` names where each goal line is in `data/tutorial_text.json` (`practice.goal_drift`, `practice.goal_alt_drift`, `practice.goal_air_spin`, `practice.goal_grind`), each a template with `{done}` and `{total}`. Until they exist, `goal_template()` uses the trick's own name(s) from `tutorial_text.json` `trick.*` and `" {done}/{total}"`: "LONG DRIFT! 0/3", "ALT DRIFT! 0/3", "AIR 180! / AIR 360! 0/3", "GRIND! 0/3". Change the keys to T-559's.
- **The falling box (T-563)** uses the same notebook: the goal's trick id is the car's own trick id (`extended_drift`, `alternate_drift`, `rail_grind`), except air spins, whose goal id is `air_spin` (two tricks); `trick_counted` gives the actual one.

## Tests and pictures

- `tests/unit/run/test_practice_session.gd`: the scene (no enemies, clock or damage), the start points, counting for each trick and no other (and the third), a real drift and a real hop onto the rail, a real ramp takeoff, the notebook's line and count, the Jump gift, pause, focus, R and leaving the playground.
- `tests/fixtures/practice_session_demo.tscn`: the session in a 704 x 440 window on a dark page; `PRACTICE_SHOT` = `drift`, `alt_drift`, `air_spin`, `grind_gift`, `grind` or `done`. `PRACTICE_SHOT=grind_gift bash game/tools/screenshot.sh res://tests/fixtures/practice_session_demo.tscn out.png 60`.
