extends GutTest
## Task T-197: the depth order on the elevation sample map, across every raised
## area, ramp and building. The car and its shadow are drawn under any area,
## ramp or building they are behind and lower than its top, and over the ones
## they are on, above or in front of; the areas and buildings are drawn in one
## back-to-front order (a stacked height-6 rooftop over the height-3 one under
## it).
##
## The layout (data/level/elevation_sample_map.json, proposals): roof-nw-3 x
## -96..-12, y -96..-66 (height 3); roof-nw-6 x -42..-12 on it (height 6);
## ramp-nw-3-6 x -54..-42, y -86..-76; a building block at x 12..42, y
## -96..-66, east of the north-west garage across the road.

const SCENE := preload("res://scenes/elevation_sample/elevation_sample_map.tscn")

var scene: Node2D
var _interp_before := false


func before_each() -> void:
	_interp_before = get_tree().physics_interpolation
	scene = SCENE.instantiate()
	add_child_autofree(scene)
	scene.car.set_physics_process(false)
	scene.car.use_keyboard = false
	scene.car.detect_tricks = false


func after_each() -> void:
	get_tree().physics_interpolation = _interp_before


func _area(id: String):
	for a in scene.areas:
		if str(a.block.id) == id:
			return a
	return null


## Puts the car at rest at units (heading rot), optionally lifted into the air
## to `air` units, and updates the drawing.
func _put(units: Vector2, rot: float = 0.0, air: float = -1.0) -> void:
	scene.place_car(units, rot)
	if air >= 0.0:
		scene.car.height_model.height = air
		scene.car.height_model.airborne = true
	scene.sync_view()


## The map's building items (slots or blocks) that cover the car now.
func _covering_buildings() -> Array:
	var units: Vector2 = scene.car.model.get_position()
	var shape: PackedVector2Array = scene.car_shape_at(scene.car.height)
	return scene.map.fade_items().filter(func(b) -> bool: return b.covers(units, shape))


# --- The four cases of the ticket ----------------------------------------------

func test_the_car_on_height_3_behind_a_height_6_area_is_under_it() -> void:
	# On roof-nw-3, just west of roof-nw-6 and south of the 3-to-6 ramp.
	_put(Vector2(-44, -74), 0.0)
	assert_almost_eq(scene.car.height, 3.0, 0.001, "on the height-3 rooftop")
	var roof6 = _area("roof-nw-6")
	var roof3 = _area("roof-nw-3")
	assert_true(roof6.covers(scene.car.model.get_position(), scene.DEPTH_RADIUS, scene.car.height,
		scene.car_shape_at(scene.car.height)), "roof-nw-6 covers the car")
	assert_lt(scene.car_sprite.z_index, roof6.z_index, "the car under the height-6 area")
	assert_lt(scene.shadow.z_index, roof6.z_index, "its shadow under the height-6 area")
	assert_gt(scene.car_sprite.z_index, roof3.z_index, "the car over the height-3 area it is on")
	assert_gt(scene.shadow.z_index, roof3.z_index, "its shadow over the height-3 area it lies on")
	assert_lt(scene.shadow.z_index, scene.car_sprite.z_index, "the shadow under the car")


func test_the_car_in_the_air_above_height_6_over_a_height_3_area_is_over_it() -> void:
	# Over roof-nw-3, west of roof-nw-6, at height 7.
	_put(Vector2(-60, -81), 0.0, 7.0)
	assert_almost_eq(scene.car.height, 7.0, 0.001)
	for id in ["roof-nw-3", "roof-nw-6", "ramp-nw-3-6", "ramp-nw-0-3"]:
		assert_gt(scene.car_sprite.z_index, _area(id).z_index, "the car over %s" % id)
	assert_gt(scene.shadow.z_index, _area("roof-nw-3").z_index, "the shadow on the height-3 top")
	assert_lt(scene.shadow.z_index, scene.car_sprite.z_index)
	# Over roof-nw-6 itself at height 7 too.
	_put(Vector2(-27, -81), 0.0, 7.0)
	assert_gt(scene.car_sprite.z_index, _area("roof-nw-6").z_index)
	assert_gt(scene.shadow.z_index, _area("roof-nw-6").z_index)


func test_the_car_behind_a_building_next_to_a_raised_area_is_under_the_building() -> void:
	# On the road between the north-west garage (x end -12) and the building
	# block at x 12..42: behind its north-west skyscraper, in front of the garage.
	_put(Vector2(8, -92), PI / 2.0)
	assert_almost_eq(scene.car.height, 0.0, 0.001, "on the street")
	var covering := _covering_buildings()
	assert_gt(covering.size(), 0, "a building covers the car")
	for b in covering:
		assert_lt(scene.car_sprite.z_index, b.z_index, "the car under %s" % b.name)
		assert_lt(scene.shadow.z_index, b.z_index, "its shadow under %s" % b.name)
	for id in ["roof-nw-3", "roof-nw-6"]:
		assert_gt(scene.car_sprite.z_index, _area(id).z_index, "the car in front of %s" % id)
		assert_gt(scene.shadow.z_index, _area(id).z_index, "its shadow in front of %s" % id)


