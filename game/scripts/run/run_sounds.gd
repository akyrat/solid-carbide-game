class_name RunSounds
extends Node
## The run's sound effects (task T-077). One node, child "Sounds" of the run
## scene, that listens to the run and plays the approved sounds (T-076):
##
##  - engine: a loop all run long; faster and louder with the car's speed.
##  - drift: a loop while the car drifts; stops when the drift stops.
##  - gun: once per volley of the starting gun.
##  - flames: a loop while the exhaust flamethrower's flames are on.
##  - hit: a weapon (a bullet or the flames) hurts an enemy.
##  - coin: the run's coin count goes up (a coin was picked up).
##  - meteor warning / impact: the kaiju's meteors (warning circles appear / a meteor lands).
##
## Every file, volume and limit is in data/sfx.json (the place to tune by ear).
## The sounds follow the tree's pause (a level-up or the pause screen silences
## them) and stop when the run ends.

const SFX_FILE := "sfx"
const SFX_DIR := "res://audio/sfx/"
const CameraFollowScript := preload("res://scripts/driving/camera_follow.gd")

var run: Node = null
## id -> {"def": Dictionary, "stream": AudioStream, "players": Array, "wanted": bool}
var sounds: Dictionary = {}
## id -> how many times it was played (tests, notes).
var play_counts: Dictionary = {}
var _last_play_msec: Dictionary = {}
var _last_volley := 0
var _last_coins := 0
var _car: Node = null


func _init() -> void:
	name = "Sounds"
	# Every sound plays on the SFX bus, whose volume is the pause screen's "SFX volume"
	# slider (default 0 = silent, saved). It is applied here so the saved value counts
	# from the start of a run.
	GameSettings.apply_sfx_volume(GameSettings.load_sfx_volume())
	var data = GameData.unwrap(GameData.load_file(SFX_FILE))
	if data == null:
		return
	for id in data["sounds"]:
		var def: Dictionary = data["sounds"][id]
		var loaded = load(SFX_DIR + String(def["file"]))
		if loaded == null:
			push_error("Sound file missing: %s" % def["file"])
			continue
		var stream: AudioStream = loaded.duplicate()
		var is_loop: bool = def.get("loop", false)
		if is_loop and stream is AudioStreamOggVorbis:
			stream.loop = true
		var players: Array = []
		for i in int(def.get("max_players", 1)):
			var p := AudioStreamPlayer.new()
			p.stream = stream
			p.bus = GameSettings.SFX_BUS
			p.volume_db = float(def["volume_db"])
			p.name = "%s%d" % [String(id).capitalize().replace(" ", ""), i]
			add_child(p)
			if is_loop and not (stream is AudioStreamOggVorbis):
				# A wav does not loop by itself here: start it over when it ends.
				p.finished.connect(_on_loop_finished.bind(id, p))
			players.append(p)
		sounds[id] = {"def": def, "stream": stream, "players": players, "wanted": false}
		play_counts[id] = 0


## Plays the sounds for `the_run` (run.gd). Follows world_rebuilt (a new run).
func bind(the_run: Node) -> void:
	run = the_run
	run.world_rebuilt.connect(_on_world_rebuilt)
	run.state.run_ended.connect(_on_run_ended)
	run.state.coins_changed.connect(_on_coins_changed)
	run.weapons.gun.fired.connect(_on_gun_fired)
	run.weapons.flamethrower.enemy_hit.connect(_on_flame_hit)
	run.kaiju_boss.meteors.warnings_shown.connect(_on_meteor_warnings)
	run.kaiju_boss.meteors.meteor_landed.connect(_on_meteor_landed)
	if run.car != null:
		_on_world_rebuilt()


func _on_world_rebuilt() -> void:
	stop_all()
	_car = run.car
	_last_volley = 0
	_last_coins = 0


func _on_run_ended(_result: String, _coins: int) -> void:
	stop_all()


