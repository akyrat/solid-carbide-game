class_name SeeThroughBuilding
extends Node2D
## A placeholder isometric building (a plain coloured box) that turns see-through
## while the car is behind it on screen (task T-020, research demo).
##
## World space is the flat physics world (pixels, y down); the screen is the 2:1
## isometric projection screen = (x - y, (x + y) / 2) the drift prototype uses.
## The footprint is a world rectangle; the box rises `height_px` screen pixels.
##
## Rule ("approach A", see docs/visual-style/see-through-buildings.md):
## the car is behind the building when the car's x + y is smaller than the
## building's front corner (x1 + y1, the draw order), AND the car's drawn
## rectangle overlaps the building's on-screen silhouette. Then the building
## fades to `see_through_alpha`; otherwise back to 1.

enum Mode {
	## Fade the whole building (one alpha per building).
	FADE,
	## Cut a round hole around the car in the building (shader); the rest stays solid.
	CUTOUT,
}

const CUTOUT_SHADER := preload("res://scripts/level/see_through_cutout.gdshader")

@export var footprint := Rect2(0, 0, 96, 96)
@export var height_px := 120.0
@export var top_color := Color("3b3566")
@export var left_color := Color("1f1b3d")
@export var right_color := Color("2c2654")
@export var edge_color := Color("22d3ee")

## How see-through the building gets (1 = solid, 0 = invisible).
var see_through_alpha := 0.35
## Seconds for a full fade (0 = instant).
var fade_time := 0.15
var mode: Mode = Mode.FADE
## Radius (screen pixels) of the cut-out hole in CUTOUT mode.
var hole_radius := 40.0

var see_through := false
## The alpha the building is fading towards.
var target_alpha := 1.0
## The alpha it has now (1 = solid). In CUTOUT mode this is the hole's alpha.
var current_alpha := 1.0
var _shader_material: ShaderMaterial


static func iso(p: Vector2) -> Vector2:
	return Vector2(p.x - p.y, (p.x + p.y) / 2.0)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = draw_order()
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = CUTOUT_SHADER
	queue_redraw()


## Draw order: bigger = nearer to the viewer. The car uses its own x + y.
func draw_order() -> int:
	return int(footprint.end.x + footprint.end.y)


## The building's on-screen silhouette (a hexagon), in screen pixels.
func silhouette() -> PackedVector2Array:
	var a := iso(footprint.position)
	var b := iso(Vector2(footprint.end.x, footprint.position.y))
	var c := iso(footprint.end)
	var d := iso(Vector2(footprint.position.x, footprint.end.y))
	var up := Vector2(0, -height_px)
	return PackedVector2Array([a + up, b + up, b, c, d, d + up])


## True when the car (world position, drawn corners in world space) is behind
## the building and its drawn rectangle overlaps the building on screen.
func occludes(car_world: Vector2, car_corners_world: PackedVector2Array) -> bool:
	if car_world.x + car_world.y >= footprint.end.x + footprint.end.y:
		return false
	var car_screen := PackedVector2Array()
	for p in car_corners_world:
		car_screen.append(iso(p))
	return not Geometry2D.intersect_polygons(silhouette(), car_screen).is_empty()


## Decides the target and moves the fade by `delta` seconds. Returns see_through.
func update_fade(car_world: Vector2, car_corners_world: PackedVector2Array, delta: float) -> bool:
	see_through = occludes(car_world, car_corners_world)
	target_alpha = see_through_alpha if see_through else 1.0
	if fade_time <= 0.0:
		current_alpha = target_alpha
	else:
		current_alpha = move_toward(current_alpha, target_alpha, delta / fade_time * (1.0 - see_through_alpha))
	_apply(car_world)
	return see_through


func _apply(car_world: Vector2) -> void:
	if mode == Mode.FADE:
		material = null
		modulate.a = current_alpha
	else:
		modulate.a = 1.0
		if _shader_material == null:
			_shader_material = ShaderMaterial.new()
			_shader_material.shader = CUTOUT_SHADER
		material = _shader_material
		_shader_material.set_shader_parameter("hole_center", iso(car_world))
		_shader_material.set_shader_parameter("hole_radius", hole_radius)
		_shader_material.set_shader_parameter("hole_alpha", current_alpha)


func _draw() -> void:
	var a := iso(footprint.position)
	var b := iso(Vector2(footprint.end.x, footprint.position.y))
	var c := iso(footprint.end)
	var d := iso(Vector2(footprint.position.x, footprint.end.y))
	var up := Vector2(0, -height_px)
	draw_colored_polygon(PackedVector2Array([d, c, c + up, d + up]), left_color)
	draw_colored_polygon(PackedVector2Array([c, b, b + up, c + up]), right_color)
	draw_colored_polygon(PackedVector2Array([a + up, b + up, c + up, d + up]), top_color)
	# Plain edge lines so the box reads as a box.
	for loop in [[a + up, b + up, c + up, d + up, a + up], [d, c, b], [d, d + up], [c, c + up], [b, b + up]]:
		draw_polyline(PackedVector2Array(loop), edge_color, 1.0)
