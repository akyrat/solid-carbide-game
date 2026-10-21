class_name LevelCreatorEditor
extends Control
## The level creator's editor (task T-234's stub, filled in by T-235). It holds the level being
## edited (an empty map for a new level, or the loaded file for an existing one) as data in the
## map-file format (level_document.gd), and draws it in the game's isometric view with the run's
## own scripts: mvp_map.gd built from the level's data, and elevation_layer.gd for the rooftops
## and ramps. The drawing is rebuilt when a piece changes (only the ground tiles are redrawn for a
## ground or road tile).
##
## Controls (game/README.md, "Level creator"): pick an asset in the side panel, left-click the map
## to place it at the clicked tile; with nothing picked, left-click selects the piece under the
## cursor (right-click selects too and drops the pick); the Delete button or the Del key removes the
## selected piece; Esc drops the pick and the selection. Pan: drag with the middle mouse button, or
## the arrow keys. Zoom: the mouse wheel.

signal back_pressed

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")

const ISO_TRANSFORM := MvpMapScript.ISO_TRANSFORM
const PX_PER_UNIT := MvpMapScript.PX_PER_UNIT
## Camera (proposals): the zoom a level opens at, its limits, a wheel step, the arrow keys' pan
## speed in screen pixels per press.
const START_ZOOM := 0.2
const MIN_ZOOM := 0.05
const MAX_ZOOM := 3.0
const ZOOM_STEP := 1.15
const KEY_PAN_PX := 80.0
## The overlay draws over every building and area (RenderingServer's z limit is 4096).
const OVERLAY_Z := 4000

## The level's data (the map-file format of data/level/elevation_sample_map.json).
var level_data: Dictionary = {}
## The file the level was loaded from; "" for a new level.
var level_path: String = ""
var back_button: Button
var delete_button: Button
var hint_label: Label
## The level's data model (level_document.gd), over level_data.
var document: LevelDocument
var panel: LevelCreatorAssetPanel
var map_view: SubViewportContainer
var viewport: SubViewport
var world: Node2D
## The view (the map view's canvas transform): how many screen pixels one map pixel takes, and
## where the map's centre is on screen (null until the view has a size: then its middle).
var zoom := START_ZOOM
var view_origin = null
## The map drawing (mvp_map.gd) and its elevation layer (elevation_layer.gd), rebuilt on changes.
var map: Node2D
var elevation: Node2D
## The selected piece (LevelDocument.piece_at), {} for none.
var selected: Dictionary = {}
## The cell under the mouse, (-1, -1) for none.
var hover_cell := Vector2i(-1, -1)

var _overlay: Node2D
var _dragging := false


## A new level: an empty map with the default name.
func open_new() -> void:
	level_path = ""
	level_data = empty_level()
	_load_document()


## An existing level, loaded from its file.
func open_level(path: String) -> void:
	level_path = path
	level_data = LevelStore.load_level(path)
	_load_document()


static func empty_level() -> Dictionary:
	return LevelDocument.new_level_data(CreatorTexts.get_text("default_level_name"))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.14)
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var layout := HBoxContainer.new()
	layout.name = "Layout"
	add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = LevelCreatorAssetPanel.new()
	panel.name = "AssetPanel"
	layout.add_child(panel)
	panel.asset_picked.connect(_on_asset_picked)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	main.add_child(bar)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = CreatorTexts.get_text("back_button")
	back_button.pressed.connect(func(): back_pressed.emit())
	bar.add_child(back_button)
	delete_button = Button.new()
	delete_button.name = "DeleteButton"
	delete_button.text = CreatorTexts.get_text("delete_label")
	delete_button.pressed.connect(delete_selected)
	bar.add_child(delete_button)

	map_view = SubViewportContainer.new()
	map_view.name = "MapView"
	map_view.stretch = true
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_view.focus_mode = Control.FOCUS_CLICK
	main.add_child(map_view)
	viewport = SubViewport.new()
	viewport.name = "MapViewport"
	viewport.handle_input_locally = false
	map_view.add_child(viewport)
	world = Node2D.new()
	world.name = "World"
	viewport.add_child(world)
	map_view.gui_input.connect(_on_map_input)
	map_view.resized.connect(_apply_view)

	hint_label = Label.new()
	hint_label.name = "Hint"
	hint_label.text = CreatorTexts.get_text("controls_hint")
	main.add_child(hint_label)

	_overlay = _Overlay.new()
	_overlay.name = "Overlay"
	_overlay.editor = self
	_overlay.z_index = OVERLAY_Z
	_overlay.z_as_relative = false

	if document == null:
		if level_data.is_empty():
			level_data = empty_level()
		document = LevelDocument.new(level_data)
	_rebuild_map()
	_apply_view()


func _load_document() -> void:
	document = LevelDocument.new(level_data)
	selected = {}
	if is_node_ready():
		_rebuild_map()


# ---- Drawing ------------------------------------------------------------------------------------

## Builds the map drawing again from the level's data: mvp_map.gd and its elevation layer.
func _rebuild_map() -> void:
	if world == null:
		return
	if map != null and is_instance_valid(map):
		world.remove_child(map)
		map.free()
	map = MapScene.instantiate()
	map.name = "Map"
	map.layout = document.map_layout()
	map.ground_layout = document.ground_layout()
	map.alert_signs_enabled = false
	world.add_child(map)
	map.set_view("iso")
	elevation = ElevationLayerScript.new()
	elevation.name = "Elevation"
	map.add_child(elevation)
	elevation.setup_data(map, map.layout)
	if _overlay.get_parent() == null:
		world.add_child(_overlay)
	else:
		world.move_child(_overlay, -1)
	_overlay.queue_redraw()