func _physics_process(_delta: float) -> void:
	sync_loops()


# --- Playing -------------------------------------------------------------

func has_sound(id: String) -> bool:
	return sounds.has(id)


## Plays a one-shot sound `id` now, unless it played less than min_interval
## seconds ago. Returns true when it started. `from` is where in the file to
## start, in seconds. Uses a free player, or the first one when all are busy.
func play(id: String, from: float = 0.0) -> bool:
	if not sounds.has(id):
		return false
	var s: Dictionary = sounds[id]
	var now := Time.get_ticks_msec()
	var gap := float(s["def"].get("min_interval", 0.0)) * 1000.0
	if now - int(_last_play_msec.get(id, -1000000)) < gap:
		return false
	_last_play_msec[id] = now
	var chosen: AudioStreamPlayer = s["players"][0]
	for p in s["players"]:
		if not p.playing:
			chosen = p
			break
	chosen.play(from)
	play_counts[id] += 1
	return true


## True while a player of sound `id` is playing.
func is_playing(id: String) -> bool:
	if not sounds.has(id):
		return false
	for p in sounds[id]["players"]:
		if p.playing:
			return true
	return false


func _set_loop(id: String, on: bool) -> void:
	if not sounds.has(id):
		return
	var s: Dictionary = sounds[id]
	var p: AudioStreamPlayer = s["players"][0]
	s["wanted"] = on
	if on and not p.playing:
		p.play()
		play_counts[id] += 1
	elif not on and p.playing:
		p.stop()


func _on_loop_finished(id: String, p: AudioStreamPlayer) -> void:
	if sounds[id]["wanted"]:
		p.play()


func stop_all() -> void:
	for id in sounds:
		sounds[id]["wanted"] = false
		for p in sounds[id]["players"]:
			p.stop()


## Starts and stops the loops to match what the run is doing now, and sets the
## engine's pitch and volume from the car's speed. Called every physics frame.
func sync_loops() -> void:
	if run == null or _car == null or not is_instance_valid(_car):
		return
	var running: bool = run.state.is_running()
	_set_loop("engine", running)
	_set_loop("drift", running and _car.model.is_drifting)
	var fl = run.weapons.flamethrower
	_set_loop("flames", running and fl.is_owned() and fl.active)
	if sounds.has("engine"):
		var d: Dictionary = sounds["engine"]["def"]
		var f: float = CameraFollowScript.speed_fraction_of(_car.model)
		var p: AudioStreamPlayer = sounds["engine"]["players"][0]
		p.pitch_scale = lerpf(float(d["pitch_min"]), float(d["pitch_max"]), f)
		p.volume_db = lerpf(float(d["volume_db_min"]), float(d["volume_db_max"]), f)


# --- Moments -------------------------------------------------------------

func _on_gun_fired(bullet: Node, _target: Node) -> void:
	var gun = run.weapons.gun
	if gun.volleys != _last_volley:  # one sound per volley, not per bullet
		_last_volley = gun.volleys
		play("gun")
	bullet.hit.connect(_on_bullet_hit)


func _on_bullet_hit(_enemy: Node, _damage: float) -> void:
	play("hit")


func _on_flame_hit(_enemy: Node, _amount: float) -> void:
	play("hit")


func _on_coins_changed(coins: int) -> void:
	if coins > _last_coins:
		play("coin")
	_last_coins = coins


func _on_meteor_warnings(spots: Array) -> void:
	if spots.is_empty() or not sounds.has("meteor_warning"):
		return
	var from := 0.0
	var s: Dictionary = sounds["meteor_warning"]
	if s["def"].get("end_aligned", false):
		var warning: float = run.kaiju_boss.meteors.stat("warning_seconds")
		from = maxf(0.0, s["stream"].get_length() - warning)
	play("meteor_warning", from)


func _on_meteor_landed(_units: Vector2, _hit_car: bool) -> void:
	play("meteor_impact")
