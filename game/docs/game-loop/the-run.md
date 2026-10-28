# The run

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## The run

The run itself (task T-036): `scenes/run/run.tscn` puts the run's map (the elevation sample map's layout since T-206, see "The run's map (T-206)" below) and the drift car together under a camera that follows the car, and holds the run's state: the 8-minute clock, the car's health, the coins collected this run, and win and loss (Game loop architecture, Decisions). The drift prototype stays as it is, as a tuning tool.

**Run it:** in the Godot editor, open `scenes/run/run.tscn` and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/run/run.tscn screenshots/run.png 30`. Keys: W, S, A and D, as in the drift prototype. Run on its own like this, nothing happens on screen when the run ends and Escape does not pause; started from the main menu (see "Screen flow"), Escape pauses and the end of the run goes back to the menu.


**The scene** (`scripts/run/run.gd`, root node `Run`):

- Children: `Map` (the MVP map scene, `scenes/level/mvp_map.tscn`, with the elevation sample map's layout since T-206, drawn in the isometric view, with the drift marks inside its drawing, see "Drift marks"), `PhysicsWorld` (the `Car`, never drawn, in the same flat world pixels as the map), `View` (the drift smoke, see "Drift smoke", then the car's sprite and the `Camera`) and `RunState` (the state, below).
- The car starts at the centre of the map (0, 0 units, in the gravel square), nose along -y, as in the drift prototype. The camera sits exactly on the drawn car, zoom 14.4, as in the drift prototype, unless a camera option is on (see "Camera options"). The map checks its challenges against the car (`map.car`).
- **The car health upgrade (T-061):** at the start of every run the car's starting and maximum health are the garage's car health upgrade at its current level, `PlayerProgress.current_value("car_health")` (level 0 is run.json's `starting_health`, 100). `GameFlow.start_run()` sets `run.progress = progress` before adding the run; `run.gd` hands it to `state.progress`, and `RunState.start_run()` uses it for `max_health` and `health`, so the HUD's health bar maximum follows. A run on its own (no `progress`, null) uses run.json's value. Test: `tests/unit/run/test_run_health_upgrade.gd`.
- `run.start_run()` starts a fresh run: it replaces the map (meteor boulders gone; every challenge open again when challenges are on) and the car (back at the start, standing still), emits `world_rebuilt`, then resets the state. The scene calls it once in `_ready()`. Anything holding the old `run.map` or `run.car` picks up the new ones on `world_rebuilt`.

**The run's map (T-206)** (Level design, Decisions, "The elevation sample map becomes the run's map"; Content, "Elevation sample map", "The run on this map"):
- **Weapons at the car's height (T-225):** `neon_underglow.gd` and `windshield_wiper.gd` have `car_height()` (the car's `height`, 0 without one) and add `Vector2(0, -height * 16)` to their drawing's position, as the exhaust flames do (T-206); the drawings sit in the car's `View`, so the depth order is the car's. Tests: `tests/unit/run/test_run_elevation_map.gd` (`test_the_underglow_*`, `test_the_wiper_*`). Screenshots: `tests/fixtures/run_elevation_underglow_{street,rooftop,ramp,air}.tscn` (`run_elevation_demo.gd` has `underglow_tier` and `wiper_tier`); results in `art-archive/T-225/screenshots/`.

- **The switch:** `const USE_ELEVATION_MAP := true` in `scripts/run/run.gd`. True (the default): the run's map is built from `data/level/elevation_sample_map.json` (`ELEVATION_LAYOUT_PATH`) with its rooftops and ramps. Set it to `false` for the MVP map (`data/level/mvp_map.json`), exactly as before T-206 (no rooftops, no round shadow, the car at height 0). Tests and fixtures can set the instance's `run.use_elevation_map` (it starts at the constant) and call `run.start_run()`.
- **Another map file (T-230; Level design, Decisions, "Level creator"):** the run plays the map file in `run.layout_path` (a `res://` or `user://` path to a layout in the elevation sample map's format; it starts at `ELEVATION_LAYOUT_PATH`, and an empty one falls back to it, `run.current_layout_path()`). Either set it before the run enters the tree (`var run = preload("res://scenes/run/run.tscn").instantiate(); run.layout_path = "user://levels/my_level.json"; add_child(run)`), or start a new run on it with `run.start_run("user://levels/my_level.json")` (which sets `layout_path`, so later `start_run()` calls keep that map). `_build_world()` uses the one path for both the map (`map.layout_path`: buildings, boulders, ground, map rectangle) and the elevation layer (`elevation.setup(map, path)`: rooftops and ramps), and the enemies' navigation (`enemy_navigation.gd`, `for_map`) is built from that map, so all of them come from the same file. With nothing set, the main menu's run plays the elevation sample map exactly as before. Only read while `use_elevation_map` is true. Tests: `tests/unit/run/test_run_layout_path.gd` (a copy of the sample map under the per-run test folder with one building and the rooftop `roof-se-6` and its ramp removed: the map and the elevation layer read it, and enemy navigation finds a path from the street up `ramp-nw-0-3` to `roof-nw-3`).
- **The elevation layer** (`scripts/level/elevation_layer.gd`, taken out of the elevation sample map scene so both share it, not copied): `_build_world()` adds it as the map's child `Elevation` and calls `setup(map, layout_path)`; `run.elevation` is it (null on the MVP map). It builds one drawing per rooftop and ramp, sorts them with the buildings (`restack`), and hooks into the map (`map.elevation`), so the map's own depth queries take the areas into account at street level: `top_z_index()` is over every area too, `car_z_index()` (used by the drift smoke and others) and `_boulder_z()` go under a rooftop covering them, and `is_open_spot()` (gift packages, meteor landings) only accepts street-level spots. `enemy_depth.gd` puts enemies, coins and pickups under any area covering them, at height 0 (since T-207 enemies and coins at the ground height they stand on: "Enemies on the rooftops and ramps (T-207)"). The map's own building fade (`_process`) is off while the layer is there; the run calls the layer's `update_see_through()` with the car's height instead. The depth order and see-through rules are the sample map's: "Depth order and see-through (T-197)" below.
- **The car:** `car.ground` is the layer's `ground_height`, so the car has its real height (`car_height.gd`). `sync_view()` on this map (`_sync_view_elevation`) draws the car lifted by its height (`car_sprite.place`) with its shadowless frames in the air (`set_in_air`, T-205), its round shadow `CarShadow` (`car_shadow.gd`, a child of the run, hidden on the MVP map) on the ground under it, both in the depth order (`elevation.z_for`, on `View` and the shadow), the see-through, and the camera following the car as drawn, height included, eased (T-228). The drift smoke and boost effect are lifted with the ground under the car (a proposal).
- **Start:** unchanged, (0, 0) in the gravel square, at street level on this layout (a proposal).
- **The board's tweaks after playing it (2026-10-21):** no drift smoke and no tyre marks while the car is airborne, even with the drift keys held; both come back on landing (Drifting, Decisions, "No drift smoke or tyre marks in the air"; `drift_smoke.gd`, `bind()` emits only when the static `smokes(car)` is true, and `drift_marks.gd`, `bind()` lays only when `lays(car)` is: drifting and not `car.airborne`, so the marks end on takeoff and new ones start on landing). The exhaust flamethrower's flames are drawn at the car's exhaust at its height (Weapons, Decisions, "The flamethrower at height"; `exhaust_flamethrower.gd`, `_update_drawing()` lifts the drawing by `car_height()` units, as the car sprite is lifted); its damage area stays the flat rectangle behind the car's map position, so it burns what is at the car's spot (since T-207 an enemy there stands on the same ground as the car, except right at an edge). Screenshot fixtures: `run_elevation_air_drift_keys.tscn` (in the air with the drift keys held, no smoke or tyre marks) and `run_elevation_flamethrower_rooftop.tscn` (drifting on the height-6 rooftop with the flamethrower); `run_elevation_demo.gd` has `steer_from`, `steer` and `flamethrower_tier` for them.

