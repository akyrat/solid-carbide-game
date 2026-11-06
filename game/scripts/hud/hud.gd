class_name Hud
extends CanvasLayer
## The run's HUD (tasks T-090, T-049 and T-113): the timer as a digital clock at the bottom left (T-335),
## the car's health bar upright at the top left (T-276: 72 x 320, the heart
## under it, the weapon icons beside it), the coins
## at the top right, the sub goal square on the right edge (T-337, SubGoal: it
## replaced the likes bar and its row) and the combo multiplier beside the car, not the live viewers counter, at the bottom
## right (T-336, in place of the combo counter). The HUD only shows values: the run
## state owns them (`time_left_changed`, `health_changed`, `xp_changed`,
## `coins_changed`). The texts are from T-048 and T-331. Since T-131 the combo
## counter is in the comic font (Bangers, hard pixel edges) and heats up in
## steps as the combo climbs (ComboHeat), with the sub goal square on fire at
## the top step (LikesFire, on the square's top edge since T-337).

## The look is HudStyle's (T-428): these names point at it.
const LABEL_FONT_SIZE := HudStyle.LABEL_FONT_SIZE
const LABEL_COLOR := HudStyle.LABEL_COLOR
const OUTLINE_COLOR := HudStyle.OUTLINE_COLOR
const MARGIN := 16
const HEALTH_COLOR := HudStyle.HEALTH_COLOR
## T-338: the hearts row and the weapon icons column at 1152 x 648 (the board's layout page).
const HEART_ROW_POS := Vector2(36, 24)
const WEAPON_ICONS_POS := Vector2(12, 88)
## Coins counter place at 1152 x 648 (T-341).
const COINS_POS := Vector2(16, 496)
const COINS_SIZE := Vector2(108, 36)
const COINS_COLOR := HudStyle.COINS_COLOR
## The likes heart's red (Visual style, Decisions, "Red after the rebrand": the heart
## stays red, as a social-media heart): used only by the heart (its art, T-086, is drawn in this red).
const HEART_COLOR := HudStyle.HEART_COLOR
## The heart's art (T-086, drawn by tools/build_heart_icon.py): 11 x 10 art
## pixels shown at 2x.
const HEART_PATH := "res://art/hud/likes_heart.png"
const HEART_SCALE := 2

# Text from T-048 (hud.health, hud.coins).
# Livestream HUD texts (T-331): {subs} and {goal} are the sub goal's numbers.
const TEXT_SUB_GOAL := "{subs} / {goal} SUBS"
const TEXT_COINS := "Coins"
## The comic font of the trick popups (T-084), used since T-131 by the combo
## counter and the sub goal label. It has capitals only.
const COMIC_FONT_PATH := HudStyle.COMIC_FONT_PATH
## The airtime counter's top left corner from the screen's centre (T-243).
const AIRTIME_OFFSET := Vector2(70, -10)
## The drift counter's top left corner from the screen's centre (T-247): under
## the airtime counter, at the same x.
const DRIFT_OFFSET := Vector2(70, 30)

## T-431: the HUD scales with the window. Every piece is laid out at the board's layout page
## size (1152 x 648) inside `root`, a Control as big as the window divided by the HUD's
## scale and scaled by it, so each piece keeps its corner or edge and a size in proportion to
## the window. The scale is the smaller of the window's width and height over the layout
## page's, times the HUD size slider's share (hud_size / 100). Textures under the root are
## drawn with nearest filtering, so the pixel art stays hard-edged at any scale. The world
## camera is never touched (HUD and menus, Content, "The HUD scales with the window").
const LAYOUT_SIZE := UiScale.BASE  # 1152 x 648, shared with every screen (T-494)

