class_name PerfRecorder
extends Node
## The run's performance recorder (task T-468; how to use it and what it writes:
## game/docs/game-loop/perf-recorder.md). Off by default. Switched on for a game session by
## the command line option `--record-perf` (after `--`) or the environment variable
## `SC_RECORD_PERF=1`; then every run writes one recording folder:
##
##     game/perf/<date>_<time>/frames.csv   one line per frame: frame time, Godot's monitors,
##                                          the run's counts, each zone's time; plus #zone,
##                                          #marker and #spike lines
##     game/perf/<date>_<time>/trace.json   Chrome trace events (Perfetto, chrome://tracing):
##                                          counters for every frame, event markers, and the
##                                          frames around every spike in full detail
##     game/perf/<date>_<time>/meta.json    the settings, the machine, and a summary at the end
##
## (`game/perf/` is git-ignored and has a .gdignore, so Godot never imports it. When the game
## runs from an exported build, the folder is user://perf instead.)
##
## The analysis: python game/tools/analyse_perf.py [folder] (latest recording by default).
##
## How a frame is cut up: the recorder follows the engine's own signals and runs its own
## _physics_process and _process last of all nodes, so each frame holds the zones
## `frame` > `physics_step` (one per physics step) > `physics.scripts` (every node's
## _physics_process) and `physics.engine` (the physics server's step, deferred calls and
## frees), then `process` (every node's _process), `after_process` (deferred calls: the
## custom drawings' _draw, frees), `render` (RenderingServer's draw) and `wait` (input, vsync
## and frame pacing until the next frame). The game's own zones (Perf.begin/end) nest inside.

const DEFAULT_SPIKE_MS := 25.0
## Frames kept in full detail before and after each spike.
const DEFAULT_FRAMES_BEFORE := 30
const DEFAULT_FRAMES_AFTER := 30
## At most this many frames in full detail in one recording (about 150 MB of trace); past it,
## only the spike frames themselves, without the frames around them.
const DEFAULT_MAX_DETAILED_FRAMES := 12000
## One ordinary frame in this many is kept in full detail too, for comparison.
const DEFAULT_SAMPLE_EVERY := 300
## Writing the detailed frames to the trace is spread over frames: once a frame has been
## written, no more this frame after this many microseconds.
const TRACE_WRITE_BUDGET_USEC := 300
const FLUSH_EVERY_FRAMES := 120

## -1 reads the command line and environment; 0 off, 1 on (tests).
static var enabled_override := -1
## Where recordings go: "" for the default (game/perf, or user://perf in an exported build).
static var dir_override := ""
## The live recorder, while one is recording (markers from anywhere go to it).
static var current: PerfRecorder = null

## Godot's monitors written every frame: column name, Performance constant name, scale.
const MONITORS := [
	["fps", "TIME_FPS", 1.0],
	["mon_process_ms", "TIME_PROCESS", 1000.0],
	["mon_physics_ms", "TIME_PHYSICS_PROCESS", 1000.0],
	["mon_navigation_ms", "TIME_NAVIGATION_PROCESS", 1000.0],
	["static_mem_mb", "MEMORY_STATIC", 1.0 / 1048576.0],
	["static_mem_max_mb", "MEMORY_STATIC_MAX", 1.0 / 1048576.0],
	["message_buffer_max_kb", "MEMORY_MESSAGE_BUFFER_MAX", 1.0 / 1024.0],
	["objects", "OBJECT_COUNT", 1.0],
	["resources", "OBJECT_RESOURCE_COUNT", 1.0],
	["nodes", "OBJECT_NODE_COUNT", 1.0],
	["orphan_nodes", "OBJECT_ORPHAN_NODE_COUNT", 1.0],
	["render_objects", "RENDER_TOTAL_OBJECTS_IN_FRAME", 1.0],
	["render_primitives", "RENDER_TOTAL_PRIMITIVES_IN_FRAME", 1.0],
	["draw_calls", "RENDER_TOTAL_DRAW_CALLS_IN_FRAME", 1.0],
	["video_mem_mb", "RENDER_VIDEO_MEM_USED", 1.0 / 1048576.0],
	["texture_mem_mb", "RENDER_TEXTURE_MEM_USED", 1.0 / 1048576.0],
	["buffer_mem_mb", "RENDER_BUFFER_MEM_USED", 1.0 / 1048576.0],
	["physics_active", "PHYSICS_2D_ACTIVE_OBJECTS", 1.0],
	["physics_pairs", "PHYSICS_2D_COLLISION_PAIRS", 1.0],
	["physics_islands", "PHYSICS_2D_ISLAND_COUNT", 1.0],
	["nav_maps", "NAVIGATION_ACTIVE_MAPS", 1.0],
	["pipeline_canvas", "PIPELINE_COMPILATIONS_CANVAS", 1.0],
	["pipeline_mesh", "PIPELINE_COMPILATIONS_MESH", 1.0],
	["pipeline_surface", "PIPELINE_COMPILATIONS_SURFACE", 1.0],
	["pipeline_draw", "PIPELINE_COMPILATIONS_DRAW", 1.0],
	["pipeline_specialization", "PIPELINE_COMPILATIONS_SPECIALIZATION", 1.0],
]

