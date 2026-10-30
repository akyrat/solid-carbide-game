class_name LevelCreatorEditor
extends Control
## The level creator's editor (task T-234's stub, filled in by T-235). It holds the level being
## edited (an empty map for a new level, or the loaded file for an existing one) as data in the
## map-file format (level_document.gd), and draws it in the game's isometric view with the run's
## own scripts: mvp_map.gd built from the level's data, and elevation_layer.gd for the rooftops
## and ramps. The drawing is rebuilt when a piece changes (only the ground tiles are redrawn for a
## ground or road tile).
##
## Controls (game/docs/level/level-creator.md, "Level creator"): pick an asset in the side panel, left-click the map
## to place it at the clicked tile; with nothing picked, left-click selects the piece under the
## cursor (right-click selects too and drops the pick); the Delete button or the Del key removes the
## selected piece; Esc drops the pick and the selection. Pan: drag with the middle mouse button, or
## the arrow keys. Zoom: the mouse wheel.
##
## Rotate and mirror (T-236): before placing, the Rotate button or the R key steps the picked asset
## to the next view its catalogue entry lists, and the Mirror button or the M key to its next mirror
## (only those: the art exists only in the angles that were generated); the preview under the
## cursor shows the art of the current view and mirror. Heights: the side panel's rooftops at
## height 3 and 6 and ramps 0 to 3 and 3 to 6; a 6 placed on a 3 stands on it ("on"), and a ramp
## climbs the rooftop whose side its top touches (LevelDocument).
##
## Snapping (T-237): a piece goes on the tile grid and lines up with close neighbours, a ramp onto
## the side of the rooftop it climbs (snapping.gd, LevelSnapping); the preview shows where. A
## rooftop or ramp that would overlap in a way the level check refuses is not placed, and the top
## bar shows the overlap message.
##
## Sizing (T-251): rooftops (3 and 6) and ramps (0 to 3, 3 to 6, 0 to 6) are of any size: with one
## picked, drag on the map to size it (a ramp: its width along the rooftop's side; R steps a ramp
## through the four directions it can climb); the top bar shows the size, and the preview is drawn
## in the engine as the piece will be (elevation_platform_drawing.gd, textured mode).
##
## Families (T-262): the side panel is one button per kind of piece (asset_panel.gd, from the
## catalogue's families); the keys V (look), R (turn), M (mirror) and H (height) step the picked
## family's member (KEY_ACTIONS, creator_families.gd step), and the looks strip under it picks a
## look (apply_member). A member is an asset, view, mirror and variant, placed as before.
##
## The road brush (T-263, road_brush.gd): Road, Centre line and Cracked road paint whole roads
## along a left-drag (a right-drag, or Del, erases), joined into corners, T-junctions, crossroads
## and dead ends by the brush; Zebra crossing is a click across a road (brush_mode).
##
## Pairs (T-272, thread the needle): the Pair obstacles button or P turns the pair tool on; click
## one obstacle (a boulder, barrier, cones or crates), then another, to pair them (anything else is
## refused with a message); a pair shows as a dashed line and rings (_Overlay._draw_pairs). Unpair
## (with a paired obstacle selected) or deleting either obstacle removes it (LevelDocument).
## T-394: an obstacle can be in several pairs. Shift+click picks a row of obstacles in order (numbered
## on screen; Shift+click on the pick takes it out again), and Pair obstacles or P then pairs each
## with the next, or a plain click adds the last one and pairs the row. Unpair with a pick removes
## only the pairs between consecutive picked ones (one picked: all its pairs).
##
## Saving (T-238): the Save button writes the level, named from the level name field, through
## LevelStore.save_level into the levels folder (levels_dir), in the map-file format
## (LevelDocument.file_data); the top bar then shows the save confirmation. A level opened from the
## levels folder is saved over its own file; a new level, or a file opened from elsewhere (the
## game's own map), gets a new file there named after the level (save_path).

signal back_pressed
## After a successful save, with the file written.
signal saved(path: String)