## The scaled area every HUD piece is in (T-431).
var root: Control
## The HUD size slider's value in percent (GameSettings.DEFAULT_HUD_SIZE until set).
var hud_size := 100.0
var timer_label: Label
## The digital clock panel holding timer_label (T-335), bottom left.
var timer_clock: TimerClock
## The sub goal square (T-337): fills as subs come in, the gift lights up at the goal.
var sub_goal: SubGoal
## Springs the square's fill to its new level (T-273); the square shows its `shown`.
var likes_spring: LikesSpring
var _likes_level := 0
## The label's numbers for after a level-up's restart: [subs, goal].
var _follow_numbers := [0, 0]
var coins_label: Label
var coins_value_label: Label
## The combo multiplier beside the car (T-514), in place of the live viewers counter (T-336).
var multiplier_tag: MultiplierTag
## The reaction icons (T-351): the Hud's first child, so every HUD piece is drawn over them.
var reactions: Reactions
## The top-left area: the hearts row and the weapon icons (T-113, T-276, T-338).
var left_column: Control
## The car's hearts in a row (T-338), in place of the health bar.
var heart_row: HeartRow
## False until the first show of a run: the first show does not animate.
var _health_shown := false
## The car's weapons as a column of icons under the hearts (T-276, T-338).
var weapon_icons: WeaponIcons
## The current mission as a notebook page, left side (T-458).
var mission_page: MissionPage
## A full-screen area (empty since T-337 and T-336 took the likes bar and the combo counter away).
var bottom_area: Control
## The combo's heat steps (T-131): lights likes_fire (the multiplier beside the car has its own look, T-514).
var combo_heat: ComboHeat
## The flames along the sub goal square's top edge at the top heat step (T-131, T-337).
var likes_fire: LikesFire
## The live airtime counter (T-243), shown only while the car is airborne.
var airtime_counter: AirtimeCounter
## The live drift counter (T-247), shown only while the car is drifting.
var drift_counter: DriftCounter
## The dots flying to the gift when a trick pays subs (T-534): data/hud.json, subs_flight.
var subs_flight_cfg: Dictionary = {}
var _flight_frame := -1
var _flights_this_frame := 0
var _flights_alive := 0
var _car: Node
var _state: RunState
## The combo's numbers (combo.json): its start value is "no combo" (T-116).
var _combo_data: ComboData
## The trick popups whose amounts fly into the multiplier (bind_popups, T-336, T-514).
var _popups: Node
## The player's HUD layout (T-453): HudLayout entries for the pieces the player moved; a piece
## not in it keeps its default place. set_layout() sets it, the pause screen's editor moves it.
var layout: Dictionary = {}
## Each movable piece's default offset_left and offset_top (its own anchoring), for putting it back.
var _default_offsets: Dictionary = {}


func _ready() -> void:
	layer = 10
	_combo_data = ComboData.new()
	var hud_file := GameData.load_file("hud")
	subs_flight_cfg = hud_file.data.get("subs_flight", {}) if hud_file.ok else {}
	_build_root()
	_build_reactions()
	_build_timer()
	_build_left()
	_build_mission_page()
	_build_bottom()
	_build_coins()
	_build_multiplier()
	_build_airtime()
	_build_drift()
	_remember_defaults()
	_layout_root()
	get_viewport().size_changed.connect(_layout_root)


## The scaled area (T-431): nearest filtering, passed on to every piece inside it.
func _build_root() -> void:
	root = Control.new()
	root.name = "Scaled"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)


## The HUD's scale for a window of `view` pixels at a HUD size of `size_percent` (T-431).
static func scale_for(view: Vector2, size_percent: float) -> float:
	var fit := UiScale.fit(view, LAYOUT_SIZE)  # the rule every screen shares (T-494)
	return fit * clampf(size_percent, GameSettings.MIN_HUD_SIZE, GameSettings.MAX_HUD_SIZE) / 100.0


## The HUD's scale now: screen pixels per layout page pixel.
func hud_scale() -> float:
	return root.scale.x


## Sets the HUD size (the pause screen's slider, in percent) and scales the HUD at once,
## paused or not. It does not save: the slider saves on release (T-427's rule).
func set_hud_size(size_percent: float) -> void:
	hud_size = clampf(size_percent, GameSettings.MIN_HUD_SIZE, GameSettings.MAX_HUD_SIZE)
	if root != null and is_inside_tree():
		_layout_root()


func _layout_root() -> void:
	var view := get_viewport().get_visible_rect().size
	var s := scale_for(view, hud_size)
	root.position = Vector2.ZERO
	root.scale = Vector2(s, s)
	root.size = view / s
	_apply_layout()
	_layout_airtime()
	_layout_drift()
	_place_multiplier()


## The movable piece with HudLayout id `id` (T-453), or null.
func piece(id: String) -> Control:
	match id:
		"hearts": return heart_row
		"weapon_icons": return weapon_icons
		"coins": return coins_label.get_parent() as Control if coins_label != null else null
		"clock": return timer_clock
		"sub_goal": return sub_goal
	return null


