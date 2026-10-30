extends GutTest
## Task T-393 (Level design, Decisions, "Obstacles and decorations respect the buildings' and
## rooftops' heights"): every placed object (boulders and the props: barrier, cones, crates, street
## lamp, AC unit, water tank, roof vent, rooftop sign) stands at the height of what it stands on
## (street, rooftop 3, rooftop 6, ramp) and is drawn behind the buildings and rooftops in front of
## it and over the ones behind it, in the editor and in the run; an object never stands across a
## rooftop's or ramp's edge or inside a building (the proposal), and a building, rooftop or ramp
## never cuts through one.

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")
const PROP_IDS := ["prop-barrier", "prop-cones", "prop-crates", "prop-ac-unit", "prop-water-tank",
	"prop-roof-vent", "prop-street-lamp", "prop-roof-sign"]
const ISO := MvpMapScript.ISO_TRANSFORM
const PX := 16.0


func _editor() -> LevelCreatorEditor:
	var e: LevelCreatorEditor = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": 111.0, "y": 111.0, "heading": 270}  # out of the way of the pieces
	e.levels_dir = RunPaths.file("t393_levels")
	add_child_autofree(e)
	return e


func _place(e: LevelCreatorEditor, id: String, at: Vector2, size: Vector2 = Vector2.ZERO) -> Dictionary:
	e.panel.pick(id)
	var p := e.place_asset(id, at + Vector2(0.1, 0.1), size)
	e.panel.pick("")
	return p


