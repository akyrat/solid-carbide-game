class_name Reactions
extends Control
## Reaction icons like a livestream's (T-351; HUD and menus, Decisions, "The HUD
## looks like a livestream"). Two moments: a burst out of the sub goal square when
## the goal is reached (burst()), and, while the live viewers count is high, a few
## icons floating up from the bottom of the screen at uneven gaps (the rate per look
## step in hud.json reactions.rates_per_second; none below the first heat step).
##
## They must not get in the way: small, partly transparent, floaters kept to the left
## and right thirds, never starting over the middle where the car is, faded out
## before the middle, at most `cap` on screen at once. The Hud makes this its first
## child, so everything else is drawn over it. Pausable; clear() on a new run.
## The pictures are placeholders drawn in code (pixel hearts and thumbs up) until
## T-352's art. Numbers: res://data/hud.json, reactions.

## 1 is a filled pixel, 0 is empty; drawn at `icon_scale` pixels per cell.
const HEART := [
	"0110110",
	"1111111",
	"1111111",
	"0111110",
	"0011100",
	"0001000",
]
const THUMB := [
	"0001100",
	"0001100",
	"0011100",
	"1111110",
	"1111111",
	"1111111",
	"1111110",
	"0111100",
]
const KINDS := [HEART, THUMB]
## Colours of the placeholders: none is the viewers cyan, the heart red or Greenbull's.
const COLORS := [Color("#ff6fae"), Color("#ff8c3a"), Color("#b58cff"), Color("#f4f4ff")]
const DEFAULT_CFG := {
	"cap": 12, "alpha": 0.7, "icon_scale": 3,
	"rates_per_second": [0.0, 0.2, 0.4, 0.7, 1.2],
	"group_min": 1, "group_max": 3, "gap_min_share": 0.4, "gap_max_share": 1.8,
	"rise_min": 70.0, "rise_max": 130.0, "wobble_px": 14.0, "wobble_hz": 0.6,
	"lane_edge": 0.03, "lane_inner": 0.28, "fade_in": 0.25,
	"burst_count": 10, "burst_speed_min": 200.0, "burst_speed_max": 420.0,
	"burst_drag": 1.5, "burst_rise": 30.0, "burst_seconds_min": 1.3, "burst_seconds_max": 1.9,
}

var cfg: Dictionary = DEFAULT_CFG.duplicate()
## Each: {kind, color, pos (centre), vel, age, life, base_x, phase, floater}.
var items: Array = []
var rng := RandomNumberGenerator.new()
## Called each frame for the live viewers counter's look step (0 base ... 4 fire).
var step_source: Callable = Callable()
## Seconds until the next group, -1 while the rate is 0.
var next_in := -1.0
var bursts_started := 0
## Tests set the screen size here (a headless viewport is 64 x 64).
var area_override := Vector2.ZERO


func _init() -> void:
	name = "Reactions"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.randomize()
	var r := GameData.load_file("hud")
	if r.ok and r.data.has("reactions"):
		for k: String in (r.data["reactions"] as Dictionary):
			if not k.begins_with("_"):
				cfg[k] = r.data["reactions"][k]


func cap() -> int:
	return int(cfg["cap"])


## The screen size the icons use: this Control's, or the viewport's when it is 0.
func area() -> Vector2:
	if area_override != Vector2.ZERO:
		return area_override
	if size.x > 1.0 and size.y > 1.0:
		return size
	return get_viewport_rect().size


## Groups of floaters per second for a look step; steps past the list use the last.
func rate_for_step(step: int) -> float:
	var rates: Array = cfg["rates_per_second"]
	if rates.is_empty():
		return 0.0
	return float(rates[clampi(step, 0, rates.size() - 1)])


func clear() -> void:
	items.clear()
	next_in = -1.0
	queue_redraw()


func count() -> int:
	return items.size()


func _add(it: Dictionary) -> bool:
	if items.size() >= cap():
		return false
	items.append(it)
	return true


func _new_item(pos: Vector2, vel: Vector2, life: float, floater: bool) -> Dictionary:
	return {
		"kind": rng.randi() % KINDS.size(), "color": COLORS[rng.randi() % COLORS.size()],
		"pos": pos, "vel": vel, "age": 0.0, "life": life, "base_x": pos.x,
		"phase": rng.randf() * TAU, "floater": floater,
	}


