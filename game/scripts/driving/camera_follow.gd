extends RefCounted
## The camera options (task T-123; Drifting, Decisions, 2026-10-13): camera
## smoothing and the dynamic camera. No nodes, so tests step it directly. The
## run and the drift prototype each own one (`camera_follow`), step it after
## every physics step and put its `position` and `size` on their Camera2D.
##
## With both options off (the default) the camera sits exactly on the car and
## its size is the slider's zoom, as before.
##
## The pause screen's controls (task T-124) use the API at the bottom
## (set_smoothing, set_dynamic, set_dynamic_min_from_current, ...), which also
## saves to GameSettings. Sizes are Unity's orthographic size: half the visible
## height, in units.

const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

## Emitted when an option or the slider's zoom changes, so the scene can put
## the new size on its camera at once (also while paused).
signal changed

## Camera smoothing: how fast the camera closes the gap to the car, per second.
## Each step it covers 1 - exp(-rate * dt) of the gap, so the lag behind a car
## moving at v units/s settles at about v / rate units (at the game's top speed,
## 33 units/s: about 4 units, under a third of the default 14.4 half-height).
const SMOOTHING_RATE := 8.0
## Dynamic camera: how fast the size eases toward its target, per second, the
## same way. 3.0 covers about 63% of a change in 0.33 s and 95% in 1 s, so the
## zoom never jumps.
const ZOOM_EASE_RATE := 3.0

## Whether the camera follows the car with a short smooth lag.
var smoothing := false
## Whether the size follows the car's speed instead of the slider's zoom.
var dynamic := false
## The dynamic camera's size at a standstill and at top forward speed.
var dynamic_min: float = GameSettingsScript.DEFAULT_DYNAMIC_ZOOM_MIN
var dynamic_max: float = GameSettingsScript.DEFAULT_DYNAMIC_ZOOM_MAX
## The slider's zoom, used while the dynamic camera is off.
var base_size: float = GameSettingsScript.DEFAULT_ZOOM

## Where the camera is now, in drawn pixels.
var position := Vector2.ZERO
## The camera's size now.
var size: float = GameSettingsScript.DEFAULT_ZOOM


## The dynamic camera's target size for a speed, as a share of the car's top
## forward speed (0 = standing, 1 = top speed; clamped to 0..1). Linear.
func target_size(speed_fraction: float) -> float:
	return lerpf(dynamic_min, dynamic_max, clampf(speed_fraction, 0.0, 1.0))


## The size the camera is heading for now.
func goal_size(speed_fraction: float) -> float:
	return target_size(speed_fraction) if dynamic else base_size


## One physics step of dt seconds toward the car at `target` (drawn pixels).
func step(target: Vector2, speed_fraction: float, dt: float) -> void:
	if smoothing:
		position += (target - position) * (1.0 - exp(-SMOOTHING_RATE * dt))
	else:
		position = target
	if dynamic:
		var goal := target_size(speed_fraction)
		size += (goal - size) * (1.0 - exp(-ZOOM_EASE_RATE * dt))
	else:
		size = base_size


## Puts the camera straight on the car at its goal size (a new run, a view switch).
func snap(target: Vector2, speed_fraction: float) -> void:
	position = target
	size = goal_size(speed_fraction)


## The share of the top forward speed a car model is moving at (any direction).
static func speed_fraction_of(model) -> float:
	var top: float = model.tuning.top_speed()
	if top <= 0.0:
		return 0.0
	return clampf(model.total_speed() / top, 0.0, 1.0)


## The slider's zoom changed. With the dynamic camera off the camera takes it
## at once, as before. With it on, the view shows it at once too (a preview, so
## the board sees the zoom it is about to set as min or max) and eases back to
## the speed's zoom once the car moves again.
func set_base_size(v: float) -> void:
	base_size = v
	size = v
	changed.emit()


## Reads the saved options (without saving anything) and puts the size on its
## goal at once.
func load_saved(speed_fraction: float = 0.0) -> void:
	smoothing = GameSettingsScript.load_camera_smoothing()
	dynamic = GameSettingsScript.load_dynamic_camera()
	dynamic_min = GameSettingsScript.load_dynamic_zoom_min()
	dynamic_max = GameSettingsScript.load_dynamic_zoom_max()
	size = goal_size(speed_fraction)
	changed.emit()


# --- API for the pause screen's controls (task T-124). Each setter saves. ---

## The "Camera smoothing" checkbox.
func set_smoothing(on: bool) -> void:
	smoothing = on
	GameSettingsScript.save_camera_smoothing(on)
	changed.emit()


func is_smoothing() -> bool:
	return smoothing


## The "Dynamic camera" checkbox. Turning it on eases from the current zoom;
## turning it off goes straight back to the slider's zoom.
func set_dynamic(on: bool) -> void:
	dynamic = on
	if not on:
		size = base_size
	GameSettingsScript.save_dynamic_camera(on)
	changed.emit()


func is_dynamic() -> bool:
	return dynamic


## "Set min zoom": the min becomes the slider's current zoom. Returns it.
func set_dynamic_min_from_current() -> float:
	dynamic_min = clampf(base_size, GameSettingsScript.MIN_ZOOM, GameSettingsScript.MAX_ZOOM)
	GameSettingsScript.save_dynamic_zoom_min(dynamic_min)
	changed.emit()
	return dynamic_min


## "Set max zoom": the max becomes the slider's current zoom. Returns it.
func set_dynamic_max_from_current() -> float:
	dynamic_max = clampf(base_size, GameSettingsScript.MIN_ZOOM, GameSettingsScript.MAX_ZOOM)
	GameSettingsScript.save_dynamic_zoom_max(dynamic_max)
	changed.emit()
	return dynamic_max


func get_dynamic_min() -> float:
	return dynamic_min


func get_dynamic_max() -> float:
	return dynamic_max
