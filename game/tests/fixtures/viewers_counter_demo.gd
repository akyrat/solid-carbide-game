extends "res://tests/fixtures/run_elevation_demo.gd"
## Screenshot fixture (task T-336): a run from the main menu with the car standing
## still, and the live viewers counter at the bottom right. VIEWERS_DEMO_MODE picks:
##
## - "stills": saves VIEWERS_PNG_PREFIX + "_<look>.png" for the base look (x1), the
##   heat steps (x2, x3, x4.5) and the fire (x6), then quits;
## - "trick" (for a GIF, --write-movie): three alternate drifts, 1.1 s apart, each
##   "+viewers" flying from its popup into the counter;
## - "crash" (for a GIF): a combo at about x4, then a crash at 1.0 s: the counter
##   flashes red, "-{viewers}" drops away and the number falls.
## Run it windowed at 1152 x 648.

var _mode := ""
var _t := 0.0
var _events: Array = []


func _ready() -> void:
	drive_steps = 1
	hold_w = false
	_mode = OS.get_environment("VIEWERS_DEMO_MODE")
	await super._ready()
	match _mode:
		"stills":
			_stills()
		"trick":
			_events = [[0.4, "trick"], [1.5, "trick"], [2.6, "trick"]]
		"crash":
			for i in 6:
				run.state.add_trick("alternate_drift")
			_land_all()
			_events = [[1.0, "crash"]]


## Lands every amount in flight and settles the number (for stills and set-ups).
func _land_all() -> void:
	var c: ViewersCounter = run.hud.viewers_counter
	for p in run.trick_popups.popups():
		p.queue_free()
		c.release(p.viewers_gain)
	for f in c.flights.duplicate():
		f.advance(10.0)
	for i in 600:
		c.advance(1.0 / 60.0)


func _process(delta: float) -> void:
	super._process(delta)
	if _mode == "stills" or run == null:
		return
	_t += delta
	while not _events.is_empty() and _t >= float(_events[0][0]):
		var e: Array = _events.pop_front()
		if e[1] == "trick":
			run.state.add_trick("alternate_drift")
		elif e[1] == "crash":
			run.state.collision()


func _stills() -> void:
	for i in 20:
		await get_tree().process_frame
	var prefix := OS.get_environment("VIEWERS_PNG_PREFIX")
	for pair in [[1.0, "base"], [2.0, "step1"], [3.0, "step2"], [4.5, "step3"], [6.0, "fire"]]:
		run.state._set_combo(pair[0])
		_land_all()
		for i in 7:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(prefix + "_" + pair[1] + ".png")
	get_tree().quit()
