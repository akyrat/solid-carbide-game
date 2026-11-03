class_name WeaponIcons
extends Control
## The car's weapons as a column of small icons beside the health bar (T-276).
## One row per weapon the car has, in the order taken: the weapon's HUD icon
## (`art/hud/weapon_icons.png`, 24 x 24 at 2x, nearest filtering, T-429; the
## level-up card picture for a weapon without one),
## and next to it "x2", "x3" ... (its tier, up to x8) once it is above tier 1,
## in the HUD's comic font (Bangers with a black outline) like the combo
## counter. It only shows what the weapon rack holds: it follows each weapon's
## `tier_changed`, so a weapon taken or upgraded at a gift pack shows at once,
## and a new run (tier back to 0) empties the column.

## The icon's side in screen pixels: the HUD's 24 x 24 weapon icon at 2x
## (T-429, the HUD style sheet's rule 1), the same 48 px slot as before.
const ICON_SIZE := HudStyle.WEAPON_ICON_FRAME * HudStyle.HUD_ART_SCALE
## Space between two rows, and between an icon and its count.
const ROW_GAP := 8
const COUNT_GAP := 6
## The count's look is HudStyle's "weapon_count" (T-428).
const COUNT_FONT_SIZE := HudStyle.WEAPON_COUNT_SIZE
const COUNT_COLOR := HudStyle.WHITE
const COUNT_OUTLINE := HudStyle.BLACK
const COUNT_OUTLINE_SIZE := HudStyle.WEAPON_COUNT_OUTLINE
## The count's text, the combo counter's "x{n}" form.
const TEXT_COUNT := "x{tier}"

## T-523: the piece holds two grids of 3 slots, the weapons' and, beside it, the driving
## power-ups' (HUD and menus, Decisions, "Weapon and power-up slots"). Pips: one per tier the
## item can reach (from the data), the tiers reached filled. The layout editor moves both
## together as this one piece.
const COL_GAP := 8
const COUNT_ROOM := 56

## The weapon ids shown, in the order taken.
var order: Array = []
## The weapon grid and the power-up grid (frames and pips).
var weapon_grid: SlotGrid
var power_grid: SlotGrid
## The power-up ids shown, in the order collected, and each one's icon.
var power_order: Array = []
var power_rows: Dictionary = {}
## T-528: each power-up icon's cooldown veil, and the sources that have a cooldown (id to object).
var power_cooldowns: Dictionary = {}
var cooldown_sources: Dictionary = {}
var _state: RunState = null
var _power_data: PowerUpData = null
## The weapon id to its row (an icon and a count label).
var rows: Dictionary = {}
var _rack: Node = null


func _init() -> void:
	name = "WeaponIcons"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_grid = SlotGrid.new()
	weapon_grid.name = "WeaponGrid"
	add_child(weapon_grid)
	power_grid = SlotGrid.new()
	power_grid.name = "PowerUpGrid"
	power_grid.position = Vector2(power_column_x(), 0.0)
	add_child(power_grid)
	custom_minimum_size = piece_size()
	size = custom_minimum_size


## The power-up column's left edge: after the weapon frames and their counts.
static func power_column_x() -> float:
	return SlotGrid.SLOT_SIZE.x + COUNT_GAP + COUNT_ROOM + COL_GAP


## The whole piece: always both grids, whatever they hold.
static func piece_size() -> Vector2:
	return Vector2(power_column_x() + SlotGrid.SLOT_SIZE.x, SlotGrid.grid_size().y)


## Follows the weapon rack (`run.weapons`): shows what it owns now, then every change.
func setup(rack: Node) -> void:
	_rack = rack
	for id in rack.weapons:
		var w: Node = rack.weapons[id]
		if not w.tier_changed.is_connected(_on_tier_changed):
			w.tier_changed.connect(_on_tier_changed)
		_set_tier(id, w.tier)


## Follows the run's driving power-ups (`power_ups_changed`), showing what it owns now.
func setup_power_ups(state: RunState) -> void:
	if _state != null and _state.power_ups_changed.is_connected(_refresh_power_ups):
		_state.power_ups_changed.disconnect(_refresh_power_ups)
	_state = state
	if _power_data == null:
		_power_data = PowerUpData.new()
	_state.power_ups_changed.connect(_refresh_power_ups)
	_refresh_power_ups()


