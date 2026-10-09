class_name SeeThroughDemo
extends Node2D
## Research demo for task T-020: flat ground, a few placeholder boxes drawn
## isometrically and a stand-in car you drive with the keyboard (the existing
## car_accelerate / car_reverse / car_steer_* keys: W S A D). Buildings fade
## when the car is behind them. Not the real map (task T-019).

const CarSprite := preload("res://scripts/driving/car_sprite.gd")
const CAR_SIZE := Vector2(48, 16)  # world pixels: 3 units long, 1 unit wide

## World position and heading (radians) of the car.
@export var car_world := Vector2(120, 40)
@export var car_heading := 0.0
@export var drive_speed := 128.0  # world px per second (8 units)
@export var turn_speed := 2.5
@export var keyboard := true
@export var see_through_alpha := 0.35
@export var fade_time := 0.15
@export var mode: SeeThroughBuilding.Mode = SeeThroughBuilding.Mode.FADE

var buildings: Array[SeeThroughBuilding] = []
var car_sprite: Sprite2D


func _ready() -> void:
	# The world's origin sits in the middle of the window.
	position = Vector2(576, 330)
	_make_ground()
	for rect in [Rect2(-40, -200, 96, 96), Rect2(120, -120, 96, 96), Rect2(-120, 40, 96, 96), Rect2(160, 100, 80, 120)]:
		var b := SeeThroughBuilding.new()
		b.footprint = rect
		add_child(b)
		buildings.append(b)
	car_sprite = CarSprite.new()
	add_child(car_sprite)
	car_sprite.use_sheet("iso")
	car_sprite.world_px_per_unit = 16.0
	_refresh()
	_update_buildings(0.0)


func _make_ground() -> void:
	var ground := Node2D.new()
	ground.z_index = -4000
	ground.draw.connect(func() -> void:
		var corners := PackedVector2Array()
		for p in [Vector2(-320, -320), Vector2(320, -320), Vector2(320, 320), Vector2(-320, 320)]:
			corners.append(SeeThroughBuilding.iso(p))
		ground.draw_colored_polygon(corners, Color("15122b"))
		for i in range(-320, 321, 32):
			ground.draw_line(SeeThroughBuilding.iso(Vector2(i, -320)), SeeThroughBuilding.iso(Vector2(i, 320)), Color("231f45"), 1.0)
			ground.draw_line(SeeThroughBuilding.iso(Vector2(-320, i)), SeeThroughBuilding.iso(Vector2(320, i)), Color("231f45"), 1.0)
	)
	add_child(ground)


## The car's drawn rectangle, as four world-space corners.
func car_corners() -> PackedVector2Array:
	var out := PackedVector2Array()
	var xf := Transform2D(car_heading, car_world)
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		out.append(xf * (c * CAR_SIZE / 2.0))
	return out


func _refresh() -> void:
	car_sprite.position = SeeThroughBuilding.iso(car_world)
	car_sprite.set_heading(car_heading)
	car_sprite.z_index = int(car_world.x + car_world.y)


func _update_buildings(delta: float) -> void:
	var corners := car_corners()
	for b in buildings:
		b.see_through_alpha = see_through_alpha
		b.fade_time = fade_time
		b.mode = mode
		b.update_fade(car_world, corners, delta)


func _process(delta: float) -> void:
	if keyboard:
		var steer := Input.get_axis("car_steer_left", "car_steer_right")
		var drive := Input.get_axis("car_reverse", "car_accelerate")
		car_heading += steer * turn_speed * delta
		car_world += Vector2.from_angle(car_heading) * drive * drive_speed * delta
	_refresh()
	_update_buildings(delta)