## The run's counts written every frame (see _counts()).
const COUNTS := [
	"minions", "minions_spawned", "minions_killed", "paths_found", "coins", "health_pickups",
	"projectiles", "bullets", "molotov_fires", "other_projectiles", "burning_enemies",
	"flame_on", "kaiju", "meteor_warnings", "boulders_pending", "boulders_standing",
	"meteor_dust", "map_meteor_boulders", "gift_helicopters", "gift_packages", "popups",
	"drift_smoke_puffs", "drift_mark_pieces", "wreck_puffs", "hud_reactions",
	"hud_viewer_flights",
]

const PHASE_ZONES := [&"physics_step", &"physics.scripts", &"physics.engine", &"process",
	&"after_process", &"render", &"wait"]

enum Phase { NONE, PHYS_SCRIPTS, PHYS_ENGINE, PROCESS, AFTER, RENDER, WAIT }

var spike_ms := DEFAULT_SPIKE_MS
var frames_before := DEFAULT_FRAMES_BEFORE
var frames_after := DEFAULT_FRAMES_AFTER
var sample_every := DEFAULT_SAMPLE_EVERY
var max_detailed_frames := DEFAULT_MAX_DETAILED_FRAMES
## Frames queued for full detail so far in this recording.
var detailed_frames := 0
## The run being recorded (run.gd), for its counts and its signals.
var run: Node = null
## The folder of the recording now open ("" before the first and after the last).
var folder := ""
## Frames written to frames.csv so far in this recording.
var frames := 0
var spikes := 0
var markers := 0
## Microseconds a begin/end pair costs while on, measured when recording starts.
var pair_cost_us := 0.0
## Totals of the recorder's own time (usec) and zone calls, for the overhead estimate.
var self_us_total := 0
var zone_calls_total := 0
var frame_us_total := 0

var _csv: FileAccess = null
var _trace: FileAccess = null
var _first_trace_event := true
var _t_base := 0
var _frame_start := 0
var _frame_open := false
var _phase := Phase.NONE
var _monitor_ids: Array = []  # [column, id, scale] for the monitors this Godot has
var _ring: Array = []  # [frame, events] of the last frames_before frames
var _after_left := 0
var _trace_queue: Array = []  # [frame, events] waiting to be written to the trace
var _paused := false
var _spawned := 0
var _killed := 0
var _last_paths := -1
var _runs_seen := 0
var _connected: Array = []  # [object, signal name, callable]


## True when this session records runs: `--record-perf` among the user arguments (after
## `--`), or SC_RECORD_PERF set to 1, true or yes (enabled_override wins when not -1).
static func is_enabled() -> bool:
	if enabled_override >= 0:
		return enabled_override == 1
	if "--record-perf" in OS.get_cmdline_user_args() or "--record-perf" in OS.get_cmdline_args():
		return true
	return OS.get_environment("SC_RECORD_PERF").to_lower() in ["1", "true", "yes", "on"]


## The spike threshold in ms: `--record-perf-spike-ms=N` or SC_PERF_SPIKE_MS, else 25.
static func configured_spike_ms() -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--record-perf-spike-ms="):
			return float(a.get_slice("=", 1))
	var e := OS.get_environment("SC_PERF_SPIKE_MS")
	return float(e) if e.is_valid_float() else DEFAULT_SPIKE_MS


## The folder recordings go in (absolute).
static func base_dir() -> String:
	if dir_override != "":
		return ProjectSettings.globalize_path(dir_override)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--record-perf-dir="):
			return a.get_slice("=", 1)
	var e := OS.get_environment("SC_PERF_DIR")
	if e != "":
		return e
	if OS.has_feature("template"):
		return ProjectSettings.globalize_path("user://perf")
	return ProjectSettings.globalize_path("res://").path_join("perf")


