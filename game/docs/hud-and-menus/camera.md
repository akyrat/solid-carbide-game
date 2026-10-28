# Camera options

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Camera options

Task T-123 (Drifting, Content, "Camera options"): camera smoothing and the dynamic camera (zoom follows the car's speed), both off by default. With both off the camera sits exactly on the drawn car with the slider's zoom, as before.

- `scripts/driving/camera_follow.gd`: the options, no nodes. The drift prototype and the run each own one, `camera_follow`. After every car physics step the scene calls `camera_follow.step(drawn_car_position, speed_fraction, dt)` and puts `camera_follow.position` and `camera_follow.size` (Unity's orthographic size) on its `Camera`; a new run, a view switch or an outside `sync_view()` call snaps it with `snap()`. `speed_fraction_of(car.model)` is the car's speed in any direction over its top forward speed, capped at 1. The tunable rates are its constants `SMOOTHING_RATE` (8 per second) and `ZOOM_EASE_RATE` (3 per second). **Height (task T-228):** `step()` and `snap()` take an optional last argument, the lift of the car's drawing (`CarSprite.lift_for_height(car.height, PX_PER_UNIT)`, 0 by default). The ground part follows as the options say; the height part (`height_offset`) eases at `HEIGHT_EASE_RATE` (4 per second, a proposal), and `position` is the sum. The run (`_sync_view_elevation`), the elevation sample scene and the elevation test scene pass the lift, so the car stays near the screen's middle on rooftops, ramps and in the air; with lift 0 the camera is exactly as before. Tests: `tests/unit/test_camera_follow_height.gd` and the camera test in `tests/unit/run/test_run_elevation_map.gd`. Recording fixture: `tests/fixtures/run_camera_height_gif.tscn` (a run driven up both ramps and off the height-6 rooftop).
- **Saved:** in `user://settings.cfg`, section `camera`, next to `zoom`: `smoothing` and `dynamic` (true or false, default false), `dynamic_min` and `dynamic_max` (6 to 20, defaults `GameSettings.DEFAULT_DYNAMIC_ZOOM_MIN` 11.0 and `DEFAULT_DYNAMIC_ZOOM_MAX` 17.0; out of range is clamped, a bad value gives the default). `GameSettings` has `load_`/`save_camera_smoothing`, `load_`/`save_dynamic_camera`, `load_`/`save_dynamic_zoom_min` and `load_`/`save_dynamic_zoom_max`. The drift prototype reads them at start; `game_flow.gd` has a run read them right after the zoom (`run.load_camera_options()`). A run scene opened on its own starts with both off.
- **Reading the board's min and max:** every save of the min or max prints a line like `Dynamic camera zoom: min 11.0, max 17.0 (saved in C:/Users/.../settings.cfg, section camera)` to Godot's output (`GameSettings.dynamic_zoom_report()` gives the same line). The file itself is a plain text file: on Windows, `%APPDATA%\Godot\app_userdata\Solid Carbide\settings.cfg`, keys `dynamic_min` and `dynamic_max`. Copy them into `DEFAULT_DYNAMIC_ZOOM_MIN` and `DEFAULT_DYNAMIC_ZOOM_MAX` to make them the game's defaults.
- **Tests:** `tests/unit/test_camera_options.gd`, part of the GUT suite.

**API for the pause screen's controls (task T-124).** The pause screen's `target` is the drift prototype or the run; call these on `target.camera_follow`. Every setter saves at once and applies at once, also while the game is paused.

| Call | Does |
| --- | --- |
| `set_smoothing(on: bool)` | The "Camera smoothing" checkbox. |
| `is_smoothing() -> bool` | Its state, for the checkbox's starting value. |
| `set_dynamic(on: bool)` | The "Dynamic camera" checkbox. On: the zoom eases from where it is toward the speed's zoom. Off: straight back to the slider's zoom. |
| `is_dynamic() -> bool` | Its state (also: show the min and max buttons only while it is on). |
| `set_dynamic_min_from_current() -> float` | "Set min zoom": the min becomes the slider's current zoom (`target.zoom`); returns the new min. |
| `set_dynamic_max_from_current() -> float` | "Set max zoom": the same for the max. |
| `get_dynamic_min() -> float`, `get_dynamic_max() -> float` | The stored values, to show next to the buttons. |
| signal `changed` | Emitted after any of the above and after a slider zoom change. |

The zoom slider keeps calling `target.set_zoom(v)`: with the dynamic camera off that is the camera's zoom, as before; with it on the view shows that zoom at once (a preview for choosing the min or max) and eases back to the speed's zoom when the car moves.

