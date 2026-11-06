extends Node2D
## The rails' placeholder drawing (task T-541, a prototype; the format: rails.gd): each rail is
## a metal bar at its height in the isometric view, on thin posts down to the ground, with a dark
## shadow line on the street under it. Drawn in code, no art (a placeholder until the board asks
## for art).
##
## Use: build(map, rails, height_at, depth_for). It adds itself to the map's view (map.view_root)
## and makes:
##  - one shadow node right after the ground tiles (as the drift marks), so the shadow lies on
##    the street under the buildings, boulders and the car;
##  - one node per piece of each rail, PIECE_UNITS long at most, each with its own z_index from
##    `depth_for` (the elevation layer's z_for at the piece's middle and height, minus one), so
##    the bar goes under the buildings and rooftops in front of it and over the rest, like the
##    car at that height. The car on the rail is drawn over it.
## update_for_car(): the pieces just in front of a car below the bar (on the street, passing
## under it) are drawn over the car; otherwise the car is drawn over the bar.
##
## The map's view carries the isometric projection; each node here undoes it (its transform is
## the projection's inverse), so the drawing is in screen pixels: crisp 1-pixel lines.

const Rails := preload("res://scripts/level/rails.gd")
const MvpMapScript := preload("res://scripts/level/mvp_map.gd")

const ISO_TRANSFORM := MvpMapScript.ISO_TRANSFORM
const PX_PER_UNIT := MvpMapScript.PX_PER_UNIT

## The longest piece a rail is cut into for the depth order, units.
const PIECE_UNITS := 2.0
## A post under the bar every this many units (and at both ends).
const POST_UNITS := 6.0
## The bar's three pixel rows, top to bottom: highlight, body, underside (cool greys, a metal
## bar; no Greenbull colours).
const BAR_COLORS := [Color(0.86, 0.88, 0.92), Color(0.58, 0.61, 0.67), Color(0.30, 0.31, 0.36)]
const POST_COLOR := Color(0.24, 0.25, 0.29)
## The shadow on the ground: a dark line, half see-through.
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.38)
const SHADOW_WIDTH_PX := 3.0
## A piece is drawn over a car below it when the car is within this many units of its middle.
const NEAR_CAR_UNITS := 3.0

var rails: Array = []
## Every piece node, in rail order: _Piece.
var pieces: Array = []
var shadows: Node2D


## The screen pixel of map point `u` (units) at height `h` (units) in the map's view.
static func screen_of(u: Vector2, h: float) -> Vector2:
	return ISO_TRANSFORM * (u * PX_PER_UNIT) + Vector2(0.0, -h * PX_PER_UNIT)


