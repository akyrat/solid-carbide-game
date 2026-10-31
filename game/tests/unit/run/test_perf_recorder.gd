extends GutTest
## Task T-468: the run's performance recorder (perf_recorder.gd). Off by default: no recorder,
## no files. On: a short run writes frames.csv (frame times, Godot's monitors, the run's
## counts, the zones), markers, and trace.json in Chrome's trace format with every begin
## matched by its end, nested; spikes keep the frames around them in full detail.

const RunScene := preload("res://scenes/run/run.tscn")
const DIR := "user://test_perf_recordings"


func before_each() -> void:
	_remove_dir(ProjectSettings.globalize_path(DIR))
	PerfRecorder.dir_override = DIR


func after_each() -> void:
	PerfRecorder.enabled_override = 0
	PerfRecorder.dir_override = ""
	Perf.on = false
	Perf.reset()
	get_tree().paused = false
	_remove_dir(ProjectSettings.globalize_path(DIR))


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var d := DirAccess.open(path)
	d.include_hidden = true
	for f in d.get_files():
		DirAccess.remove_absolute(path.path_join(f))
	for sub in d.get_directories():
		_remove_dir(path.path_join(sub))
	DirAccess.remove_absolute(path)


func _start_run() -> Node2D:
	var run: Node2D = RunScene.instantiate()
	add_child(run)
	return run


func _stop_run(run: Node2D) -> void:
	remove_child(run)
	run.free()


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	assert_not_null(f, "can read " + path)
	return f.get_as_text() if f != null else ""


## Returns "" when every B has its E, nested (same name, last opened first closed), with
## times that never go back; else what is wrong.
static func trace_problem(events: Array) -> String:
	var stack: Array = []
	var last_ts := -INF
	for e in events:
		var ph: String = e.get("ph", "")
		if ph != "B" and ph != "E":
			continue
		var ts: float = e.ts
		if ts < last_ts:
			return "time goes back at %s" % e
		last_ts = ts
		if ph == "B":
			stack.append(e)
		else:
			if stack.is_empty():
				return "an end with no begin: %s" % e
			var b: Dictionary = stack.pop_back()
			if b.name != e.name:
				return "%s ends while %s is open" % [e.name, b.name]
			if ts < float(b.ts):
				return "%s ends before it begins" % e.name
	if not stack.is_empty():
		return "%d zones never end" % stack.size()
	return ""


func test_off_by_default_no_recorder_and_no_files() -> void:
	PerfRecorder.enabled_override = -1
	assert_false(PerfRecorder.is_enabled(), "off without --record-perf or SC_RECORD_PERF")
	PerfRecorder.enabled_override = 0
	var run := _start_run()
	await wait_physics_frames(10)
	assert_null(run.get_node_or_null("PerfRecorder"))
	assert_false(Perf.on)
	assert_eq(Perf.events.size(), 0, "zones cost nothing and keep nothing")
	_stop_run(run)
	assert_false(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(DIR)), "no folder written")