const MapScene := preload("res://scenes/level/mvp_map.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const ElevationLayerScript := preload("res://scripts/level/elevation_layer.gd")
const BuildingTowers := preload("res://scripts/level/building_towers.gd")

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
## The levels folder a level is saved into (the creator's; tests set a temporary one).
var levels_dir: String = LevelStore.LEVELS_DIR
## The level name field and its label, and the Save button.
var name_field: LineEdit
var name_label: Label
var save_button: Button
var back_button: Button
var delete_button: Button
var rotate_button: Button
var mirror_button: Button
var style_button: Button
## T-264: the platform sizes S, M, L and Any size (the buttons by id), and the ramp arrows Up and Down.
var size_buttons: Dictionary = {}
var arrows_buttons: Dictionary = {}
## T-265: the top bar's Banner on and Banner off (by id, "on" and "off"), shown with a skyscraper picked or selected.
var banner_buttons: Dictionary = {}
## T-265: whether the next skyscraper placed shows its banner (key B): off by default.
var pick_banner: bool = false
## The picked asset's height label (creator_texts.json; empty for a piece without a height).
var height_label: Label
var hint_label: Label
## A message for the board (the overlap message when a piece can't be placed); empty otherwise.
var message_label: Label
## Why the last piece was not placed (LevelSnapping.overlap_problem), "" when it was.
var last_problem: String = ""
## The view and mirror the picked asset is placed in (one its catalogue entry lists).
var pick_view: String = ""
var pick_mirror: bool = false
## Which of the view's textures (T-262: a skyscraper's second body is one of its family's looks); "" for the first.
var pick_variant: String = ""
## T-264: the size a platform's plain click places, by the top bar's S, M, L and Any size: the
## squares in units (a proposal: 8, 16 and 32, the board's numbers). "any" is the board dragging the
## size out; its plain click is M's, the default. Snapping and the overlap refusal apply as before.
const PLATFORM_SIZES := {"s": 8.0, "m": 16.0, "l": 32.0}
var pick_platform_size: String = "m"
## T-264: which way a new ramp's arrows point, "up" the slope (the default) or "down" it (key A).
var pick_arrows: String = "up"
## The piece style a new rooftop or ramp of any size is drawn in (T-255; elevation_layer.gd PIECE_STYLES): the Style button steps it.
var pick_style: String = ElevationLayerScript.DEFAULT_PIECE_STYLE
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
## The cell under the mouse, (-1, -1) for none, and the point under it (units).
var hover_cell := Vector2i(-1, -1)
var hover_units := Vector2.ZERO
## A point inside a cell, from its corner (units): names that cell to LevelDocument.place.
const CELL_MIDDLE := LevelDocument.CELL / 2.0

var _overlay: Node2D
var _dragging := false

## Sizing (T-251): with a rooftop or ramp of any size picked, pressing the left button on the map
## starts a drag at that cell and releasing it places the piece over the cells dragged across (a
## ramp: its width along the rooftop's side; its length is fixed). A press and release on one cell
## places the default size. (-1, -1) while no drag is on.
var size_drag_start := Vector2i(-1, -1)
## The top bar's sizing line: size_hint while a resizable piece is picked, size_readout during a
## drag; and a picked ramp's direction (ramp_dir_*).
var size_label: Label
var direction_label: Label
## The preview of a piece of any size, drawn in the engine as it will be (a child of the overlay).
var preview_drawing: Node2D
var _preview_key := ""

## The road brush (T-263, road_brush.gd): with Road, Centre line or Cracked road picked, the left
## button paints road along the drag and the right button (or Del) erases it; with Zebra crossing
## picked, a click lays a crossing across the road. The last block a stroke reached ((-1, -1): no
## stroke on), and whether the stroke erases.
var road_stroke_last := Vector2i(-1, -1)
var road_erasing := false

## Pairs of obstacles (T-272, thread the needle): the pair tool (the top bar's Pair obstacles, key P)
## is on, the obstacles picked while it is, in order (T-394: a row, [] before), and the top bar's
## two buttons. pair_first is the first of them ({} for none).
var pair_mode := false
var pair_picks: Array = []
var pair_first: Dictionary:
	get:
		return pair_picks[0] if not pair_picks.is_empty() else {}
var pair_button: Button
var unpair_button: Button
## How a pair shows in the editor (a proposal): a dashed line across the gap between the two and a
## ring round each, in this colour (none of Greenbull's colours); the first obstacle clicked is ringed thicker.
const PAIR_COLOR := Color(0.35, 1.0, 0.75, 0.95)
const PAIR_DASH_UNITS := 1.0


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
	panel.member_picked.connect(apply_member)

	var main := VBoxContainer.new()
	main.name = "Main"
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(main)
	# A flow container: the bar wraps onto a second line when the picked piece's labels (height,
	# direction, size: T-251) don't fit beside the buttons.
	var bar := HFlowContainer.new()
	bar.name = "TopBar"
	bar.add_theme_constant_override("h_separation", 14)
	main.add_child(bar)
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = CreatorTexts.get_text("back_button")
	back_button.pressed.connect(func(): back_pressed.emit())
	bar.add_child(back_button)
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = CreatorTexts.get_text("name_field_label")
	bar.add_child(name_label)
	name_field = LineEdit.new()
	name_field.name = "NameField"
	name_field.custom_minimum_size = Vector2(220, 0)
	bar.add_child(name_field)
	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = CreatorTexts.get_text("save_label")
	save_button.pressed.connect(save)
	bar.add_child(save_button)
	delete_button = Button.new()
	delete_button.name = "DeleteButton"
	delete_button.text = CreatorTexts.get_text("delete_label")
	delete_button.pressed.connect(delete_selected)
	bar.add_child(delete_button)
	rotate_button = Button.new()
	rotate_button.name = "RotateButton"
	rotate_button.text = CreatorTexts.get_text("rotate_label")
	rotate_button.pressed.connect(rotate_pick)
	bar.add_child(rotate_button)
	mirror_button = Button.new()
	mirror_button.name = "MirrorButton"
	mirror_button.text = CreatorTexts.get_text("mirror_label")
	mirror_button.pressed.connect(mirror_pick)
	bar.add_child(mirror_button)
	style_button = Button.new()
	style_button.name = "StyleButton"
	style_button.pressed.connect(style_pick)
	bar.add_child(style_button)
	_update_style_button()
	for id in ["s", "m", "l", "any"]:
		var b := Button.new()
		b.name = "Size_" + id
		b.text = CreatorTexts.get_text("platform_size_" + id)
		b.toggle_mode = true
		b.pressed.connect(set_platform_size.bind(id))
		bar.add_child(b)
		size_buttons[id] = b
	for id in ["up", "down"]:
		var b := Button.new()
		b.name = "Arrows_" + id
		b.text = CreatorTexts.get_text("ramp_arrows_" + id)
		b.toggle_mode = true
		b.pressed.connect(set_arrows.bind(id))
		bar.add_child(b)
		arrows_buttons[id] = b
	for id in ["on", "off"]:
		var b := Button.new()
		b.name = "Banner_" + id
		b.text = CreatorTexts.get_text("banner_" + id)
		b.toggle_mode = true
		b.pressed.connect(set_banner.bind(id == "on"))
		bar.add_child(b)
		banner_buttons[id] = b
	pair_button = Button.new()
	pair_button.name = "PairButton"
	pair_button.text = CreatorTexts.get_text("pair_tool")
	pair_button.toggle_mode = true
	pair_button.pressed.connect(_on_pair_button)
	bar.add_child(pair_button)
	unpair_button = Button.new()
	unpair_button.name = "UnpairButton"
	unpair_button.text = CreatorTexts.get_text("unpair_label")
	unpair_button.pressed.connect(unpair_selected)
	bar.add_child(unpair_button)
	height_label = Label.new()
	height_label.name = "HeightLabel"
	bar.add_child(height_label)
	direction_label = Label.new()
	direction_label.name = "DirectionLabel"
	bar.add_child(direction_label)
	size_label = Label.new()
	size_label.name = "SizeLabel"
	bar.add_child(size_label)
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	bar.add_child(message_label)

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
	# T-280: the line with moving the start added (controls_hint_spawn).
	hint_label.text = CreatorTexts.get_text("controls_hint_spawn")
	# T-262: the longer line shrinks its font to fit a narrow window instead of running off its edge.
	map_view.resized.connect(_fit_hint)
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
	_show_name()
	_rebuild_map()
	_apply_view()
	_update_pose_controls()


## The hint line's font: the theme's size, smaller (down to HINT_MIN_FONT) while the line is wider
## than the map view.
const HINT_MIN_FONT := 10


func _fit_hint() -> void:
	if hint_label == null or map_view == null or map_view.size.x <= 0.0:
		return
	hint_label.remove_theme_font_size_override("font_size")
	var font := hint_label.get_theme_font("font")
	var fs := hint_label.get_theme_font_size("font_size")
	while fs > HINT_MIN_FONT and font.get_string_size(hint_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > map_view.size.x - 4.0:
		fs -= 1
	hint_label.add_theme_font_size_override("font_size", fs)


func _load_document() -> void:
	document = LevelDocument.new(level_data)
	document.ensure_spawn()  # T-280: every level has its spawn point
	selected = {}
	_show_name()
	_show_message("")
	if is_node_ready():
		_rebuild_map()


## The name field shows the level's name (its file name when the file has none).
func _show_name() -> void:
	if name_field == null:
		return
	var n := str(level_data.get("name", ""))
	if n == "" and level_path != "":
		n = level_path.get_file().get_basename()
	name_field.text = n


# ---- Saving (T-238) -----------------------------------------------------------------------------

## The name the level is saved under: the name field's text, or the default name when it is empty.
func level_name() -> String:
	var n := name_field.text.strip_edges() if name_field != null else str(level_data.get("name", ""))
	return n if n != "" else CreatorTexts.get_text("default_level_name")


## Where Save writes: the level's own file when it was opened from the levels folder (or saved
## there before), else a new file in the levels folder named after the level
## (LevelDocument.file_stem), with "-2", "-3"... when that name is taken.
func save_path() -> String:
	if level_path != "" and _same_dir(level_path.get_base_dir(), levels_dir):
		return level_path
	var stem := LevelDocument.file_stem(level_name())
	var path := levels_dir.path_join(stem + ".json")
	var n := 2
	while FileAccess.file_exists(path):
		path = levels_dir.path_join("%s-%d.json" % [stem, n])
		n += 1
	return path


static func _same_dir(a: String, b: String) -> bool:
	return a.simplify_path().trim_suffix("/") == b.simplify_path().trim_suffix("/")


## The Save button: writes the level (LevelDocument.file_data) with LevelStore.save_level and shows
## creator_texts.json's "save_confirmation". Returns OK or the error (nothing is shown then).
func save() -> Error:
	var path := save_path()
	var err := LevelStore.save_level(path, document.file_data(level_name()))
	if err != OK:
		_show_message("")
		return err
	level_path = path
	_show_message(CreatorTexts.get_text("save_confirmation"))
	saved.emit(path)
	return OK


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

## Places the catalogue asset `asset_id` with the cursor at `units` (into the data and the
## drawing), in the picked view and mirror when it is the picked asset (else its first ones),
## snapped to the tile grid and to close neighbours (LevelSnapping.placement, T-237). A rooftop or
## ramp that would overlap in a way check_height_data.py refuses is not placed, and the message
## label shows creator_texts.json's "overlap_message". Returns the placed piece, or {}.
##
## `size`: a rooftop's or ramp's size (T-251, LevelDocument.piece_size; ZERO: its default).
func place_asset(asset_id: String, units: Vector2, size: Vector2 = Vector2.ZERO) -> Dictionary:
	var picked_now := panel != null and asset_id == panel.picked
	var view := pick_view if picked_now else ""
	var mirror := pick_mirror if picked_now else false
	var variant := pick_variant if picked_now else ""
	size = default_size_for(asset_id, size)
	var at := LevelSnapping.placement(document, asset_id, units, view, mirror, size)
	if at.is_empty():
		return {}
	# The snapped corner is a cell corner: the middle of its cell names that cell.
	var corner: Vector2 = at.corner
	var piece := document.place(asset_id, corner + Vector2(CELL_MIDDLE, CELL_MIDDLE), view, mirror, at.rect.size, pick_style, variant, pick_arrows, pick_banner)
	if piece.is_empty():
		return {}
	if str(piece.kind) in ["rooftop", "ramp"]:
		last_problem = LevelSnapping.overlap_problem(document, str(piece.kind), piece.item)
		if last_problem != "":
			document.delete(piece)
			_show_message(CreatorTexts.get_text("overlap_message"))
			return {}
	# T-393 (proposal): an object stands wholly on one surface (street, one rooftop, one ramp) and
	# never inside a building; a building, rooftop or ramp never cuts through an object.
	var why := ""
	if str(piece.kind) in ["boulder", "prop"]:
		why = LevelSnapping.object_problem(document, document.piece_rect(piece))
	elif str(piece.kind) == "crater":
		why = LevelSnapping.crater_problem(document, document.piece_rect(piece))  # T-398: on the street
	elif str(piece.kind) in ["building", "rooftop", "ramp"]:
		why = LevelSnapping.cuts_object_problem(document, str(piece.kind), piece.item)
	if why != "":
		last_problem = why
		document.delete(piece)
		_show_message(CreatorTexts.get_text("overlap_message"))
		return {}
	if str(piece.kind) in ["building", "boulder", "prop"] and document.spawn_problem(LevelSpawn.position_of(level_data)) != "":
		# T-280: a piece never goes over the start: the car must always be able to stand there.
		document.delete(piece)
		_show_message(CreatorTexts.get_text("spawn_blocked"))
		return {}
	last_problem = ""
	_show_message("")
	_refresh_after(str(piece.kind))
	return piece


## Where the picked asset would go with the cursor at `units` (LevelSnapping.placement), {} for none.
func placement_at(units: Vector2, size: Vector2 = Vector2.ZERO) -> Dictionary:
	if _picked() == "" or document == null:
		return {}
	return LevelSnapping.placement(document, _picked(), units, pick_view, pick_mirror, default_size_for(_picked(), size))


## The size a plain click gives `asset_id` (T-264): a rooftop's S, M or L square (M for "any"); a
## size already given (a drag) is kept, and so is any other piece's.
func default_size_for(asset_id: String, size: Vector2) -> Vector2:
	if size != Vector2.ZERO or str(LevelDocument.entry(asset_id).get("kind", "")) != "rooftop" 			or not LevelDocument.is_resizable(asset_id):
		return size
	var side: float = PLATFORM_SIZES.get(pick_platform_size, PLATFORM_SIZES.m)
	return Vector2(side, side)


## The top bar's S, M, L or Any size (T-264): the size of the next platform's plain click.
func set_platform_size(id: String) -> void:
	pick_platform_size = id if id in ["s", "m", "l", "any"] else "m"
	_update_pose_controls()
	_overlay.queue_redraw()


## The top bar's Arrows up or down, and key A (T-264): which way the next ramp's arrows point. With
## a ramp selected and no ramp picked, it turns that ramp's arrows instead.
func set_arrows(arrows: String) -> void:
	pick_arrows = "down" if arrows == "down" else "up"
	if not selected.is_empty() and str(selected.kind) == "ramp" and str(LevelDocument.entry(_picked()).get("kind", "")) != "ramp":
		document.set_ramp_arrows(selected.item, pick_arrows)
		_rebuild_map()
	_update_pose_controls()
	_overlay.queue_redraw()


## The skyscraper a banner choice applies to (T-265): the one picked, else (nothing picked) the selected
## building when it is a skyscraper. {} for none; {"picked": true} for the picked one.
func _banner_target() -> Dictionary:
	if LevelDocument.is_skyscraper(_picked()):
		return {"picked": true}
	if _picked() == "" and not selected.is_empty() and str(selected.kind) == "building" \
			and LevelDocument.is_skyscraper(str(selected.item.get("asset", ""))):
		return {"building": selected.item}
	return {}


## The top bar's Banner on or off, and key B (T-265): whether the next skyscraper shows its banner. With
## no skyscraper picked and one selected, it sets that building's banner instead (and redraws it).
func set_banner(on: bool) -> void:
	var t := _banner_target()
	if t.has("building"):
		document.set_building_banner(t.building, on)
		_rebuild_map()
	else:
		pick_banner = on
	_update_pose_controls()
	_overlay.queue_redraw()


## B: the other way round for the banner. Returns the banner now (false with no skyscraper to apply it to).
func banner_pick() -> bool:
	var t := _banner_target()
	if t.is_empty():
		return false
	var now: bool = pick_banner if t.has("picked") else LevelDocument.banner_of(t.building)
	set_banner(not now)
	return not now


## A: the other way round for the arrows. Returns the arrows now.
func arrows_pick() -> String:
	set_arrows("up" if pick_arrows == "down" else "down")
	return pick_arrows


# ---- Pairs of obstacles (T-272, thread the needle) ----------------------------------------------

## Turns the pair tool on or off (the top bar's Pair obstacles, key P). On, it drops the pick and
## the selection; a left click then picks an obstacle (pair_click). Picking a piece, Esc or a
## right-click turns it off.
func set_pair_tool(on: bool) -> void:
	pair_picks = []
	if on:
		pair_mode = true  # before the pick goes, so _on_asset_picked("") leaves it on
		size_drag_start = Vector2i(-1, -1)
		end_road_stroke()
		if panel != null and panel.picked != "":
			panel.pick("")
		selected = {}
	pair_mode = on
	_show_message("")
	_update_pose_controls()
	if _overlay != null:
		_overlay.queue_redraw()


## P: the pair tool on or off; with a row of two or more picked (T-394), pairs the row instead
## (pair_picked_row) and the tool stays on. Returns whether it is on now.
func pair_pick() -> bool:
	if pair_mode and pair_picks.size() >= 2:
		pair_picked_row()
		return true
	set_pair_tool(not pair_mode)
	return pair_mode


## The top bar's Pair obstacles: as P (pair_pick).
func _on_pair_button() -> void:
	if pair_mode and pair_picks.size() >= 2:
		pair_picked_row()
		pair_button.set_pressed_no_signal(true)
		return
	set_pair_tool(pair_button.button_pressed)


## A click with the pair tool at `units`. A plain click: the first obstacle clicked is held, the next
## (another obstacle) makes the pair with it (LevelDocument.make_pair; pair_made on the top bar), or,
## after a row picked with Shift+click, is added as the row's last and the row is paired (T-394); a
## picked one clicked again is let go. With `add` (Shift+click, T-394) the obstacle joins the row
## picked so far, numbered on screen, or leaves it when it is already in. Anything that is not an
## obstacle is refused with pair_not_obstacle, and the pick stays. Returns "first", "made",
## "cancelled", "added", "removed" or "not_obstacle".
func pair_click(units: Vector2, add := false) -> String:
	var piece := document.piece_at(units)
	if not LevelDocument.is_obstacle(piece):
		_show_message(CreatorTexts.get_text("pair_not_obstacle"))
		return "not_obstacle"
	var at := _pick_index(piece)
	var result := "first"
	_show_message("")
	if add:
		if at >= 0:
			pair_picks.remove_at(at)
			result = "removed"
		else:
			pair_picks.append(piece)
			result = "added"
	elif pair_picks.is_empty():
		pair_picks = [piece]
	elif at >= 0:
		pair_picks.remove_at(at)
		result = "cancelled"
	else:
		pair_picks.append(piece)
		result = "made" if pair_picked_row() > 0 else "cancelled"
	_update_pose_controls()
	_overlay.queue_redraw()
	return result


## Pairs the picked row (T-394): each obstacle with the next (LevelDocument.make_chain), keeping
## their other pairs; pair_made on the top bar. The pick is dropped. Returns how many pairs the row
## has (new or already there), 0 with fewer than two picked.
func pair_picked_row() -> int:
	if pair_picks.size() < 2:
		return 0
	var made := document.make_chain(pair_picks)
	pair_picks = []
	_show_message(CreatorTexts.get_text("pair_made") if not made.is_empty() else "")
	_update_pose_controls()
	if _overlay != null:
		_overlay.queue_redraw()
	return made.size()


## Where `piece` is in the picked row, -1 when it is not.
func _pick_index(piece: Dictionary) -> int:
	for i in pair_picks.size():
		if _same_piece(pair_picks[i], piece):
			return i
	return -1


## Shift+click with nothing picked and the pair tool off (T-394): on an obstacle, turns the tool on
## and starts a row with it. Returns true when it did.
func shift_pick_obstacle(units: Vector2) -> bool:
	if pair_mode or document == null or not LevelDocument.is_obstacle(document.piece_at(units)):
		return false
	set_pair_tool(true)
	pair_click(units, true)
	return true


## The top bar's Unpair. With the pair tool's pick (T-394): only the pairs between consecutive
## picked obstacles (one picked: all its pairs; LevelDocument.unpair_picked), and the pick is
## dropped. Otherwise every pair of the selected obstacle. True when a pair went.
func unpair_selected() -> bool:
	var gone := false
	if pair_mode and not pair_picks.is_empty():
		gone = document.unpair_picked(pair_picks) > 0
		pair_picks = []
	elif not selected.is_empty():
		gone = document.unpair(selected)
	if not gone:
		return false
	_show_message("")
	_update_pose_controls()
	_overlay.queue_redraw()
	return true


## Whether Unpair has something to remove: a pair between consecutive picked obstacles, the pairs
## of the one picked, or (the tool off) of the selected obstacle.
func can_unpair() -> bool:
	if document == null:
		return false
	if pair_mode:
		if pair_picks.size() == 1:
			return not document.pairs_with(pair_picks[0]).is_empty()
		for i in range(pair_picks.size() - 1):
			if not document.pair_between(pair_picks[i], pair_picks[i + 1]).is_empty():
				return true
		return false
	return not selected.is_empty() and not document.pair_of(selected).is_empty()


# ---- Sizing (T-251) -----------------------------------------------------------------------------

## The cells a size drag from `from` to `to` covers, as {corner: the point naming its top-left
## cell (units), size: Vector2 units}; size ZERO (the default size) when the two are one cell. A
## ramp's drag only sets its width, along the rooftop's side (LevelDocument.ramp_width_axis): the
## other axis stays at `from`.
func drag_area(from: Vector2i, to: Vector2i) -> Dictionary:
	var lo := Vector2i(mini(from.x, to.x), mini(from.y, to.y))
	var hi := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y))
	var id := _picked()
	if LevelDocument.entry(id).get("kind", "") == "ramp":
		var axis := LevelDocument.ramp_width_axis(pick_view)
		var other := 1 - axis
		lo[other] = from[other]
		hi[other] = from[other]
	var size := Vector2(hi - lo + Vector2i.ONE) * LevelDocument.CELL
	if from == to or (LevelDocument.entry(id).get("kind", "") == "ramp" and lo == hi):
		size = Vector2.ZERO
	return {"corner": document.cell_corner(lo) + Vector2(CELL_MIDDLE, CELL_MIDDLE), "size": size}


