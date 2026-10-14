extends GutTest
## Task T-132: trick popups (and the challenge popup) are always drawn above
## every building, sign, boulder and the car, whatever the map's depth scheme.

const RunScene := preload("res://scenes/run/run.tscn")
const GameScene := preload("res://scenes/game/game.tscn")
const PrototypeScene := preload("res://scenes/drift_prototype/drift_prototype.tscn")


## A node's drawing order as Godot works it out: its z_index plus its
## z_as_relative ancestors' (stopping at the first absolute one).
func effective_z(n: CanvasItem) -> int:
	var z := 0
	var cur: Node = n
	while cur is CanvasItem:
		z += cur.z_index
		if not cur.z_as_relative:
			break
		cur = cur.get_parent()
	return mini(z, RenderingServer.CANVAS_ITEM_Z_MAX)


func _highest_in_map(run: Node2D) -> int:
	var top: int = run.map.top_z_index()
	for b in run.map.fade_items():
		top = maxi(top, effective_z(b))
	for s in run.map.alert_signs:
		top = maxi(top, effective_z(s))
	for s in run.map.boulder_sprites:
		top = maxi(top, effective_z(s))
	return top


func test_popup_is_above_everything_in_the_map_and_the_car() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var pop = run.trick_popups.show_popup("FULL 360!", run.car_sprite.position)
	var pz := effective_z(pop)
	assert_gt(pz, run.map.top_z_index(), "over map.top_z_index()")
	assert_gt(pz, _highest_in_map(run), "over every slot, sign and boulder")
	assert_gt(pz, effective_z(run.car_sprite), "over the car's drawing")


func test_popup_stays_above_when_the_car_is_under_a_building() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.view_root.z_index = 5  # the car under a covering building: the view's z is low
	var pop = run.trick_popups.show_popup("LONG DRIFT!", run.car_sprite.position)
	assert_gt(effective_z(pop), _highest_in_map(run))


func test_rule_does_not_depend_on_todays_numbers() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	var pop = run.trick_popups.show_popup("ALT DRIFT!", run.car_sprite.position)
	assert_false(pop.z_as_relative, "absolute: the view's own z does not count")
	# The map grows: a lot more building slots, and the view at its top z.
	run.view_root.z_index = run.map.top_z_index() + 2000
	for b in run.map.fade_items():
		b.z_index += 2000
	assert_gt(effective_z(pop), _highest_in_map(run), "still above after the map's top z grew")
	assert_eq(pop.z_index, RenderingServer.CANVAS_ITEM_Z_MAX, "the top of Godot's range")


func test_challenge_popup_is_above_too() -> void:
	var run: Node2D = RunScene.instantiate()
	add_child_autofree(run)
	run.state.score.emit(25.0, "c-1")
	var pop = run.trick_popups.popups().back()
	assert_gt(effective_z(pop), _highest_in_map(run))


func test_popups_still_draw_under_the_hud() -> void:
	var game: Node = GameScene.instantiate()
	add_child_autofree(game)
	game.menu.start_button.pressed.emit()
	await wait_process_frames(2)
	var pop = game.run.trick_popups.show_popup("FULL 360!", game.run.car_sprite.position)
	# z only orders items inside one canvas layer: the HUD and screens sit in
	# CanvasLayers with a layer above the world's (layer 0).
	var node: Node = pop
	while node != null and not (node is CanvasLayer):
		node = node.get_parent()
	assert_null(node, "the popup is in the world's own canvas, not in a CanvasLayer")
	var layers := 0
	for c in game.find_children("*", "CanvasLayer", true, false):
		layers += 1
		assert_gt(c.layer, 0, "%s draws over the world, popups included" % c.name)
	assert_gt(layers, 0, "the game has its HUD layer")


func test_the_drift_prototype_popups_are_absolute_and_on_top() -> void:
	var proto: Node = PrototypeScene.instantiate()
	add_child_autofree(proto)
	var pop = proto.trick_popups.show_popup("FULL 360!", Vector2.ZERO)
	assert_eq(effective_z(pop), RenderingServer.CANVAS_ITEM_Z_MAX)
