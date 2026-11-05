extends RefCounted
## The placeholder effects of the paired meteors (task T-539; Enemies,
## Decisions, "Paired meteors hurt the kaiju"), drawn in code by
## kaiju_meteors.gd's drawings; this file only knows how. No generated art.
##
## - The pair line: a faint cyan dashed line on the ground between the edges
##   of the two circles (or boulders) of a pair, so the player sees which two
##   belong together; brighter and pulsing once both have landed (armed).
## - The break-up: each boulder of a struck pair bursts into rock chunks in the
##   boulders' navy, purple and magenta that fly out and fall, with a magenta
##   flash ring.
## - The link: a jagged cyan and pink energy beam that shoots from the middle
##   of the pair to the kaiju's chest, then fades; when it reaches the kaiju, a
##   burst of rings and rays there (the kaiju's red hit flash comes from its own
##   take_damage).
## The game's own effects glow pink and cyan (Visual style), the alien rock
## keeps its own colours. Everything is a pure function of the effect's age.

## How long the beam lasts, and the part of it spent shooting to the kaiju.
const LINK_SECONDS := 0.7
const LINK_TRAVEL_SECONDS := 0.15
## How long the burst on the kaiju lasts, from the beam's arrival.
const KAIJU_BURST_SECONDS := 0.45
## How long a boulder's break-up lasts.
const BREAKUP_SECONDS := 0.55

const CYAN := Color(0.45, 0.95, 1.0)
const PINK := Color(1.0, 0.45, 0.85)
const WHITE := Color(1.0, 0.98, 1.0)
const PAIR_LINE := Color(0.45, 0.95, 1.0, 0.35)
const PAIR_LINE_ARMED := Color(0.55, 1.0, 1.0, 0.7)
const ROCK := Color(0.20, 0.14, 0.32)
const ROCK_DARK := Color(0.05, 0.04, 0.10)
const ROCK_GLOW := Color(0.85, 0.30, 0.90)

const CHUNKS := 9


## The dashed line from `from` to `to` (screen pixels of the view: the edges
## of the two circles of a pair, facing each other).
static func draw_pair_line(ci: CanvasItem, from: Vector2, to: Vector2, armed: bool, pulse: float) -> void:
	var col := PAIR_LINE
	var width := 2.0
	if armed:
		col = PAIR_LINE_ARMED
		col.a *= 0.75 + 0.25 * sin(pulse * TAU)
		width = 3.0
	ci.draw_dashed_line(from, to, col, width, 8.0)
	# Small diamonds at both ends, so the line reads as a link, not a crack.
	for p in [from, to]:
		var s := 4.0
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s, 0), p + Vector2(0, s), p + Vector2(-s, 0)]), col)


## The beam from `from` (the pair's middle on the ground) to `to` (the
## kaiju's chest), both screen pixels, `age` seconds after the strike.
static func draw_link(ci: CanvasItem, from: Vector2, to: Vector2, age: float, seed_: int) -> void:
	var reach := clampf(age / LINK_TRAVEL_SECONDS, 0.0, 1.0)
	var fade := 1.0 - clampf((age - LINK_TRAVEL_SECONDS) / maxf(LINK_SECONDS - LINK_TRAVEL_SECONDS, 0.001), 0.0, 1.0)
	var end := from.lerp(to, reach)
	var pts := _jagged(from, end, age, seed_)
	var glow := PINK
	glow.a = 0.55 * fade
	var core := CYAN
	core.a = fade
	var hot := WHITE
	hot.a = fade
	ci.draw_polyline(pts, glow, 12.0 * (0.6 + 0.4 * fade))
	ci.draw_polyline(pts, core, 5.0)
	ci.draw_polyline(pts, hot, 2.0)
	# The beam's head while it travels, and a glow where it leaves the pair.
	ci.draw_circle(from, 9.0 * fade + 2.0, Color(CYAN, 0.6 * fade))
	if reach < 1.0:
		ci.draw_circle(end, 8.0, WHITE)
	else:
		draw_kaiju_burst(ci, to, age - LINK_TRAVEL_SECONDS)


## The burst on the kaiju `t` seconds after the beam reached it.
static func draw_kaiju_burst(ci: CanvasItem, at: Vector2, t: float) -> void:
	if t < 0.0 or t >= KAIJU_BURST_SECONDS:
		return
	var f := t / KAIJU_BURST_SECONDS
	var a := 1.0 - f
	ci.draw_circle(at, 22.0 * (1.0 - f) + 4.0, Color(WHITE, 0.8 * a))
	ci.draw_arc(at, 14.0 + 50.0 * f, 0.0, TAU, 32, Color(CYAN, a), 5.0 * a + 1.0)
	ci.draw_arc(at, 8.0 + 34.0 * f, 0.0, TAU, 32, Color(PINK, a), 4.0 * a + 1.0)
	for i in 8:
		var dir := Vector2.RIGHT.rotated(TAU * i / 8.0 + 0.2)
		ci.draw_line(at + dir * (10.0 + 30.0 * f), at + dir * (22.0 + 48.0 * f), Color(WHITE, a), 3.0)


## A boulder breaking up at `at` (its ground point, screen pixels), `age`
## seconds after the strike: chunks fly out and fall, a magenta flash ring.
static func draw_breakup(ci: CanvasItem, at: Vector2, age: float, seed_: int) -> void:
	var f := clampf(age / BREAKUP_SECONDS, 0.0, 1.0)
	var a := 1.0 - f
	var centre := at - Vector2(0, 18.0)  # the boulder's body, above its ground point
	ci.draw_arc(centre, 10.0 + 40.0 * f, 0.0, TAU, 28, Color(ROCK_GLOW, a), 4.0 * a + 1.0)
	if f < 0.25:
		ci.draw_circle(centre, 26.0 * (1.0 - f * 4.0), Color(WHITE, 0.7 * (1.0 - f * 4.0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for i in CHUNKS:
		var ang := TAU * (i + rng.randf() * 0.6) / CHUNKS
		var speed := 70.0 + rng.randf() * 60.0  # px/s outwards
		var up := 90.0 + rng.randf() * 80.0  # px/s upwards
		var t := age
		var p := centre + Vector2(cos(ang) * speed * t, sin(ang) * speed * t * 0.5 - up * t + 260.0 * t * t)
		var s := (5.0 + rng.randf() * 4.0) * (1.0 - 0.5 * f)
		ci.draw_rect(Rect2(p - Vector2(s + 1, s + 1), Vector2(2 * s + 2, 2 * s + 2)), Color(ROCK_DARK, a))
		ci.draw_rect(Rect2(p - Vector2(s, s), Vector2(2 * s, 2 * s)), Color(ROCK, a))
		ci.draw_rect(Rect2(p - Vector2(s * 0.4, s * 0.4), Vector2(s * 0.8, s * 0.8)), Color(ROCK_GLOW, a))


## The beam's points: a straight line from `a` to `b` broken into segments
## that jitter sideways (changing a few times a second).
static func _jagged(a: Vector2, b: Vector2, age: float, seed_: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var d := b - a
	var n := maxi(2, int(d.length() / 18.0))
	var side := Vector2(-d.y, d.x).normalized() if d.length() > 0.001 else Vector2.ZERO
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_ * 131 + int(age * 20.0)
	for i in n + 1:
		var t := i / float(n)
		var off := 0.0 if i == 0 or i == n else (rng.randf() - 0.5) * 14.0
		pts.append(a + d * t + side * off)
	return pts
