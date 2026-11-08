extends Node2D
## Task T-580 fixture (investigation only; nothing here is in the game): drives one of the cases in
## tests/helpers/facing_travel_probe.gd with the game's own driving model and the real isometric
## car sprite (car_sprite.gd, the run's 2:1 projection), one physics step per rendered frame, and
## draws on top, in this fixture only:
## - a GREEN arrow: where the car's body points (its heading, projected to the screen);
## - an ORANGE arrow: where it actually moves (its velocity, projected);
## - a thin trail of where it has been, and a line of numbers (angles in degrees).
## The sprite is what the player sees; compare its nose with both arrows.
##
## The case comes from the environment variable T580_CASE (a case name; default
## coast_turn_onto_screen_up_right). Record it, one physics step per frame:
##   T580_CASE=<name> "$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/t580_facing_demo.tscn
## then assemble with game/tools/frames_to_gif.py. The scene quits when the case ends.
## Task T-583: T583_COMBO picks the fixes measured, "none" (default, T-580's state), "A" (the frame
## remap), "C" (the grip outside a drift) or "AC" (game/tools/record_t583_facing.sh).

const Probe := preload("res://tests/helpers/facing_travel_probe.gd")
const CarSpriteScript := preload("res://scripts/driving/car_sprite.gd")
const CarFacing := preload("res://scripts/driving/car_facing.gd")
const PX := 16.0
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const GREEN := Color(0.24, 0.9, 0.35)
const ORANGE := Color(1.0, 0.58, 0.12)

var probe
var model
var case_data := {}
var phases: Array = []
var phase := 0
var step_in_phase := 0
var steps_done := 0
var record := {}
var trail: Array = []
var sprite: Sprite2D
var camera: Camera2D
var overlay: Node2D
var label: Label
var done := false
## The keys of the step just taken (for the label).
var keys_text := "-"
var combo := "none"


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.16, 0.17, 0.2))
	# The fixture places everything itself each frame: no smoothing between physics steps.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	probe = Probe.new()
	combo = OS.get_environment("T583_COMBO")
	if combo == "":
		combo = "none"
	probe.set_combo(combo)
	CarFacing.remap_override = probe.remap
	var want := OS.get_environment("T580_CASE")
	if want == "":
		want = "coast_turn_onto_screen_up_right"
	for c in Probe.cases():
		if c.name == want:
			case_data = c
	# Also "straight_screen_<deg>": W held 2 s straight along that screen angle (the art alone).
	if case_data.is_empty() and want.begins_with("straight_screen_"):
		var deg := float(want.trim_prefix("straight_screen_"))
		case_data = {"name": want, "start": Probe.world_heading_for_screen(deg),
			"phases": [[100, true, false, 0.0]]}
	if case_data.is_empty():
		push_error("t580_facing_demo: unknown case %s" % want)
		get_tree().quit(1)
		return
	phases = case_data.phases
	model = probe.car(float(case_data.start))
	record = probe.sample(model, 0.0)
	sprite = CarSpriteScript.new()
	sprite.world_px_per_unit = PX
	sprite.use_sheet("iso")
	add_child(sprite)
	overlay = Node2D.new()
	overlay.z_index = 10
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	camera = Camera2D.new()
	camera.zoom = Vector2(3.2, 3.2)
	add_child(camera)
	var hud := CanvasLayer.new()
	add_child(hud)
	label = Label.new()
	label.position = Vector2(12, 8)
	label.add_theme_font_size_override("font_size", 16)
	hud.add_child(label)
	_sync()


func _process(_delta: float) -> void:
	if done or model == null:
		return
	if phase >= phases.size():
		done = true
		get_tree().quit()
		return
	var ph: Array = phases[phase]
	model.step(bool(ph[1]), bool(ph[2]), float(ph[3]))
	keys_text = _keys_text()
	steps_done += 1
	record = probe.sample(model, steps_done * model.dt)
	step_in_phase += 1
	if step_in_phase >= int(ph[0]):
		phase += 1
		step_in_phase = 0
	_sync()


func _combo_text() -> String:
	return {"none": "NONE (before)", "A": "A (frame remap)", "C": "C (grip)", "AC": "A+C (after)"}.get(combo, combo)


func _exit_tree() -> void:
	CarFacing.remap_override = null


func _keys_text() -> String:
	if phase >= phases.size():
		return "-"
	var ph: Array = phases[phase]
	var k := []
	if ph[1]:
		k.append("W")
	if ph[2]:
		k.append("S")
	if float(ph[3]) > 0.0:
		k.append("A")
	elif float(ph[3]) < 0.0:
		k.append("D")
	return "+".join(k) if not k.is_empty() else "none (coasting)"


func _sync() -> void:
	var p: Vector2 = ISO * (model.get_position() * PX)
	sprite.position = p
	sprite.set_heading(model.rotation)
	camera.position = p
	trail.append(p)
	if trail.size() > 400:
		trail.pop_front()
	label.text = "fixes: %s   case %s  t=%.2f s  keys held: %s\nspeed %.1f   world: nose %.0f, travel %.0f, gap %+.0f\nscreen: nose %.0f, travel %.0f, gap %+.0f\nsprite frame %d, its drawing points at %.0f: %+.0f from the travel\nGREEN = where the body points   ORANGE = where it moves   WHITE = where the drawing's nose points" % [
		_combo_text(), case_data.name, record.t, keys_text, record.speed, record.heading, record.travel,
		record.world_gap, record.screen_heading, record.screen_travel, record.screen_gap,
		record.frame, record.art_screen, record.drawn_gap]
	overlay.queue_redraw()


func _arrow(from: Vector2, deg: float, length: float, colour: Color, width: float) -> void:
	var d := Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg)))
	var tip := from + d * length
	overlay.draw_line(from, tip, Color(0, 0, 0, 0.8), width + 2.0)
	overlay.draw_line(from, tip, colour, width)
	for side in [150.0, -150.0]:
		var h := d.rotated(deg_to_rad(side))
		overlay.draw_line(tip, tip + h * 9.0, colour, width)


func _draw_overlay() -> void:
	# A light isometric grid of world units every 4 units, so the world's axes show.
	var c: Vector2 = model.get_position()
	var g0 := Vector2(floorf(c.x / 4.0) * 4.0, floorf(c.y / 4.0) * 4.0)
	for i in range(-12, 13):
		var a: Vector2 = ISO * ((g0 + Vector2(i * 4.0, -48.0)) * PX)
		var b: Vector2 = ISO * ((g0 + Vector2(i * 4.0, 48.0)) * PX)
		overlay.draw_line(a, b, Color(1, 1, 1, 0.07), 1.0)
		a = ISO * ((g0 + Vector2(-48.0, i * 4.0)) * PX)
		b = ISO * ((g0 + Vector2(48.0, i * 4.0)) * PX)
		overlay.draw_line(a, b, Color(1, 1, 1, 0.07), 1.0)
	if trail.size() > 1:
		overlay.draw_polyline(PackedVector2Array(trail), Color(1, 1, 1, 0.35), 1.5)
	var p: Vector2 = sprite.position
	_arrow(p, float(record.screen_heading), 70.0, GREEN, 3.0)
	if float(record.speed) > 0.05:
		_arrow(p, float(record.screen_travel), 55.0, ORANGE, 3.0)
	_arrow(p, float(record.art_screen), 40.0, Color(1, 1, 1, 0.9), 2.0)