## A group of floaters entering from the bottom, in the left or right third.
func spawn_group() -> int:
	var a := area()
	var n := rng.randi_range(int(cfg["group_min"]), int(cfg["group_max"]))
	var left := rng.randf() < 0.5
	var added := 0
	for i in n:
		var u := rng.randf_range(float(cfg["lane_edge"]), float(cfg["lane_inner"]))
		var x := a.x * (u if left else 1.0 - u)
		var rise := rng.randf_range(float(cfg["rise_min"]), float(cfg["rise_max"]))
		var half := 4.0 * float(cfg["icon_scale"])
		var y := a.y + half + rng.randf() * 40.0
		# Climbs the whole screen, so it is long gone before it is done.
		var life := (a.y + 2.0 * half) / rise
		if _add(_new_item(Vector2(x, y), Vector2(0, -rise), life, true)):
			added += 1
	return added


## The sub goal's burst: icons pop out of `origin` all at once, fanned up and out,
## slowing as they go. Older icons make room under the cap.
func burst(origin: Vector2) -> int:
	bursts_started += 1
	var n := mini(int(cfg["burst_count"]), cap())
	while items.size() + n > cap() and not items.is_empty():
		items.remove_at(0)
	var added := 0
	for i in n:
		var ang := deg_to_rad(rng.randf_range(-165.0, -15.0))
		var sp := rng.randf_range(float(cfg["burst_speed_min"]), float(cfg["burst_speed_max"]))
		var life := rng.randf_range(float(cfg["burst_seconds_min"]), float(cfg["burst_seconds_max"]))
		if _add(_new_item(origin, Vector2(cos(ang), sin(ang)) * sp, life, false)):
			added += 1
	queue_redraw()
	return added


## Opacity of an item at its age: eases in, holds, fades out over the last half.
func alpha_of(it: Dictionary) -> float:
	var t: float = it["age"]
	var life: float = it["life"]
	var a := minf(1.0, t / maxf(float(cfg["fade_in"]), 0.01))
	var f := t / maxf(life, 0.01)
	if f > 0.5:
		a *= clampf(1.0 - (f - 0.5) / 0.5, 0.0, 1.0)
	return a * float(cfg["alpha"])


func advance(dt: float) -> void:
	var step := 0
	if step_source.is_valid():
		step = int(step_source.call())
	var rate := rate_for_step(step)
	if rate <= 0.0:
		next_in = -1.0
	else:
		if next_in < 0.0:
			next_in = _gap(rate)
		next_in -= dt
		if next_in <= 0.0:
			spawn_group()
			next_in = _gap(rate)
	var drag: float = float(cfg["burst_drag"])
	var i := items.size() - 1
	while i >= 0:
		var it: Dictionary = items[i]
		it["age"] += dt
		if it["floater"]:
			var sway := sin(it["phase"] + it["age"] * TAU * float(cfg["wobble_hz"])) * float(cfg["wobble_px"])
			it["pos"] = Vector2(it["base_x"] + sway, it["pos"].y + it["vel"].y * dt)
		else:
			it["vel"] = it["vel"] * maxf(0.0, 1.0 - drag * dt) + Vector2(0, -float(cfg["burst_rise"])) * dt
			it["pos"] += it["vel"] * dt
		if it["age"] >= it["life"] or it["pos"].y < -20.0:
			items.remove_at(i)
		i -= 1
	queue_redraw()


## An uneven gap: the mean for the rate, times a random share.
func _gap(rate: float) -> float:
	return rng.randf_range(float(cfg["gap_min_share"]), float(cfg["gap_max_share"])) / rate


func _process(dt: float) -> void:
	advance(dt)


func _draw() -> void:
	var s: int = int(cfg["icon_scale"])
	for it in items:
		var grid: Array = KINDS[it["kind"]]
		var c: Color = it["color"]
		c.a = alpha_of(it)
		var w: int = (grid[0] as String).length()
		var origin: Vector2 = (it["pos"] - Vector2(w, grid.size()) * s / 2.0).round()
		for y in grid.size():
			var row: String = grid[y]
			for x in row.length():
				if row[x] == "1":
					draw_rect(Rect2(origin + Vector2(x, y) * s, Vector2(s, s)), c)