Tests: `tests/unit/run/test_run_elevation_map.gd` (the switch both ways, one drawing per area, a new run with a new layer, the car's height, shadow, air frames and depth order on a rooftop and behind one, the see-through, the camera, open spots, an enemy's depth, and a run going on with enemies). Tests that check the MVP map's own blocks set `run.use_elevation_map = false` first (`test_see_through_map.gd`, `test_drift_smoke.gd`, `test_mvp_map_no_challenges.gd`, `test_run_scene.gd`'s challenges test).

**The 2-minute scripted run:** `python game/tools/run_scene_headless.py res://tests/fixtures/run_elevation_soak.tscn 150 --show` starts a run from the main menu on the elevation map and plays it for 120 s (`run_elevation_soak.gd`): the car driven by script and moved every 12 s to the street, the rooftops at 3 and 6 and a ramp's foot, two level-ups through the gift packs at 25 s, the clock moved to 1:01 at 70 s for the kaiju; one line every 10 s and a summary. `run_mvp_soak.tscn` does the same on the MVP map. At exit Godot prints `ERROR: 1 resources still in use at exit` on both maps (the engine sound's stream, `audio/sfx/engine/748027_sedan-engine-loop.ogg`, still held when the game quits): it comes from quitting, not from the run, and is older than T-206.

