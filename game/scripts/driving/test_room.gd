extends Node2D
## The drift prototype's test room (task T-033): a few walls and one boulder,
## so the board can try the car's bounce. Not the game's map (that is the MVP
## map, task T-019).
##
## Like the MVP map, the obstacles are static bodies on collision layer 1 in
## the flat physics world (build_bodies puts them under the prototype's
## PhysicsWorld), and this node draws them; the prototype gives it the
## isometric transform in the isometric view, as it does the ground.
##
## Positions are in units from the car's start point (x right, y down). The
## room is far enough out that the prototype's scripted drives (the tests and
## the screenshot demo) never reach it.

const Car := preload("res://scripts/driving/car.gd")

## The outer walls: a closed square, inside faces ROOM_HALF units from the start.
const ROOM_HALF := 40.0
const OUTER_WALL_THICKNESS := 2.0
## Inside walls: an L to the car's right, rect = [x, y, width, height] in units.
const INNER_WALLS := [[6.0, -25.0, 20.0, 1.0], [25.0, -24.0, 1.0, 28.0]]
## The boulder: 3 units across, at this centre (units).
const BOULDER_CENTRE := Vector2(12.0, -12.0)
const BOULDER_DIAMETER := 3.0

## Placeholder colours, the MVP map's building and boulder colours.
var wall_color := Color(0.22, 0.15, 0.38)
var wall_edge_color := Color(0.45, 0.30, 0.70)
var boulder_color := Color(0.13, 0.12, 0.15)
var boulder_edge_color := Color(0.95, 0.45, 0.25)

var px_per_unit := Car.PX_PER_UNIT
var walls_body: StaticBody2D
var boulder_body: StaticBody2D


## Every wall rectangle in units: the four outer walls, then the inside walls.
static func wall_rects() -> Array[Rect2]:
	var h := ROOM_HALF
	var t := OUTER_WALL_THICKNESS
	var out: Array[Rect2] = [
		Rect2(-h - t, -h - t, 2.0 * (h + t), t),  # top
		Rect2(-h - t, h, 2.0 * (h + t), t),       # bottom
		Rect2(-h - t, -h, t, 2.0 * h),            # left
		Rect2(h, -h, t, 2.0 * h),                 # right
	]
	for r in INNER_WALLS:
		out.append(Rect2(r[0], r[1], r[2], r[3]))
	return out


## Adds the walls' and the boulder's static bodies (layer 1) to parent.
func build_bodies(parent: Node) -> void:
	var u := px_per_unit
	walls_body = StaticBody2D.new()
	walls_body.name = "TestRoomWalls"
	walls_body.collision_layer = Car.LAYER_OBSTACLES
	walls_body.collision_mask = 0
	parent.add_child(walls_body)
	var i := 0
	for r in wall_rects():
		var shape := RectangleShape2D.new()
		shape.size = r.size * u
		var cs := CollisionShape2D.new()
		cs.name = "Wall%d" % (i + 1)
		cs.shape = shape
		cs.position = r.get_center() * u
		walls_body.add_child(cs)
		i += 1
	boulder_body = StaticBody2D.new()
	boulder_body.name = "TestRoomBoulder"
	boulder_body.collision_layer = Car.LAYER_OBSTACLES
	boulder_body.collision_mask = 0
	parent.add_child(boulder_body)
	var circle := CircleShape2D.new()
	circle.radius = BOULDER_DIAMETER / 2.0 * u
	var bcs := CollisionShape2D.new()
	bcs.name = "Boulder"
	bcs.shape = circle
	bcs.position = BOULDER_CENTRE * u
	boulder_body.add_child(bcs)
	queue_redraw()


func _draw() -> void:
	var u := px_per_unit
	for r in wall_rects():
		var pr := Rect2(r.position * u, r.size * u)
		draw_rect(pr, wall_color)
		draw_rect(pr, wall_edge_color, false, 2.0)
	var c := BOULDER_CENTRE * u
	var rad := BOULDER_DIAMETER / 2.0 * u
	draw_circle(c, rad, boulder_color)
	draw_arc(c, rad - 1.0, 0.0, TAU, 32, boulder_edge_color, 2.0)