## Rebuilds the power-up slots: owned ones in the order collected, 3 at most.
func _refresh_power_ups() -> void:
	var owned: Dictionary = _state.owned_power_ups()
	for id in power_order.duplicate():
		if not owned.has(id):
			power_order.erase(id)
	for id in owned:
		if not power_order.has(id):
			power_order.append(id)
	for id in power_rows.keys():
		if not power_order.has(id):
			power_rows[id].queue_free()
			power_rows.erase(id)
			power_cooldowns[id].queue_free()
			power_cooldowns.erase(id)
	for i in SlotGrid.SLOTS:
		if i >= power_order.size():
			power_grid.set_slot(i, 0, 0)
			continue
		var id: String = power_order[i]
		if not power_rows.has(id):
			power_rows[id] = _make_power_icon(id)
		var icon: TextureRect = power_rows[id]
		power_cooldowns[id].position = power_grid.position + SlotGrid.icon_pos(i)
		# The art is 32 x 32 shown at 1x, centred in the weapon icons' 48 px slot.
		icon.position = power_grid.position + SlotGrid.icon_pos(i) + (Vector2(ICON_SIZE, ICON_SIZE) - icon.size) / 2.0
		power_grid.set_slot(i, int(owned[id]), _power_data.max_tier(id))


## T-528: a power-up with a cooldown (an object with `cooldown_fraction_left()`, and
## optionally `signal ready_again`) shows it on its slot icon like a loading bar.
func bind_cooldown(id: String, source: Object) -> void:
	cooldown_sources[id] = source
	if power_cooldowns.has(id):
		power_cooldowns[id].bind_source(source)


func _make_power_icon(id: String) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "PowerIcon_%s" % id
	var path: String = _power_data.icon(id)
	icon.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = Vector2(icon.texture.get_size()) if icon.texture != null else Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var veil := SlotCooldown.new()
	veil.name = "Cooldown_%s" % id
	add_child(veil)  # after the icon, so it draws over it
	power_cooldowns[id] = veil
	veil.bind_source(cooldown_sources.get(id))
	return icon


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
	for i in SlotGrid.SLOTS:
		if i < order.size():
			var w: Node = _rack.get_weapon(order[i])
			weapon_grid.set_slot(i, w.tier, w.max_tier())
		else:
			weapon_grid.set_slot(i, 0, 0)
	for i in mini(order.size(), SlotGrid.SLOTS):
		var id: String = order[i]
		if not rows.has(id):
			rows[id] = _make_row(id)
		var row: Dictionary = rows[id]
		var tier: int = _rack.get_weapon(id).tier
		row.icon.position = SlotGrid.icon_pos(i)
		var count: Label = row.count
		count.visible = tier > 1
		count.text = count_text(tier)
		count.size = count.get_combined_minimum_size()
		count.position = Vector2(
			SlotGrid.SLOT_SIZE.x + COUNT_GAP,
			row.icon.position.y + (ICON_SIZE - count.size.y) / 2.0)
	custom_minimum_size = piece_size()
	size = custom_minimum_size


func _make_row(weapon_id: String) -> Dictionary:
	var icon := TextureRect.new()
	icon.name = "Icon_%s" % weapon_id
	icon.texture = icon_texture(weapon_id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	var count := Label.new()
	count.name = "Count_%s" % weapon_id
	HudStyle.apply(count, "weapon_count")
	count.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count)
	return {"icon": icon, "count": count}


## A weapon's icon: its frame of the HUD icon sheet (24 x 24, shown at 2x); a
## weapon the sheet has no frame for falls back to its level-up card picture.
static func icon_texture(weapon_id: String) -> Texture2D:
	var t := HudStyle.weapon_icon(weapon_id)
	return t if t != null else LevelUpScreen.weapon_image(weapon_id)


static func count_text(tier: int) -> String:
	return TEXT_COUNT.format({"tier": tier})
