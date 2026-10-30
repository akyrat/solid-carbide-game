class_name Hud
extends CanvasLayer
## The run's HUD (tasks T-090, T-049 and T-113): the timer as a digital clock at the bottom left (T-335),
## the car's health bar upright at the top left (T-276: 72 x 320, the heart
## under it, the weapon icons beside it), the coins
## at the top right, the sub goal square on the right edge (T-337, SubGoal: it
## replaced the likes bar and its row) and the live viewers counter at the bottom
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
const TEXT_LIVE_BADGE := "LIVE"
const TEXT_VIEWERS_UNIT := "WATCHING"
const TEXT_COINS := "Coins"
## The comic font of the trick popups (T-084), used since T-131 by the combo
## counter and the sub goal label. It has capitals only.
const COMIC_FONT_PATH := HudStyle.COMIC_FONT_PATH
## The airtime counter's top left corner from the screen's centre (T-243).
const AIRTIME_OFFSET := Vector2(70, -10)
## The drift counter's top left corner from the screen's centre (T-247): under
## the airtime counter, at the same x.
const DRIFT_OFFSET := Vector2(70, 30)

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
## The live viewers counter at the bottom right (T-336): the combo shown as viewers.
var viewers_counter: ViewersCounter
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
## A full-screen area (empty since T-337 and T-336 took the likes bar and the combo counter away).
var bottom_area: Control
## The combo's heat steps (T-131): lights likes_fire (the viewers counter has its own, T-336).
var combo_heat: ComboHeat
## The flames along the sub goal square's top edge at the top heat step (T-131, T-337).
var likes_fire: LikesFire
## The live airtime counter (T-243), shown only while the car is airborne.
var airtime_counter: AirtimeCounter
## The live drift counter (T-247), shown only while the car is drifting.
var drift_counter: DriftCounter
var _car: Node
var _state: RunState
## The combo's numbers (combo.json): its start value is "no combo" (T-116).
var _combo_data: ComboData
## The trick popups whose amounts fly into the viewers counter (bind_popups, T-336).
var _popups: Node


func _ready() -> void:
	layer = 10
	_combo_data = ComboData.new()
	_build_reactions()
	_build_timer()
	_build_left()
	_build_bottom()
	_build_coins()
	_build_viewers()
	_build_airtime()
	_build_drift()


## The reaction icons (T-351): under every other HUD piece, fed the viewers counter's step.
func _build_reactions() -> void:
	reactions = Reactions.new()
	reactions.step_source = func() -> int:
		return viewers_counter.step if viewers_counter != null else 0
	add_child(reactions)


## The airtime counter (T-243): hidden until the car is airborne. It sits right
## of the screen's centre, a little below it: at the bottom right of where the
## combo popups show (they pop out above the car, which the camera keeps at the
## centre). A proposal for the playtest.
func _build_airtime() -> void:
	airtime_counter = AirtimeCounter.new()
	airtime_counter.name = "AirtimeCounter"
	add_child(airtime_counter)
	airtime_counter.resized.connect(_layout_airtime)
	_layout_airtime()
	get_viewport().size_changed.connect(_layout_airtime)


func _layout_airtime() -> void:
	var view := get_viewport().get_visible_rect().size
	airtime_counter.position = (view / 2.0 + AIRTIME_OFFSET).round()


## The drift counter (T-247): hidden until the car drifts; under the airtime
## counter, so both can show at once.
func _build_drift() -> void:
	drift_counter = DriftCounter.new()
	drift_counter.name = "DriftCounter"
	add_child(drift_counter)
	drift_counter.resized.connect(_layout_drift)
	_layout_drift()
	get_viewport().size_changed.connect(_layout_drift)


func _layout_drift() -> void:
	var view := get_viewport().get_visible_rect().size
	drift_counter.position = (view / 2.0 + DRIFT_OFFSET).round()