func _remember_defaults() -> void:
	for id in HudLayout.PIECES:
		var c := piece(id)
		_default_offsets[id] = Vector2(c.offset_left, c.offset_top)
		c.resized.connect(_on_piece_resized.bind(id))
	sub_goal.label_row.resized.connect(_on_piece_resized.bind("sub_goal"))


## A moved piece that grows (more hearts or weapons, a longer label) stays fully on screen; the
## default pieces grow by their own anchoring.
func _on_piece_resized(id: String) -> void:
	if layout.has(id):
		_apply_piece(id)


## What a piece shows, relative to its own top left: its rect, and for the sub goal the label
## row under the square too (it can be a little wider than the square).
func _extent(id: String) -> Rect2:
	var c := piece(id)
	var r := Rect2(Vector2.ZERO, c.size)
	if id == "sub_goal":
		r = r.merge(Rect2(sub_goal.label_row.position, sub_goal.label_row.size))
	return r


## Where the piece's parent sits in the scaled area (the hearts and weapons are in left_column).
func _parent_offset(c: Control) -> Vector2:
	var p := c.get_parent()
	return Vector2.ZERO if p == root or not (p is Control) else (p as Control).position


## The piece's shown rect (its extent) in the scaled area's layout pixels.
func piece_rect(id: String) -> Rect2:
	var c := piece(id)
	var ext := _extent(id)
	return Rect2(_parent_offset(c) + c.position + ext.position, ext.size)


## Uses `new_layout` (HudLayout entries; invalid ones dropped) and places every piece at once.
func set_layout(new_layout: Dictionary) -> void:
	layout = HudLayout.clean(new_layout)
	if root != null and is_inside_tree():
		_apply_layout()


## Moves a piece so its shown rect's top left is at `layout_pos` (layout pixels, snapped and kept
## on screen: HudLayout.snap) and keeps it in the layout. Returns where it went.
func move_piece(id: String, layout_pos: Vector2) -> Vector2:
	var ext := _extent(id)
	var at := HudLayout.snap(layout_pos, ext.size, root.size)
	layout[id] = HudLayout.entry_for(at, ext.size, root.size)
	_apply_layout()
	return piece_rect(id).position


## Every piece back at its default place (the editor's Reset).
func reset_layout() -> void:
	set_layout({})


## Places every movable piece: the moved ones by the layout, the others at their default places.
## Every piece at its place (the sub goal no longer needs to clear a counter, T-514).
func _apply_layout() -> void:
	if _default_offsets.is_empty():
		return
	for id in HudLayout.PIECES:
		_apply_piece(id)


func _apply_piece(id: String) -> void:
	if _default_offsets.is_empty():
		return
	var c := piece(id)
	var size := c.size
	if layout.has(id):
		var ext := _extent(id)
		var at := HudLayout.position_for(layout[id], ext.size, root.size)
		var target := at - ext.position - _parent_offset(c)
		if not c.position.is_equal_approx(target):
			c.position = target
	else:
		var d: Vector2 = _default_offsets[id]
		if not (is_equal_approx(c.offset_left, d.x) and is_equal_approx(c.offset_top, d.y)):
			c.offset_left = d.x
			c.offset_top = d.y
			c.offset_right = d.x + size.x
			c.offset_bottom = d.y + size.y


## A point in screen (canvas) pixels as a point in the scaled area's own pixels.
func to_layout(screen_point: Vector2) -> Vector2:
	return root.get_global_transform().affine_inverse() * screen_point


## The reaction icons (T-351): under every other HUD piece, fed the multiplier's step.
func _build_reactions() -> void:
	reactions = Reactions.new()
	reactions.step_source = func() -> int:
		return multiplier_tag.step if multiplier_tag != null else 0
	root.add_child(reactions)


## The airtime counter (T-243): hidden until the car is airborne. It sits right
## of the screen's centre, a little below it: at the bottom right of where the
## combo popups show (they pop out above the car, which the camera keeps at the
## centre). A proposal for the playtest.
func _build_airtime() -> void:
	airtime_counter = AirtimeCounter.new()
	airtime_counter.name = "AirtimeCounter"
	root.add_child(airtime_counter)
	airtime_counter.resized.connect(_layout_airtime)


