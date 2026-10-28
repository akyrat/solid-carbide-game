# Drift

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Drift prototype

The first playable piece (task T-012): the car driving and drifting like the board's Unity prototype, on a flat, empty ground with a grid, with a tuning panel and a flat / isometric view switch. It is no longer the project's main scene (the main menu is, since task T-055); it stays as a tuning tool. After the board's playtest (task T-029) it differs from the Unity prototype in four defaults (see Drifting, Decisions, 2026-10-08): top speed multiplier 3.0 (top speed 33; Unity 2.5), cruise jump still 11, physics interpolation on, and it starts in the isometric view. Every other driving value is the Unity value.

**Run it:**

- From the Godot editor: open the `game/` folder as a project, open `scenes/drift_prototype/drift_prototype.tscn` and press F6 (Run Current Scene). F5 starts the game on the main menu instead.
- Without the editor, from the repo root in Git Bash: `"$GODOT_BIN" --path game res://scenes/drift_prototype/drift_prototype.tscn` (with `GODOT_BIN` from `.env`). In PowerShell: `& $env:GODOT_BIN --path game res://scenes/drift_prototype/drift_prototype.tscn` after setting `$env:GODOT_BIN` to the same path.

**Keys:**

| Key | Does |
| --- | --- |
| W | Forward: jumps to cruise speed, then speeds up to top speed |
| S | Brakes while moving forward, then reverses |
| A / D | Rotate the car left / right (at any speed, also standing still) |
| Tab | Opens and closes the tuning panel |
| V | Switches between the flat top-down and the isometric view |
| Escape | Pauses and resumes. The pause screen shows the title, a hint and the camera zoom slider (see "Pause screen") |

There is no jump, no arrow-key steering and no gamepad.

**Tuning panel** (Tab): a live readout (speed, forward and sideways speed, drift angle, drift amount, and the last trick, how long ago it was and how many of each trick so far), a button that resets everything to the game's values (the defaults above, interpolation on, zoom 14.4, wall bounce 0.25, the trick limits), an "Isometric view" toggle (same as V; on at start), a "Physics interpolation" toggle (on by default), the camera zoom slider (6 to 20, starting at 14.4), one slider per handling setting, the side slip out of a drift's four sliders in their own group (task T-278; see "Side slip out of a drift (T-278)") and, in a "Collisions" group at the bottom, the wall bounce slider (task T-033: 0 to 1, proposed default 0.25; see "Car collisions") and, in a "Tricks" group under it, the alternate drift's limits (task T-079; see "Tricks"). Every slider starts at the game's value and applies at once; hover a slider or its label for a tooltip, which also shows the Unity value. Changes are not saved: restarting goes back to the defaults.

**Test room** (task T-033): a few walls and one boulder (3 units across) around the start point, so the board can try the bounce: a closed square of walls 40 units from the start on every side, an L-shaped wall to the right of the start (its corner about 25 units right and 25 up) and the boulder 12 units right and 12 up. Placeholder colours, the MVP map's. The real map is the MVP map (below).

**How it is built** (`scripts/driving/`):