## Follows the car's airborne state from now on (T-243): counts its airtime
## while it is in the air. Call again when the car is rebuilt.
func bind_car(car: Node) -> void:
	if _car != null and is_instance_valid(_car) and _car.stepped.is_connected(_on_car_stepped):
		_car.stepped.disconnect(_on_car_stepped)
	_car = car
	airtime_counter.stop()
	drift_counter.stop()
	car.stepped.connect(_on_car_stepped)


func _on_car_stepped() -> void:
	airtime_counter.step(_car.airborne, _car.model.dt)
	drift_counter.step(_car.model.is_drifting, _car.model.dt)


func _build_timer() -> void:
	timer_clock = TimerClock.new()
	add_child(timer_clock)
	timer_label = timer_clock.label


func _build_left() -> void:
	left_column = Control.new()
	left_column.name = "Left"
	left_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_column)
	heart_row = HeartRow.new()
	left_column.add_child(heart_row)
	weapon_icons = WeaponIcons.new()
	left_column.add_child(weapon_icons)
	_layout_left()


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
	add_child(bottom_area)
	sub_goal = SubGoal.new()
	add_child(sub_goal)
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


## The live viewers counter (T-336), anchored to the bottom-right corner (hud.json).
func _build_viewers() -> void:
	viewers_counter = ViewersCounter.new()
	add_child(viewers_counter)


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
	add_child(box)
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
	_state = state
	_state.time_left_changed.connect(_on_time_left_changed)
	_state.health_changed.connect(_on_health_changed)
	_state.xp_changed.connect(_on_xp_changed)
	_state.coins_changed.connect(_on_coins_changed)
	_state.combo_changed.connect(_on_combo_changed)
	_state.combo_broken.connect(_on_combo_broken)
	_state.level_up.connect(_on_level_up)
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
	viewers_counter.reset(_state.combo)
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
	reactions.burst(sub_goal.get_global_rect().get_center())


func _on_coins_changed(coins: int) -> void:
	coins_value_label.text = str(coins)


func _on_combo_changed(multiplier: float) -> void:
	viewers_counter.set_multiplier(multiplier)
	combo_heat.set_multiplier(multiplier)


## A crash cut the combo (T-336): the counter flashes red and drops the viewers lost.
func _on_combo_broken() -> void:
	viewers_counter.crash(viewers_counter.last_loss())
	# T-356: the stream reacts badly, from the counter's lane.
	reactions.bad_burst(viewers_counter.get_global_rect().get_center().y)


## Flies the trick popups' "+viewers" into the viewers counter from now on (T-336):
## the counter holds a trick's viewers back until its amount lands. The run scene
## calls it once the popups exist.
func bind_popups(popups: Node) -> void:
	if _popups != null and is_instance_valid(_popups):
		_popups.viewers_popup.disconnect(_on_viewers_popup)
		_popups.amount_detached.disconnect(_on_amount_detached)
	_popups = popups
	popups.fly_amounts = true
	popups.viewers_popup.connect(_on_viewers_popup)
	popups.amount_detached.connect(_on_amount_detached)


func _on_viewers_popup(p: Node2D) -> void:
	viewers_counter.hold(p.viewers_gain)
	# A popup pushed out before its amount left (the three-popup limit): no flight,
	# the viewers count in at once.
	p.tree_exiting.connect(func() -> void:
		if not p.amount_gone:
			viewers_counter.release(p.viewers_gain))


func _on_amount_detached(p: Node2D, screen_at: Vector2) -> void:
	var amount: String = TrickPopupArt.split_text(p.text)[1]
	viewers_counter.fly_in(amount, p.viewers_gain, screen_at)


## The combo's heat step now (0 base, 1 from x2, 2 from x3, 3 from x4; T-131).
func combo_step() -> int:
	return combo_heat.step


## Whether the sub goal square is on fire now (the top heat step, T-131).
func fire_on() -> bool:
	return likes_fire.burning and likes_fire.visible
