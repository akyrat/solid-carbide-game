# The Drift Guide (task T-517)

Design: `docs/drifting.md`, Decisions and Content, "The Drift Guide". This page is how the code works.

## Pieces
- `scripts/driving/drift_guide.gd` (a Node2D, `run.drift_guide`, a child of the run's `View` under the car sprite, lifted with the ground under the car like the drift smoke).
- `GameSettings.load_drift_guide_enabled()` / `save_drift_guide_enabled(on)` (section "graphics", off by default). Every save emits `GameSettings.notifier.drift_guide_enabled_changed`, which the guide follows: **the function the pause screen calls to switch it at once is `GameSettings.save_drift_guide_enabled(on)`** (it saves and applies).
- `CarModel.duplicate_state()`: a full copy of the driving state, so a prediction has no side effects.
- `Car.last_input`: `[w, s, steer]` of the last physics step.
- `data/drift_guide.json`: seconds ahead (1.0), points every 5 steps, width, head, gray, opacity, fade bands, fade-in and fade-out seconds. All proposals.

## How it runs
1. After each car step (`Car.stepped`) the guide reads `car.model.is_drifting`. While drifting, or while still fading out, `DriftGuide.predict()` steps a copy of the model 50 steps with `last_input` and keeps a point every `sample_steps` steps (`path_units`, in units).
2. `_process` moves `alpha` to 1 while drifting (`fade_in_seconds`) and to 0 otherwise (`fade_out_seconds`). Setting off: alpha 0, no path, nothing computed.
3. Drawing: the path as quads in flat opacity bands (`fade_bands`, from `max_opacity` to `tip_opacity` of it at the tip) times `alpha`, and a triangle head, through the iso transform, so it lies flat on the ground.

## Walls, ramps, jumps
- `blocked` (the run sets it to `Car.test_move` with the car's current heading) ends the path before a step that would hit something.
- No height is predicted and Space is not predicted; Rev Charge and the Polarized Steering Wheel are not predicted. In the air the model is not drifting, so the arrow fades out.

## Tests and screenshots
`tests/unit/test_drift_guide.gd`; fixtures `tests/fixtures/drift_guide_left.tscn` and `drift_guide_right.tscn`; screenshots in `art-archive/T-517/screenshots/`. The prediction test holds the input for 1 s and requires every sampled point to be within 0.01 units of the real car.