## Where the picked piece goes now: during a size drag over the cells dragged across, otherwise at
## the cell under the mouse in its default size. {} for none.
func current_placement() -> Dictionary:
	if _picked() == "" or document == null or hover_cell.x < 0:
		return {}
	if size_drag_start.x >= 0:
		var a := drag_area(size_drag_start, hover_cell)
		return placement_at(a.corner, a.size)
	return placement_at(document.cell_corner(hover_cell) + Vector2(CELL_MIDDLE, CELL_MIDDLE))


## Starts a size drag at the cell under `units` (the left button pressed with a resizable piece).
func begin_size_drag(units: Vector2) -> void:
	size_drag_start = document.cell_at(units)
	hover_cell = size_drag_start
	_update_pose_controls()


## Ends the size drag with the mouse at `units`: places the picked piece over the dragged cells.
## Returns the placed piece, or {}.
func end_size_drag(units: Vector2) -> Dictionary:
	if size_drag_start.x < 0:
		return {}
	var to := document.cell_at(units)
	if to.x < 0:
		to = hover_cell if hover_cell.x >= 0 else size_drag_start
	var a := drag_area(size_drag_start, to)
	size_drag_start = Vector2i(-1, -1)
	var piece := place_asset(_picked(), a.corner, a.size)
	_update_pose_controls()
	return piece