## Called by the run scene (run.gd _ready) before its first start_run(): adds a recorder to
## the run when recording is on, and returns it (null when off: nothing else happens).
static func attach_to_run(the_run: Node) -> PerfRecorder:
	if not is_enabled():
		return null
	var r := PerfRecorder.new()
	r.name = "PerfRecorder"
	r.run = the_run
	the_run.add_child(r)
	return r


## A marker on the timeline, from anywhere (no-op when nothing records).
static func mark(marker_name: String, args: Dictionary = {}) -> void:
	if current != null:
		current.add_marker(marker_name, args)


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Last of all nodes, so its _physics_process and _process close the scripts' phases.
	process_priority = 1 << 30
	process_physics_priority = 1 << 30


func _enter_tree() -> void:
	spike_ms = configured_spike_ms() if spike_ms == DEFAULT_SPIKE_MS else spike_ms
	var tree := get_tree()
	tree.physics_frame.connect(_on_physics_frame)
	tree.process_frame.connect(_on_process_frame)
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)
	_bind_run()
	start_recording()


func _exit_tree() -> void:
	stop_recording()
	var tree := get_tree()
	if tree.physics_frame.is_connected(_on_physics_frame):
		tree.physics_frame.disconnect(_on_physics_frame)
	if tree.process_frame.is_connected(_on_process_frame):
		tree.process_frame.disconnect(_on_process_frame)
	if RenderingServer.frame_pre_draw.is_connected(_on_pre_draw):
		RenderingServer.frame_pre_draw.disconnect(_on_pre_draw)
	if RenderingServer.frame_post_draw.is_connected(_on_post_draw):
		RenderingServer.frame_post_draw.disconnect(_on_post_draw)
	_unbind_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		stop_recording()


## True while a recording is open.
func is_recording() -> bool:
	return _csv != null


## Opens a new recording folder and starts timing frames.
func start_recording() -> void:
	stop_recording()
	var base := base_dir()
	DirAccess.make_dir_recursive_absolute(base)
	if not FileAccess.file_exists(base.path_join(".gdignore")):
		var g := FileAccess.open(base.path_join(".gdignore"), FileAccess.WRITE)
		if g != null:
			g.close()
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	folder = base.path_join(stamp)
	var n := 2
	while DirAccess.dir_exists_absolute(folder):
		folder = base.path_join("%s_%d" % [stamp, n])
		n += 1
	DirAccess.make_dir_recursive_absolute(folder)
	_csv = FileAccess.open(folder.path_join("frames.csv"), FileAccess.WRITE)
	_trace = FileAccess.open(folder.path_join("trace.json"), FileAccess.WRITE)
	if _csv == null or _trace == null:
		push_warning("PerfRecorder: cannot write to %s" % folder)
		_csv = null
		_trace = null
		return
	frames = 0
	spikes = 0
	markers = 0
	self_us_total = 0
	zone_calls_total = 0
	frame_us_total = 0
	_ring.clear()
	_trace_queue.clear()
	detailed_frames = 0
	_after_left = 0
	_spawned = 0
	_killed = 0
	_last_paths = -1
	_resolve_monitors()
	_calibrate()
	var header := PackedStringArray(["frame", "wall_s", "run_s", "paused", "frame_ms", "zone_calls"])
	for m in _monitor_ids:
		header.append(m[0])
	for c in COUNTS:
		header.append(c)
	header.append("zones")
	_csv.store_line(",".join(header))
	for id in Perf.names.size():
		_csv.store_line("#zone,%d,%s" % [id, Perf.names[id]])
	Perf.on_new_zone = func(id: int, zone_name: String) -> void:
		if _csv != null:
			_csv.store_line("#zone,%d,%s" % [id, zone_name])
	_trace.store_string('{"displayTimeUnit":"ms","traceEvents":[\n')
	_first_trace_event = true
	_trace_event('{"name":"process_name","ph":"M","pid":1,"tid":1,"args":{"name":"Solid Carbide"}}')
	_trace_event('{"name":"thread_name","ph":"M","pid":1,"tid":1,"args":{"name":"main thread"}}')
	_write_meta(false)
	_t_base = Time.get_ticks_usec()
	_frame_open = false
	_phase = Phase.NONE
	_paused = get_tree().paused if is_inside_tree() else false
	Perf.reset()
	Perf.clear_frame()
	Perf.on = true
	current = self
	add_marker("recording_started", {"folder": folder})


