extends Node2D
## The wreck's smoke and flames (task T-360; Game loop architecture, Decisions,
## "Wrecked: the stream keeps rolling"): when the car's last heart is gone it
## smokes and burns for the wreck's seconds, until the run ends.
##
## - Flames: a few flickering tongues on the car, drawn where the car is drawn
##   every frame (follow()), so they ride along while the wreck slides.
## - Smoke: puffs leave the car, stay where they were left in the view, rise and
##   drift a little, grow and then shrink, and pop out at the end of their life.
## - Placeholders drawn in code (this file's _draw): opaque pixel squares, no
##   fading (Visual style, "See-through rule"), smoke in greys, flames in red,
##   orange, light orange and a white-hot core, none of Greenbull's colours
##   (Visual style, Content, "Rules", rule 6).
## - The art swap (T-361): set `smoke_frames` and/or `flame_frames` (a
##   SpriteFrames with an animation named "default"). A puff then draws the
##   smoke frame for its age (first frame at birth, last at the end of its life),
##   and the flames loop the flame frames at the SpriteFrames' own speed. Nothing
##   else changes; the placeholder drawing is used only while they are null.
##
## Numbers: run.json's wreck section (RunData.wreck(), configure()). It ages in
## _process (the default, pausable process mode), so pause freezes it with the
## rest of the wreck. The run scene (run.gd) adds it to the drawn view, above
## the car sprite, starts it on RunState.wreck_started and stops it on a new run.

const SMOKE_DARK := Color8(54, 54, 62)
const SMOKE_MID := Color8(92, 92, 102)
const SMOKE_LIGHT := Color8(136, 136, 146)
const FLAME_RED := Color8(200, 44, 30)
const FLAME_ORANGE := Color8(242, 112, 32)
const FLAME_LIGHT := Color8(255, 162, 70)
const FLAME_CORE := Color8(255, 238, 220)
## Every placeholder colour, for the tests' colour check.
const COLOURS := [SMOKE_DARK, SMOKE_MID, SMOKE_LIGHT, FLAME_RED, FLAME_ORANGE, FLAME_LIGHT, FLAME_CORE]

## The art's animations (T-361). Null: the placeholder drawing.
var smoke_frames: SpriteFrames = null
var flame_frames: SpriteFrames = null

var puffs_per_second := 12.0
var smoke_life := 1.4
var rise_px_per_second := 16.0
var drift_px_per_second := 4.0
var max_radius_px := 9.0
var flame_tongues := 5
var flame_height_px := 16.0
var flickers_per_second := 12.0
var pixel_px := 2.0

## Where the car is drawn now (the run's View coordinates).
var emitter := Vector2.ZERO
## Seconds since start().
var time := 0.0
## Smoke puffs, oldest first: {at: Vector2 (birth place), velocity: Vector2, born: float}.
var puffs: Array = []

var _playing := false
var _spawn_debt := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "WreckEffect"
	visible = false
	_rng.seed = 360


## Takes the numbers from run.json's wreck section (missing keys keep their default).
func configure(cfg: Dictionary) -> void:
	puffs_per_second = float(cfg.get("smoke_puffs_per_second", puffs_per_second))
	smoke_life = maxf(float(cfg.get("smoke_life_seconds", smoke_life)), 0.01)
	rise_px_per_second = float(cfg.get("smoke_rise_px_per_second", rise_px_per_second))
	drift_px_per_second = float(cfg.get("smoke_drift_px_per_second", drift_px_per_second))
	max_radius_px = float(cfg.get("smoke_max_radius_px", max_radius_px))
	flame_tongues = int(cfg.get("flame_tongues", flame_tongues))
	flame_height_px = float(cfg.get("flame_height_px", flame_height_px))
	flickers_per_second = float(cfg.get("flame_flickers_per_second", flickers_per_second))
	pixel_px = maxf(float(cfg.get("pixel_px", pixel_px)), 1.0)


## Starts smoking and burning at `at` (where the car is drawn).
func start(at: Vector2) -> void:
	emitter = at
	time = 0.0
	puffs.clear()
	_spawn_debt = 1.0  # the first puff at once
	_playing = true
	visible = true
	_spawn_due()
	queue_redraw()


## Stops and clears everything (a new run).
func stop() -> void:
	_playing = false
	visible = false
	puffs.clear()
	queue_redraw()


func is_playing() -> bool:
	return _playing


## Keeps the flames and the new puffs on the car: `at` is where the car is drawn now.
func follow(at: Vector2) -> void:
	emitter = at


func _process(delta: float) -> void:
	Perf.begin(&"effects.wreck")
	advance(delta)
	Perf.end(&"effects.wreck")


## Ages the effect by `delta` seconds: new puffs, old ones gone. Tests call it by hand.
func advance(delta: float) -> void:
	if not _playing or delta <= 0.0:
		return
	time += delta
	while not puffs.is_empty() and time - float(puffs[0].born) >= smoke_life:
		puffs.pop_front()
	_spawn_debt += delta * puffs_per_second
	_spawn_due()
	queue_redraw()


