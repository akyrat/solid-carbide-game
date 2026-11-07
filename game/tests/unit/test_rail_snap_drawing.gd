extends GutTest
## Task T-566 (Drifting, Decisions, "A grind starts when the car's drawing crosses the rail's";
## Content, "The rail snap on the drawing (task T-566)"): with Space held in the air, the car snaps
## onto a rail as soon as its drawing on screen (its own pixels, lifted by its height) crosses the
## rail's drawn bar, whatever its height above or below the bar; not without Space, not when the
## drawings don't cross; the nearest bar on screen wins; the outline file matches the car's art.

const CarScript := preload("res://scripts/driving/car.gd")
const Rails := preload("res://scripts/level/rails.gd")
const RailGrind := preload("res://scripts/driving/rail_grind.gd")
const RailDrawing := preload("res://scripts/level/rail_drawing.gd")
const CarOutline := preload("res://scripts/driving/car_outline.gd")

## One rail along x (east) at height 6: high enough to be passed well under and well over.
const BAR := 6.0
const LAYOUT := {"rails": [{"id": "high", "x1": 0.0, "y1": 0.0, "z1": BAR, "x2": 40.0, "y2": 0.0, "z2": BAR}]}

var _world: Node2D


func before_each() -> void:
	_world = Node2D.new()
	add_child_autofree(_world)


## A car with no ground source (flat street at 0) and `layout`'s rails, at `pos` heading along
## `vel`, in the air at `height` going up at `vz`, Space held when `held`.
func _car(pos: Vector2, vel: Vector2, height: float, vz: float, held := true, layout := LAYOUT) -> CharacterBody2D:
	var car: CharacterBody2D = CarScript.new()
	car.model.set_position(pos)
	car.model.rotation = atan2(vel.y, vel.x)
	_world.add_child(car)
	car.set_physics_process(false)
	car.use_keyboard = false
	car.model.set_velocity(vel)
	car.grind.rails = Rails.from_layout(layout)
	car.scripted_jump_held = held
	car.height_model.height = height
	car.height_model.leave_rail(vz)
	return car


## Steps until a grind starts or the car lands; the steps taken.
func _fly(car, max_steps := 400) -> int:
	for i in max_steps:
		if car.grind.active or not car.airborne:
			return i
		car.physics_step()
	return max_steps


# --- The rule: the drawings cross, at any height -----------------------------------------------

func test_the_drawing_crossing_the_bar_catches_at_every_height() -> void:
	# In the isometric view a car d units nearer the viewer (south, +y) and d units higher than the
	# bar is drawn on it; so is one d units further (north) and d units lower.
	var g = RailGrind.new()
	g.rails = Rails.from_layout(LAYOUT)
	for dh in [-5.0, -3.0, -1.5, 0.0, 1.5, 3.0, 5.0, 8.0]:
		var on := g.find(Vector2(20, dh), Vector2(10, 0), BAR + dh)
		assert_true(on.has("index"), "%+.1f units over the bar, drawn on it: caught" % dh)
		var off := g.find(Vector2(20, dh + 3.0), Vector2(10, 0), BAR + dh)
		assert_eq(off, {}, "%+.1f units over the bar, drawn 3 units' worth clear of it: not caught" % dh)


func test_a_car_falling_from_well_above_snaps_and_grinds_at_the_bars_height() -> void:
	# 6 units over the bar and 4 in front of it: the drawing falls onto the bar while far above it.
	var car := _car(Vector2(2, 4), Vector2(10, 0), BAR + 6.0, 0.0)
	_fly(car)
	assert_true(car.grind.active, "snapped on from above")
	assert_gt(car.grind.grinds, 0)
	assert_almost_eq(car.height, BAR, 1e-6, "grinds at the bar's height")
	assert_almost_eq(car.model.get_position().y, 0.0, 1e-6, "on the rail's line")


func test_a_car_hopping_from_below_snaps_up_onto_the_bar() -> void:
	# 4 units behind the bar, rising from 1.0: its drawing rises across the bar 5 units under it.
	var car := _car(Vector2(2, -4), Vector2(10, 0), 1.0, 8.0)
	_fly(car)
	assert_true(car.grind.active, "snapped on from below")
	assert_almost_eq(car.height, BAR, 1e-6, "lifted onto the bar")
	assert_almost_eq(car.model.get_position().y, 0.0, 1e-6)


func test_the_drawing_moves_only_onto_the_bar_at_the_snap() -> void:
	var car := _car(Vector2(2, 4), Vector2(10, 0), BAR + 6.0, 0.0)
	var before := Vector2.ZERO
	for i in 400:
		before = CarOutline.screen_of(car.model.get_position(), car.height)
		car.physics_step()
		if car.grind.active:
			break
	var after := CarOutline.screen_of(car.model.get_position(), car.height)
	var half := CarOutline.bounds(Vector2.ZERO, 0.0, 3).size.y / 2.0 + RailGrind.BAR_HALF_PX
	gut.p("the drawing moved %.1f px at the snap (at most %.1f: half its height and the bar's)" % [before.distance_to(after), half])
	assert_lte(before.distance_to(after), half, "its centre goes onto the bar where the player sees it cross, no further")


# --- Not without Space, not without crossing ----------------------------------------------------

func test_without_space_held_it_never_snaps() -> void:
	for start in [[Vector2(2, 4), BAR + 6.0, 0.0], [Vector2(2, -4), 1.0, 8.0]]:
		var car := _car(start[0], Vector2(10, 0), start[1], start[2], false)
		_fly(car)
		assert_eq(car.grind.grinds, 0, "Space not held: no grind from %s" % str(start[0]))
		assert_false(car.airborne, "it landed on the street")


