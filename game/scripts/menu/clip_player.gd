class_name ClipPlayer
extends Control
## Plays one of the tutorial clips (task T-485): the recorded GIFs in game/art/tutorial/clips/,
## which Godot does not play, as frame sheets made by game/tools/gif_to_sheet.py
## (<clip>_sheet.png and <clip>_sheet.json: the frame size, the columns and each frame's own
## duration, read from the GIF). It draws the current frame stretched over its own rectangle
## (cropped to fill, the aspect kept) with nearest-neighbour pixels, and loops. It loads the
## sheet pages (each at most 4096 x 4096, for WebGL) when its slide is shown (the slides call
## ensure_loaded) and frees them when it is hidden, so only the visible slide's clips are in
## memory; it only advances while visible. `advance(delta)` is the whole clock, so a test can step it.

const CLIP_DIR := "res://art/tutorial/clips/"

var clip := ""
var sheet: Texture2D  # the first page
var pages: Array[Texture2D] = []
var meta: Dictionary = {}
var frame := 0
var elapsed_ms := 0.0
var _durations: Array = []
var _loaded := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


## Chooses the clip by name ("drift"); it loads when first shown, or at once with `load_now`.
func set_clip(clip_name: String, load_now := false) -> void:
	clip = clip_name
	_loaded = false
	unload()
	frame = 0
	elapsed_ms = 0.0
	if load_now:
		ensure_loaded()


## Reads the sheet and its timing; false (and an error) when a file is missing.
func ensure_loaded() -> bool:
	if _loaded:
		return sheet != null
	_loaded = true
	var json_path := CLIP_DIR + clip + "_sheet.json"
	var f := FileAccess.open(json_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ClipPlayer: no sheet for the clip '%s'" % clip)
		return false
	meta = parsed
	_durations = meta["durations_ms"]
	pages.clear()
	for name in meta["pages"]:
		var path: String = CLIP_DIR + name
		if not ResourceLoader.exists(path):
			push_error("ClipPlayer: missing sheet page %s" % path)
			unload()
			return false
		pages.append(load(path) as Texture2D)
	sheet = pages[0]
	queue_redraw()
	return true


## Frees the sheet pages (the clock's place is kept); ensure_loaded reads them again.
func unload() -> void:
	pages.clear()
	sheet = null
	_loaded = false


func frame_count() -> int:
	return _durations.size()


## Steps the clip's clock by `delta` seconds, frame by frame with each frame's own duration.
func advance(delta: float) -> void:
	if _durations.is_empty():
		return
	elapsed_ms += delta * 1000.0
	var before := frame
	while elapsed_ms >= float(_durations[frame]):
		elapsed_ms -= float(_durations[frame])
		frame = (frame + 1) % _durations.size()
	if frame != before:
		queue_redraw()


func _process(delta: float) -> void:
	if is_visible_in_tree() and _loaded and sheet != null:
		advance(delta)


func _on_visibility_changed() -> void:
	if is_visible_in_tree() and clip != "":
		ensure_loaded()
	elif _loaded:
		unload()


func _draw() -> void:
	if pages.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var fs := Vector2(meta["frame_size"][0], meta["frame_size"][1])
	var cols := int(meta["columns"])
	var per_page := int(meta["frames_per_page"])
	var in_page := frame % per_page
	var page: Texture2D = pages[frame / per_page]
	var origin := Vector2((in_page % cols) * fs.x, (in_page / cols) * fs.y)
	# Cover: crop the frame to the rectangle's aspect, so nothing is stretched.
	var src := Rect2(origin, fs)
	var want := size.x / size.y
	if fs.x / fs.y > want:
		var w := fs.y * want
		src = Rect2(origin + Vector2((fs.x - w) / 2.0, 0), Vector2(w, fs.y))
	elif fs.x / fs.y < want:
		var h := fs.x / want
		src = Rect2(origin + Vector2(0, (fs.y - h) / 2.0), Vector2(fs.x, h))
	draw_texture_rect_region(page, Rect2(Vector2.ZERO, size), src)
