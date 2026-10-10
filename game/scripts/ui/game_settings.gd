class_name GameSettings
extends RefCounted
## The player's saved settings, in a small file under user:// (task T-015).
## For now only the camera zoom. No nodes, so tests run it directly.

const DEFAULT_ZOOM := 14.4
const MIN_ZOOM := 6.0
const MAX_ZOOM := 20.0
const DEFAULT_PATH := "user://settings.cfg"

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
