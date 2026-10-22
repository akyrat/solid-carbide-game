class_name LevelCreatorAssetPanel
extends PanelContainer
## The level creator editor's side panel (task T-235): every asset of the catalogue
## (data/level/creator_assets.json), grouped by kind under the category names of
## data/level/creator_texts.json, one button per asset showing its art. Pressing one picks it
## (asset_picked); pressing the picked one again drops the pick.

signal asset_picked(asset_id: String)

## Kind -> the text key of its category, in the panel's order.
const CATEGORIES := [
	["ground", "category_ground"],
	["road", "category_roads"],
	["building", "category_buildings"],
	["boulder", "category_boulders"],
	["rooftop", "category_rooftops"],
	["ramp", "category_ramps"],
]
## Rooftops and ramps carry a label (their heights) from creator_texts.json.
const LABEL_KEYS := {
	"rooftop-3": "rooftop_height_3",
	"rooftop-6": "rooftop_height_6",
	"ramp-0-3": "ramp_height_0_3",
	"ramp-3-6": "ramp_height_3_6",
	# T-252: the road pieces, one button per rotation (the art tells them apart; the tooltip is the id).
	"road-piece_corner_ne": "road_corner",
	"road-piece_corner_es": "road_corner",
	"road-piece_corner_sw": "road_corner",
	"road-piece_corner_nw": "road_corner",
	"road-piece_t_nes": "road_t_junction",
	"road-piece_t_esw": "road_t_junction",
	"road-piece_t_swn": "road_t_junction",
	"road-piece_t_wne": "road_t_junction",
	"road-piece_cross": "road_crossroads",
	"road-piece_dead_n": "road_dead_end",
	"road-piece_dead_e": "road_dead_end",
	"road-piece_dead_s": "road_dead_end",
	"road-piece_dead_w": "road_dead_end",
}
const BUTTON_SIZE := Vector2(64, 64)
const PANEL_WIDTH := 300.0

## The picked asset's id, "" for none.
var picked: String = ""
## Asset id -> its button.
var buttons: Dictionary = {}
## The category labels, in order, and the asset ids under each: [{kind, label, ids}].
var groups: Array = []

var _group := ButtonGroup.new()


func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_group.allow_unpress = true
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for cat in CATEGORIES:
		var kind: String = cat[0]
		var header := Label.new()
		header.name = "Category_" + kind
		header.text = CreatorTexts.get_text(cat[1])
		list.add_child(header)
		var grid := GridContainer.new()
		grid.name = "Grid_" + kind
		grid.columns = 4
		list.add_child(grid)
		var ids: Array = []
		for e in LevelDocument.entries():
			if str(e.kind) != kind:
				continue
			var id := str(e.id)
			grid.add_child(_make_button(e))
			ids.append(id)
		groups.append({"kind": kind, "label": header, "ids": ids})


func _make_button(e: Dictionary) -> Button:
	var id := str(e.id)
	var b := Button.new()
	b.name = "Asset_" + id.replace("-", "_")
	b.toggle_mode = true
	b.button_group = _group
	b.custom_minimum_size = BUTTON_SIZE
	b.expand_icon = true
	b.icon = icon_of(e)
	b.tooltip_text = id
	b.set_meta("asset_id", id)
	if LABEL_KEYS.has(id) and id.begins_with("road-"):
		# A road piece (T-252): the art fills the button and its label (the text key) sits in a
		# small Label over its lower edge, so the 2:1 tile keeps the full button width.
		var label := Label.new()
		label.name = "Label"
		label.text = CreatorTexts.get_text(LABEL_KEYS[id])
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 4)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(label)
		b.set_meta("label", label)
	elif LABEL_KEYS.has(id):
		b.text = CreatorTexts.get_text(LABEL_KEYS[id])
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.custom_minimum_size = Vector2(BUTTON_SIZE.x * 2, BUTTON_SIZE.y)
	b.toggled.connect(func(on: bool): _on_toggled(id, on))
	buttons[id] = b
	return b


## The asset's first texture (its atlas region for the ground tiles), for its button.
static func icon_of(e: Dictionary) -> Texture2D:
	var t: Dictionary = e.textures[0]
	var tex := load(str(t.texture)) as Texture2D
	if tex == null or not t.has("region"):
		return tex
	var at := AtlasTexture.new()
	at.atlas = tex
	var r: Array = t.region
	at.region = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	return at


func _on_toggled(id: String, on: bool) -> void:
	if on:
		picked = id
	elif picked == id:
		picked = ""
	asset_picked.emit(picked)


## Picks an asset as if its button were pressed ("" drops the pick).
func pick(id: String) -> void:
	if id == "":
		var b := _group.get_pressed_button()
		if b != null:
			b.button_pressed = false
		picked = ""
		return
	if buttons.has(id):
		buttons[id].button_pressed = true


## The panel's entries: category text -> asset ids, in the panel's order.
func entries_by_category() -> Dictionary:
	var out := {}
	for g in groups:
		out[g.label.text] = g.ids.duplicate()
	return out
