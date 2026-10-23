class_name LevelCreatorAssetPanel
extends PanelContainer
## The level creator editor's side panel (task T-235; one button per kind of piece since T-262).
## The families of the catalogue (data/level/creator_assets.json "families", built by
## build_creator_assets.py; stepped by creator_families.gd) in six groups from the ground up, under
## the group names of data/level/creator_texts.json (group_*), one button per family with its
## name (piece_*) and its first look's art. Pressing one picks it (asset_picked, with the asset of
## its first member); pressing the picked one again drops the pick.
##
## The looks strip (T-262) sits under the picked family's group: the heading (looks_heading), a
## small picture per look at the picked height, clickable (member_picked), and the counter
## (look_counter). The editor's keys V, R, M and H step the member (editor.gd KEY_ACTIONS) and show
## it here with show_member.

signal asset_picked(asset_id: String)
## A look clicked in the looks strip: the family member to pick.
signal member_picked(member: Dictionary)

## Rooftops and ramps carry a label (their heights) from creator_texts.json, shown on the top bar
## for the picked member's asset (editor.gd height_label), as do the buildings and road pieces.
const LABEL_KEYS := {
	"rooftop-3": "rooftop_height_3",
	"rooftop-6": "rooftop_height_6",
	"ramp-0-3": "ramp_height_0_3",
	"ramp-3-6": "ramp_height_3_6",
	"ramp-0-6": "ramp_height_0_6",
	"building-small": "building_small",
	"building-long": "building_long",
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
## A ramp's view is the direction it climbs (T-251): the top bar's label for each.
const RAMP_DIR_KEYS := {
	"north": "ramp_dir_north",
	"east": "ramp_dir_east",
	"south": "ramp_dir_south",
	"west": "ramp_dir_west",
}
## A family button (icon over its name), two to a row; a look in the strip.
const BUTTON_SIZE := Vector2(136, 64)
const LOOK_SIZE := Vector2(40, 40)
const COLUMNS := 2
const PANEL_WIDTH := 300.0

## The picked member's asset id, "" for none.
var picked: String = ""
## The picked family's id, "" for none, and its member (creator_families.gd), {} for none.
var picked_family: String = ""
var member: Dictionary = {}
## Family id -> its button.
var buttons: Dictionary = {}
## The groups, in order: [{group, label, grid, ids (family ids)}].
var groups: Array = []
## The looks strip and its parts (under the picked family's group; hidden with nothing picked).
var looks_strip: VBoxContainer
var looks_heading: Label
var looks_row: HFlowContainer
var look_counter: Label
## The strip's look buttons, in order (each has the member it picks as meta "member").
var look_buttons: Array = []

var _group := ButtonGroup.new()
var _list: VBoxContainer
var _pending: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_group.allow_unpress = true
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	for g in CreatorFamilies.groups():
		var group := str(g)
		var header := Label.new()
		header.name = "Group_" + group
		header.text = CreatorTexts.get_text("group_" + group)
		_list.add_child(header)
		var grid := GridContainer.new()
		grid.name = "Grid_" + group
		grid.columns = COLUMNS
		_list.add_child(grid)
		var ids: Array = []
		for f in CreatorFamilies.in_group(group):
			grid.add_child(_make_button(f))
			ids.append(str(f.id))
		groups.append({"group": group, "label": header, "grid": grid, "ids": ids})
	_make_strip()


func _make_button(f: Dictionary) -> Button:
	var fid := str(f.id)
	var b := Button.new()
	b.name = "Family_" + fid.replace("-", "_")
	b.toggle_mode = true
	b.button_group = _group
	b.custom_minimum_size = BUTTON_SIZE
	b.expand_icon = true
	b.icon = member_icon(f.members[0])
	b.text = CreatorTexts.get_text(str(f.label))
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.tooltip_text = fid
	b.set_meta("family", fid)
	b.toggled.connect(func(on: bool): _on_toggled(fid, on))
	buttons[fid] = b
	return b


func _make_strip() -> void:
	looks_strip = VBoxContainer.new()
	looks_strip.name = "LooksStrip"
	looks_heading = Label.new()
	looks_heading.name = "Heading"
	looks_heading.text = CreatorTexts.get_text("looks_heading")
	looks_strip.add_child(looks_heading)
	looks_row = HFlowContainer.new()
	looks_row.name = "Looks"
	looks_strip.add_child(looks_row)
	look_counter = Label.new()
	look_counter.name = "Counter"
	looks_strip.add_child(look_counter)
	looks_strip.visible = false
	_list.add_child(looks_strip)


## The text key of an asset's label (creator_texts.json): the heights of rooftops and ramps, the
## buildings, the road pieces, and a prop's name (its entry's "label", T-253); "" for none.
static func label_key(id: String) -> String:
	if LABEL_KEYS.has(id):
		return LABEL_KEYS[id]
	return str(LevelDocument.entry(id).get("label", ""))


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


## A family member's picture: its asset's texture in its view, mirror and variant.
static func member_icon(m: Dictionary) -> Texture2D:
	var t := LevelDocument.texture_of(str(m.asset), str(m.view), bool(m.mirror), str(m.get("variant", "")))
	return icon_of({"textures": [t]}) if not t.is_empty() else null


func _on_toggled(fid: String, on: bool) -> void:
	if on:
		picked_family = fid
		var m: Dictionary = _pending if not _pending.is_empty() else CreatorFamilies.first_member(fid)
		_pending = {}
		show_member(m)
	elif picked_family == fid:
		picked_family = ""
		show_member({})
	else:
		return
	asset_picked.emit(picked)


## Shows `m` (a member of the picked family) as the pick: the asset placed, the looks strip.
func show_member(m: Dictionary) -> void:
	member = m
	picked = str(m.get("asset", ""))
	_update_strip()


func _update_strip() -> void:
	for b in look_buttons:
		looks_row.remove_child(b)
		b.queue_free()
	look_buttons = []
	if picked_family == "" or member.is_empty():
		looks_strip.visible = false
		return
	# Under the picked family's group (right after its grid of buttons).
	for g in groups:
		if picked_family in g.ids:
			_list.move_child(looks_strip, (g.grid as Node).get_index() + 1)
	var all := CreatorFamilies.looks(picked_family, member)
	var at := CreatorFamilies.look_index(picked_family, member)
	for i in all.size():
		var m: Dictionary = all[i]
		var b := Button.new()
		b.name = "Look_%d" % i
		b.toggle_mode = true
		b.button_pressed = i == at
		b.custom_minimum_size = LOOK_SIZE
		b.expand_icon = true
		b.icon = member_icon(m)
		b.tooltip_text = str(m.asset)
		b.set_meta("member", m)
		b.pressed.connect(func(): member_picked.emit(m))
		looks_row.add_child(b)
		look_buttons.append(b)
	look_counter.text = CreatorTexts.get_text("look_counter").format({"n": at + 1, "count": all.size()})
	looks_strip.visible = true


## Picks a family (its id) or a catalogue asset (the family holding it, at the member placing that
## asset in `view` and `mirror`) as if its button were pressed; "" drops the pick.
func pick(id: String, view: String = "", mirror: bool = false) -> void:
	if id == "":
		var b := _group.get_pressed_button()
		if b != null:
			b.button_pressed = false
		picked = ""
		picked_family = ""
		member = {}
		_update_strip()
		return
	var fid := id if buttons.has(id) else CreatorFamilies.family_of_asset(id)
	if not buttons.has(fid):
		return
	var m: Dictionary = CreatorFamilies.first_member(fid) if fid == id else CreatorFamilies.member_for(id, view, mirror)
	if picked_family == fid:
		show_member(m)
		asset_picked.emit(picked)
		return
	_pending = m
	buttons[fid].button_pressed = true


## The panel's buttons: group text -> family ids, in the panel's order.
func entries_by_category() -> Dictionary:
	var out := {}
	for g in groups:
		out[g.label.text] = g.ids.duplicate()
	return out
