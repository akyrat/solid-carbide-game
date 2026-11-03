extends Node2D
## The green liquid one dying minion spills (task T-531; Enemies, Decisions, "Minion deaths";
## Visual style, Decisions, "The minion's death animation and green spill"), drawn in code:
## hard-edged square pixels, no blur, no texture.
##
## A burst of droplets leaves the body with a speed each, rises, falls under gravity and, where
## it lands, makes or feeds a small pool on the ground there. The ground is the map's heights
## (EnemyHeight.height_at), so a droplet lands on the rooftop or the ramp it falls onto and the
## pool is drawn at that height. A pool spreads out for a moment after it lands. All of one
## burst's droplets and pools are in this one node (parallel arrays, one _draw), so a death costs
## one node however many droplets it makes; the node redraws only while something moves, grows
## or changes.
##
## The corpse keeper (minion_corpses.gd) makes one per death, caps how many droplets and pools
## exist, steps it and fades it with the corpse (begin_fade).
##
## Colours: a slimy acid green of its own, clear of Greenbull's brand greens (dark 12,76,44,
## light 104,220,96, yellow 247,208,52): more yellow than the light green and brighter than the
## minion's own body.

const PX_PER_UNIT := 16.0
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const EnemyHeightScript := preload("res://scripts/enemies/enemy_height.gd")

## The size of one liquid pixel on screen (the art's pixels, doubled so it reads at play size).
const PIXEL := 2.0
const COLOR_BODY := Color(0.55, 0.88, 0.10)
const COLOR_LIGHT := Color(0.80, 0.98, 0.35)
const COLOR_DARK := Color(0.30, 0.55, 0.08)
## A droplet landing within this many screen pixels of a pool feeds it instead of making another.
const MERGE_PX := 5.0

# One droplet per index: flat position (units), height (units), velocity (units/s).
var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _h := PackedFloat32Array()
var _vx := PackedFloat32Array()
var _vy := PackedFloat32Array()
var _vh := PackedFloat32Array()
# One pool per index: screen centre (this node's pixels), radius it spreads to and has now (px).
var _pool_at := PackedVector2Array()
var _pool_max := PackedFloat32Array()
var _pool_r := PackedFloat32Array()

var gravity := 24.0
var spread_seconds := 0.35
var pool_max_radius_px := 7.0
var pool_max_seconds := 8.0
var age := 0.0
## Seconds of fade left (-1: not fading). It fades the whole node (modulate).
var fade_left := -1.0
var fade_total := 0.4
var ground = null
var _dirty := true


## Starts a burst of `count` droplets from `at_units` (flat world), at height `start_height`
## (units, absolute), with the numbers of `p` (enemies.json minion.death), random from `rng`.
func burst(at_units: Vector2, start_height: float, count: int, p: Dictionary, rng: RandomNumberGenerator) -> void:
	gravity = float(p.get("droplet_gravity", 24.0))
	spread_seconds = maxf(float(p.get("pool_spread_seconds", 0.35)), 0.01)
	pool_max_radius_px = float(p.get("pool_max_radius_px", 7.0))
	pool_max_seconds = float(p.get("pool_max_seconds", 8.0))
	fade_total = maxf(float(p.get("fade_seconds", 0.4)), 0.01)
	var s0 := float(p.get("droplet_speed_min", 2.5))
	var s1 := maxf(float(p.get("droplet_speed_max", 6.0)), s0)
	var u0 := float(p.get("droplet_up_min", 4.0))
	var u1 := maxf(float(p.get("droplet_up_max", 8.0)), u0)
	for i in count:
		var a := rng.randf() * TAU
		var sp := rng.randf_range(s0, s1)
		_x.append(at_units.x)
		_y.append(at_units.y)
		_h.append(start_height)
		_vx.append(cos(a) * sp)
		_vy.append(sin(a) * sp)
		_vh.append(rng.randf_range(u0, u1))
	_dirty = true
	queue_redraw()


func droplet_count() -> int:
	return _x.size()


func pool_count() -> int:
	return _pool_at.size()


## The pool `i`'s radius in screen pixels now, and the one it spreads to.
func pool_radius(i: int) -> float:
	return _pool_r[i]


func pool_final_radius(i: int) -> float:
	return _pool_max[i]


## The pool `i`'s centre on screen (this node's pixels).
func pool_screen(i: int) -> Vector2:
	return _pool_at[i]


## The droplet `i`'s height in units, for the tests.
func droplet_height(i: int) -> float:
	return _h[i]


## The droplet `i`'s flat position in units.
func droplet_units(i: int) -> Vector2:
	return Vector2(_x[i], _y[i])