- `car_model.gd`: the movement, step by step as in the Unity prototype report, section 4, in units (1 unit = the car's width). No nodes, so tests run it directly. Its `cruise_jump(from_speed, w_just_pressed)` signal fires when W makes the car jump up to cruise speed (for the boost effect, task T-008).
- `car_tuning.gd`: the handling values (defaults = the Unity values except top speed multiplier 3.0; the `UNITY` constant keeps the Unity values) and the slider list with labels, ranges and tooltips.
- `car.gd`: the car's `CharacterBody2D` in the flat physics world, a 1 x 1 unit square, running the model once per physics step (50 per second, set in `project.godot`). It relays `cruise_jump` and emits `stepped` after every step. It also handles collisions, the `hit_obstacle` signal and knockback (see "Car collisions"), and the `trick` signal (see "Tricks").
- `trick_detector.gd`: finds the tricks in the car's driving (see "Tricks"). No nodes, so tests run it directly.
- `drift_prototype.gd`: builds the scene. The physics world is never drawn; the `View` node draws the ground grid and the car sprite either flat or through the 2:1 isometric projection screen = (x - y, (x + y) / 2), and places the camera exactly on the drawn car (no rotation, no smoothing). Switching views changes only the drawing.
- `car_sprite.gd`: picks the sheet frame closest to the car's heading, reading the layout from the JSON next to each sheet (see "Placeholder car sprite sheets"), so the final art drops in without code changes.
- `ground_grid.gd`, `tuning_panel.gd`: the ground and the panel.
- `drift_marks.gd`: the drift marks (task T-117, see "Drift marks"), drawn over the ground and under the test room and the car, in the current view.
- `boost_effect.gd`: the boost effect (tasks T-008 and T-009, see "Boost effect"), used by the run.
- `drift_smoke.gd`: the drift smoke (task T-121, see "Drift smoke"), drawn over the test room and under the car, in the current view.
- `test_room.gd`: the test room's walls and boulder (static bodies on layer 1, under `PhysicsWorld`) and their drawing.

**Pixel scale:** 16 pixels per unit in the flat world, the same as the placeholder car sheets, so the flat placeholder sheet is drawn at scale 1 and the final isometric sheet (32 px per unit) at scale 0.5. The camera zoom is Unity's orthographic size (half the visible height in units); Godot's zoom is set to window height / (2 x size x 16), so 14.4 shows 28.8 units from top to bottom in both views.

**Tests:** `tests/unit/test_drift_model.gd` (the movement against the report's numbers) `tests/unit/test_drift_prototype.gd` (settings, input map, sliders, reset, view switch, camera, sprite), `tests/unit/test_car_collisions.gd` (bounce, enemies, the hit signal, knockback, layers, the test room and the bounce slider) and `tests/unit/test_tricks.gd` (the three tricks, the trick signal, the trick sliders and readout, and the movement being the same with detection on and off), part of the GUT suite. For screenshots of a scripted drive, use the fixtures `res://tests/fixtures/drift_prototype_demo_flat.tscn` and `..._iso.tscn` (add `_panel` for the panel open) with the screenshot tool, for example `bash game/tools/screenshot.sh res://tests/fixtures/drift_prototype_demo_iso.tscn screenshots/drift_iso.png 400`. `res://tests/fixtures/drift_prototype_room_flat.tscn` and `..._iso.tscn` drive the car into the test boulder, zoomed out to show the walls (40 frames is enough).

## Side slip out of a drift (T-278)

The board's decision: Drifting, Decisions, "A little side slip out of a drift". What it does in plain words: Drifting, Content, "Side slip out of a drift (task T-278)".

- **Where:** `car_model.gd`, `_exit_slip_turn()` and `_start_exit_slip()`, called once per ground step between the drift amount (step 2) and the steering (step 3). The model's `exit_slip` is the extra turn this step in degrees per second, signed like steer (positive = the way A turns); 0 = no slip. Nothing else in the step changes: speed, grip and the drift amount are as before.
- **When it starts:** on the step a drift ends because A or D is let go (`is_drifting` was true, is now false, and no steering is held). It is the share `exit_slip_turn` of the turn rate, times k², where k = the drift angle (0 to 90 degrees, measured from either end of the car) / `exit_slip_full_angle`, capped at 1, and turned the way the drift was turning. It starts only if that turn was making the slide bigger (sideways speed x forward speed x steer > 0), so a turn that was straightening the car never slips.
- **How it ends:** it fades in a straight line to 0 in `exit_slip_seconds`; steering against it fades it `exit_slip_catch` times faster; steering its own way ends it at once. Letting go of W while still steering (the alternate drift's switch) has no slip. In the air (`airborne`) it is cleared and never starts, so landing has none either.
- **Its size:** the whole extra turn is the full slip x (seconds + one step) / 2: 14.1 degrees at the defaults, at most 55 at the sliders' ends, so it can never spin the car.
- **Defaults** (`car_tuning.gd`, the block after `wall_bounce`; sliders in `SLIP_SETTINGS`, shown by the tuning panel in the "Out of a drift: side slip" group right after the handling sliders, and in its `slip_sliders`): strength `exit_slip_turn` 0.35 (0 to 0.75), length `exit_slip_seconds` 0.4 s (0.05 to 0.75), catch `exit_slip_catch` 4 (1 to 10), full at `exit_slip_full_angle` 60 degrees (10 to 90). The Unity values set the strength to 0, so `reset_to_unity()` gives the Unity car exactly. The panel's readout shows the slip in degrees per second.
- **Tests:** `tests/unit/test_drift_exit_slip.gd`.
- **GIF fixtures:** `res://tests/fixtures/drift_exit_slip_gif.tscn` (the drift prototype) and `drift_exit_slip_gif_run.tscn` (a run from the main menu, on the street at (0, 10) facing east, where the drive hits nothing): a drift with the slip off, one left alone, one caught with counter-steer, with a caption. Record with `"$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/drift_exit_slip_gif.tscn`, then `python game/tools/make_turn_gif.py C:/abs/dir out.gif --glob "f*.png" --every 2 --size 680 460 --scale 1 --ms 40`. `DRIFT_SLIP_START="x,y,heading"` tries another start spot; the fixture prints each wall hit.