## Placed in the scaled area's pixels (T-431): _layout_root calls it on every resize.
func _layout_airtime() -> void:
	if airtime_counter == null:
		return
	airtime_counter.position = (root.size / 2.0 + AIRTIME_OFFSET).round()


## The drift counter (T-247): hidden until the car drifts; under the airtime
## counter, so both can show at once.
func _build_drift() -> void:
	drift_counter = DriftCounter.new()
	drift_counter.name = "DriftCounter"
	root.add_child(drift_counter)
	drift_counter.resized.connect(_layout_drift)


func _layout_drift() -> void:
	if drift_counter == null:
		return
	drift_counter.position = (root.size / 2.0 + DRIFT_OFFSET).round()


## Follows the car's airborne state from now on (T-243): counts its airtime
## while it is in the air. Call again when the car is rebuilt.
func bind_car(car: Node) -> void:
	if _car != null and is_instance_valid(_car) and _car.stepped.is_connected(_on_car_stepped):
		_car.stepped.disconnect(_on_car_stepped)
	_car = car
	airtime_counter.stop()
	drift_counter.stop()
	car.stepped.connect(_on_car_stepped)
	# T-528: the Polarized Steering Wheel's cooldown shows on its slot icon.
	if "polarized" in car:
		weapon_icons.bind_cooldown("polarized_steering_wheel", car.polarized)


func _on_car_stepped() -> void:
	airtime_counter.step(_car.airborne, _car.model.dt)
	drift_counter.step(_car.model.is_drifting, _car.model.dt)


func _build_timer() -> void:
	timer_clock = TimerClock.new()
	root.add_child(timer_clock)
	timer_label = timer_clock.label


func _build_left() -> void:
	left_column = Control.new()
	left_column.name = "Left"
	left_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_column)
	heart_row = HeartRow.new()
	left_column.add_child(heart_row)
	weapon_icons = WeaponIcons.new()
	left_column.add_child(weapon_icons)
	_layout_left()


## The mission notebook page on the left (T-458), between the weapon icons and the coins.
## Not one of the movable pieces: T-453's movable HUD is not on this branch.
func _build_mission_page() -> void:
	mission_page = MissionPage.new()
	root.add_child(mission_page)


## The hearts row and the weapon icons' column at the layout page's places.
func _layout_left() -> void:
	heart_row.position = HEART_ROW_POS
	weapon_icons.position = WEAPON_ICONS_POS


## Shows the weapon rack's weapons as icons (T-276); the run scene calls it once the rack is bound.
func bind_weapons(rack: Node) -> void:
	weapon_icons.setup(rack)


func _build_bottom() -> void:
	bottom_area = Control.new()
	bottom_area.name = "Bottom"
	bottom_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bottom_area)
	sub_goal = SubGoal.new()
	root.add_child(sub_goal)
	# On the square's top edge, over the frame and the gift (T-131, T-337).
	likes_fire = LikesFire.new()
	sub_goal.add_child(likes_fire)
	likes_fire.place(sub_goal.square_rect())
	likes_fire.fill_ratio = 1.0
	likes_spring = LikesSpring.new()
	add_child(likes_spring)
	likes_spring.changed.connect(func(_s: float) -> void: _show_likes())
	likes_spring.restarted.connect(_on_spring_restarted)
	combo_heat = ComboHeat.new()
	add_child(combo_heat)
	combo_heat.setup(null, likes_fire)


## The multiplier beside the car (T-514): placed each frame next to the car's screen place
## (the camera keeps the car at the centre, as for the airtime and drift counters).
func _build_multiplier() -> void:
	multiplier_tag = MultiplierTag.new()
	root.add_child(multiplier_tag)
	_place_multiplier()


func _place_multiplier() -> void:
	if multiplier_tag != null:
		multiplier_tag.follow(root.size / 2.0)


func _build_coins() -> void:
	var box := HBoxContainer.new()
	box.name = "Coins"
	box.add_theme_constant_override("separation", 10)
	# T-341: bottom left, just above the clock (board's layout at 1152 x 648:
	# x16 y496, 108 x 36), anchored to the corner so it keeps its margins.
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_left = COINS_POS.x
	box.offset_right = COINS_POS.x + COINS_SIZE.x
	box.offset_top = COINS_POS.y - 648.0
	box.offset_bottom = COINS_POS.y + COINS_SIZE.y - 648.0
	root.add_child(box)
	coins_label = _make_label("CoinsLabel", TEXT_COINS)
	box.add_child(coins_label)
	coins_value_label = _make_label("CoinsValue", "0")
	box.add_child(coins_value_label)


