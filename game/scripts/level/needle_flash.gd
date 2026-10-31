class_name NeedleFlash
extends Node
## T-451 (Level design, Decisions, "Threading the needle flashes the pair"): when the car threads the
## needle, the two paired obstacles and the dashed line between them flash, so the player sees which
## gap paid. Only the pair just threaded flashes (in a chained row, the other gaps stay still, an
## obstacle shared with the next gap included only while its own gap flashes: the flash belongs to
## one pair). The look is a proposal for the playtest: two quick white pulses over 0.6 seconds (the car is already metres on, so it is short); the
## obstacles brighten (their pixels mix towards white, up to 75 percent), the line goes opaque white and twice
## as thick. Code only, no new art. The run makes one (run.gd), binds it to the map and the
## ThreadTheNeedle, and it flashes on `threaded` (the step the trick pays).

const DURATION := 0.6
const PULSES := 2
## At the brightest the obstacle's pixels are this far towards white (modulate above 1 does not
## brighten in this renderer, so a small shader mixes the colour towards white; the alpha is kept).
const OBSTACLE_WHITEN := 0.75
const SHADER_CODE := "shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
"

static var _shader: Shader

## Per pair id: {t: seconds into the flash, sprites: [the two obstacles' sprites]}.
var active: Dictionary = {}
var needle: ThreadTheNeedle
var map: Node2D


func bind(the_needle: ThreadTheNeedle, the_map: Node2D) -> void:
	needle = the_needle
	map = the_map
	active.clear()
	needle.threaded.connect(start)


## The pulse at `t` seconds into the flash: 1 at the start, back to 0 at each pulse's end.
static func intensity_at(t: float) -> float:
	if t < 0.0 or t >= DURATION:
		return 0.0
	return 0.5 * (1.0 + cos(TAU * PULSES * t / DURATION))


## Starts (or restarts) the flash of pair `pair_id`.
func start(pair_id: String) -> void:
	var sprites: Array = []
	for g in needle.gates:
		if str(g.id) == pair_id:
			for ref in g.refs:
				var sp = sprite_of(map, str(ref))
				if sp != null:
					sprites.append(sp)
	active[pair_id] = {"t": 0.0, "sprites": sprites}
	_apply(pair_id)


func is_flashing(pair_id: String) -> bool:
	return active.has(pair_id)


## The sprite drawing obstacle `ref` (ObstaclePairs) on `map`: a prop's by its id, a boulder's by its
## centre. null when it has none.
static func sprite_of(the_map: Node2D, ref: String) -> Object:
	if the_map == null:
		return null
	var o := ObstaclePairs.resolve(the_map.layout, ref)
	if o.is_empty():
		return null
	if str(o.kind) == "prop":
		for sp in the_map.prop_sprites:
			if is_instance_valid(sp) and str(sp.prop_id) == str(o.item.get("id", "")):
				return sp
		return null
	var c: Vector2 = o.centre
	for sp in the_map.boulder_sprites:
		if is_instance_valid(sp) and sp.centre_units.distance_to(c) < 0.01:
			return sp
	return null


func _process(delta: float) -> void:
	advance(delta)


## Moves every flash on by `dt` seconds; a finished one is put back to rest and removed.
func advance(dt: float) -> void:
	for id in active.keys():
		active[id].t += dt
		if active[id].t >= DURATION:
			_rest(id)
			active.erase(id)
		else:
			_apply(id)


func _apply(pair_id: String) -> void:
	var v := intensity_at(float(active[pair_id].t))
	for sp in active[pair_id].sprites:
		if is_instance_valid(sp):
			if sp.material == null:
				var mat := ShaderMaterial.new()
				mat.shader = _shader_of()
				sp.material = mat
			(sp.material as ShaderMaterial).set_shader_parameter("flash", OBSTACLE_WHITEN * v)
	var m = needle.markers.get(pair_id)
	if m != null and is_instance_valid(m):
		m.set_flash(v)


static func _shader_of() -> Shader:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


func _rest(pair_id: String) -> void:
	for sp in active[pair_id].sprites:
		if is_instance_valid(sp):
			sp.material = null
	var m = needle.markers.get(pair_id)
	if m != null and is_instance_valid(m):
		m.set_flash(0.0)