## Closes the recording: the last frame, the trace's end, the summary in meta.json.
func stop_recording() -> void:
	if _csv == null:
		return
	add_marker("recording_stopped", {})
	_end_phase()
	var t := Time.get_ticks_usec()
	if _frame_open:
		_write_frame(_take_frame(t, false), _frame_start, t)
		_frame_open = false
	Perf.on = false
	Perf.on_new_zone = Callable()
	Perf.clear_frame()
	while not _trace_queue.is_empty():
		_write_trace_frames(1 << 30)
	_trace.store_string("\n]}\n")
	_trace.close()
	_trace = null
	_csv.close()
	_csv = null
	_write_meta(true)
	if current == self:
		current = null
	print("PerfRecorder: %d frames, %d spikes over %.0f ms, written to %s" % [frames, spikes, spike_ms, folder])


## A marker at this moment: a #marker line in frames.csv and an instant event in the trace.
func add_marker(marker_name: String, args: Dictionary = {}) -> void:
	if _csv == null:
		return
	markers += 1
	var t := Time.get_ticks_usec() - _t_base
	var a := args.duplicate()
	a["frame"] = frames
	a["run_s"] = snappedf(_run_seconds(), 0.001)
	var json := JSON.stringify(a)
	_csv.store_line("#marker,%d,%.6f,%.3f,%s,%s" % [frames, t / 1000000.0, _run_seconds(), marker_name, json])
	_trace_event('{"name":%s,"ph":"i","s":"g","pid":1,"tid":1,"ts":%d,"args":%s}' % [JSON.stringify(marker_name), t, json])


# --- The frame's phases -----------------------------------------------------------------

func _on_physics_frame() -> void:
	if _csv == null:
		return
	if _phase == Phase.PHYS_ENGINE or _phase == Phase.PHYS_SCRIPTS:
		_end_phase()
	else:
		_new_frame()
	Perf.begin(&"physics_step")
	Perf.begin(&"physics.scripts")
	_phase = Phase.PHYS_SCRIPTS


func _physics_process(_delta: float) -> void:
	if _csv == null or _phase != Phase.PHYS_SCRIPTS:
		return
	Perf.end(&"physics.scripts")
	Perf.begin(&"physics.engine")
	_phase = Phase.PHYS_ENGINE


func _on_process_frame() -> void:
	if _csv == null:
		return
	if _phase == Phase.PHYS_ENGINE or _phase == Phase.PHYS_SCRIPTS:
		_end_phase()
	else:
		_new_frame()
	Perf.begin(&"process")
	_phase = Phase.PROCESS


func _process(_delta: float) -> void:
	if _csv == null or _phase != Phase.PROCESS:
		return
	Perf.end(&"process")
	Perf.begin(&"after_process")
	_phase = Phase.AFTER


func _on_pre_draw() -> void:
	if _csv == null or (_phase != Phase.AFTER and _phase != Phase.PROCESS):
		return
	_end_phase()
	Perf.begin(&"render")
	_phase = Phase.RENDER


func _on_post_draw() -> void:
	if _csv == null or _phase != Phase.RENDER:
		return
	Perf.end(&"render")
	Perf.begin(&"wait")
	_phase = Phase.WAIT


## Closes the phase zone open now (and a physics step's own zone).
func _end_phase() -> void:
	match _phase:
		Phase.PHYS_SCRIPTS:
			Perf.end(&"physics.scripts")
			Perf.end(&"physics_step")
		Phase.PHYS_ENGINE:
			Perf.end(&"physics.engine")
			Perf.end(&"physics_step")
		Phase.PROCESS:
			Perf.end(&"process")
		Phase.AFTER:
			Perf.end(&"after_process")
		Phase.RENDER:
			Perf.end(&"render")
		Phase.WAIT:
			Perf.end(&"wait")
	_phase = Phase.NONE


## The first engine signal of a new frame: closes the last frame and writes it. The writing
## is timed as the zone `perf.recorder` at the start of the new frame, where it is spent.
func _new_frame() -> void:
	_end_phase()
	var t := Time.get_ticks_usec()
	if not _frame_open:
		_frame_start = t
		_frame_open = true
		Perf.begin(&"frame")
		return
	var snap := _take_frame(t)
	var start := _frame_start
	_frame_start = t
	Perf.begin(&"frame")
	Perf.begin(&"perf.recorder")
	_write_frame(snap, start, t)
	Perf.end(&"perf.recorder")