## The comic font (Bangers) with smoothing off: hard pixel edges (T-131). HudStyle's (T-428).
static func comic_font() -> FontFile:
	return HudStyle.comic_font()


func _make_label(label_name: String, text: String) -> Label:
	var l := Label.new()
	l.name = label_name
	l.text = text
	HudStyle.apply(l, "coins")
	return l



## Shows the given run state's values, and follows them from now on.
func bind(state: RunState) -> void:
	if _state != null:
		_state.time_left_changed.disconnect(_on_time_left_changed)
		_state.health_changed.disconnect(_on_health_changed)
		_state.xp_changed.disconnect(_on_xp_changed)
		_state.coins_changed.disconnect(_on_coins_changed)
		_state.combo_changed.disconnect(_on_combo_changed)
		_state.combo_broken.disconnect(_on_combo_broken)
		_state.level_up.disconnect(_on_level_up)
		_state.trick_subs_paid.disconnect(_on_trick_subs_paid)
	_state = state
	weapon_icons.setup_power_ups(state)
	_state.time_left_changed.connect(_on_time_left_changed)
	_state.health_changed.connect(_on_health_changed)
	_state.xp_changed.connect(_on_xp_changed)
	_state.coins_changed.connect(_on_coins_changed)
	_state.combo_changed.connect(_on_combo_changed)
	_state.combo_broken.connect(_on_combo_broken)
	_state.level_up.connect(_on_level_up)
	_state.trick_subs_paid.connect(_on_trick_subs_paid)
	mission_page.bind(_state.missions)
	sub_goal.stop()
	reactions.clear()
	_likes_level = 0
	likes_spring.snap(0.0)
	timer_label.text = _state.time_left_text()
	timer_clock.set_time_left(_state.time_left)
	_health_shown = false
	_on_health_changed(_state.health, _state.max_health)
	_on_xp_changed(_state.xp, _state.xp_needed(), _state.level)
	_on_coins_changed(_state.coins)
	multiplier_tag.reset(_state.combo)
	_on_combo_changed(_state.combo)


func _on_time_left_changed(_seconds_left: float) -> void:
	timer_label.text = _state.time_left_text()
	timer_clock.set_time_left(_state.time_left)


func _on_health_changed(health: float, max_health: float) -> void:
	heart_row.set_hearts(int(round(health)), int(round(max_health)), _health_shown)
	_health_shown = true


func _on_xp_changed(xp: float, xp_needed: float, level: int) -> void:
	# At the top level xp_needed is 0: the square stays full.
	var ratio := clampf(xp / xp_needed, 0.0, 1.0) if xp_needed > 0.0 else 1.0
	var numbers := sub_numbers(xp, xp_needed)
	if level < _likes_level:
		# A new run (the level went back): drop any level-up still showing.
		sub_goal.stop()
		_likes_level = 0
	if likes_spring.has_follow and _likes_level > 0:
		# Still full for the last level-up: only the leftover and the next
		# goal's numbers change, shown when it starts again.
		_follow_numbers = numbers
		likes_spring.set_follow(ratio)
		_likes_level = level
		return
	if _likes_level > 0 and level > _likes_level:
		# The square fills completely (the old goal reached), stays full while
		# it celebrates, then starts again.
		_follow_numbers = numbers
		sub_goal.set_numbers(sub_goal.goal, sub_goal.goal)
		likes_spring.fill_then(ratio, maxf(SubGoal.celebrate_length() - LikesSpring.DURATION, 0.0))
	elif _likes_level > 0 and ratio >= likes_spring.target:
		sub_goal.set_numbers(numbers[0], numbers[1])
		likes_spring.spring_to(ratio)
	else:
		# A new run, or the subs draining: no spring.
		sub_goal.set_numbers(numbers[0], numbers[1])
		likes_spring.snap(ratio)
	_likes_level = level
	_show_likes()


## The label's numbers, [subs, goal] in whole subs; at the top level (no next
## goal, xp_needed 0) the goal is the subs, so the label reads full.
static func sub_numbers(xp: float, xp_needed: float) -> Array:
	var subs := int(floorf(maxf(xp, 0.0)))
	if xp_needed <= 0.0:
		return [subs, subs]
	var goal := int(ceilf(xp_needed))
	return [mini(subs, goal), goal]