## Builds the drawing of `the_rails` (Rails.from_layout) in `map`'s view. height_at(units) ->
## the ground's height there (none: the street, 0); depth_for(units, rot, height) -> the car's
## z_index there (none: every piece at z 0).
func build(map: Node2D, the_rails: Array, height_at := Callable(), depth_for := Callable()) -> void:
	rails = the_rails
	name = "Rails"
	map.view_root.add_child(self)
	shadows = _Shadows.new()
	shadows.name = "RailShadows"
	shadows.transform = ISO_TRANSFORM.affine_inverse()
	map.view_root.add_child(shadows)
	if map.get("ground_tiles") != null:
		map.view_root.move_child(shadows, map.ground_tiles.get_index() + 1)
	for r in rails:
		var n := maxi(1, ceili(float(r.length) / PIECE_UNITS))
		var rot := atan2(r.dir.y, r.dir.x)
		var post_at := post_places(float(r.length))
		var k := 0
		# T-542 round 2: the shadow on the street is one line per run of pieces over the street; a piece
		# over a ramp or a rooftop draws its own shadow on that surface (_Piece.shadow), at its depth.
		var run_from := -1.0
		for i in n:
			var s0 := float(r.length) * float(i) / float(n)
			var s1 := float(r.length) * float(i + 1) / float(n)
			var p := _Piece.new()
			p.transform = ISO_TRANSFORM.affine_inverse()
			p.rail_id = str(r.id)
			p.mid = Rails.point_at(r, (s0 + s1) / 2.0)
			p.mid_height = Rails.height_at(r, (s0 + s1) / 2.0)
			p.from = screen_of(Rails.point_at(r, s0), Rails.height_at(r, s0))
			p.to = screen_of(Rails.point_at(r, s1), Rails.height_at(r, s1))
			while k < post_at.size() and float(post_at[k]) <= s1 + 1e-6:
				var at := Rails.point_at(r, float(post_at[k]))
				p.posts.append([screen_of(at, Rails.height_at(r, float(post_at[k]))), screen_of(at, _ground(height_at, at))])
				k += 1
			var g0 := _ground(height_at, Rails.point_at(r, s0))
			var g1 := _ground(height_at, Rails.point_at(r, s1))
			var gm := _ground(height_at, p.mid)
			if maxf(g0, maxf(g1, gm)) > 0.001:
				p.shadow = [screen_of(Rails.point_at(r, s0), g0), screen_of(Rails.point_at(r, s1), g1)]
				if run_from >= 0.0:
					shadows.lines.append([screen_of(Rails.point_at(r, run_from), 0.0), screen_of(Rails.point_at(r, s0), 0.0)])
					run_from = -1.0
			elif run_from < 0.0:
				run_from = s0
			if depth_for.is_valid():
				p.base_z = int(depth_for.call(p.mid, rot, p.mid_height)) - 1
			p.z_index = p.base_z
			add_child(p)
			pieces.append(p)
		if run_from >= 0.0:
			shadows.lines.append([screen_of(Rails.point_at(r, run_from), 0.0), screen_of(r.b, 0.0)])
	shadows.queue_redraw()


## Where a rail of `length` units has its posts (units from its end a): every POST_UNITS from
## 0, and one at the far end (unless a post is already within a unit of it).
static func post_places(length: float) -> Array:
	var out: Array = []
	var s := 0.0
	while s <= length + 1e-6:
		out.append(s)
		s += POST_UNITS
	if length - float(out[-1]) > 1.0:
		out.append(length)
	return out


static func _ground(height_at: Callable, u: Vector2) -> float:
	return float(height_at.call(u)) if height_at.is_valid() else 0.0


## Each physics step (the run): pieces just in front of the car (nearer the viewer, within
## NEAR_CAR_UNITS) while the car is below the bar go one over the car's z_index `car_z`; every
## other piece keeps its own depth.
func update_for_car(units: Vector2, height: float, car_z: int) -> void:
	var depth := units.x + units.y
	for p in pieces:
		var z: int = p.base_z
		if height < p.mid_height - 0.3 and p.mid.x + p.mid.y > depth \
				and p.mid.distance_to(units) < NEAR_CAR_UNITS:
			z = maxi(z, car_z + 1)
		if p.z_index != z:
			p.z_index = z


class _Piece extends Node2D:
	var rail_id := ""
	## The piece's middle (units) and the bar's height there.
	var mid := Vector2.ZERO
	var mid_height := 0.0
	## The bar's ends on screen (pixels) and its posts: [[top, foot], ...].
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var posts: Array = []
	## The shadow on the ground under the piece when that is a ramp or a rooftop: [from, to] pixels, or [].
	var shadow: Array = []
	var base_z := 0

	func _draw() -> void:
		if shadow.size() == 2:
			draw_line((shadow[0] as Vector2).floor(), (shadow[1] as Vector2).floor(), SHADOW_COLOR, SHADOW_WIDTH_PX, false)
		for post in posts:
			var top: Vector2 = (post[0] as Vector2).floor()
			var foot: Vector2 = (post[1] as Vector2).floor()
			draw_line(top, foot, POST_COLOR, 2.0, false)
		var a := from.floor()
		var b := to.floor()
		for row in BAR_COLORS.size():
			var off := Vector2(0.0, float(row) - 1.0)
			draw_line(a + off, b + off, BAR_COLORS[row], 1.0, false)


class _Shadows extends Node2D:
	## [[from, to], ...] on screen (pixels), on the ground under each rail.
	var lines: Array = []

	func _draw() -> void:
		for l in lines:
			draw_line((l[0] as Vector2).floor(), (l[1] as Vector2).floor(), SHADOW_COLOR, SHADOW_WIDTH_PX, false)
