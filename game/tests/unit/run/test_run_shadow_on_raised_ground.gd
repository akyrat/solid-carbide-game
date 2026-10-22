extends GutTest
## Task T-258: the car's round shadow shows on raised ground while the car is in
## the air, in the run (elevation map, shared with the level creator's runs).
## It is drawn over the rooftop or ramp it lies on and at that ground's height.
## Heights: roof-nw-3 (3) under (-70, -81), roof-nw-6 (6) under (-27, -81), the
## street at (0, -81).

const RunScene := preload("res://scenes/run/run.tscn")

var run: Node2D


func before_each() -> void:
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.car.use_keyboard = false
	run.car.detect_tricks = false


func _area(id: String):
	for a in run.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


## Car at rest over `units`, `above` units over the ground there, in the air.
func _fly(units: Vector2, above: float, rot: float = 0.0) -> void:
	var car = run.car
	car.model.set_position(units)
	car.model.rotation = rot
	car.model.set_velocity(Vector2.ZERO)
	car._sync_from_model()
	car.ground = run.elevation.ground_height
	var g: float = run.elevation.ground_height.height_at(units)
	car.height_model.height = g + above
	car.height_model.airborne = true
	run.sync_view()


## The areas whose rectangle holds `units` and whose top there is `ground`.
func _under(units: Vector2) -> Array:
	return run.elevation.areas.filter(func(a) -> bool:
		return a.rect().has_point(units) and absf(a.top_height_at(units) - run.elevation.ground_height.height_at(units)) < 0.01)


func _check_shadow(units: Vector2, label: String) -> void:
	_fly(units, 3.0)
	var ground: float = run.elevation.ground_height.height_at(units)
	assert_true(run.car_sprite.in_air, "%s: in the air" % label)
	assert_true(run.shadow.visible, "%s: shadow shown" % label)
	assert_almost_eq(run.shadow.surface_height, ground, 0.001, "%s: shadow at the ground's height" % label)
	assert_almost_eq(run.shadow.position.y,
		(run.ISO_TRANSFORM * (units * 16.0)).y - ground * 16.0, 0.01, "%s: shadow drawn on the ground" % label)
	for a in _under(units):
		assert_gt(run.shadow.z_index, a.z_index, "%s: shadow over %s" % [label, a.name])
	assert_lt(run.shadow.z_index, run.view_root.z_index, "%s: shadow under the car" % label)


func test_shadow_shows_under_the_airborne_car_over_the_street() -> void:
	_check_shadow(Vector2(0, -81), "street")


func test_shadow_shows_over_a_height_3_rooftop() -> void:
	_check_shadow(Vector2(-70, -81), "roof 3")


func test_shadow_shows_over_a_height_6_rooftop() -> void:
	_check_shadow(Vector2(-27, -81), "roof 6")


func test_shadow_shows_over_a_ramp() -> void:
	var ramp = run.elevation.ground_height.ramps[0]
	var r: Rect2 = ramp.rect
	_check_shadow(r.get_center(), "ramp")


func test_shadow_over_every_area_across_its_whole_top() -> void:
	for a in run.elevation.areas:
		var r: Rect2 = a.rect()
		for fx in [0.1, 0.5, 0.9]:
			for fy in [0.1, 0.5, 0.9]:
				var p := r.position + Vector2(r.size.x * fx, r.size.y * fy)
				_fly(p, 2.0)
				for under in _under(p):
					assert_gt(run.shadow.z_index, under.z_index,
						"%s at %s: shadow over %s" % [a.name, p, under.name])


func test_shadow_is_never_under_an_area_the_car_is_drawn_over() -> void:
	# Found with the old depth order: (-88, -64) with the ramp-nw-0-3 and
	# (-52, -88) with the ramp-nw-3-6, the car in the air drawn over the ramp
	# while its shadow was drawn under it (lost behind it).
	for spot in [[Vector2(-88, -64), 0.0, 3.0], [Vector2(-88, -64), 0.0, 8.0],
			[Vector2(-52, -88), PI / 2.0, 3.0], [Vector2(-52, -88), PI / 2.0, 8.0]]:
		_fly(spot[0], spot[2], spot[1])
		for a in run.elevation.areas:
			if run.view_root.z_index > a.z_index:
				assert_gt(run.shadow.z_index, a.z_index,
					"%s at %s lift %s: shadow over it as the car is" % [a.name, spot[0], spot[2]])
		assert_lt(run.shadow.z_index, run.view_root.z_index, "under the car")