func test_on_a_run_writes_frames_monitors_counts_zones_markers_and_a_trace() -> void:
	PerfRecorder.enabled_override = 1
	var run := _start_run()
	var rec: PerfRecorder = run.get_node("PerfRecorder")
	assert_not_null(rec)
	assert_true(rec.is_recording())
	rec.spike_ms = 0.0  # every frame is a spike: all of them in full detail
	run.minions.rng.seed = 468
	var car_units: Vector2 = run.car.position / 16.0
	for k in 6:
		run.minions.spawn_minion_at(car_units + Vector2(6, 0).rotated(k * TAU / 6.0))
	await wait_physics_frames(20)
	run.state.add_xp(run.state.xp_needed())  # a level-up: a marker
	await wait_physics_frames(10)
	var folder := rec.folder
	_stop_run(run)
	assert_false(Perf.on, "off once the run is gone")
	# frames.csv
	var lines: Array = Array(_read(folder.path_join("frames.csv")).split("\n", false))
	var header: PackedStringArray = String(lines[0]).split(",")
	for col in ["frame", "run_s", "frame_ms", "fps", "mon_process_ms", "mon_physics_ms", "draw_calls",
			"nodes", "orphan_nodes", "static_mem_mb", "video_mem_mb", "physics_pairs", "minions",
			"projectiles", "coins", "molotov_fires", "meteor_warnings", "popups", "drift_smoke_puffs", "zones"]:
		assert_true(col in header, "column " + col)
	var rows: Array = lines.filter(func(l: String) -> bool: return not l.begins_with("#") and l != lines[0])
	assert_true(rows.size() >= 10, "a line per frame (%d)" % rows.size())
	var zone_names := {}
	for l in lines:
		if String(l).begins_with("#zone,"):
			zone_names[l.get_slice(",", 2)] = int(l.get_slice(",", 1))
	for z in ["frame", "physics_step", "physics.scripts", "process", "car.physics", "minions.step",
			"minions.walk", "minions.separation", "weapons.step", "run.clock", "draw.minion"]:
		assert_true(zone_names.has(z), "zone " + z)
	var last: PackedStringArray = String(rows[-2]).split(",")
	var minions_col := header.find("minions")
	assert_true(int(last[minions_col]) >= 6, "the minions alive are counted")
	assert_true(float(last[header.find("frame_ms")]) > 0.0)
	assert_true(last[header.find("zones")].contains(":"), "the frame's zones with their times")
	var markers: Array = lines.filter(func(l: String) -> bool: return l.begins_with("#marker,"))
	var marker_names := markers.map(func(l: String) -> String: return l.get_slice(",", 4))
	for m in ["recording_started", "run_started", "level_up", "gift_helicopter_sent", "recording_stopped"]:
		assert_true(m in marker_names, "marker " + m)
	# trace.json
	var parsed = JSON.parse_string(_read(folder.path_join("trace.json")))
	assert_true(parsed is Dictionary, "the trace is JSON")
	var events: Array = parsed.get("traceEvents", [])
	assert_eq(trace_problem(events), "", "every begin has its end, nested")
	var phs := {}
	var names := {}
	for e in events:
		phs[e.ph] = true
		names[e.name] = true
	for ph in ["B", "E", "i", "C", "M"]:
		assert_true(phs.has(ph), "trace has %s events" % ph)
	for z in ["frame", "physics_step", "minions.step", "minions.walk", "level_up"]:
		assert_true(names.has(z), "trace has " + z)
	# meta.json
	var meta = JSON.parse_string(_read(folder.path_join("meta.json")))
	assert_true(meta.frames >= 10)
	assert_true(meta.pair_cost_us > 0.0)
	assert_true(meta.has("recorder_self_us_per_frame"))
	assert_eq(int(meta.unbalanced_zones), 0, "every zone in the game is closed")


func test_spike_keeps_the_frames_around_it_in_detail() -> void:
	PerfRecorder.enabled_override = 1
	var run := _start_run()
	run.minions.enabled = false
	var rec: PerfRecorder = run.get_node("PerfRecorder")
	rec.spike_ms = 30.0
	rec.sample_every = 0
	rec.frames_before = 3
	rec.frames_after = 2
	await wait_process_frames(30)
	var stall := func() -> void: OS.delay_msec(45)
	get_tree().process_frame.connect(stall, CONNECT_ONE_SHOT)
	await wait_process_frames(30)
	var folder := rec.folder
	_stop_run(run)
	var text := _read(folder.path_join("frames.csv"))
	var spikes := Array(text.split("\n")).filter(func(l: String) -> bool: return l.begins_with("#spike,"))
	assert_true(spikes.size() >= 1, "the stalled frame is flagged")
	var parsed = JSON.parse_string(_read(folder.path_join("trace.json")))
	var events: Array = parsed.traceEvents
	assert_eq(trace_problem(events), "")
	var detailed := {}
	var spike_marked := false
	for e in events:
		if e.ph == "B" and e.name == "frame":
			detailed[int(e.args.frame)] = true
		if e.ph == "i" and String(e.name).begins_with("SPIKE"):
			spike_marked = true
	assert_true(spike_marked)
	var spike_frames: Array = spikes.map(func(l: String) -> int: return int(l.get_slice(",", 1)))
	var stalled: Array = spike_frames.filter(func(f: int) -> bool: return f >= 20)
	assert_eq(stalled.size(), 1, "the stalled frame is a spike (%s)" % [spike_frames])
	if stalled.is_empty():
		return
	var s: int = stalled[0]
	assert_true(detailed.has(s), "the spike frame in full detail")
	assert_true(detailed.has(s - 3) and detailed.has(s - 1), "the frames before it")
	assert_true(detailed.has(s + 1) and detailed.has(s + 2), "the frames after it")
	var allowed := {}
	for f in spike_frames:
		for k in range(f - 3, f + 3):
			allowed[k] = true
	var far := detailed.keys().filter(func(f: int) -> bool: return not allowed.has(f))
	assert_eq(far, [], "frames far from a spike are only counters")


func test_a_new_run_on_the_same_scene_gets_its_own_recording() -> void:
	PerfRecorder.enabled_override = 1
	var run := _start_run()
	run.minions.enabled = false
	var rec: PerfRecorder = run.get_node("PerfRecorder")
	await wait_physics_frames(5)
	var first := rec.folder
	run.start_run()
	await wait_physics_frames(5)
	assert_ne(rec.folder, first)
	_stop_run(run)
	assert_true(FileAccess.file_exists(first.path_join("frames.csv")))
	assert_true(FileAccess.get_file_as_string(first.path_join("trace.json")).strip_edges().ends_with("]}"), "the first trace was closed")