func test_the_car_on_top_of_a_height_6_area_is_over_it_and_the_height_3_under_it() -> void:
	for at in [Vector2(-27, -81), Vector2(-40, -94), Vector2(27, 81)]:
		_put(at, 0.0)
		assert_almost_eq(scene.car.height, 6.0, 0.001, "on a height-6 top at %s" % at)
		var six = _area("roof-nw-6") if at.y < 0.0 else _area("roof-se-6")
		var three = _area("roof-nw-3") if at.y < 0.0 else _area("roof-se-3")
		assert_gt(scene.car_sprite.z_index, six.z_index, "over the height-6 area at %s" % at)
		assert_gt(scene.car_sprite.z_index, three.z_index, "over the height-3 area at %s" % at)
		assert_gt(scene.shadow.z_index, six.z_index, "the shadow on the height-6 top at %s" % at)
		assert_lt(scene.shadow.z_index, scene.car_sprite.z_index)


# --- One consistent back-to-front order -----------------------------------------

func test_a_stacked_area_is_drawn_over_the_area_it_stands_on() -> void:
	assert_gt(_area("roof-nw-6").z_index, _area("roof-nw-3").z_index)
	assert_gt(_area("roof-se-6").z_index, _area("roof-se-3").z_index)


func test_the_order_keeps_every_drawn_before_pair() -> void:
	var items: Array = scene.depth_items
	for a in items:
		for b in items:
			if a != b and scene.drawn_before(a, b):
				assert_lt(a.z_index, b.z_index, "%s before %s" % [a.name, b.name])


func test_areas_and_buildings_are_one_order() -> void:
	# The garage is west of the building block across the road: drawn first.
	var block_item = null
	for b in scene.map.fade_items():
		if scene.item_rect(b).intersects(Rect2(12, -96, 30, 30)):
			block_item = b
			break
	assert_not_null(block_item)
	assert_lt(_area("roof-nw-6").z_index, block_item.z_index)
	assert_lt(_area("roof-nw-3").z_index, block_item.z_index)


# --- No item covers the car from a level it shares ------------------------------

func test_the_car_is_never_under_an_area_it_is_on_above_or_in_front_of() -> void:
	# A grid over both garages and the roads around them; at each point every
	# area the car overlaps on screen without being behind it (it is on it,
	# above it or in front of it) is drawn under the car.
	var hits := 0
	for gx in range(-100, 100, 4):
		for gy in [-98, -90, -82, -74, -68, -62, 60, 68, 76, 84, 92, 98]:
			var at := Vector2(gx, gy)
			_put(at, 0.0)
			var units: Vector2 = scene.car.model.get_position()
			var shape: PackedVector2Array = scene.car_shape_at(scene.car.height)
			for a in scene.areas:
				if a.is_behind(units, scene.DEPTH_RADIUS, scene.car.height):
					continue
				if Geometry2D.intersect_polygons(a.silhouette(), shape).is_empty():
					continue
				hits += 1
				if scene.car_sprite.z_index <= a.z_index:
					fail_test("at %s (height %.1f) the car (z %d) is under %s (z %d)" % [
						at, scene.car.height, scene.car_sprite.z_index, a.name, a.z_index])
					return
	assert_gt(hits, 0)


func test_the_car_and_shadow_stay_over_the_ground_everywhere() -> void:
	# The ground, drift marks and arrows are at z 0 (mvp_map.gd).
	for gx in range(-118, 118, 6):
		for gy in range(-118, 118, 6):
			_put(Vector2(gx, gy), 0.0)
			if scene.shadow.z_index <= 0:
				fail_test("at %s the shadow (z %d) is at or under the ground" % [Vector2(gx, gy), scene.shadow.z_index])
				return
	pass_test("over the ground")


func test_a_boulder_nothing_covers_is_over_every_area() -> void:
	var top: int = scene.top_z_index()
	var checked := 0
	for sp in scene.map.boulder_sprites:
		var covered := false
		for b in scene.map.fade_items():
			if b.is_behind(sp.centre_units) and not Geometry2D.intersect_polygons(b.iso_silhouette(), sp.outline).is_empty():
				covered = true
		for a in scene.areas:
			if a.is_behind(sp.centre_units, 0.0, 0.0) and not Geometry2D.intersect_polygons(a.silhouette(), sp.outline).is_empty():
				covered = true
		if not covered:
			checked += 1
			assert_eq(sp.z_index, top, "boulder at %s" % sp.centre_units)
	assert_gt(checked, 0)


func test_the_car_is_under_every_area_that_covers_it() -> void:
	for gx in range(-100, 100, 4):
		for gy in [-100, -98, -90, -82, -74, -68, -62, 60, 64, 68, 76, 84, 92, 98]:
			_put(Vector2(gx, gy), 0.0)
			var units: Vector2 = scene.car.model.get_position()
			var shape: PackedVector2Array = scene.car_shape_at(scene.car.height)
			for a in scene.areas:
				if a.covers(units, scene.DEPTH_RADIUS, scene.car.height, shape):
					assert_lt(scene.car_sprite.z_index, a.z_index, "at %s under %s" % [units, a.name])