## Ends the frame zone at `t` and takes the frame's numbers: [events, zone text, zone calls].
## `strict`: zones still open inside the frame (a begin without its end) are counted as
## unbalanced; false when the recording stops in the middle of a frame.
func _take_frame(t: int, strict := true) -> Array:
	if strict and Perf.depth() > 1:
		Perf.unbalanced += Perf.depth() - 1
	Perf.close_all(t)
	var ev := Perf.events
	Perf.events = PackedInt64Array()
	var snap := [ev, _zone_text(), Perf.zone_calls]
	Perf.clear_frame()
	return snap


## Writes one frame (from `start` to `t`, usec): its frames.csv line, its trace counters, and
## its zones in full detail when it is a spike, near one, or a sample.
func _write_frame(snap: Array, start: int, t: int) -> void:
	var r0 := Time.get_ticks_usec()
	var ev: PackedInt64Array = snap[0]
	var calls_now: int = snap[2]
	var frame_us := t - start
	var paused := get_tree().paused if is_inside_tree() else _paused
	if paused != _paused:
		_paused = paused
		add_marker("paused" if paused else "resumed", {})
	var frame_ms := frame_us / 1000.0
	var line := PackedStringArray([
		str(frames), "%.6f" % ((start - _t_base) / 1000000.0), "%.3f" % _run_seconds(),
		"1" if paused else "0", "%.3f" % frame_ms, str(calls_now)])
	for m in _monitor_ids:
		var v: float = Performance.get_monitor(m[1]) * m[2]
		line.append(str(int(v)) if m[2] == 1.0 and m[0] != "fps" else "%.3f" % v)
	var counts := _counts()
	for c in counts:
		line.append(str(c))
	line.append(snap[1])
	_csv.store_line(",".join(line))
	var spike := frame_ms >= spike_ms
	# Counters on the trace's timeline for every frame.
	var ts := start - _t_base
	_trace_event('{"name":"frame_ms","ph":"C","pid":1,"tid":1,"ts":%d,"args":{"ms":%.3f}}' % [ts, frame_ms])
	_trace_event('{"name":"minions","ph":"C","pid":1,"tid":1,"ts":%d,"args":{"alive":%d}}' % [ts, counts[0]])
	_trace_event('{"name":"projectiles","ph":"C","pid":1,"tid":1,"ts":%d,"args":{"n":%d}}' % [ts, counts[6]])
	# Full detail: the frames before a spike, the spike, the frames after, and a sample.
	_ring.append([frames, ev])
	if detailed_frames >= max_detailed_frames:
		_ring = [_ring[-1]] if spike else []  # past the cap: the spike frame alone
		_after_left = 0
	if spike:
		spikes += 1
		_trace_event('{"name":"SPIKE %.1f ms","ph":"i","s":"g","pid":1,"tid":1,"ts":%d,"args":{"frame":%d,"run_s":%.3f}}' % [frame_ms, ts, frames, _run_seconds()])
		_csv.store_line("#spike,%d,%.3f" % [frames, frame_ms])
		_queue_detail(_ring)
		_ring.clear()
		_after_left = frames_after if detailed_frames < max_detailed_frames else 0
	elif _after_left > 0:
		_after_left -= 1
		_queue_detail(_ring)
		_ring.clear()
	elif sample_every > 0 and frames % sample_every == 0 and not _ring.is_empty():
		_queue_detail([_ring[-1]])
		_ring.clear()
	while _ring.size() > frames_before:
		_ring.pop_front()
	_write_trace_frames(TRACE_WRITE_BUDGET_USEC)
	frames += 1
	if frames % FLUSH_EVERY_FRAMES == 0:
		_csv.flush()
		_trace.flush()
	self_us_total += Time.get_ticks_usec() - r0
	zone_calls_total += calls_now
	frame_us_total += frame_us


## "id:inclusive:self:calls;..." for the zones used this frame.
func _zone_text() -> String:
	var parts := PackedStringArray()
	for id in Perf.touched:
		parts.append("%d:%d:%d:%d" % [id, Perf.tot_us[id], Perf.self_us[id], Perf.calls[id]])
	return ";".join(parts)


func _queue_detail(items: Array) -> void:
	_trace_queue.append_array(items)
	detailed_frames += items.size()


## Writes queued detailed frames to the trace as begin/end pairs, frame by frame, until
## `budget_usec` has gone by.
func _write_trace_frames(budget_usec: int) -> void:
	var t0 := Time.get_ticks_usec()
	while not _trace_queue.is_empty() and Time.get_ticks_usec() - t0 < budget_usec:
		var item: Array = _trace_queue.pop_front()
		_write_frame_events(item[0], item[1])