**Screenshot fixtures** (`tests/fixtures/run_elevation_demo.gd`: a run from the main menu with the car put at `start_units`, W held for `drive_steps` physics steps, then stopped, health kept full): `run_elevation_{street,rooftop,air,behind,kaiju}.tscn`, for example `bash game/tools/screenshot.sh res://tests/fixtures/run_elevation_air.tscn art-archive/T-206/screenshots/run_elevation_air.png 500` (the air shot drives 106 steps, so it needs many frames). Screenshots: `art-archive/T-206/screenshots/`.

**The state** (`scripts/run/run_state.gd`, class `RunState`). Reach it with `run.state`, or from anywhere with `get_tree().get_first_node_in_group("run_state")`.

| Function | Does |
| --- | --- |
| `start_run()` | Resets the state for a fresh run: health = max health = the starting health in `data/run.json`, 8:00 on the clock, 0 coins. Use `run.start_run()` to reset the map and car too |
| `damage_car(amount: float)` | Takes `amount` off the car's health (stops at 0). At 0 the run ends as a loss. Ignored when the run is over or `amount` is not positive |
| `add_coins(amount: int)` | Adds coins collected this run. Ignored when the run is over or `amount` is not positive |
| `kaiju_killed()` | The Enemy Behavior Agent calls it when the kaiju dies: the run ends at once as a win. Ignored when the run is over |
| `advance(seconds: float)` | Moves the clock forward by hand (tests). The clock otherwise runs on its own in `_process` |
| `is_running()` | True from `start_run()` until the run ends |
| `time_left_text()` | The time left as M:SS ("8:00" ... "0:01", "0:00"), rounded up to whole seconds |
| `shown_seconds()`, `time_elapsed()` | The time left in whole seconds as the clock shows it; seconds since the run started |

| Value | Is |
| --- | --- |
| `time_left` | Seconds left, 480 at the start, 0 at the end |
| `health`, `max_health` | The car's health now, and its full health |
| `coins` | Coins collected this run |
| `result` | "" while the run is going, then "win" or "loss" |

| Signal | Fires |
| --- | --- |
| `run_started()` | When a fresh run starts (after every value is reset) |
| `boss_time()` | Once per run, when 7 minutes have passed (1:00 left). The kaiju spawns on it |
| `run_ended(result: String, coins: int)` | Once per run: "win" (kaiju killed) or "loss" (health at 0, or the clock reaching 0:00), with this run's coins, kept either way. Saving them is a Game Data task that listens here |
| `time_left_changed(seconds_left: float)` | When the clock shows a different whole second (and on start) |
| `health_changed(health: float, max_health: float)` | When the car takes damage (and on start) |
| `coins_changed(coins: int)` | When coins are added (and on start) |

**Likes (XP) and levels** (task T-037; the rules are Game loop architecture, Decisions, the numbers are `data/run.json` through `RunData`). The run scene connects the map's `challenge_completed` and `meteor_challenge_completed` to `state.challenge_completed` (neither fires while challenges are off in the MVP, so likes come from drifting only), and after every car physics step calls `state.drift_step(car.model.is_drifting, car.model.dt)`. Drifting is the driving model's `is_drifting` (the Unity definition: W, or S without W, held with A or D). All XP gained is multiplied by the combo (below).

