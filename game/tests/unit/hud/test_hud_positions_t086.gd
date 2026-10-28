extends GutTest
## Task T-086: the heart art swap moves nothing else on the HUD. The likes row's
## top and height and "Hype Lv" sit exactly
## where they did before T-086 (the combo counter is gone since T-336) (measured from master's code, T-131 layout), moved up 48 px by the 64 px likes bar (T-273).

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
## Measured from master's hud.gd (f6ff2eb, before T-086) at 1152x648 with
## "Hype Lv 99": rects as [x, y, w, h].
const ROW := Rect2(288, 536, 66, 26)
const LIKES := Rect2(320, 536, 34, 26)
const LEVEL := Rect2(792, 536, 72, 26)
const BAR := Rect2(288, 568, 576, 64)


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


func test_heart_is_level_with_likes_inside_its_26px_box() -> void:
	var hud := _hud(1.5)
	await get_tree().process_frame
	assert_eq(hud.heart_box.size, Vector2(Hud.HEART_BOX, Hud.HEART_BOX))
	var heart := hud.heart.get_global_rect()
	assert_eq(heart.size, Vector2(22, 20))
	# Likes' letters span y 587-601 (screenshot); the heart's red 587-602.
	assert_eq(heart.position.y, 537.0, "heart box top, level with the letters")