## The road brush's mode for the picked family: "paint" (Road, Centre line, Cracked road), "zebra"
## (Zebra crossing) or "" (not a road brush; the family's "brush" in creator_assets.json).
func brush_mode() -> String:
	if panel == null or panel.picked_family == "":
		return ""
	return str(CreatorFamilies.family(panel.picked_family).get("brush", ""))


## The asphalt the brush paints: the picked look's (its member's "asphalt").
func brush_asphalt() -> String:
	return str(panel.member.get("asphalt", "a0")) if panel != null else "a0"


## Starts a brush stroke at `units`: paints (or with `erase`, erases) the block there.
func begin_road_stroke(units: Vector2, erase: bool = false) -> void:
	road_erasing = erase
	road_stroke_last = Vector2i(-1, -1)
	continue_road_stroke(units)


## Carries the stroke on to `units`: every block between the last one and this (next to each
## other, no gaps), painted with the picked road kind and asphalt or erased.
func continue_road_stroke(units: Vector2) -> void:
	if brush_mode() == "sidewalk":
		_continue_sidewalk_stroke(units)
		return
	var b := RoadBrush.block_at(document, units)
	if b.x < 0 or b == road_stroke_last:
		return
	var blocks: Array = [b] if road_stroke_last.x < 0 else RoadBrush.blocks_between(road_stroke_last, b)
	road_stroke_last = b
	var changed: Array = RoadBrush.erase(document, blocks) if road_erasing \
		else RoadBrush.paint(document, blocks, panel.picked_family, brush_asphalt())
	if not changed.is_empty():
		_refresh_after("road")


## The sidewalk brush (T-398, sidewalk_brush.gd): the same stroke, cell by cell (one ground tile),
## painting sidewalk or erasing it; the curbs follow by themselves.
func _continue_sidewalk_stroke(units: Vector2) -> void:
	var c := SidewalkBrush.cell_at(document, units)
	if c.x < 0 or c == road_stroke_last:
		return
	var cells: Array = [c] if road_stroke_last.x < 0 else RoadBrush.blocks_between(road_stroke_last, c)
	road_stroke_last = c
	var changed: Array = SidewalkBrush.erase(document, cells) if road_erasing else SidewalkBrush.paint(document, cells)
	if not changed.is_empty():
		_refresh_after("ground")