## One frame's zones as B/E events, nested: sorted by start, outer zones first (one native
## sort of start << 22 | depth << 16 | index), written in one go.
func _write_frame_events(frame_index: int, ev: PackedInt64Array) -> int:
	var n := ev.size() / 5
	if n == 0:
		return 0
	var base := ev[1]
	for i in n:
		base = mini(base, ev[i * 5 + 1])
	var keys := PackedInt64Array()
	keys.resize(n)
	for i in n:
		keys[i] = ((ev[i * 5 + 1] - base) << 22) | (mini(ev[i * 5 + 3], 63) << 16) | i
	keys.sort()
	var out := PackedStringArray()
	var fa := ',"args":{"frame":%d}}' % frame_index
	var stack_d := PackedInt64Array()
	var stack_end := PackedInt64Array()
	var stack_name := PackedStringArray()
	# Times never go back in the file: an end is never before the last time written (a zone
	# cut short by the recording's stop could otherwise end before its children).
	var last := 0
	for key in keys:
		var i := key & 0xFFFF
		var d := ev[i * 5 + 3]
		while not stack_d.is_empty() and stack_d[-1] >= d:
			last = maxi(stack_end[-1], last)
			out.append('{"name":"' + stack_name[-1] + '","ph":"E","pid":1,"tid":1,"ts":' + str(last - _t_base) + '}')
			stack_d.resize(stack_d.size() - 1)
			stack_end.resize(stack_end.size() - 1)
			stack_name.resize(stack_name.size() - 1)
		var zone_name := Perf.names[ev[i * 5]]
		var calls_n := ev[i * 5 + 4]
		last = maxi(ev[i * 5 + 1], last)
		var head := '{"name":"' + zone_name + '","ph":"B","pid":1,"tid":1,"ts":' + str(last - _t_base)
		if calls_n > 0:
			out.append(head + ',"args":{"each":true,"calls":%d,"us":%d,"frame":%d}}' % [calls_n, ev[i * 5 + 2] - ev[i * 5 + 1], frame_index])
		else:
			out.append(head + fa)
		stack_d.append(d)
		stack_end.append(ev[i * 5 + 2])
		stack_name.append(zone_name)
	while not stack_d.is_empty():
		last = maxi(stack_end[-1], last)
		out.append('{"name":"' + stack_name[-1] + '","ph":"E","pid":1,"tid":1,"ts":' + str(last - _t_base) + '}')
		stack_d.resize(stack_d.size() - 1)
		stack_end.resize(stack_end.size() - 1)
		stack_name.resize(stack_name.size() - 1)
	_trace_event(",
".join(out))
	return n


func _trace_event(json: String) -> void:
	if _trace == null:
		return
	if _first_trace_event:
		_first_trace_event = false
		_trace.store_string(json)
	else:
		_trace.store_string(",\n" + json)


# --- The run: counts and markers ----------------------------------------------------------

func _run_seconds() -> float:
	var s = run.get("state") if run != null and is_instance_valid(run) else null
	if s == null or not is_instance_valid(s) or not s.has_method("time_elapsed"):
		return -1.0
	return s.time_elapsed()


static func _n(obj, prop: String) -> int:
	if obj == null or not is_instance_valid(obj):
		return -1
	var v = obj.get(prop)
	if v == null:
		return -1
	if v is Array or v is Dictionary:
		return v.size()
	if v is bool:
		return 1 if v else 0
	if v is int:
		return v
	return -1


static func _prop(obj, prop: String):
	if obj == null or not is_instance_valid(obj):
		return null
	return obj.get(prop)


## The run's counts, in COUNTS order (-1 when a part is missing).
func _counts() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(COUNTS.size())
	out.fill(-1)
	if run == null or not is_instance_valid(run):
		return out
	var spawner = _prop(run, "minions")
	out[0] = _n(spawner, "minions")
	out[1] = _spawned
	out[2] = _killed
	_spawned = 0
	_killed = 0
	var nav = _prop(spawner, "navigation")
	var paths := _n(nav, "paths_total")
	out[3] = 0 if _last_paths < 0 or paths < _last_paths else paths - _last_paths
	_last_paths = paths
	out[4] = _n(spawner, "coins")
	out[5] = _n(spawner, "health_pickups")
	var weapons = _prop(run, "weapons")
	var projectiles = _prop(weapons, "projectiles")
	if projectiles is Array:
		var bullets := 0
		var fires := 0
		for p in projectiles:
			if not is_instance_valid(p):
				continue
			var s = p.get_script()
			var path: String = s.resource_path if s != null else ""
			if path.ends_with("bullet.gd"):
				bullets += 1
			elif path.ends_with("molotov_fire.gd"):
				fires += 1
		out[6] = projectiles.size()
		out[7] = bullets
		out[8] = fires
		out[9] = projectiles.size() - bullets - fires
	var flame = weapons.get("flamethrower") if weapons != null and is_instance_valid(weapons) else null
	out[10] = _n(flame, "burning")
	out[11] = _n(flame, "active")
	var boss = _prop(run, "kaiju_boss")
	var k = _prop(boss, "kaiju")
	out[12] = 1 if k != null and is_instance_valid(k) else 0
	var meteors = _prop(boss, "meteors")
	out[13] = _n(meteors, "warnings")
	out[14] = _n(meteors, "pending_boulders")
	out[15] = _n(meteors, "standing_boulders")
	out[16] = _n(meteors, "dust")
	out[17] = _n(_prop(run, "map"), "meteor_boulders")
	var gifts = _prop(run, "gift_drops")
	out[18] = _n(gifts, "helicopters")
	out[19] = _n(gifts, "packages")
	var popups = _prop(run, "trick_popups")
	out[20] = popups.get_child_count() if popups != null and is_instance_valid(popups) else -1
	out[21] = _n(_prop(run, "drift_smoke"), "_puffs")
	out[22] = _n(_prop(run, "drift_marks"), "_pieces")
	out[23] = _n(_prop(run, "wreck_effect"), "puffs")
	var hud = _prop(run, "hud")
	out[24] = _n(_prop(hud, "reactions"), "items")
	out[25] = _n(_prop(hud, "multiplier_tag"), "flights")
	return out


func _bind_run() -> void:
	if run == null:
		return
	var state = run.get("state")
	if state != null:
		_on(state, "run_started", func() -> void: _on_run_started())
		_on(state, "boss_time", func() -> void: add_marker("boss_time"))
		_on(state, "run_ended", func(result: String, coins: int) -> void: add_marker("run_ended", {"result": result, "coins": coins}))
		_on(state, "level_up", func(lv: int) -> void: add_marker("level_up", {"level": lv}))
		_on(state, "level_up_choice_started", func(lv: int) -> void: add_marker("level_up_screen_opened", {"level": lv}))
		_on(state, "level_up_choice_made", func(lv: int) -> void: add_marker("level_up_choice_made", {"level": lv}))
		_on(state, "wreck_started", func(s: float) -> void: add_marker("wreck", {"seconds": s}))
		_on(state, "revived", func() -> void: add_marker("revive"))
		_on(state, "time_up_started", func(_s: float) -> void: add_marker("time_up"))
		_on(state, "car_damaged", func(amount: float) -> void: add_marker("car_damaged", {"amount": amount}))
		_on(state, "combo_broken", func() -> void: add_marker("combo_broken"))
	_on(run, "world_rebuilt", func() -> void: add_marker("world_rebuilt"))
	var gifts = run.get("gift_drops")
	if gifts != null:
		_on(gifts, "helicopter_sent", func(_h) -> void: add_marker("gift_helicopter_sent"))
		_on(gifts, "package_dropped", func(_p) -> void: add_marker("gift_pack_dropped"))
		_on(gifts, "package_landed", func(_p) -> void: add_marker("gift_pack_landed"))
		_on(gifts, "package_picked_up", func(_p) -> void: add_marker("gift_pack_picked_up"))
	var weapons = run.get("weapons")
	if weapons != null:
		var list = weapons.get("weapons")
		if list is Dictionary:
			for w in list.values():
				_on(w, "tier_changed", func(id: String, tier: int) -> void:
					add_marker("weapon_reset" if tier == 0 else ("weapon_gained" if tier == 1 else "weapon_tier"), {"weapon": id, "tier": tier}))
	var boss = run.get("kaiju_boss")
	if boss != null:
		_on(boss, "kaiju_appeared", func(_k) -> void: add_marker("kaiju_arrived"))
		_on(boss, "kaiju_defeated", func(_c: int) -> void: add_marker("kaiju_defeated"))
		var meteors = boss.get("meteors")
		if meteors != null:
			_on(meteors, "attack_started", func() -> void: add_marker("meteor_attack"))
			_on(meteors, "meteor_landed", func(_u, hit: bool) -> void: add_marker("meteor_landed", {"hit_car": hit}))
			_on(meteors, "boulder_placed", func(_u, _b) -> void: add_marker("boulder_placed"))
	var spawner = run.get("minions")
	if spawner != null:
		_on(spawner, "minion_spawned", func(_m) -> void: _spawned += 1)
		_on(spawner, "minion_killed", func(_m, _c: int) -> void: _killed += 1)


func _on(obj: Object, sig: String, f: Callable) -> void:
	if obj == null or not obj.has_signal(sig):
		return
	obj.connect(sig, f)
	_connected.append([obj, sig, f])


func _unbind_run() -> void:
	for c in _connected:
		if is_instance_valid(c[0]) and c[0].is_connected(c[1], c[2]):
			c[0].disconnect(c[1], c[2])
	_connected.clear()


## A run starts: the first one is this recording's; a later one (a new run on the same run
## scene) gets a recording of its own.
func _on_run_started() -> void:
	_runs_seen += 1
	if _runs_seen > 1:
		start_recording()
	add_marker("run_started")


# --- Setup -----------------------------------------------------------------------------

func _resolve_monitors() -> void:
	_monitor_ids.clear()
	for m in MONITORS:
		if ClassDB.class_has_integer_constant("Performance", m[1]):
			_monitor_ids.append([m[0], ClassDB.class_get_integer_constant("Performance", m[1]), m[2]])


## Measures what a begin/end pair costs while recording (a real zone and an each-zone,
## averaged), for the overhead estimate.
func _calibrate() -> void:
	var was := Perf.on
	Perf.on = true
	Perf.reset()
	var n := 2000
	var t0 := Time.get_ticks_usec()
	Perf.begin(&"perf.calibration")
	for i in n:
		Perf.begin(&"perf.calibration_zone")
		Perf.end(&"perf.calibration_zone")
		if Perf.on: Perf.each_begin(&"perf.calibration_each")
		if Perf.on: Perf.each_end(&"perf.calibration_each")
	Perf.end(&"perf.calibration")
	pair_cost_us = float(Time.get_ticks_usec() - t0) / (2 * n)
	Perf.reset()
	Perf.on = was


func _write_meta(final: bool) -> void:
	var meta := {
		"version": 1,
		"ticket": "T-468",
		"folder": folder,
		"started": Time.get_datetime_string_from_system(false, true),
		"spike_ms": spike_ms,
		"frames_before": frames_before,
		"frames_after": frames_after,
		"sample_every": sample_every,
		"max_detailed_frames": max_detailed_frames,
		"pair_cost_us": pair_cost_us,
		"godot": Engine.get_version_info().get("string", ""),
		"debug_build": OS.is_debug_build(),
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"cpu_count": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")),
		"window_size": str(DisplayServer.window_get_size()) if DisplayServer.get_name() != "headless" else "headless",
		"refresh_rate": DisplayServer.screen_get_refresh_rate() if DisplayServer.get_name() != "headless" else -1.0,
		"vsync_mode": DisplayServer.window_get_vsync_mode() if DisplayServer.get_name() != "headless" else -1,
		"max_fps": Engine.max_fps,
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"max_physics_steps_per_frame": Engine.max_physics_steps_per_frame,
		"cmdline": " ".join(OS.get_cmdline_args()),
		"user_args": " ".join(OS.get_cmdline_user_args()),
		"monitors": _monitor_ids.map(func(m: Array) -> String: return m[0]),
		"counts": COUNTS,
	}
	if final:
		meta["ended"] = Time.get_datetime_string_from_system(false, true)
		meta["frames"] = frames
		meta["spikes"] = spikes
		meta["markers"] = markers
		meta["detailed_frames"] = detailed_frames
		meta["unbalanced_zones"] = Perf.unbalanced
		meta["zones"] = Array(Perf.names)
		meta["recorder_self_us_per_frame"] = float(self_us_total) / maxf(frames, 1)
		meta["zone_calls_per_frame"] = float(zone_calls_total) / maxf(frames, 1)
		meta["zone_overhead_us_per_frame_est"] = pair_cost_us * float(zone_calls_total) / maxf(frames, 1)
		meta["mean_frame_ms"] = float(frame_us_total) / maxf(frames, 1) / 1000.0
	var f := FileAccess.open(folder.path_join("meta.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta, "  "))
		f.close()