func test_drawings_that_never_cross_never_snap() -> void:
	# In front of the bar and below it: the drawing only moves further down, away from the bar.
	var car := _car(Vector2(2, 4), Vector2(10, 0), 3.0, 0.0)
	_fly(car)
	assert_eq(car.grind.grinds, 0, "no grind")
	# Straight across the bar's drawing: square-on, so not caught (only the speed along is kept).
	var across := _car(Vector2(20, -6), Vector2(0, 10), BAR, 0.0)
	_fly(across)
	assert_eq(across.grind.grinds, 0, "crossing square-on")


func test_a_rail_through_the_empty_corner_of_the_frame_is_not_caught() -> void:
	# The car's own pixels count, not its frame or bounding box.
	var at := Vector2(100, 100)
	var box := CarOutline.bounds(at, 0.0, 3)
	var corner_a := Vector2(box.end.x - 1.0, box.position.y + 1.0)
	var corner_b := Vector2(box.end.x - 6.0, box.position.y + 1.0)
	assert_true(CarOutline.segment_hits_rect(corner_a, corner_b, box), "inside the bounding box")
	assert_false(CarOutline.touches_segment(at, 0.0, 3, corner_a, corner_b, 0.5), "but no car pixel there")
	assert_true(CarOutline.touches_segment(at, 0.0, 3, at - Vector2(40, 0), at + Vector2(40, 0), 0.5), "through its middle")


# --- Two rails ----------------------------------------------------------------------------------

func test_two_bars_crossed_the_nearest_on_screen_wins() -> void:
	var g = RailGrind.new()
	g.rails = Rails.from_layout({"rails": [
		{"id": "a", "x1": 0.0, "y1": 0.0, "z1": 2.0, "x2": 40.0, "y2": 0.0},
		{"id": "b", "x1": 0.0, "y1": 0.8, "z1": 2.0, "x2": 40.0, "y2": 0.8}]})
	assert_eq(int(g.find(Vector2(20, 0.6), Vector2(10, 0), 2.0).index), 1, "b is nearer on screen")
	assert_eq(int(g.find(Vector2(20, 0.2), Vector2(10, 0), 2.0).index), 0, "a is nearer on screen")
	# A higher bar drawn nearer the car's drawing beats a lower bar nearer on the map.
	g.rails = Rails.from_layout({"rails": [
		{"id": "low", "x1": 0.0, "y1": 0.0, "z1": 2.0, "x2": 40.0, "y2": 0.0},
		{"id": "high", "x1": 0.0, "y1": -1.0, "z1": 3.0, "x2": 40.0, "y2": -1.0}]})
	var f := g.find(Vector2(20, 0.0), Vector2(10, 0), 2.0)
	assert_eq(int(f.index), 0, "on the low bar, map and screen agree")
	var f2 := g.find(Vector2(20, -0.4), Vector2(10, 0), 2.8)
	assert_eq(int(f2.index), 1, "nearer on screen, though further on the map")


# --- The outline and the projection -------------------------------------------------------------

func test_the_projection_is_the_rails_drawing() -> void:
	for p in [[Vector2(2, 1), 0.0], [Vector2(-3, 7.5), 4.25], [Vector2(40, -12), 9.0]]:
		assert_eq(CarOutline.screen_of(p[0], p[1]), RailDrawing.screen_of(p[0], p[1]))


func test_the_outline_file_matches_the_car_art() -> void:
	var d := CarOutline.data()
	assert_false(d.is_empty(), "art/car/car_iso_outline.json loads")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/car/car_iso_noshadow.json"))
	assert_eq(int(d.frame_count), int(layout.frame_count))
	assert_eq(float(d.center_px.x), float(layout.center_px.x))
	assert_eq(CarOutline.scale(), 0.5, "half size on screen, as car_sprite.gd draws it")
	var w := int(d.frame_width)
	var h := int(d.frame_height)
	var checks := [["air", "res://art/car/car_iso_noshadow.png", 0, 0], ["air", "res://art/car/car_iso_noshadow.png", 0, 13],
		["tilt3", "res://art/car/car_iso_tilt.png", 2, 5], ["tilt1", "res://art/car/car_iso_tilt.png", 0, 27]]
	for c in checks:
		var img: Image = (load(c[1]) as Texture2D).get_image()
		img.decompress()
		var spans: Array = d.sheets[c[0]][c[3]]
		var by_row := {}
		for i in range(0, spans.size(), 3):
			by_row[int(spans[i])] = [int(spans[i + 1]), int(spans[i + 2])]
		var bad := 0
		for y in h:
			var left := -1
			var right := -1
			for x in w:
				if img.get_pixel(c[3] * w + x, c[2] * h + y).a >= 0.5:
					if left < 0:
						left = x
					right = x
			var want = [left, right] if left >= 0 else null
			if by_row.get(y) != want:
				bad += 1
		assert_eq(bad, 0, "%s frame %d: every row's span matches the PNG (else run tools/build_car_outline.py)" % [c[0], c[3]])


func test_the_frame_follows_the_heading_as_the_sprite() -> void:
	var sprite := preload("res://scripts/driving/car_sprite.gd").new()
	add_child_autofree(sprite)
	sprite.use_sheet("iso")
	for deg in [0.0, 11.0, 47.0, 180.0, -100.0, 359.0]:
		assert_eq(CarOutline.frame_for(deg_to_rad(deg)), sprite.frame_for_rotation(deg_to_rad(deg)), "%s degrees" % deg)