## Paints sidewalk along a drag through `points` (with Sidewalk picked; for tests and fixtures).
func paint_sidewalk(points: Array) -> void:
	_stroke(points, false)


## Erases sidewalk along a drag through `points` (a right-drag with Sidewalk picked).
func erase_sidewalk(points: Array) -> void:
	_stroke(points, true)


func end_road_stroke() -> void:
	road_stroke_last = Vector2i(-1, -1)
	road_erasing = false


## Paints a whole drag at once (from the first point to the last, through each in turn): what a
## drag with the left button does, for tests and fixtures.
func paint_road(points: Array) -> void:
	_stroke(points, false)


## Erases road along a drag through `points` (what a right-drag does).
func erase_road(points: Array) -> void:
	_stroke(points, true)


func _stroke(points: Array, erase: bool) -> void:
	if points.is_empty():
		return
	begin_road_stroke(points[0], erase)
	for p in points.slice(1):
		continue_road_stroke(p)
	end_road_stroke()


## Zebra crossing: a crossing across the road at `units` (RoadBrush.zebra_at). True when laid.
func place_zebra(units: Vector2) -> bool:
	if not RoadBrush.zebra_at(document, units):
		return false
	_refresh_after("road")
	return true


## The size line on the top bar: during a drag the size it would place (size_readout: {w} the
## width east-west, {d} the depth north-south, units); with a resizable piece picked, size_hint.
## With a road brush picked (T-263): road_brush_hint.
func _update_size_label() -> void:
	if size_label == null:
		return
	if pair_mode:
		size_label.text = CreatorTexts.get_text("pair_hint")  # T-272
		return
	if brush_mode() == "paint":
		size_label.text = CreatorTexts.get_text("road_brush_hint")
		return
	if not LevelDocument.is_resizable(_picked()):
		size_label.text = ""
		return
	var at := current_placement() if size_drag_start.x >= 0 else {}
	if at.is_empty():
		size_label.text = CreatorTexts.get_text("size_hint")
		return
	var s: Vector2 = at.rect.size
	size_label.text = CreatorTexts.get_text("size_readout").format({"w": int(s.x), "d": int(s.y)})


## The piece of any size the preview shows, in GroundHeight's format ({id, rect, height | side,
## bottom_height, top_height}) with "kind" and "base"; {} when the picked asset is not resizable.
func preview_block() -> Dictionary:
	var id := _picked()
	if not LevelDocument.is_resizable(id):
		return {}
	var at := current_placement()
	if at.is_empty():
		return {}
	var e := LevelDocument.entry(id)
	var rect: Rect2 = at.rect
	if str(e.kind) == "ramp":
		var t := LevelDocument.texture_of(id, pick_view, false)
		return {"kind": "ramp", "id": "preview", "rect": rect, "side": str(t.get("side", "east")), "arrows": pick_arrows,
			"bottom_height": float(e.heights[0]), "top_height": float(e.heights[1]), "base": float(e.heights[0]),
			"style": pick_style}
	var under := document.rooftop_under(rect, float(e.height))
	return {"kind": "platform", "id": "preview", "rect": rect, "height": float(e.height),
		"base": float(under.height) if not under.is_empty() else 0.0, "style": pick_style}


## Brings the engine-drawn preview in step with the pick, the mouse and the drag (each frame).
func _sync_preview() -> void:
	if _overlay == null:
		return
	var b := preview_block()
	var key := str(b)
	if key == _preview_key:
		return
	_preview_key = key
	if preview_drawing != null and is_instance_valid(preview_drawing):
		preview_drawing.queue_free()
		preview_drawing = null
	_update_size_label()
	if b.is_empty():
		return
	preview_drawing = ElevationDrawingScript.new()
	preview_drawing.name = "PreviewPiece"
	preview_drawing.setup(str(b.kind), b, ISO_TRANSFORM, "res://art/creator_pieces/", "none")
	preview_drawing.use_style(ElevationLayerScript.piece_style_named(pick_style), float(b.base))
	preview_drawing.modulate.a = PREVIEW_ALPHA
	preview_drawing.show_behind_parent = true
	_overlay.add_child(preview_drawing)


func _process(_delta: float) -> void:
	_sync_preview()


func _show_message(text: String) -> void:
	if message_label != null:
		message_label.text = text


## Selects the piece drawn on top at `units` (LevelDocument.piece_at).
func select_at(units: Vector2) -> Dictionary:
	if spawn_cell_has(units):
		return select_spawn()
	selected = document.piece_at(units)
	_clear_spawn_hint()
	_update_pose_controls()
	_overlay.queue_redraw()
	return selected


## Removes a piece from the data and the drawing. Returns true when something was removed.
func delete_piece(piece: Dictionary) -> bool:
	if str(piece.get("kind", "")) == "spawn":
		_show_message(CreatorTexts.get_text("spawn_no_delete"))  # T-280: a level always has one
		return false
	if not document.delete(piece):
		return false
	if not selected.is_empty() and _same_piece(selected, piece):
		selected = {}
		_update_pose_controls()
	_refresh_after(str(piece.kind))
	return true


## The Delete button and the Del key: removes the selected piece.
func delete_selected() -> void:
	if selected.is_empty():
		return
	if str(selected.get("kind", "")) == "spawn":
		delete_piece(selected)  # refused with its message; the start stays selected
		return
	var piece := selected
	selected = {}
	delete_piece(piece)
	_update_pose_controls()


static func _same_piece(a: Dictionary, b: Dictionary) -> bool:
	if a.has("cell") or b.has("cell"):
		return a.get("cell") == b.get("cell")
	return is_same(a.get("item"), b.get("item"))


func _on_asset_picked(id: String) -> void:
	if id != "" and pair_mode:
		pair_mode = false  # T-272: picking a piece ends the pair tool
		pair_picks = []
	if id != "" and panel != null and not panel.member.is_empty():
		_pose_from(panel.member)
	else:
		pick_view = LevelDocument.valid_view(id, "") if id != "" else ""
		pick_mirror = LevelDocument.valid_mirror(id, false) if id != "" else false
		pick_variant = ""
	_update_pose_controls()
	_overlay.queue_redraw()


func _pose_from(m: Dictionary) -> void:
	pick_view = str(m.view)
	pick_mirror = bool(m.mirror)
	pick_variant = str(m.get("variant", ""))


# ---- Looks, turns, mirrors and heights (T-262) --------------------------------------------------

## The keys that step the picked family's member (creator_families.gd step: the axis each steps).
## The one place the creator's piece keys are handled (_unhandled_key_input reads it).
const KEY_ACTIONS := {
	KEY_V: "look",
	KEY_R: "turn",
	KEY_M: "flip",
	KEY_H: "height",
	KEY_A: "arrows",
	KEY_B: "banner",
	KEY_P: "pair",
}


## Picks `m`, a member of the picked family (the looks strip, the keys): the asset, view, mirror
## and variant placed next.
func apply_member(m: Dictionary) -> void:
	if panel == null or m.is_empty():
		return
	panel.show_member(m)
	_pose_from(m)
	_update_pose_controls()
	_overlay.queue_redraw()


## Steps the picked family's member along `axis` (look, turn, flip, height; KEY_ACTIONS). Returns
## the member now ({} with nothing picked).
func step_pick(axis: String) -> Dictionary:
	if panel == null or panel.picked_family == "":
		return {}
	apply_member(CreatorFamilies.step(panel.picked_family, panel.member, axis))
	return panel.member


## V: the next look.
func look_pick() -> Dictionary:
	return step_pick("look")


