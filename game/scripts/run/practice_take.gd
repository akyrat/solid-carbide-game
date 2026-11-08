class_name PracticeTake
extends RefCounted
## A recorded take of a tutorial practice (task T-574 tweak 8, step 1 of the board's recorded demos;
## HUD and menus, "Tutorial slides"). The board drives the trick in a practice window (dev builds
## only), and the take keeps what it pressed each physics step, so a replay drives the real car
## again, step for step: crisp at any size and a few kilobytes. Checkpoints (the car's place,
## heading and height every CHECKPOINT_EVERY steps) show whether a replay follows the take.
##
## The file (data/tutorial_takes/<trick>.json; the previous take is kept as <trick>.prev.json):
##   {"format": FORMAT, "version": 1, "trick": "alt_drift", "physics_fps": 50, "steps": 312,
##    "start": {"x", "y", "heading"} (the spawn the take started on, degrees),
##    "gift": "jump" or "" (the power-up taken at the start, the grind's),
##    "inputs": [[count, w, s, steer, held, hop], ...] (run-length: `count` steps in a row with
##      the same keys; w, s, held and hop are 0 or 1, steer -1 to 1; hop: Space pressed that step),
##    "resets": [step, ...] (R pressed before that step: the car back at the start),
##    "checkpoints": [{"step", "x", "y", "rotation", "height"}, ...],
##    "result": {"successes", "drift_seconds"} (the count when the take was saved),
##    "_comment": "..." (optional: a note on the take, for example that it is a stand-in; T-574 tweak 10)}

const FORMAT := "solid-carbide-tutorial-take"
const VERSION := 1
## Where the takes are saved (the game's own data; never the board's data/levels/ folder).
const TAKES_DIR := "res://data/tutorial_takes"
## A checkpoint every this many physics steps (1 s at 50 steps a second).
const CHECKPOINT_EVERY := 50

var trick := ""
var physics_fps := 50
var start := {}
var gift := ""
## One entry per physics step: [w, s, steer, held, hop].
var frames: Array = []
var resets: Array = []
var checkpoints: Array = []
var result := {}
## A note kept with the take ("" for none): the stand-in takes say they are stand-ins (T-574 tweak 10,
## step 2), so the board's own recordings replace them; a take the board recorded has none.
var comment := ""


func steps() -> int:
	return frames.size()


func seconds() -> float:
	return float(frames.size()) / float(physics_fps)


## The step's keys, after the car has stepped with them.
func add_frame(w: bool, s: bool, steer: float, held: bool, hop: bool) -> void:
	frames.append([w, s, snappedf(steer, 0.001), held, hop])


func add_checkpoint(step: int, position: Vector2, rotation: float, height: float) -> void:
	checkpoints.append({"step": step, "x": snappedf(position.x, 0.0001), "y": snappedf(position.y, 0.0001),
		"rotation": snappedf(rotation, 0.0001), "height": snappedf(height, 0.0001)})


## The checkpoint for `step`, or {} when there is none.
func checkpoint_at(step: int) -> Dictionary:
	for c in checkpoints:
		if int(c.step) == step:
			return c
	return {}


func to_dict() -> Dictionary:
	var runs: Array = []
	for f in frames:
		var row := [1 if f[0] else 0, 1 if f[1] else 0, f[2], 1 if f[3] else 0, 1 if f[4] else 0]
		if not runs.is_empty() and (runs[-1] as Array).slice(1) == row:
			runs[-1][0] += 1
		else:
			runs.append([1] + row)
	var d := {"format": FORMAT, "version": VERSION, "trick": trick, "physics_fps": physics_fps,
		"steps": frames.size(), "start": start, "gift": gift, "inputs": runs, "resets": resets,
		"checkpoints": checkpoints, "result": result}
	if comment != "":
		d["_comment"] = comment
	return d


static func from_dict(d: Dictionary) -> PracticeTake:
	if String(d.get("format", "")) != FORMAT:
		return null
	var t := PracticeTake.new()
	t.trick = String(d.get("trick", ""))
	t.physics_fps = int(d.get("physics_fps", 50))
	t.start = d.get("start", {})
	t.gift = String(d.get("gift", ""))
	for r in d.get("inputs", []):
		for i in int(r[0]):
			t.frames.append([int(r[1]) == 1, int(r[2]) == 1, float(r[3]), int(r[4]) == 1, int(r[5]) == 1])
	t.resets = (d.get("resets", []) as Array).map(func(v) -> int: return int(v))
	t.checkpoints = d.get("checkpoints", [])
	t.result = d.get("result", {})
	t.comment = String(d.get("_comment", ""))
	return t


static func path_for(trick_name: String, dir := TAKES_DIR) -> String:
	return "%s/%s.json" % [dir, trick_name]


static func backup_path_for(trick_name: String, dir := TAKES_DIR) -> String:
	return "%s/%s.prev.json" % [dir, trick_name]


## Saves the take as <dir>/<trick>.json; an earlier take there becomes <trick>.prev.json first.
## Returns the error (OK when saved).
func save(dir := TAKES_DIR) -> Error:
	var abs_dir := ProjectSettings.globalize_path(dir)
	var err := DirAccess.make_dir_recursive_absolute(abs_dir)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return err
	var path := path_for(trick, dir)
	if FileAccess.file_exists(path):
		var backup := backup_path_for(trick, dir)
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
		err = DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup))
		if err != OK:
			return err
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(to_dict(), " ") + "\n")
	f.close()
	return OK


## The saved take for `trick_name`, or null when there is none (or it isn't a take).
static func load_take(trick_name: String, dir := TAKES_DIR) -> PracticeTake:
	var path := path_for(trick_name, dir)
	if not FileAccess.file_exists(path):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_dict(parsed) if parsed is Dictionary else null