| Function | Does |
| --- | --- |
| `challenge_completed(challenge_id: String)` | A challenge (preset or meteor) was completed: sends `score` with the current level's `challenge_xp`, then adds it as XP |
| `drift_step(drifting: bool, delta: float)` | One physics step of the car's drift state. An unbroken drift gives `drift_xp_per_second` when it reaches 1 s (the first second included), then again at each further full second: 0.9 s gives nothing, 3 s gives 3 seconds' worth, 3.5 s gives 3. A step without drifting ends the drift |
| `add_xp(amount: float)` | Adds XP. Each time XP reaches the level's threshold, the level goes up by one and `level_up` fires; leftover XP carries over (`carry_over_xp`), so one gain can give several level-ups. At the top level (`max_level`) XP stays at 0 and the bar stops |
| `xp_needed()` | The current level's threshold (0 at the top level) |
| `is_max_level()` | True at the top level |
| `open_choice(level_reached: int)` | (T-144) Starts the weapon choice for that level: pauses the run and sends `level_up_choice_started`, so the level-up screen opens; while a choice is on show it waits its turn. The gift pack calls it when the car drives over a package (see "The gift pack drop"); with the switch on, every level-up calls it at once. Ignored when the run is not going |
| `choice_made()` | The player made the level-up's weapon choice (T-052 calls it): the next waiting choice starts, or the run resumes. Ignored when no choice is waiting |
| `is_waiting_for_choice()`, `choice_level()` | Whether the run is paused for a choice, and the level whose choice is on show (0 for none) |

| Value | Is |
| --- | --- |
| `xp` | XP toward the next level (after leftovers), 0 at the start |
| `level` | The level, 1 at the start |
| `pause_on_level_up` | The level-up pause switch, **off** (the run scene keeps it off since T-144). Off: a level-up raises the level and the run carries on; in the run scene the gift pack's package opens the choice through `open_choice()` when it is driven over. On (tests and tools only): each level-up pauses the run (`get_tree().paused`, so the clock and the car stop) at once until `choice_made()`, with no helicopter; two level-ups at once wait one after the other |
| `pending_choices` | The levels whose choice is waiting (opened by `open_choice()`), oldest first |

| Signal | Fires |
| --- | --- |
| `xp_changed(xp: float, xp_needed: float, level: int)` | When XP or the level changes (gains, level-ups, every frame the likes drain takes XP away), and on start. For the HUD's likes bar (T-049) |
| `score(amount: float, challenge_id: String)` | When a challenge is completed, with the XP (likes) it gave. For the challenge popup (T-092) |
| `level_up(new_level: int)` | Once per level reached, switch on or off |
| `level_up_choice_started(new_level: int)` | `open_choice()` (the package picked up, or the switch on): the run is now paused for that level's choice (T-052 opens its screen here) |
| `level_up_choice_made(new_level: int)` | `choice_made()` closed that level's choice |

A new run (`start_run()`) resets XP to 0 and the level to 1, forgets the drift in progress and any waiting choice (unpausing if it was waiting). Nothing is added after the run ends.

