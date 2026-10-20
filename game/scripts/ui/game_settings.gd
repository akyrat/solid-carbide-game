class_name GameSettings
extends RefCounted
## The player's saved settings, in a small file under user:// (task T-015).
## The camera zoom and the camera options (task T-123): camera smoothing, the
## dynamic camera and its min and max zoom. No nodes, so tests run it directly.

const DEFAULT_ZOOM := 14.4
const MIN_ZOOM := 6.0
const MAX_ZOOM := 20.0
const DEFAULT_PATH := "user://settings.cfg"
## Camera options (task T-123), both off by default.
const DEFAULT_CAMERA_SMOOTHING := false
const DEFAULT_DYNAMIC_CAMERA := false
## The dynamic camera's zoom at a standstill and at top forward speed:
## proposals for the board to tune, around the default 14.4.
const DEFAULT_DYNAMIC_ZOOM_MIN := 11.0
const DEFAULT_DYNAMIC_ZOOM_MAX := 17.0

## The sound effects' volume (task T-077), 0 to 100, in section "audio". 0 is silent,
## and it is the default (board, 2026-10-16): sound effects are silent until turned up.
const DEFAULT_SFX_VOLUME := 0.0
const SFX_BUS := "SFX"
## The music's volume (task T-209), 0 to 100, in section "audio", on its own "Music" bus so it
## never moves the sound effects. The starting value is a proposal for the playtest; T-210's
## pause screen slider sets it.
const DEFAULT_MUSIC_VOLUME := 40.0
const MUSIC_BUS := "Music"

## Where the settings are read and written. Tests point this at a test file.
static var path := DEFAULT_PATH


## The saved camera zoom, or DEFAULT_ZOOM when there is no file or no valid value.
static func load_zoom() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return DEFAULT_ZOOM
	var v = cfg.get_value("camera", "zoom", DEFAULT_ZOOM)
	if not (v is float or v is int):
		return DEFAULT_ZOOM
	return clampf(float(v), MIN_ZOOM, MAX_ZOOM)


## Saves the camera zoom, keeping any other settings already in the file.
static func save_zoom(zoom: float) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("camera", "zoom", clampf(zoom, MIN_ZOOM, MAX_ZOOM))
	return cfg.save(path) == OK


## Whether camera smoothing is on (default off).
static func load_camera_smoothing() -> bool:
	return _load_bool("smoothing", DEFAULT_CAMERA_SMOOTHING)


static func save_camera_smoothing(on: bool) -> bool:
	return _save_value("smoothing", on)


## Whether the dynamic camera is on (default off).
static func load_dynamic_camera() -> bool:
	return _load_bool("dynamic", DEFAULT_DYNAMIC_CAMERA)


static func save_dynamic_camera(on: bool) -> bool:
	return _save_value("dynamic", on)


## The dynamic camera's zoom at a standstill, clamped to 6..20.
static func load_dynamic_zoom_min() -> float:
	return _load_zoom_value("dynamic_min", DEFAULT_DYNAMIC_ZOOM_MIN)


## The dynamic camera's zoom at top forward speed, clamped to 6..20.
static func load_dynamic_zoom_max() -> float:
	return _load_zoom_value("dynamic_max", DEFAULT_DYNAMIC_ZOOM_MAX)


## Saves the min and prints the min and max for the Project Lead to copy.
static func save_dynamic_zoom_min(v: float) -> bool:
	var ok := _save_value("dynamic_min", clampf(v, MIN_ZOOM, MAX_ZOOM))
	print(dynamic_zoom_report())
	return ok


## Saves the max and prints the min and max for the Project Lead to copy.
static func save_dynamic_zoom_max(v: float) -> bool:
	var ok := _save_value("dynamic_max", clampf(v, MIN_ZOOM, MAX_ZOOM))
	print(dynamic_zoom_report())
	return ok


## One readable line with the saved min and max and the file they are in.
static func dynamic_zoom_report() -> String:
	return "Dynamic camera zoom: min %.1f, max %.1f (saved in %s, section camera)" % [
		load_dynamic_zoom_min(), load_dynamic_zoom_max(), ProjectSettings.globalize_path(path)]


static func _load_bool(key: String, default: bool) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return default
	var v = cfg.get_value("camera", key, default)
	return v if v is bool else default


static func _load_zoom_value(key: String, default: float) -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return default
	var v = cfg.get_value("camera", key, default)
	if not (v is float or v is int):
		return default
	return clampf(float(v), MIN_ZOOM, MAX_ZOOM)


static func _save_value(key: String, v: Variant) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("camera", key, v)
	return cfg.save(path) == OK


## The saved SFX volume, 0 to 100 (default 0).
static func load_sfx_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return DEFAULT_SFX_VOLUME
	var v = cfg.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME)
	if not (v is float or v is int):
		return DEFAULT_SFX_VOLUME
	return clampf(float(v), 0.0, 100.0)


static func save_sfx_volume(v: float) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("audio", "sfx_volume", clampf(v, 0.0, 100.0))
	return cfg.save(path) == OK


## Makes sure the "SFX" audio bus exists (every sound effect plays on it) and returns its index.
static func ensure_sfx_bus() -> int:
	var i := AudioServer.get_bus_index(SFX_BUS)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, SFX_BUS)
		AudioServer.set_bus_send(i, "Master")
	return i


## Sets the SFX bus to `volume` (0 to 100): 0 is muted, 100 leaves the per-sound volumes
## (data/sfx.json) as they are, in between it scales the loudness (a straight 0..1 gain).
static func apply_sfx_volume(volume: float) -> void:
	var i := ensure_sfx_bus()
	var gain := clampf(volume, 0.0, 100.0) / 100.0
	AudioServer.set_bus_mute(i, gain <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(gain, 0.0001)))


## The saved music volume, 0 to 100 (default DEFAULT_MUSIC_VOLUME).
static func load_music_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return DEFAULT_MUSIC_VOLUME
	var v = cfg.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
	if not (v is float or v is int):
		return DEFAULT_MUSIC_VOLUME
	return clampf(float(v), 0.0, 100.0)


static func save_music_volume(v: float) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("audio", "music_volume", clampf(v, 0.0, 100.0))
	return cfg.save(path) == OK


## Makes sure the "Music" audio bus exists (the music plays on it) and returns its index.
static func ensure_music_bus() -> int:
	var i := AudioServer.get_bus_index(MUSIC_BUS)
	if i < 0:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, MUSIC_BUS)
		AudioServer.set_bus_send(i, "Master")
	return i


## Sets the Music bus to `volume` (0 to 100): 0 is muted, 100 is full, in between a straight
## 0..1 gain (like the SFX bus).
static func apply_music_volume(volume: float) -> void:
	var i := ensure_music_bus()
	var gain := clampf(volume, 0.0, 100.0) / 100.0
	AudioServer.set_bus_mute(i, gain <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(gain, 0.0001)))
