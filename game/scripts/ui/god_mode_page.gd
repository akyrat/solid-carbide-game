class_name GodModePage
extends PanelContainer
## The secret God mode page (task T-505; HUD and menus, Decisions, "A secret God mode"). Opened
## from the pause screen's settings once God mode is unlocked (N, T-504). It shows the title and
## its line, then the weapons and the driving power-ups, one row each: the icon, the name, the
## tier ("Tier 3 / 8", "Not owned") and the - and + buttons, which set the tier through T-504's
## API (run.god_mode.step). The rows come from god_mode.entries(), never from a list here, so a
## new power-up appears on its own. It only displays and collects input; the tiers are changed
## by GodMode. Texts come from data/pause_text.json (T-501); names from the recap and power-up
## texts. Mouse, arrows/WASD and Enter/Space work (T-492's KeyNav); Escape or Back closes it.

signal closed

const TEXT_TITLE_KEY := "god_mode_title"
const TEXT_SUBTITLE_KEY := "god_mode_subtitle"
const TEXT_WEAPONS_KEY := "god_mode_weapons_heading"
const TEXT_POWER_UPS_KEY := "god_mode_power_ups_heading"
const TEXT_TIER_KEY := "god_mode_tier_format"
const TEXT_NOT_OWNED_KEY := "god_mode_not_owned"
const TEXT_BACK_KEY := "god_mode_back"
## Where the page starts: higher than the pause strip (92), so a fifth power-up still fits 648.
const PAGE_TOP := 56.0
const ICON_SIZE := 24
const NAME_WIDTH := 200.0
const TIER_WIDTH := 110.0

var god: Node = null
var back_button: Button
## One per entry: {kind, id, name_label, tier_label, minus, plus}.
var rows: Array = []
var _box: VBoxContainer
var _power_up_data: PowerUpData = null


## `the_god` is the run's GodMode node (T-504). Builds the page once; hidden until open().
func setup(the_god: Node) -> void:
	god = the_god
	name = "GodModePage"
	visible = false
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = PAGE_TOP
	offset_bottom = PAGE_TOP
	var style := StyleBoxFlat.new()
	style.bg_color = HudStyle.PAUSE_STRIP_COLOR
	style.set_content_margin_all(10.0)
	add_theme_stylebox_override("panel", style)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 3)
	add_child(_box)
	_power_up_data = PowerUpData.new()
	_build()
	if god.has_signal("tier_set"):
		god.tier_set.connect(func(_k, _i, _t): refresh())


func _label(text: String, role := "pause_text") -> Label:
	var l := Label.new()
	l.text = text
	HudStyle.apply(l, role)
	return l


func _build() -> void:
	var title := _label(pause_text(TEXT_TITLE_KEY), "pause_title")
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	var sub := _label(pause_text(TEXT_SUBTITLE_KEY))
	sub.name = "Subtitle"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sub)
	var shown_kind := ""
	for e in god.entries():
		if e.kind != shown_kind:
			shown_kind = e.kind
			var key := TEXT_WEAPONS_KEY if shown_kind == GodMode.KIND_WEAPON else TEXT_POWER_UPS_KEY
			var h := _label(pause_text(key), "pause_title")
			h.name = "Heading_%s" % shown_kind
			_box.add_child(h)
		_add_row(e)
	back_button = _button("BackButton", pause_text(TEXT_BACK_KEY))
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	_box.add_child(back_button)
	_chain()
	refresh()


func _button(node_name: String, text: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	HudStyle.style_button(b, true)  # the shared button (T-446)
	return b


func _add_row(e: Dictionary) -> void:
	var kind: String = e.kind
	var id: String = e.id
	var row := HBoxContainer.new()
	row.name = "Row_%s" % id
	row.add_theme_constant_override("separation", 8)
	_box.add_child(row)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _icon(kind, id)
	row.add_child(icon)
	var name_label := _label(display_name(kind, id))
	name_label.name = "Name"
	name_label.custom_minimum_size.x = NAME_WIDTH
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var tier_label := _label("")
	tier_label.name = "Tier"
	tier_label.custom_minimum_size.x = TIER_WIDTH
	tier_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tier_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tier_label)
	var minus := _button("Minus_%s" % id, "-")
	minus.pressed.connect(func(): god.step(kind, id, -1))
	row.add_child(minus)
	var plus := _button("Plus_%s" % id, "+")
	plus.pressed.connect(func(): god.step(kind, id, 1))
	row.add_child(plus)
	rows.append({"kind": kind, "id": id, "name_label": name_label, "tier_label": tier_label,
			"minus": minus, "plus": plus})


func _icon(kind: String, id: String) -> Texture2D:
	if kind == GodMode.KIND_WEAPON:
		return HudStyle.weapon_icon(id)
	return PowerUpScreen.icon_texture(_power_up_data, id)


## A text from data/pause_text.json by its key; empty if missing.
static func pause_text(key: String) -> String:
	var data = GameData.unwrap(GameData.load_file("pause_text"))
	return str(data.get(key, "")) if data is Dictionary else ""


## A weapon's name (recap texts) or a power-up's name (power-up texts).
static func display_name(kind: String, id: String) -> String:
	if kind == GodMode.KIND_WEAPON:
		return RecapScreen.text("weapon." + id)
	return PowerUpScreen.name_of(id)


## "Tier 3 / 8", or "Not owned" at tier 0.
static func tier_text(tier: int, last: int) -> String:
	if tier <= 0:
		return pause_text(TEXT_NOT_OWNED_KEY)
	return pause_text(TEXT_TIER_KEY).replace("{tier}", str(tier)).replace("{max}", str(last))


## Re-reads every tier from GodMode and dims the buttons that would do nothing.
func refresh() -> void:
	for r in rows:
		var tier: int = god.current_tier(r.kind, r.id)
		var last: int = god.last_tier(r.kind, r.id)
		var low: int = god.min_tier(r.kind, r.id)
		r.tier_label.text = tier_text(tier, last)
		# Never disabled, so the keyboard focus is not lost at an end; just dimmed.
		r.minus.modulate.a = 0.4 if tier <= low else 1.0
		r.plus.modulate.a = 0.4 if tier >= last else 1.0


## Up and down walk the rows on the same side (- or +) then Back, wrapping; left and right swap
## between - and +.
func _chain() -> void:
	if back_button == null:
		return
	var n := rows.size()
	for side in ["minus", "plus"]:
		for i in n:
			var b: Button = rows[i][side]
			var up: Control = rows[i - 1][side] if i > 0 else back_button
			var down: Control = rows[i + 1][side] if i < n - 1 else back_button
			b.focus_neighbor_top = b.get_path_to(up)
			b.focus_neighbor_bottom = b.get_path_to(down)
			b.focus_neighbor_left = b.get_path_to(rows[i]["minus"] if side == "plus" else b)
			b.focus_neighbor_right = b.get_path_to(rows[i]["plus"] if side == "minus" else b)
			b.focus_next = b.get_path_to(down)
			b.focus_previous = b.get_path_to(up)
	if n > 0:
		back_button.focus_neighbor_top = back_button.get_path_to(rows[n - 1]["plus"])
		back_button.focus_neighbor_bottom = back_button.get_path_to(rows[0]["plus"])
		back_button.focus_neighbor_left = back_button.get_path_to(back_button)
		back_button.focus_neighbor_right = back_button.get_path_to(back_button)
		back_button.focus_next = back_button.focus_neighbor_bottom
		back_button.focus_previous = back_button.focus_neighbor_top


func is_open() -> bool:
	return visible


func open() -> void:
	refresh()
	visible = true
	back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and KeyNav.handle_wasd(event, self):
		return