## The run on the editor's level, saved.
func _run_of(e: LevelCreatorEditor, file: String) -> Node2D:
	var path := RunPaths.file(file)
	assert_eq(LevelStore.save_level(path, e.document.file_data("T-393")), OK)
	var run: Node2D = RunScene.instantiate()
	run.layout_path = path
	add_child_autofree(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	return run


## The fade items (building slots) standing on `r` (units).
func _building_nodes(map: Node2D, r: Rect2) -> Array:
	var out: Array = []
	for b in map.fade_items():
		var fr: Rect2 = map.elevation.item_rect(b)
		if fr.intersects(r):
			out.append(b)
	return out


func _area(map: Node2D, id: String) -> Node2D:
	for a in map.elevation.areas:
		if str(a.block.id) == id:
			return a
	return null


func _prop_sprite(map: Node2D, id: String) -> Node2D:
	for sp in map.prop_sprites:
		if sp.prop_id == id:
			return sp
	return null


## A level with a far-away rooftop (so the map has an elevation layer and the buildings are
## restacked with the areas, the board's case) and one low-rise at x 20..32, y 20..32.
func _low_rise_level(e: LevelCreatorEditor) -> Dictionary:
	assert_false(_place(e, "rooftop-3", Vector2(-100, -100), Vector2(16, 16)).is_empty(), "the far rooftop")
	var b := _place(e, "short-0", Vector2(20, 20))
	assert_false(b.is_empty(), "the low-rise")
	assert_eq(Rect2(float(b.item.x), float(b.item.y), float(b.item.w), float(b.item.h)), Rect2(20, 20, 12, 12))
	return b


func _check_barrier_by_the_low_rise(map: Node2D, where: String) -> void:
	var nodes := _building_nodes(map, Rect2(20, 20, 12, 12))
	assert_false(nodes.is_empty(), where)
	var behind: Node2D = _prop_sprite(map, "prop-1")
	var front: Node2D = _prop_sprite(map, "prop-2")
	for b in nodes:
		assert_true(b.is_behind(behind.centre_units), "%s: the barrier is behind the low-rise" % where)
		assert_false(Geometry2D.intersect_polygons(b.iso_silhouette(), behind.outline).is_empty(),
			"%s: and overlaps it on screen" % where)
		assert_lt(behind.z_index, b.z_index, "%s: the barrier behind the low-rise is drawn under it" % where)
		assert_gt(front.z_index, b.z_index, "%s: the barrier in front of the low-rise is drawn over it" % where)


## The board's case (its screenshot): a barrier on the street just behind (west of) a low-rise,
## overlapping it on screen, on a level with a rooftop. Before T-393 it was drawn over the low-rise:
## the depth order took the restacked low-rise's z_index for "no building covers it".
func test_a_barrier_behind_a_low_rise_is_drawn_under_it_in_the_editor_and_the_run() -> void:
	var e := _editor()
	_low_rise_level(e)
	assert_false(_place(e, "prop-barrier", Vector2(14, 24)).is_empty(), "behind: x 14..18, y 24..25")
	assert_false(_place(e, "prop-barrier", Vector2(24, 34)).is_empty(), "in front: x 24..28, y 34..35")
	_check_barrier_by_the_low_rise(e.map, "editor")
	var run := _run_of(e, "t393_low_rise.json")
	_check_barrier_by_the_low_rise(run.map, "run")


func test_a_boulder_behind_a_low_rise_is_drawn_under_it() -> void:
	var e := _editor()
	_low_rise_level(e)
	assert_false(_place(e, "boulder-a", Vector2(16, 24)).is_empty())
	var sp: Node2D = e.map.boulder_sprites[0]
	var nodes := _building_nodes(e.map, Rect2(20, 20, 12, 12))
	for b in nodes:
		if not Geometry2D.intersect_polygons(b.iso_silhouette(), sp.outline).is_empty():
			assert_lt(sp.z_index, b.z_index, "the boulder behind the low-rise is drawn under it")


## The heights level: rooftop 3 at x -60..-20, y -60..-20, a 6 standing on it at x -50..-30,
## y -50..-30, and a 0-to-3 ramp alone on the street at x 40..50, y -60..-48.
func _heights_level(e: LevelCreatorEditor) -> void:
	assert_false(_place(e, "rooftop-3", Vector2(-60, -60), Vector2(40, 40)).is_empty(), "the 3")
	assert_false(_place(e, "rooftop-6", Vector2(-50, -50), Vector2(20, 20)).is_empty(), "the 6 on the 3")
	var ramp := _place(e, "ramp-0-3", Vector2(40, -60))
	assert_false(ramp.is_empty(), "the ramp")
	assert_eq(Rect2(float(ramp.item.x), float(ramp.item.y), float(ramp.item.w), float(ramp.item.h)), Rect2(40, -60, 10, 12))


## Where each object goes on each surface: [id, corner (units), surface, height (-1: the ramp's)].
## Street: a column at x -100; the 3: a column on its west band (x -58); the 6: a 3 x 3 grid; the
## ramp: two objects.
func _spots() -> Array:
	var out: Array = []
	var ids: Array = PROP_IDS + ["boulder-a"]
	for k in ids.size():
		out.append([ids[k], Vector2(-100, 40 + 6 * k), "street", 0.0])
		out.append([ids[k], Vector2(-58, -60 + 4 * k), "3", 3.0])
		out.append([ids[k], Vector2(-50 + 6 * (k % 3), -50 + 6 * (k / 3)), "6", 6.0])
	out.append(["prop-cones", Vector2(42, -58), "ramp", -1.0])
	out.append(["boulder-a", Vector2(42, -54), "ramp", -1.0])
	return out


## Checks the object `piece` stands at `h` (units) on `map`: a prop's sprite (its anchor on the
## centre, lifted by h) or a boulder's (its bottom on the circle's front edge, lifted by h).
func _check_height(map: Node2D, piece: Dictionary, h: float, what: String) -> void:
	if str(piece.kind) == "prop":
		var sp: Node2D = _prop_sprite(map, str(piece.item.id))
		assert_not_null(sp, what)
		if sp == null:
			return
		var c := Rect2(float(piece.item.x), float(piece.item.y), float(piece.item.w), float(piece.item.h)).get_center()
		var s := LevelProps.sprite_of(str(piece.item.asset), str(piece.item.rotation))
		var scale := float(LevelProps.data().get("draw_scale", 0.5))
		var want: Vector2 = ISO * (c * PX) - (s.anchor_px as Vector2) * scale - Vector2(0.0, h * PX)
		assert_almost_eq(sp.ground_units, h, 0.001, what)
		assert_almost_eq(sp.position.x, want.x, 0.01, what)
		assert_almost_eq(sp.position.y, want.y, 0.01, what)
	else:
		var c := Vector2(float(piece.item.x), float(piece.item.y))
		var sp: Node2D = null
		for b in map.boulder_sprites:
			if b.centre_units.is_equal_approx(c):
				sp = b
		assert_not_null(sp, what)
		if sp == null:
			return
		var d := float(piece.item.diameter) * PX
		var bottom: float = (ISO * (c * PX)).y + d * sqrt(2.0) / 4.0 - h * PX
		assert_almost_eq(sp.ground_units, h, 0.001, what)
		assert_almost_eq(sp.box.end.y, bottom, 0.01, what)


func test_every_object_stands_at_the_height_of_what_it_stands_on_in_the_editor_and_the_run() -> void:
	var e := _editor()
	_heights_level(e)
	var placed: Array = []
	for spot in _spots():
		var p := _place(e, str(spot[0]), spot[1])
		assert_false(p.is_empty(), "%s on the %s at %s" % [spot[0], spot[2], spot[1]])
		if p.is_empty():
			continue
		var h: float = float(spot[3])
		if h < 0.0:
			# On the ramp: the slope's height under its centre, between its foot and its top.
			h = e.document.height_at(e.document.piece_rect(p).get_center())
			assert_true(h > 0.0 and h < 3.0, "%s on the ramp stands on the slope (%s)" % [spot[0], h])
		placed.append([p, h, "%s on the %s" % [spot[0], spot[2]]])
	for it in placed:
		_check_height(e.map, it[0], it[1], "editor: " + it[2])
	var run := _run_of(e, "t393_heights.json")
	for it in placed:
		_check_height(run.map, it[0], it[1], "run: " + it[2])


## The depth order against the rooftops: on the street behind the 3 (west of it, overlapping it on
## screen) under it, in front of it over it; on the 3 over the 3; on the 3 behind the 6 under the 6;
## on the 6 over both.
func _check_rooftop_depth(map: Node2D, where: String) -> void:
	var r3 := _area(map, "roof-1")
	var r6 := _area(map, "roof-2")
	assert_not_null(r3, where)
	assert_not_null(r6, where)
	var street_behind: Node2D = _prop_sprite(map, "prop-1")
	var street_front: Node2D = _prop_sprite(map, "prop-2")
	var on_3_behind_6: Node2D = _prop_sprite(map, "prop-3")
	var on_6: Node2D = _prop_sprite(map, "prop-4")
	assert_false(Geometry2D.intersect_polygons(r3.silhouette(), street_behind.outline).is_empty(), where + ": overlaps the 3")
	assert_lt(street_behind.z_index, r3.z_index, where + ": on the street behind the 3: under it")
	assert_gt(street_front.z_index, r3.z_index, where + ": on the street in front of the 3: over it")
	assert_gt(on_3_behind_6.z_index, r3.z_index, where + ": on the 3: over it")
	assert_false(Geometry2D.intersect_polygons(r6.silhouette(), on_3_behind_6.outline).is_empty(), where + ": overlaps the 6")
	assert_lt(on_3_behind_6.z_index, r6.z_index, where + ": on the 3 behind the 6: under the 6")
	assert_gt(on_6.z_index, r6.z_index, where + ": on the 6: over it")
	assert_gt(on_6.z_index, r3.z_index, where + ": on the 6: over the 3")


func test_objects_are_drawn_behind_or_in_front_of_rooftops_by_where_they_stand() -> void:
	var e := _editor()
	_heights_level(e)
	assert_false(_place(e, "prop-water-tank", Vector2(-66, -40)).is_empty(), "street, west of the 3")
	assert_false(_place(e, "prop-water-tank", Vector2(-40, -16)).is_empty(), "street, south of the 3")
	assert_false(_place(e, "prop-water-tank", Vector2(-56, -42)).is_empty(), "on the 3, west of the 6")
	assert_false(_place(e, "prop-water-tank", Vector2(-42, -42)).is_empty(), "on the 6")
	_check_rooftop_depth(e.map, "editor")
	_check_rooftop_depth(_run_of(e, "t393_depth.json").map, "run")


# ---- The edge proposal ----------------------------------------------------------------------------

func test_an_object_across_a_rooftop_or_ramp_edge_or_into_a_building_is_not_placed() -> void:
	var e := _editor()
	_heights_level(e)
	assert_false(_place(e, "short-0", Vector2(60, 40)).is_empty(), "a low-rise at x 60..72, y 40..52")
	for id in ["prop-barrier", "prop-water-tank", "boulder-a"]:
		# Across the 3's west edge (x -60), across the 6's west edge (x -50, on the 3), across the
		# ramp's west edge (x 40), into the low-rise.
		for at in [Vector2(-62, -40), Vector2(-52, -40), Vector2(38, -56), Vector2(58, 44)]:
			var before := e.document.placed_pieces().size()
			var p := _place(e, id, at)
			assert_true(p.is_empty(), "%s at %s is refused" % [id, at])
			assert_eq(e.document.placed_pieces().size(), before, "%s at %s: nothing added" % [id, at])
			assert_ne(e.last_problem, "", "%s at %s: the problem is named" % [id, at])
	# Touching an edge or a building is allowed: just west of the 3, just west of the low-rise.
	assert_false(_place(e, "prop-cones", Vector2(-62, -30)).is_empty(), "touching the 3's west edge")
	assert_false(_place(e, "prop-cones", Vector2(56, 44)).is_empty(), "touching the low-rise")


func test_a_building_rooftop_or_ramp_that_would_cut_through_an_object_is_not_placed() -> void:
	var e := _editor()
	var tank := _place(e, "prop-water-tank", Vector2(0, 0))  # x 0..4, y 0..4
	assert_false(tank.is_empty())
	var before := e.document.placed_pieces().size()
	assert_true(_place(e, "short-0", Vector2(-4, -4)).is_empty(), "a low-rise over the tank")
	assert_true(_place(e, "rooftop-3", Vector2(2, -10), Vector2(16, 16)).is_empty(), "a rooftop whose edge cuts the tank")
	assert_true(_place(e, "ramp-0-3", Vector2(-8, 2)).is_empty(), "a ramp whose edge cuts the tank")
	assert_eq(e.document.placed_pieces().size(), before, "nothing added")
	# A rooftop wholly over the tank lifts it to its height.
	assert_false(_place(e, "rooftop-3", Vector2(-10, -10), Vector2(16, 16)).is_empty(), "a rooftop over the tank")
	assert_almost_eq(_prop_sprite(e.map, str(tank.item.id)).ground_units, 3.0, 0.001)


# ---- As before where nothing was wrong ------------------------------------------------------------

func test_the_game_map_and_a_level_without_rooftops_draw_their_objects_on_the_ground_as_before() -> void:
	# The game's own map: every boulder on the ground, its sprite where it was before T-393 (its
	# bottom on the circle's front edge, not lifted).
	var map: Node2D = load("res://scenes/level/mvp_map.tscn").instantiate()
	add_child_autofree(map)
	map.set_view("iso")
	assert_gt(map.boulder_sprites.size(), 0)
	for sp in map.boulder_sprites:
		assert_eq(sp.ground_units, 0.0)
	for b in map.all_boulders():
		var d := float(b.diameter) * PX
		var bottom: float = (ISO * (Vector2(float(b.x), float(b.y)) * PX)).y + d * sqrt(2.0) / 4.0
		var r: Dictionary = map.boulder_sprite_rect(b, map.boulder_variant(b))
		assert_almost_eq((r.rect as Rect2).end.y, bottom, 0.01)
	# A level without rooftops: a barrier and a boulder on the street, on the ground, over everything.
	var e := _editor()
	_place(e, "prop-barrier", Vector2(0, 0))
	_place(e, "boulder-a", Vector2(10, 0))
	assert_eq(e.map.prop_sprites[0].ground_units, 0.0)
	assert_eq(e.map.boulder_sprites[0].ground_units, 0.0)
	assert_eq(e.map.prop_sprites[0].z_index, e.map.top_z_index(), "nothing covers it: over everything")