## Draws the spring's fill in the square, never past full; the gift is lit
## while the square is (or is springing to) full.
func _show_likes() -> void:
	sub_goal.fill = likes_spring.shown
	sub_goal.lit = likes_spring.target >= 1.0 or likes_spring.has_follow


func _on_spring_restarted() -> void:
	sub_goal.set_numbers(_follow_numbers[0], _follow_numbers[1])


## Ends the square's spring (and its hold at full) at once (tests and tools).
func settle_likes() -> void:
	likes_spring.finish()
	_show_likes()


## The player levelled up (T-139, T-337): the sub goal square celebrates now,
## at the moment it fills, whatever the run does next.
func _on_level_up(_new_level: int) -> void:
	sub_goal.celebrate()
	reactions.burst(to_layout(sub_goal.get_global_rect().get_center()))


func _on_coins_changed(coins: int) -> void:
	coins_value_label.text = str(coins)


func _on_combo_changed(multiplier: float) -> void:
	multiplier_tag.set_multiplier(multiplier)
	combo_heat.set_multiplier(multiplier)


## A crash cut the combo: the multiplier flashes red and drops what was lost (T-514).
func _on_combo_broken() -> void:
	multiplier_tag.crash(multiplier_tag.last_loss())
	# T-356: the stream reacts badly, rising from the multiplier's height.
	reactions.bad_burst(to_layout(multiplier_tag.get_global_rect().get_center()).y)


## Flies the trick popups' "+x0.5" into the multiplier from now on (T-336, T-514): the
## multiplier holds a trick's add back until its amount lands. The run scene calls it once
## the popups exist.
func bind_popups(popups: Node) -> void:
	if _popups != null and is_instance_valid(_popups):
		_popups.gain_popup.disconnect(_on_gain_popup)
		_popups.amount_detached.disconnect(_on_amount_detached)
	_popups = popups
	popups.fly_amounts = true
	popups.gain_popup.connect(_on_gain_popup)
	popups.amount_detached.connect(_on_amount_detached)


func _on_gain_popup(p: Node2D) -> void:
	multiplier_tag.hold(p.gain)
	# A popup pushed out before its amount left (the three-popup limit): no flight, the add
	# counts in at once.
	p.tree_exiting.connect(func() -> void:
		if not p.amount_gone:
			multiplier_tag.release(p.gain))


func _on_amount_detached(p: Node2D, screen_at: Vector2) -> void:
	var amount: String = TrickPopupArt.split_text(p.text)[1]
	multiplier_tag.fly_in(amount, p.gain, screen_at)


## The combo's heat step now (0 base, 1 from x2, 2 from x3, 3 from x4; T-131).
func combo_step() -> int:
	return combo_heat.step


## Whether the sub goal square is on fire now (the top heat step, T-131).
func fire_on() -> bool:
	return likes_fire.burning and likes_fire.visible


## A trick paid subs (T-534): dots fly from the car's place (the screen's centre, where the
## camera keeps it) to the gift's place now. At most subs_flight.max_per_frame start in one
## frame and subs_flight.max_alive are on screen at once; the rest pay without a flight.
func _on_trick_subs_paid(_trick_id: String, _subs: float) -> void:
	spawn_subs_flight()


## Starts one flight; null when the bounds in data say no.
func spawn_subs_flight() -> SubsFlight:
	var frame := Engine.get_process_frames()
	if frame != _flight_frame:
		_flight_frame = frame
		_flights_this_frame = 0
	if _flights_this_frame >= int(subs_flight_cfg.get("max_per_frame", 3)):
		return null
	if _flights_alive >= int(subs_flight_cfg.get("max_alive", 12)):
		return null
	_flights_this_frame += 1
	_flights_alive += 1
	var f := SubsFlight.new()
	f.setup(root.size / 2.0, gift_center, subs_flight_cfg)
	f.arrived.connect(func() -> void: _flights_alive -= 1)
	f.tree_exiting.connect(func() -> void:
		if not f.done:
			_flights_alive -= 1)
	root.add_child(f)
	return f


## Where the gift is now, in the HUD's own pixels (it follows the layout editor and the size).
func gift_center() -> Vector2:
	return to_layout(sub_goal.gift.get_global_rect().get_center())