## H: the next height (a platform's 3 and 6, a ramp's steps).
func height_pick() -> Dictionary:
	return step_pick("height")


## Rotate (R): the picked piece's next turn (its next view, or for a road tile the tile along the
## other axis). Returns the view now.
func rotate_pick() -> String:
	if _picked() == "" and str(selected.get("kind", "")) == "spawn":
		turn_spawn()  # T-280: R turns the selected start's heading
		return pick_view
	if panel != null and panel.picked_family != "":
		step_pick("turn")
		return pick_view
	pick_view = _next_of(LevelDocument.views_of(_picked()), pick_view, pick_view)
	_update_pose_controls()
	_overlay.queue_redraw()
	return pick_view


## Mirror (M): the picked piece's mirrored look, when its art has one. Returns the asset's mirror now.
func mirror_pick() -> bool:
	if panel != null and panel.picked_family != "":
		step_pick("flip")
		return pick_mirror
	pick_mirror = bool(_next_of(LevelDocument.mirrors_of(_picked()), pick_mirror, pick_mirror))
	_overlay.queue_redraw()
	return pick_mirror


## Style (T-255): the next piece style for new rooftops and ramps (office, car park, T-198's).
## Pieces already placed keep theirs. Returns the style now.
func style_pick() -> String:
	var names: Array = ElevationLayerScript.PIECE_STYLES.keys()
	pick_style = names[(names.find(pick_style) + 1) % names.size()]
	_update_style_button()
	_overlay.queue_redraw()
	return pick_style


func _update_style_button() -> void:
	if style_button != null:
		style_button.text = CreatorTexts.get_text("style_label").replace("{style}", CreatorTexts.get_text("style_" + pick_style))


## The picked asset's catalogue texture for the current view and mirror ({} with nothing picked).
func pick_texture() -> Dictionary:
	if _picked() == "":
		return {}
	return LevelDocument.texture_of(_picked(), pick_view, pick_mirror, pick_variant)


func _picked() -> String:
	return panel.picked if panel != null else ""


static func _next_of(list: Array, current, fallback):
	if list.is_empty():
		return fallback
	var i := list.find(current)
	return list[(i + 1) % list.size()]


## Rotate and Mirror are on only when the picked asset has more than one view or mirror; the
## height label names the picked rooftop's or ramp's height.
func _update_pose_controls() -> void:
	if rotate_button == null:
		return
	var id := _picked()
	if panel != null and panel.picked_family != "":
		rotate_button.disabled = not CreatorFamilies.can_step(panel.picked_family, panel.member, "turn")
		mirror_button.disabled = not CreatorFamilies.can_step(panel.picked_family, panel.member, "flip")
	else:
		rotate_button.disabled = LevelDocument.views_of(id).size() < 2
		mirror_button.disabled = LevelDocument.mirrors_of(id).size() < 2
	var key: String = LevelCreatorAssetPanel.label_key(id)
	height_label.text = CreatorTexts.get_text(key) if key != "" else ""
	var dir_key: String = LevelCreatorAssetPanel.RAMP_DIR_KEYS.get(pick_view, "") \
		if str(LevelDocument.entry(id).get("kind", "")) == "ramp" else ""
	if dir_key == "" and panel != null and bool(CreatorFamilies.family(panel.picked_family).get("facing_labels", false)):
		dir_key = LevelCreatorAssetPanel.FACING_KEYS.get(pick_view, "")  # T-398: a car's facing
	direction_label.text = CreatorTexts.get_text(dir_key) if dir_key != "" else ""
	# T-264: the S, M, L and Any size buttons show with a rooftop picked, Arrows up and down with a ramp.
	var kind := str(LevelDocument.entry(id).get("kind", ""))
	for b_id in size_buttons:
		size_buttons[b_id].visible = kind == "rooftop"
		size_buttons[b_id].button_pressed = b_id == pick_platform_size
	for b_id in arrows_buttons:
		arrows_buttons[b_id].visible = kind == "ramp"
		arrows_buttons[b_id].button_pressed = b_id == pick_arrows
	# T-265: Banner on and off show with a skyscraper picked (or selected, nothing picked).
	var bt := _banner_target()
	var banner_now: bool = pick_banner if bt.has("picked") else (LevelDocument.banner_of(bt.building) if bt.has("building") else false)
	for b_id in banner_buttons:
		banner_buttons[b_id].visible = not bt.is_empty()
		banner_buttons[b_id].button_pressed = (b_id == "on") == banner_now
	# T-272: Pair obstacles pressed while the tool is on; Unpair shows with a paired obstacle selected.
	if pair_button != null:
		pair_button.set_pressed_no_signal(pair_mode)
		unpair_button.visible = can_unpair()  # T-394: also for a pick in the pair tool
	_update_size_label()


# ---- The spawn point (T-280) --------------------------------------------------------------------

## True while the spawn point is being dragged (from a left press on it to the release).
var spawn_dragging := false
## Where the dragged spawn point would land (the cell's middle under the mouse), and why it can't.
var spawn_drop := Vector2.ZERO
var spawn_drop_problem := ""
## The spawn marker's colours (proposals; none of Greenbull's colours).
const SPAWN_COLOR := Color(0.35, 0.95, 0.45, 0.95)
const SPAWN_REFUSED_COLOR := Color(0.75, 0.75, 0.75, 0.8)
const SPAWN_OUTLINE := Color(0.05, 0.1, 0.05, 1.0)


## True when `units` is in the spawn point's cell.
func spawn_cell_has(units: Vector2) -> bool:
	return document != null and document.piece_rect(document.spawn_piece()).has_point(units)


## Selects the spawn point (a click on it): the top bar shows spawn_hint.
func select_spawn() -> Dictionary:
	selected = document.spawn_piece()
	_show_message(CreatorTexts.get_text("spawn_hint"))
	_update_pose_controls()
	_overlay.queue_redraw()
	return selected


func _clear_spawn_hint() -> void:
	if message_label != null and message_label.text == CreatorTexts.get_text("spawn_hint"):
		_show_message("")


## Moves the spawn point to the cell under `units`, at that surface's height. A cell the car can't
## stand in (a building, an obstacle, off the map) is refused with spawn_blocked and the point
## stays. Returns true when it moved.
func move_spawn(units: Vector2) -> bool:
	var why := document.move_spawn(units)
	if why != "":
		_show_message(CreatorTexts.get_text("spawn_blocked"))
		_overlay.queue_redraw()
		return false
	_show_message(CreatorTexts.get_text("spawn_hint") if str(selected.get("kind", "")) == "spawn" else "")
	_overlay.queue_redraw()
	return true


## R: turns the start's heading to the next of the eight. Returns the heading (degrees).
func turn_spawn() -> int:
	var h := document.turn_spawn()
	_overlay.queue_redraw()
	return h


func begin_spawn_drag() -> void:
	select_spawn()
	spawn_dragging = true
	spawn_drop = LevelSpawn.position_of(level_data)
	spawn_drop_problem = ""


func update_spawn_drag(units: Vector2) -> void:
	spawn_drop = LevelSpawn.snap(level_data, units)
	spawn_drop_problem = document.spawn_problem(spawn_drop)
	_overlay.queue_redraw()


