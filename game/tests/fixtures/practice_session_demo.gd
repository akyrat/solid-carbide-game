extends Control
## Screenshot fixture for task T-561: the practice session (scenes/run/practice_session.tscn) in a
## window-sized SubViewport on a dark page, as the tutorial slide (T-562) will embed it. The env
## var PRACTICE_SHOT picks what it shows:
##   drift, alt_drift: the car drifting (scripted W + A), the goal at 1/3 (alt drift 2/3);
##   air_spin: the car driven off the jump ramp, turning in the air, the goal at 1/3;
##   grind_gift: the grind practice's start, the Jump gift on show;
##   grind: Jump taken, the car hopped onto the rail and grinding;
##   done: the drift goal at 3/3, ticked.
## Run: PRACTICE_SHOT=drift bash game/tools/screenshot.sh res://tests/fixtures/practice_session_demo.tscn out.png 60

const SessionScene := preload("res://scenes/run/practice_session.tscn")
const WINDOW_POS := Vector2(224, 104)
const WINDOW_SIZE := Vector2i(704, 440)

var session: PracticeSession
var shot := "drift"


func _ready() -> void:
	shot = OS.get_environment("PRACTICE_SHOT")
	if shot == "":
		shot = "drift"
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.09)
	bg.size = Vector2(1152, 648)
	add_child(bg)
	var frame := ColorRect.new()
	frame.color = Color(0.85, 0.35, 0.65)
	frame.position = WINDOW_POS - Vector2(4, 4)
	frame.size = Vector2(WINDOW_SIZE) + Vector2(8, 8)
	add_child(frame)
	var box := SubViewportContainer.new()
	box.position = WINDOW_POS
	box.size = Vector2(WINDOW_SIZE)
	box.stretch = true
	add_child(box)
	var vp := SubViewport.new()
	vp.size = WINDOW_SIZE
	box.add_child(vp)
	session = SessionScene.instantiate()
	session.trick = {"drift": "drift", "alt_drift": "alt_drift", "air_spin": "air_spin",
		"grind_gift": "grind", "grind": "grind", "done": "drift"}.get(shot, "drift")
	vp.add_child(session)
	session.start()
	session.set_focused(true)
	var car = session.car
	car.use_keyboard = false
	match shot:
		"drift", "done":
			car.scripted_input = [true, false, 1.0]
			for i in (3 if shot == "done" else 1):
				session.state.add_trick("extended_drift", 1.5)
		"alt_drift":
			car.scripted_input = [true, false, 1.0]
			session.state.add_trick("alternate_drift")
			session.state.add_trick("alternate_drift")
		"air_spin":
			session.state.add_trick("air_one_eighty")
			_drive_east(true, false, func() -> bool: return car.airborne and car.model.get_position().x > 14.0, 25)
		"grind":
			session.gift_screen.skip_animation()
			session.take_gift()
			_drive_east(false, true, func() -> bool: return car.grind.active, 25)


## T-560's drive from the start point, stepped here (the screenshot tool's physics runs slowly):
## W held, A in the air when `spin`, Space held in the air when `hold_space`, both past the ramp
## (x > 11); `extra` steps after `reached` is first true, then the car stops (frozen for the shot).
func _drive_east(spin: bool, hold_space: bool, reached: Callable, extra: int) -> void:
	var car = session.car
	var left := -1
	for i in 900:
		var in_air: bool = car.airborne
		var past: bool = car.model.get_position().x > 11.0
		car.scripted_input = [true, false, 1.0 if (spin and in_air and past) else 0.0]
		car.scripted_jump_held = hold_space and (in_air or car.grind.active) and past
		car.physics_step()
		if left < 0 and reached.call():
			left = extra
		if left == 0:
			break
		if left > 0:
			left -= 1
	car.set_physics_process(false)
