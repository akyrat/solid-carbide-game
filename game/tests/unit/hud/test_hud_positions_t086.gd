extends GutTest
## Task T-086: the heart art swap moves nothing else on the HUD. The likes row's
## top and height, "Hype Lv" and the combo counter (at every step) sit exactly
## where they did before T-086 (measured from master's code, T-131 layout), moved up 48 px by the 64 px likes bar (T-273).

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
## Measured from master's hud.gd (f6ff2eb, before T-086) at 1152x648 with
## "Hype Lv 99": rects as [x, y, w, h].
const ROW := Rect2(288, 536, 67, 26)
const LIKES := Rect2(320, 536, 35, 26)
const LEVEL := Rect2(792, 536, 72, 26)
const BAR := Rect2(288, 568, 576, 64)
## The combo counter's layout rect (position and size, before the heat's
## pulse scale, which changes with time), per multiplier.
const COMBO := {
	1.5: Rect2(516, 499, 120, 33),
	2.0: Rect2(501, 493, 150, 39),
	3.0: Rect2(488, 486, 176, 46),
	4.5: Rect2(473, 477, 207, 55),
}


func _hud(mult: float) -> Hud:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	hud.level_label.text = Hud.TEXT_LEVEL.format({"level": 99})
	hud._on_combo_changed(mult)
	return hud


func _same(got: Rect2, want: Rect2, what: String) -> void:
	assert_almost_eq(got.position, want.position, Vector2(0.02, 0.02), "%s position" % what)
	assert_almost_eq(got.size, want.size, Vector2(0.02, 0.02), "%s size" % what)


func test_row_labels_and_bar_sit_where_they_did_before_the_art() -> void:
	var hud := _hud(1.5)
	await get_tree().process_frame
	_same(hud.likes_row.get_global_rect(), ROW, "likes row")
	_same(hud.likes_label.get_global_rect(), LIKES, "Likes")
	_same(hud.level_label.get_global_rect(), LEVEL, "Hype Lv")
	_same(hud.likes_bar.get_global_rect(), BAR, "likes bar")


func test_combo_counter_at_every_step_sits_where_it_did() -> void:
	for m: float in COMBO:
		var hud := _hud(m)
		await get_tree().process_frame
		_same(Rect2(hud.combo_label.position, hud.combo_label.size), COMBO[m], "combo x%s" % m)


func test_heart_is_level_with_likes_inside_its_26px_box() -> void:
	var hud := _hud(1.5)
	await get_tree().process_frame
	assert_eq(hud.heart_box.size, Vector2(Hud.HEART_BOX, Hud.HEART_BOX))
	var heart := hud.heart.get_global_rect()
	assert_eq(heart.size, Vector2(22, 20))
	# Likes' letters span y 587-601 (screenshot); the heart's red 587-602.
	assert_eq(heart.position.y, 537.0, "heart box top, level with the letters")