## Drops the dragged spawn point at `units`. Returns true when it moved.
func end_spawn_drag(units: Vector2) -> bool:
	spawn_dragging = false
	var moved := move_spawn(units)
	_overlay.queue_redraw()
	return moved


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
		elif mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT] and brush_mode() != "":
			# The road brush (T-263): left paints along the drag, right erases; Zebra: a click.
			var units := screen_to_units(mb.position)
			if not mb.pressed:
				end_road_stroke()
			elif brush_mode() == "zebra" and mb.button_index == MOUSE_BUTTON_LEFT:
				place_zebra(units)
			else:
				begin_road_stroke(units, mb.button_index == MOUSE_BUTTON_RIGHT)
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var units := screen_to_units(mb.position)
			if panel.picked == "" and not pair_mode and spawn_cell_has(units):
				begin_spawn_drag()  # T-280: drag the start
			elif panel.picked != "" and LevelDocument.is_resizable(panel.picked):
				begin_size_drag(units)
			elif panel.picked != "":
				place_asset(panel.picked, units)
			elif pair_mode:
				pair_click(units, mb.shift_pressed)  # T-272; Shift+click: a row (T-394)
			elif mb.shift_pressed and shift_pick_obstacle(units):
				pass  # T-394: Shift+click on an obstacle starts a row with the pair tool
			else:
				select_at(units)
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and spawn_dragging:
			end_spawn_drag(screen_to_units(mb.position))
		elif mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and size_drag_start.x >= 0:
			end_size_drag(screen_to_units(mb.position))
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			panel.pick("")
			if pair_mode:
				set_pair_tool(false)
			select_at(screen_to_units(mb.position))
		map_view.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging:
			pan_by(mm.relative)
		hover_units = screen_to_units(mm.position)
		if road_stroke_last.x >= 0:
			continue_road_stroke(hover_units)
		if spawn_dragging:
			update_spawn_drag(hover_units)
		var c :=document.cell_at(hover_units)
		if c != hover_cell:
			hover_cell = c
			_overlay.queue_redraw()
			if size_drag_start.x >= 0:
				_update_size_label()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed:
		return
	if KEY_ACTIONS.has(k.keycode):
		# V, R, M, H (T-262): step the picked piece's look, turn, mirror or height.
		match str(KEY_ACTIONS[k.keycode]):
			"turn":
				rotate_pick()
			"flip":
				mirror_pick()
			"arrows":
				arrows_pick()
			"banner":
				banner_pick()
			"pair":
				pair_pick()
			var axis:
				step_pick(axis)
		get_viewport().set_input_as_handled()
		return
	match k.keycode:
		KEY_DELETE:
			if brush_mode() != "" and hover_cell.x >= 0:
				# The road brush (T-263): Del erases the road block under the mouse.
				erase_road([hover_units])
			else:
				delete_selected()
		KEY_T:
			style_pick()
		KEY_ESCAPE:
			size_drag_start = Vector2i(-1, -1)
			end_road_stroke()
			panel.pick("")
			if pair_mode:
				set_pair_tool(false)
			selected = {}
			_update_pose_controls()
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


## The preview's alpha (a proposal): the art of the picked view, see-through over the map.
const PREVIEW_ALPHA := 0.65
## Building art is drawn at this scale (32 art px per unit, 16 screen px per unit; building_towers.gd).
const BUILDING_ART_SCALE := 0.5
const ElevationDrawingScript := preload("res://scripts/level/elevation_platform_drawing.gd")


## The preview of the picked asset in its current view and mirror with its top-left corner at
## `corner` (units): {texture, rect} in map pixels, {} with nothing picked. A rooftop's or ramp's
## art goes exactly where it is drawn once placed (its record, moved from the sample map); other
## art is fitted over its footprint, its bottom on the footprint's front corner.
func preview_of(corner: Vector2) -> Dictionary:
	var id := _picked()
	var e := LevelDocument.entry(id)
	var t := pick_texture()
	if e.is_empty() or t.is_empty() or bool(e.get("resizable", false)):
		return {}  # a piece of any size: preview_block, drawn in the engine (T-251)
	if str(e.kind) == "prop":
		return _prop_preview(id, corner)
	if str(e.kind) in ["rooftop", "ramp"]:
		var art := str(t.variant)
		var record_path: String = ElevationDrawingScript.SAMPLE_ART_DIR + art + ".json"
		var info = JSON.parse_string(FileAccess.get_file_as_string(record_path)) if FileAccess.file_exists(record_path) else null
		var tex := load(str(t.texture)) as Texture2D
		if tex != null and info is Dictionary and info.has("top_left_art_px"):
			var s: float = ElevationDrawingScript.ART_SCALE
			var shift: Vector2 = ElevationLayerScript.art_offset(art, Rect2(corner, Vector2.ONE))
			var pos := Vector2(info.top_left_art_px[0], info.top_left_art_px[1]) * s + ISO_TRANSFORM * (shift * PX_PER_UNIT)
			return {"texture": tex, "rect": Rect2(pos, tex.get_size() * s)}
	var icon := LevelCreatorAssetPanel.icon_of({"textures": [t]})
	if LevelDocument.is_skyscraper(id) and not pick_banner:
		# T-265: the skyscraper without its banner (the sign-less copy of the body).
		var plain := BuildingTowers.nobanner_path(str(t.texture))
		var plain_tex := BuildingTowers.load_texture(plain) if plain != "" else null
		if plain_tex != null:
			icon = plain_tex
	if icon == null:
		return {}
	var foot := LevelDocument.footprint_of(_picked(), pick_view, pick_mirror)
	if t.has("anchor_art_px"):
		# Art with its own anchor (T-254): the anchor pixel stands on the footprint's front corner.
		var a: Array = t.anchor_art_px
		var at := ISO_TRANSFORM * ((corner + foot) * PX_PER_UNIT) - Vector2(float(a[0]), float(a[1])) * BUILDING_ART_SCALE
		return {"texture": icon, "rect": Rect2(at, icon.get_size() * BUILDING_ART_SCALE)}
	var pts: Array = []
	for p in [corner, corner + Vector2(foot.x, 0), corner + foot, corner + Vector2(0, foot.y)]:
		pts.append(ISO_TRANSFORM * (p * PX_PER_UNIT))
	var min_x: float = pts.map(func(p): return p.x).min()
	var max_x: float = pts.map(func(p): return p.x).max()
	var bottom: float = pts.map(func(p): return p.y).max()
	var size := icon.get_size() * ((max_x - min_x) / maxf(icon.get_size().x, 1.0))
	# T-393: a boulder stands at the height under its centre (a rooftop's, a ramp's), as placed.
	if str(e.kind) == "boulder":
		bottom -= document.height_at(corner + foot / 2.0) * PX_PER_UNIT
	return {"texture": icon, "rect": Rect2(Vector2((min_x + max_x - size.x) / 2.0, bottom - size.y), size)}


## A prop's preview (T-253): its sprite in the picked rotation, standing where it would, at the
## height under its centre (level_props.gd).
func _prop_preview(id: String, corner: Vector2) -> Dictionary:
	var s := LevelProps.sprite_of(id, pick_view)
	if s.is_empty():
		return {}
	var centre := corner + LevelDocument.piece_size(id, pick_view) / 2.0
	var scale: float = float(LevelProps.data().get("draw_scale", 0.5))
	var pos: Vector2 = ISO_TRANSFORM * (centre * PX_PER_UNIT) - (s.anchor_px as Vector2) * scale 		- Vector2(0.0, document.height_at(centre) * PX_PER_UNIT)
	return {"texture": s.texture, "rect": Rect2(pos, (s.texture as Texture2D).get_size() * scale)}


