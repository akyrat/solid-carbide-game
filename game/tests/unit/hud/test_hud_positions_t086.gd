extends GutTest
## Task T-086: the heart art swap moved nothing else on the HUD. Since T-337 the
## likes bar, its row ("Likes", "Hype Lv") and the heart in it are gone (the sub
## goal square replaced them); the combo counter (at every step) still sits
## exactly where it did before T-086 (measured from master's code, T-131
## layout, moved up 48 px by the 64 px likes bar of T-273).

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
## The combo counter's layout rect (position and size, before the heat's
## pulse scale, which changes with time), per multiplier, at 1152x648.
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
	hud._on_combo_changed(mult)
	return hud


func _same(got: Rect2, want: Rect2, what: String) -> void:
	assert_almost_eq(got.position, want.position, Vector2(0.02, 0.02), "%s position" % what)
	assert_almost_eq(got.size, want.size, Vector2(0.02, 0.02), "%s size" % what)


func test_combo_counter_at_every_step_sits_where_it_did() -> void:
	for m: float in COMBO:
		var hud := _hud(m)
		await get_tree().process_frame
		_same(Rect2(hud.combo_label.position, hud.combo_label.size), COMBO[m], "combo x%s" % m)