func _spawn_due() -> void:
	while _spawn_debt >= 1.0:
		_spawn_debt -= 1.0
		var side := _rng.randf_range(-1.0, 1.0)
		puffs.append({
			"at": emitter + Vector2(side * max_radius_px * 0.6, -flame_height_px * 0.5),
			"velocity": Vector2(side * drift_px_per_second, -rise_px_per_second),
			"born": time,
		})


## Where a puff is drawn now.
func puff_position(p: Dictionary) -> Vector2:
	return p.at + p.velocity * (time - float(p.born))


## A puff's radius now, px: it grows over the first half of its life, then shrinks.
func puff_radius(p: Dictionary) -> float:
	var f := clampf((time - float(p.born)) / smoke_life, 0.0, 1.0)
	var grow := f / 0.5 if f < 0.5 else (1.0 - f) / 0.5
	return maxf(max_radius_px * (0.35 + 0.65 * grow), pixel_px)


## The flame tongues' heights now, px, one per tongue: they flicker in steps.
func flame_heights() -> Array:
	var step := int(floor(time * flickers_per_second))
	var out: Array = []
	for i in flame_tongues:
		var h := float(absi(hash(Vector2i(step, i))) % 1000) / 1000.0
		out.append(flame_height_px * (0.55 + 0.45 * h))
	return out


## The flames' base: on the car, centred under the tongues.
func flame_base() -> Vector2:
	return emitter + Vector2(0.0, -pixel_px * 2.0)


func _snap(v: Vector2) -> Vector2:
	return (v / pixel_px).floor() * pixel_px


func _draw() -> void:
	if Perf.on: Perf.each_begin(&"draw.wreck")
	if not _playing:
		if Perf.on: Perf.each_end(&"draw.wreck")
		return
	for p in puffs:
		_draw_puff(p)
	_draw_flames()
	if Perf.on: Perf.each_end(&"draw.wreck")


func _draw_puff(p: Dictionary) -> void:
	var c := _snap(puff_position(p))
	if smoke_frames != null and smoke_frames.has_animation("default") and smoke_frames.get_frame_count("default") > 0:
		var n := smoke_frames.get_frame_count("default")
		var f := clampf((time - float(p.born)) / smoke_life, 0.0, 0.999)
		var tex := smoke_frames.get_frame_texture("default", int(f * n))
		draw_texture(tex, c - tex.get_size() * 0.5)
		return
	var r := puff_radius(p)
	var cells := int(ceil(r / pixel_px))
	for gy in range(-cells, cells + 1):
		for gx in range(-cells, cells + 1):
			var d := Vector2(gx, gy).length() * pixel_px
			if d > r:
				continue
			# Lit from the top left: a light cap, a mid body, a dark rim below.
			var lit := (Vector2(gx, gy) * pixel_px - Vector2(-r, -r) * 0.35).length()
			var col := SMOKE_DARK if d > r * 0.75 and gy >= 0 else (SMOKE_LIGHT if lit < r * 0.55 else SMOKE_MID)
			draw_rect(Rect2(c + Vector2(gx, gy) * pixel_px, Vector2(pixel_px, pixel_px)), col)


func _draw_flames() -> void:
	var base := _snap(flame_base())
	if flame_frames != null and flame_frames.has_animation("default") and flame_frames.get_frame_count("default") > 0:
		var n := flame_frames.get_frame_count("default")
		var fps := flame_frames.get_animation_speed("default")
		var tex := flame_frames.get_frame_texture("default", int(floor(time * fps)) % n)
		draw_texture(tex, base - Vector2(tex.get_size().x * 0.5, tex.get_size().y))
		return
	var heights := flame_heights()
	var width := flame_tongues * pixel_px
	for i in heights.size():
		var x := base.x - width * 0.5 + i * pixel_px
		var cells := int(ceil(float(heights[i]) / pixel_px))
		for k in cells:
			var f := float(k) / maxf(cells - 1, 1)
			var col := FLAME_CORE if f < 0.2 else (FLAME_LIGHT if f < 0.45 else (FLAME_ORANGE if f < 0.75 else FLAME_RED))
			draw_rect(Rect2(Vector2(x, base.y - (k + 1) * pixel_px), Vector2(pixel_px, pixel_px)), col)
	# A one-pixel orange edge either side at the bottom, so the fire reads
	# wider than a stack of single columns.
	draw_rect(Rect2(Vector2(base.x - width * 0.5 - pixel_px, base.y - pixel_px * 2.0), Vector2(pixel_px, pixel_px * 2.0)), FLAME_ORANGE)
	draw_rect(Rect2(Vector2(base.x + width * 0.5, base.y - pixel_px * 2.0), Vector2(pixel_px, pixel_px * 2.0)), FLAME_ORANGE)
