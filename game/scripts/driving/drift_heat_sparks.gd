extends Node2D
## The sparks and flames of the hype drift trail (task T-249). Child of the
## drift marks: drawn over the marks, in the same flat world pixels (under the
## view's transform). Every particle is an opaque pixel square that shrinks and
## pops out when its life ends (no per-pixel alpha, no fading), in the colours
## its heat step's look gives (drift_marks.tscn, heat_looks).
##
## Sparks fly out fast and short from the tyre; flames (top step only) rise
## slowly, bigger, and go from orange to yellow to white-hot as they age.

## Most particles alive at once; a new one past it replaces the oldest.
const MAX_PARTICLES := 160
## The colours a flame goes through, young to old. Never red.
const FLAME_COLORS: Array[Color] = [Color(1.0, 0.6, 0.08), Color(1.0, 0.86, 0.25), Color(1.0, 0.98, 0.82)]

## Particles: {pos: Vector2, vel: Vector2, age: float, life: float, size: float,
## colors: Array, flame: bool}.
var particles: Array = []


func emit(at: Vector2, look: Dictionary, flame: bool) -> void:
	var a := randf() * TAU
	var colors: Array = look.spark_colors
	var vel := Vector2(cos(a), sin(a)) * float(look.spark_speed) * randf_range(0.4, 1.0)
	var size: float = look.spark_size_px
	var life: float = float(look.spark_life) * randf_range(0.7, 1.2)
	if flame:
		vel = Vector2(randf_range(-6.0, 6.0), randf_range(-26.0, -12.0))
		size = look.flame_size_px
		life = float(look.flame_life) * randf_range(0.8, 1.2)
		colors = FLAME_COLORS
	if particles.size() >= MAX_PARTICLES:
		particles.pop_front()
	particles.append({"pos": at + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)),
		"vel": vel, "age": 0.0, "life": life, "size": size, "colors": colors, "flame": flame})
	queue_redraw()


func age(delta: float) -> void:
	if particles.is_empty():
		return
	var keep: Array = []
	for p in particles:
		p.age += delta
		if p.age >= p.life:
			continue
		p.pos += p.vel * delta
		keep.append(p)
	particles = keep
	queue_redraw()


func clear() -> void:
	particles.clear()
	queue_redraw()


func _draw() -> void:
	for p in particles:
		var t: float = p.age / p.life
		var colors: Array = p.colors
		var c: Color
		if p.flame:
			c = colors[mini(int(t * colors.size()), colors.size() - 1)]
		else:
			c = colors[int(abs(sin(p.pos.x * 12.9898 + p.pos.y * 78.233) * 43758.5453)) % colors.size()]
		var s := maxf(1.0, roundf(p.size * (1.0 - t * 0.6)))
		var at: Vector2 = (p.pos - Vector2(s, s) * 0.5).round()
		draw_rect(Rect2(at, Vector2(s, s)), c)