## One step of `dt` seconds: droplets fly and land, pools spread, the fade runs.
## `pool_room` is how many more new pools may be made (the keeper's cap); a droplet that
## lands near a pool still feeds it. Returns true while the node still has something to show.
func step(dt: float, pool_room: int = 1000000) -> bool:
	age += dt
	if fade_left < 0.0 and age >= pool_max_seconds:
		begin_fade(fade_total)
	var i := 0
	while i < _x.size():
		_vh[i] -= gravity * dt
		_x[i] += _vx[i] * dt
		_y[i] += _vy[i] * dt
		_h[i] += _vh[i] * dt
		var at := Vector2(_x[i], _y[i])
		var g := EnemyHeightScript.height_at(ground, at)
		if _h[i] <= g and _vh[i] <= 0.0:
			if _land(at, g, pool_room > 0):
				pool_room -= 1
			_remove_droplet(i)
			continue
		i += 1
	var spreading := false
	for k in _pool_r.size():
		if _pool_r[k] < _pool_max[k]:
			_pool_r[k] = minf(_pool_r[k] + _pool_max[k] * dt / spread_seconds, _pool_max[k])
			spreading = true
	if _x.size() > 0 or spreading or _dirty:
		queue_redraw()
		_dirty = false
	if fade_left >= 0.0:
		fade_left -= dt
		modulate.a = clampf(fade_left / fade_total, 0.0, 1.0)
		if fade_left <= 0.0:
			return false
	return true


## Starts fading out over `seconds` (once).
func begin_fade(seconds: float) -> void:
	if fade_left < 0.0:
		fade_total = maxf(seconds, 0.01)
		fade_left = fade_total


func is_fading() -> bool:
	return fade_left >= 0.0


func _screen_at(at_units: Vector2, g: float) -> Vector2:
	return ISO_TRANSFORM * (at_units * PX_PER_UNIT) - Vector2(0.0, g * PX_PER_UNIT)


## A droplet lands at `at_units` on ground `g`: feeds a pool nearby or, when `may_make` and
## there is no pool near, makes a new one. Returns true when it made a new pool.
func _land(at_units: Vector2, g: float, may_make: bool) -> bool:
	var s := _screen_at(at_units, g)
	for k in _pool_at.size():
		if _pool_at[k].distance_to(s) <= MERGE_PX:
			_pool_max[k] = minf(_pool_max[k] + 2.0, pool_max_radius_px)
			_dirty = true
			return false
	if not may_make:
		return false
	_pool_at.append(s)
	_pool_max.append(minf(4.0, pool_max_radius_px))
	_pool_r.append(1.0)
	_dirty = true
	return true


func _remove_droplet(i: int) -> void:
	var last := _x.size() - 1
	_x[i] = _x[last]
	_y[i] = _y[last]
	_h[i] = _h[last]
	_vx[i] = _vx[last]
	_vy[i] = _vy[last]
	_vh[i] = _vh[last]
	_x.resize(last)
	_y.resize(last)
	_h.resize(last)
	_vx.resize(last)
	_vy.resize(last)
	_vh.resize(last)


func _draw() -> void:
	if Perf.on: Perf.each_begin(&"draw.minion_spill")
	for k in _pool_at.size():
		_draw_pool(_pool_at[k], _pool_r[k])
	for i in _x.size():
		var s := _screen_at(Vector2(_x[i], _y[i]), _h[i])
		var p := Vector2(roundf(s.x / PIXEL) * PIXEL, roundf(s.y / PIXEL) * PIXEL)
		draw_rect(Rect2(p, Vector2(PIXEL, PIXEL)), COLOR_BODY)
		draw_rect(Rect2(p, Vector2(PIXEL * 0.5, PIXEL * 0.5)), COLOR_LIGHT)
	if Perf.on: Perf.each_end(&"draw.minion_spill")


## A flat pool: a dark rim, the body colour inside, a light spot, all in whole PIXEL steps.
func _draw_pool(c: Vector2, r: float) -> void:
	var rx := maxf(roundf(r / PIXEL), 1.0)
	var ry := maxf(roundf(rx * 0.55), 1.0)
	var cx := roundf(c.x / PIXEL)
	var cy := roundf(c.y / PIXEL)
	for row in range(-int(ry), int(ry) + 1):
		var t := float(row) / (ry + 0.5)
		var w := int(roundf(rx * sqrt(maxf(1.0 - t * t, 0.0))))
		draw_rect(Rect2((cx - w) * PIXEL, (cy + row) * PIXEL, (2 * w + 1) * PIXEL, PIXEL), COLOR_DARK)
		if w >= 2 and absi(row) < int(ry) + 1 and absi(row) < int(ry):
			draw_rect(Rect2((cx - w + 1) * PIXEL, (cy + row) * PIXEL, (2 * w - 1) * PIXEL, PIXEL), COLOR_BODY)
	if rx >= 3.0:
		draw_rect(Rect2((cx - 1) * PIXEL, (cy - int(ry) + 1) * PIXEL, PIXEL, PIXEL), COLOR_LIGHT)