## Draws, over the map: the picked asset's preview (its art in the current view and mirror) and
## footprint at the cell under the mouse, and the selected piece's outline (both on the ground, in
## the isometric view).
class _Overlay extends Node2D:
	var editor

	func _draw() -> void:
		var doc: LevelDocument = editor.document
		if doc == null:
			return
		var w := 2.0 / maxf(editor.zoom, 0.01)
		var brush: String = editor.brush_mode()
		if brush != "" and editor.hover_cell.x >= 0:
			# The road brush (T-263): the block it paints or erases, or the crossing's row of tiles.
			var r: Rect2 = RoadBrush.zebra_rect(doc, editor.hover_units) if brush == "zebra" \
				else RoadBrush.block_rect(doc, RoadBrush.block_at(doc, editor.hover_units))
			var ok: bool = brush == "zebra" or RoadBrush.block_at(doc, editor.hover_units).x >= 0
			if brush == "sidewalk":  # T-398: one cell
				r = SidewalkBrush.cell_rect(doc, editor.hover_cell)
				ok = true
			if r.size != Vector2.ZERO and ok:
				var col := Color(1.0, 0.55, 0.45, 0.9) if editor.road_erasing else Color(0.55, 0.85, 1.0, 0.9)
				_outline(r, col, w)
		elif editor.panel != null and editor.panel.picked != "" and editor.hover_cell.x >= 0:
			# Where the piece would go, snapped (LevelSnapping): its art and footprint there (a
			# piece of any size: the engine-drawn preview, editor.preview_drawing, and footprint).
			var at: Dictionary = editor.current_placement()
			if not at.is_empty() and LevelDocument.is_resizable(editor.panel.picked):
				_outline(at.rect, Color(0.55, 0.85, 1.0, 0.9), w)
			elif not at.is_empty():
				var pv: Dictionary = editor.preview_of(at.corner)
				if not pv.is_empty():
					draw_texture_rect(pv.texture, pv.rect, false, Color(1, 1, 1, editor.PREVIEW_ALPHA))
				_outline(at.rect, Color(0.55, 0.85, 1.0, 0.9), w)
		if not editor.selected.is_empty() and str(editor.selected.get("kind", "")) != "spawn":
			_outline(doc.piece_rect(editor.selected), Color(1.0, 0.85, 0.3, 1.0), w * 1.5)
		_draw_pairs(doc, w)
		_draw_spawn(doc, w)

	## T-280: the spawn point, always: a car-shaped arrow on its cell (turned to the heading), the
	## label above, at the height of the surface it stands on. Dragged: a ghost at the drop cell.
	func _draw_spawn(doc: LevelDocument, w: float) -> void:
		var s := LevelSpawn.of(doc.data)
		var at := Vector2(s.x, s.y)
		var refused := false
		if editor.spawn_dragging:
			at = editor.spawn_drop
			refused = editor.spawn_drop_problem != ""
		var h := doc.height_at(at)
		var col: Color = editor.SPAWN_REFUSED_COLOR if refused else editor.SPAWN_COLOR
		var heading := deg_to_rad(float(s.heading))
		var fwd := Vector2(cos(heading), sin(heading))
		var side := Vector2(-fwd.y, fwd.x)
		var cell := Rect2(at - Vector2.ONE, Vector2(2, 2))
		var ring := PackedVector2Array()
		for q in [cell.position, Vector2(cell.end.x, cell.position.y), cell.end, Vector2(cell.position.x, cell.end.y)]:
			ring.append(_at(q, h))
		draw_colored_polygon(ring, Color(col, 0.35))
		ring.append(ring[0])
		draw_polyline(ring, editor.SPAWN_OUTLINE, w * 3.0)
		draw_polyline(ring, col, w * 1.5)
		if str(editor.selected.get("kind", "")) == "spawn":
			draw_polyline(ring, Color(1.0, 0.85, 0.3, 1.0), w * 3.0)  # the selection outline, at the point's height
		# The arrow: a shaft and a head ahead of the cell's middle.
		var tip := _at(at + fwd * 4.4, h)
		var head_a := _at(at + fwd * 2.2 + side * 1.7, h)
		var head_b := _at(at + fwd * 2.2 - side * 1.7, h)
		var tail := _at(at - fwd * 2.2, h)
		draw_line(_at(at + fwd * 2.2, h), tail, editor.SPAWN_OUTLINE, w * 7.0)
		draw_line(_at(at + fwd * 2.2, h), tail, col, w * 4.0)
		draw_colored_polygon(PackedVector2Array([tip, head_a, head_b]), col)
		draw_polyline(PackedVector2Array([tip, head_a, head_b, tip]), editor.SPAWN_OUTLINE, w * 2.0)
		var text := CreatorTexts.get_text("spawn_label")
		var font := ThemeDB.fallback_font
		var fs := int(clampf(16.0 / maxf(editor.zoom, 0.01), 16.0, 400.0))
		var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var label_at := _at(at, h) + Vector2(-size.x / 2.0, -2.2 * editor.PX_PER_UNIT - 4.0 * w)
		draw_string_outline(font, label_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(fs / 5, 2), editor.SPAWN_OUTLINE)
		draw_string(font, label_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	## T-272: each pair as a dashed line across the gap and a ring round each of its obstacles, at
	## the height they stand on; the pair tool's picked obstacles ringed thicker, numbered for a row
	## (T-394). An obstacle in several pairs (a chain) shows a line for each.
	func _draw_pairs(doc: LevelDocument, w: float) -> void:
		var col: Color = editor.PAIR_COLOR
		for p in doc.pairs():
			var line := ObstaclePairs.line_of(doc.data, p)
			if line.is_empty():
				continue
			var ha := doc.height_at(line.a)
			var hb := doc.height_at(line.b)
			draw_dashed_line(_at(line.gap_a, ha), _at(line.gap_b, hb), col, w * 1.5,
				editor.PAIR_DASH_UNITS * editor.PX_PER_UNIT)
			_ring(line.obstacle_a, ha, col, w)
			_ring(line.obstacle_b, hb, col, w)
		# The pick (T-394: a row): each ringed thicker and, for a row, numbered in order.
		var font := ThemeDB.fallback_font
		var fs := int(clampf(24.0 / maxf(editor.zoom, 0.01), 24.0, 600.0))  # as the spawn's label, larger
		var picks: Array = editor.pair_picks
		for i in picks.size():
			var o := ObstaclePairs.resolve(doc.data, LevelDocument.obstacle_ref(picks[i]))
			if o.is_empty():
				continue
			var c := ObstaclePairs.centre_of(o)
			var h := doc.height_at(c)
			_ring(o, h, col, w * 2.5)
			if picks.size() < 2:
				continue
			var text := str(i + 1)
			var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var at := _at(c, h) + Vector2(-size.x / 2.0, -2.2 * editor.PX_PER_UNIT)  # above the obstacle
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(fs / 5, 2), editor.SPAWN_OUTLINE)
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	func _at(units: Vector2, h: float) -> Vector2:
		return editor.ISO_TRANSFORM * (units * editor.PX_PER_UNIT) - Vector2(0.0, h * editor.PX_PER_UNIT)

	## A ring just outside an obstacle's collision (a circle's or a rectangle's), on the ground at `h`.
	func _ring(o: Dictionary, h: float, color: Color, width: float) -> void:
		var pts := PackedVector2Array()
		if str(o.shape) == "circle":
			var r := float(o.radius) + 0.4
			for i in 33:
				var t := TAU * i / 32.0
				pts.append(_at(o.centre + Vector2(cos(t), sin(t)) * r, h))
		else:
			var rr: Rect2 = (o.rect as Rect2).grow(0.4)
			for q in [rr.position, Vector2(rr.end.x, rr.position.y), rr.end, Vector2(rr.position.x, rr.end.y), rr.position]:
				pts.append(_at(q, h))
		draw_polyline(pts, color, width)

	func _outline(r: Rect2, color: Color, width: float) -> void:
		var pts := PackedVector2Array()
		for p in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]:
			pts.append(editor.ISO_TRANSFORM * (p * editor.PX_PER_UNIT))
		draw_polyline(pts, color, width)
