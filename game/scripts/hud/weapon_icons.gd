class_name WeaponIcons
extends Control
## The car's weapons as a column of small icons beside the health bar (T-276).
## One row per weapon the car has, in the order taken: the weapon's level-up
## card picture (LevelUpScreen.weapon_image, nearest filtering, no new art),
## and next to it "x2", "x3" ... (its tier, up to x8) once it is above tier 1,
## in the HUD's comic font (Bangers with a black outline) like the combo
## counter. It only shows what the weapon rack holds: it follows each weapon's
## `tier_changed`, so a weapon taken or upgraded at a gift pack shows at once,
## and a new run (tier back to 0) empties the column.

## The icon's side in screen pixels: the 16 px card picture at 3x.
const ICON_SIZE := 48
## Space between two rows, and between an icon and its count.
const ROW_GAP := 8
const COUNT_GAP := 6
const COUNT_FONT_SIZE := 32
const COUNT_COLOR := Color(1.0, 1.0, 1.0)
const COUNT_OUTLINE := Color(0.0, 0.0, 0.0)
const COUNT_OUTLINE_SIZE := 8
## The count's text, the combo counter's "x{n}" form.
const TEXT_COUNT := "x{tier}"

## The weapon ids shown, in the order taken.
var order: Array = []
## The weapon id to its row (an icon and a count label).
var rows: Dictionary = {}
var _rack: Node = null


func _init() -> void:
	name = "WeaponIcons"
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Follows the weapon rack (`run.weapons`): shows what it owns now, then every change.
func setup(rack: Node) -> void:
	_rack = rack
	for id in rack.weapons:
		var w: Node = rack.weapons[id]
		if not w.tier_changed.is_connected(_on_tier_changed):
			w.tier_changed.connect(_on_tier_changed)
		_set_tier(id, w.tier)


func _on_tier_changed(weapon_id: String, tier: int) -> void:
	_set_tier(weapon_id, tier)


func _set_tier(weapon_id: String, tier: int) -> void:
	if tier < 1:
		order.erase(weapon_id)
	elif not order.has(weapon_id):
		order.append(weapon_id)
	_refresh()


## Rebuilds the rows from `order` and the rack's tiers.
func _refresh() -> void:
	for id in rows.keys():
		if not order.has(id):
			rows[id].icon.queue_free()
			rows[id].count.queue_free()
			rows.erase(id)
	for i in order.size():
		var id: String = order[i]
		if not rows.has(id):
			rows[id] = _make_row(id)
		var row: Dictionary = rows[id]
		var tier: int = _rack.get_weapon(id).tier
		row.icon.position = Vector2(0.0, i * (ICON_SIZE + ROW_GAP))
		var count: Label = row.count
		count.visible = tier > 1
		count.text = count_text(tier)
		count.size = count.get_combined_minimum_size()
		count.position = Vector2(
			ICON_SIZE + COUNT_GAP,
			row.icon.position.y + (ICON_SIZE - count.size.y) / 2.0)
	custom_minimum_size = Vector2(ICON_SIZE + COUNT_GAP + 56.0, _column_height())
	size = custom_minimum_size


func _column_height() -> float:
	if order.is_empty():
		return 0.0
	return order.size() * ICON_SIZE + (order.size() - 1) * ROW_GAP


func _make_row(weapon_id: String) -> Dictionary:
	var icon := TextureRect.new()
	icon.name = "Icon_%s" % weapon_id
	icon.texture = LevelUpScreen.weapon_image(weapon_id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var count := Label.new()
	count.name = "Count_%s" % weapon_id
	count.add_theme_font_override("font", Hud.comic_font())
	count.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	count.add_theme_color_override("font_color", COUNT_COLOR)
	count.add_theme_color_override("font_outline_color", COUNT_OUTLINE)
	count.add_theme_constant_override("outline_size", COUNT_OUTLINE_SIZE)
	count.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count)
	return {"icon": icon, "count": count}


static func count_text(tier: int) -> String:
	return TEXT_COUNT.format({"tier": tier})