**The likes drain** (task T-115; the rule is Game loop architecture, Decisions, "Likes drain", the numbers are `likes_drain` in `data/run.json` through `RunData`, task T-114). Once the combo is back at "no combo" (`combo` at `start_multiplier`, after the combo's own wait and drain), and after `likes_drain_extra_wait_seconds` (0 for now), `xp` goes down by `RunData.likes_drain_xp_per_second(level)` per second, stopping at 0: the level never goes down. Any trick raises the combo, which stops the drain until the combo has drained again. It runs inside `advance()` (`_drain_likes()`), so it stops while the tree is paused (pause screen, level-up screen) and after the run ends; it also skips while a weapon choice is waiting. At the top level there is nothing to drain: XP stays at 0 there and the HUD shows the bar full. Each frame it takes XP away it sends `xp_changed`, so the HUD's likes bar empties (the bar rounds to whole likes, its step being 1, so it moves one like at a time).

| Function or value | Is |
| --- | --- |
| `has_no_combo()` | True when the combo is at "no combo" |
| `is_likes_draining()` | True while the drain is taking XP away now (no combo, the extra wait passed, XP above 0, not the top level, no choice waiting, the run going) |
| `likes_drain_idle` | Seconds the combo has been at "no combo"; a trick or a new run sets it to 0 |

A screenshot fixture, `tests/fixtures/likes_drain_demo.tscn`, starts a run from the main menu with level 2 and a fifth of its bar, then does nothing, printing the time, XP and level every half second: `bash game/tools/screenshot.sh res://tests/fixtures/likes_drain_demo.tscn screenshots/likes_drain_1.png 90` (the bar emptying; at T-120's speed the fifth of level 2's bar is gone in about 2.5 s) and `... screenshots/likes_drain_2.png 3500` (empty, still level 2). The frame counts depend on the screen's refresh rate; the printed lines say how far in each shot is.

**The level-up effect** (task T-112; Visual style, Decisions, "Level-up effect"): at every level-up the car gives off one burst of pixel particles. The run scene connects the state's `level_up` signal to its burst, `run.level_up_burst`, a `CPUParticles2D` from `scenes/run/level_up_burst.tscn` (script `scripts/run/level_up_burst.gd`: `play()` starts the burst, `is_playing()`). It sits under `View`, drawn over the car, and `sync_view()` keeps it on the drawn car; `local_coords` is on, so the particles move with the car while they play. Several level-ups in the same moment (one gain giving two levels) restart the same burst, so they show as one burst. Its `process_mode` is Always, so it keeps playing while the run is paused for the level-up screen (T-052).

- **Particle art (task T-074, a proposal for the board's review):** `art/effects/level_up_particles.png`, one row of six 11 x 11 frames drawn by a script (no PixelLab, board 2026-10-13): a cyan and a pink four-point star, a pink and a cyan diamond, a violet pixel cross and a small cyan spark, each with a white-hot core and stepped darker halo pixels (glow in the pixels), 13 colours in all, no red. Its record, with the palette, is `art/effects/level_up_particles.json`. Built and checked by `python game/tools/build_level_up_particles.py build` (byte-identical every run) and `python game/tools/build_level_up_particles.py check` (every frame: transparent background, no semi-transparent pixels, about 30 colours or fewer; the whole sheet: no red; exit 1 on a fail). Python tests: `game/tools/test_build_level_up_particles.py` (also fails if the committed PNG or record is out of date).
- **How the scene uses it:** a `CanvasItemMaterial` with particles animation (`particles_anim_h_frames` 6) reads the sheet as a flipbook; `anim_offset` 0 to 1 with `anim_speed` 0 gives every particle one random shape for its whole life. `scale_amount` 0.5 draws the art at the car's density (32 art pixels per unit at 16 world pixels per unit); particles are never rotated. Tuning: `amount` 40, `lifetime` 0.8 s with `lifetime_randomness` 0.35, `emission_sphere_radius` 24, `spread` 180, `initial_velocity` 180 to 320, `damping` 180 to 240. They do not fade: `scale_amount_curve` keeps full size until 65% of the life, steps to half size, and pops out at 86%. The placeholder (a 4 x 4 pale cyan square, T-112) is gone.
- **To swap the art and retune it (T-074):** change only `scenes/run/level_up_burst.tscn` (and redraw the sheet with the script above): `texture` (the particle sprite; keep `color` white so the sprite shows its own colours), `amount`, `lifetime`, `initial_velocity_min/max`, `damping_min/max`, `spread`, `emission_sphere_radius`, `scale_amount_curve` and the flipbook material's frame count. Keep `texture_filter` Nearest, `one_shot`, `explosiveness` 1, `process_mode` Always and every colour's alpha at 1; the tests below check them. When and how it plays is in `scripts/run/run.gd` and does not change.
- **Screenshot** of the burst at a level-up in a run from the main menu: `bash game/tools/screenshot.sh res://tests/fixtures/level_up_burst_demo.tscn screenshots/level_up_burst.png 40`.
- **Tests:** `tests/unit/run/test_level_up_burst.gd` (part of the GUT suite): not playing before, started by the `level_up` signal and by a real level-up, on the car and following it, two level-ups at once, one burst that ends, still playing while paused, the settings in the scene, nearest-neighbour, no alpha fade, and particle art that is not the heart's red. `tests/unit/run/test_level_up_particles_art.gd` (T-074): the scene uses the sheet, the sheet matches its record, one random shape per particle, the car's art density, no rotation, the stepped shrink with no fade.

**The combo** (task T-081; the rules are Game loop architecture, Decisions, the numbers are `data/combo.json` through `ComboData`). The run scene connects the car's `trick` signal to `state.add_trick` and the car's `hit_obstacle` (walls, buildings, the map edge, boulders) to `state.collision`. `damage_car()` also calls `collision()`, so any damage to the car (enemies, meteors) cuts the combo. The multiplier multiplies all XP gained: `challenge_completed()` (and its `score` signal), the drift seconds of `drift_step()`, and `add_xp()`.

| Function | Does |
| --- | --- |
| `add_trick(trick_id: String)` | The car did a trick: the multiplier goes up by `trick_add[trick_id]`, held at `max_multiplier`, and the drain wait starts again. Sends `combo_trick`, then `combo_changed` (if it changed). An id that is not one of `TrickDetector.TRICK_IDS` is ignored |
| `collision()` | The car collided with something: the multiplier is cut by `collision_cut` (80%) of the part above `start_multiplier` (`ComboData.after_collision`) |
| `combo_spawn_multiplier()` | How much the minion spawn rate is multiplied at the current combo (`ComboData.spawn_multiplier`, 1.0 with no combo). For enemy spawning (T-085) |

| Value | Is |
| --- | --- |
| `combo` | The multiplier now, `start_multiplier` (1.0, no combo) at the start of a run |
| `combo_idle` | Seconds since the last trick (or the run's start). Once it passes `drain_wait_seconds` (2 s), the multiplier drains by `drain_per_second`, down to `start_multiplier` |

| Signal | Fires |
| --- | --- |
| `combo_trick(trick_id: String, added: float, multiplier: float)` | Every trick during the run: the trick, how much the multiplier went up (the data's amount, less at the cap, 0 once there) and the new multiplier. For the trick popups (T-083) |
| `combo_changed(multiplier: float)` | Whenever the multiplier changes (a trick, a collision, the drain, every frame while draining) and on start. For the HUD's combo counter (T-083) and enemy spawning (T-085) |

The drain runs with the clock (`advance()`), so it stops while the run is paused, and the drain wait does not count paused time. A new run resets the multiplier and the drain wait. Nothing changes after the run ends.

**Pause:** the clock runs in `_process` with the default (pausable) process mode, so setting `get_tree().paused = true` stops it. Anything that pauses the run (the pause screen, the level-up choice) does it that way. The run's length (8 minutes) and the boss's arrival (7 minutes in) are constants in `run_state.gd`, `RUN_SECONDS` and `BOSS_TIME_LEFT`, because they are Decisions, not balancing numbers.

**Tests:** `tests/unit/run/test_run_state.gd` (the clock, boss time, health, coins, win and loss, pause, a second run), `tests/unit/run/test_run_scene.gd` (the map and car loaded, the start position, the camera following the car, a second run resetting the map and car) and `tests/unit/run/test_run_likes.gd` (challenge and meteor challenge XP, drift seconds, level-ups and leftovers, the pause switch off and on, two level-ups at once, the top level, a new run resetting XP) and `tests/unit/run/test_run_combo.gd` (tricks raising the multiplier, the cap, likes multiplied, collisions and damage cutting it, the drain and a trick stopping it, a new run, pause, a run started from the main menu) and `tests/unit/run/test_run_likes_drain.gd` (T-115: no drain with a combo, the drain at T-114's speed once it is gone, a trick stopping it, never below the level's start even over a long drain, no drain while paused, while a choice waits, after the run ends or at the top level, the extra wait, the switch, `xp_changed` firing and the HUD's likes bar emptying in a run), part of the GUT suite.

