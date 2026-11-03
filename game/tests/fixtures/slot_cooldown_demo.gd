extends Node2D
## T-528 screenshots: the HUD's power-up slots with a Polarized Steering Wheel (and Jump)
## whose cooldown is a stub; the fraction left comes from the SLOT_COOLDOWN environment
## variable (1 = spent, 0.5 = half, 0 = ready).

class StubWheel extends RefCounted:
	signal ready_again
	var left := 0.0
	func cooldown_fraction_left() -> float:
		return left


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(60, 90, 70)
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var layer := CanvasLayer.new()
	add_child(layer)
	var hud: Hud = preload("res://scenes/hud/hud.tscn").instantiate()
	layer.add_child(hud)
	var state := RunState.new()
	hud.bind(state)
	var stub := StubWheel.new()
	stub.left = float(OS.get_environment("SLOT_COOLDOWN")) if OS.get_environment("SLOT_COOLDOWN") != "" else 0.0
	hud.weapon_icons.bind_cooldown("polarized_steering_wheel", stub)
	state.set_power_up_tier("jump", 1)
	state.set_power_up_tier("polarized_steering_wheel", 1)
	set_meta("stub", stub)
