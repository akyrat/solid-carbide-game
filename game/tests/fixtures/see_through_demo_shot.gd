extends Node
## Screenshot fixture for task T-020: the see-through demo with the car parked
## at a given world position, no keyboard. Set the exports in a .tscn.

@export var car_world := Vector2(120, 40)
@export var car_heading := 0.0
@export var see_through_alpha := 0.35
@export var mode := 0


func _ready() -> void:
	var demo := preload("res://scripts/level/see_through_demo.gd").new()
	demo.keyboard = false
	demo.car_world = car_world
	demo.car_heading = car_heading
	demo.see_through_alpha = see_through_alpha
	demo.fade_time = 0.0
	demo.mode = mode
	add_child(demo)