## Redraws only the ground tiles (after a ground or road tile changed).
func _refresh_ground() -> void:
	map.ground_layout = document.ground_layout()
	map.ground_tiles.queue_redraw()


func _refresh_after(kind: String) -> void:
	if kind in ["ground", "road"]:
		_refresh_ground()
	else:
		_rebuild_map()
	_overlay.queue_redraw()


# ---- Placing, selecting and deleting ------------------------------------------------------------

## Places the catalogue asset `asset_id` at the tile under `units` (into the data and the
## drawing). Returns the placed piece, or {}.
func place_asset(asset_id: String, units: Vector2) -> Dictionary:
	var piece := document.place(asset_id, units)
	if not piece.is_empty():
		_refresh_after(str(piece.kind))
	return piece


## Selects the piece drawn on top at `units` (LevelDocument.piece_at).
func select_at(units: Vector2) -> Dictionary:
	selected = document.piece_at(units)
	_overlay.queue_redraw()
	return selected


## Removes a piece from the data and the drawing. Returns true when something was removed.
func delete_piece(piece: Dictionary) -> bool:
	if not document.delete(piece):
		return false
	if not selected.is_empty() and _same_piece(selected, piece):
		selected = {}
	_refresh_after(str(piece.kind))
	return true


## The Delete button and the Del key: removes the selected piece.
func delete_selected() -> void:
	if selected.is_empty():
		return
	var piece := selected
	selected = {}
	delete_piece(piece)


static func _same_piece(a: Dictionary, b: Dictionary) -> bool:
	if a.has("cell") or b.has("cell"):
		return a.get("cell") == b.get("cell")
	return is_same(a.get("item"), b.get("item"))


func _on_asset_picked(_id: String) -> void:
	_overlay.queue_redraw()


# ---- Camera and input ---------------------------------------------------------------------------

## A point in the map view (its local pixels) -> map units.
func screen_to_units(local_pos: Vector2) -> Vector2:
	var canvas := viewport.get_canvas_transform().affine_inverse() * local_pos
	return ISO_TRANSFORM.affine_inverse() * canvas / PX_PER_UNIT


## Map units -> a point in the map view (its local pixels).
func units_to_screen(units: Vector2) -> Vector2:
	return viewport.get_canvas_transform() * (ISO_TRANSFORM * (units * PX_PER_UNIT))


## Sets the map view's canvas transform from zoom and view_origin (the map's centre in the
## middle of the view until the view has been panned or zoomed).
func _apply_view() -> void:
	if viewport == null:
		return
	if view_origin == null:
		var s := map_view.size
		if s.x <= 0.0 or s.y <= 0.0:
			viewport.canvas_transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, Vector2.ZERO)
			return
		view_origin = s / 2.0
	viewport.canvas_transform = Transform2D(0.0, Vector2(zoom, zoom), 0.0, view_origin)
	if _overlay != null:
		_overlay.queue_redraw()


func _origin() -> Vector2:
	return view_origin if view_origin != null else map_view.size / 2.0


## Moves the view by a drag of `screen_delta` pixels (the map follows the mouse).
func pan_by(screen_delta: Vector2) -> void:
	view_origin = _origin() + screen_delta
	_apply_view()


## Zooms by `factor` (above 1 closer), keeping the point under `local_pos` in place.
func zoom_by(factor: float, local_pos: Vector2) -> void:
	var o := _origin()
	var before := (local_pos - o) / zoom
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	view_origin = local_pos - before * zoom
	_apply_view()


func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_by(ZOOM_STEP, mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_by(1.0 / ZOOM_STEP, mb.position)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var units := screen_to_units(mb.position)
			if panel.picked != "":
				place_asset(panel.picked, units)
			else:
				select_at(units)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			panel.pick("")
			select_at(screen_to_units(mb.position))
		map_view.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			pan_by(mm.relative)
		var c := document.cell_at(screen_to_units(mm.position))
		if c != hover_cell:
			hover_cell = c
			_overlay.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed:
		return
	match k.keycode:
		KEY_DELETE:
			delete_selected()
		KEY_ESCAPE:
			panel.pick("")
			selected = {}
			_overlay.queue_redraw()
		KEY_LEFT:
			pan_by(Vector2(KEY_PAN_PX, 0))
		KEY_RIGHT:
			pan_by(Vector2(-KEY_PAN_PX, 0))
		KEY_UP:
			pan_by(Vector2(0, KEY_PAN_PX))
		KEY_DOWN:
			pan_by(Vector2(0, -KEY_PAN_PX))
		_:
			return
	get_viewport().set_input_as_handled()


## Draws, over the map: the picked asset's footprint at the cell under the mouse, and the
## selected piece's outline (both on the ground, in the isometric view).
class _Overlay extends Node2D:
	var editor

	func _draw() -> void:
		var doc: LevelDocument = editor.document
		if doc == null:
			return
		var w := 2.0 / maxf(editor.zoom, 0.01)
		if editor.panel != null and editor.panel.picked != "" and editor.hover_cell.x >= 0:
			var e := LevelDocument.entry(editor.panel.picked)
			if not e.is_empty():
				var r := Rect2(doc.cell_corner(editor.hover_cell),
					Vector2(float(e.footprint_units[0]), float(e.footprint_units[1])))
				_outline(r, Color(0.55, 0.85, 1.0, 0.9), w)
		if not editor.selected.is_empty():
			_outline(doc.piece_rect(editor.selected), Color(1.0, 0.85, 0.3, 1.0), w * 1.5)

	func _outline(r: Rect2, color: Color, width: float) -> void:
		var pts := PackedVector2Array()
		for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]:
			pts.append(editor.ISO_TRANSFORM * (p * editor.PX_PER_UNIT))
		draw_polyline(pts, color, width)
