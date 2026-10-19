class_name GroundHeight
extends RefCounted
## Ground height of the elevation test scene (T-182): a query over data only,
## no nodes and no physics. Format: game/README.md, "Elevation test scene".
## World units, x east, y south (north = -y). Every number in the data is a proposal.

const DEFAULT_PATH := "res://data/level/elevation_test.json"
## Step length when walking a segment in edge_between (units).
const SAMPLE_STEP := 0.05

var platforms: Array = []
var ramps: Array = []


static func from_file(path: String = DEFAULT_PATH) -> GroundHeight:
	var g := GroundHeight.new()
	g.load_file(path)
	return g


## Loads the data file. Returns false (and leaves the ground flat) on a bad file.
func load_file(path: String = DEFAULT_PATH) -> bool:
	platforms = []
	ramps = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	for p in data.get("platforms", []):
		platforms.append({
			"id": str(p.get("id", "")),
			"rect": Rect2(float(p.x), float(p.y), float(p.w), float(p.h)),
			"height": float(p.height),
		})
	for r in data.get("ramps", []):
		ramps.append({
			"id": str(r.get("id", "")),
			"platform": str(r.get("platform", "")),
			"side": str(r.get("side", "east")),
			"rect": Rect2(float(r.x), float(r.y), float(r.w), float(r.h)),
			"bottom_height": float(r.get("bottom_height", 0.0)),
			"top_height": float(r.top_height),
		})
	return true


static func _contains(rect: Rect2, point: Vector2) -> bool:
	# Closed on every side (Rect2.has_point is open on the far sides).
	return point.x >= rect.position.x and point.x <= rect.end.x \
		and point.y >= rect.position.y and point.y <= rect.end.y


## The ramp under the point, or an empty Dictionary.
func ramp_at(point: Vector2) -> Dictionary:
	for r in ramps:
		if _contains(r.rect, point):
			return r
	return {}


func is_ramp(point: Vector2) -> bool:
	return not ramp_at(point).is_empty()


## 0 = the foot (far end), 1 = the top (at the platform), along the climbing side.
func _ramp_t(r: Dictionary, point: Vector2) -> float:
	var rect: Rect2 = r.rect
	var t := 0.0
	match r.side:
		"east":   # the top is at the ramp's west end
			t = (rect.end.x - point.x) / rect.size.x
		"west":
			t = (point.x - rect.position.x) / rect.size.x
		"south":  # the top is at the ramp's north end
			t = (rect.end.y - point.y) / rect.size.y
		"north":
			t = (point.y - rect.position.y) / rect.size.y
	return clampf(t, 0.0, 1.0)


func height_at(point: Vector2) -> float:
	var r := ramp_at(point)
	if not r.is_empty():
		return lerpf(r.bottom_height, r.top_height, _ramp_t(r, point))
	var best := 0.0
	for p in platforms:
		if _contains(p.rect, point):
			best = maxf(best, p.height)
	return best


## Which area gives the ground's height at the point (task T-184): a ramp's
## index is platforms.size() + its index in ramps, a platform's its index in
## platforms; -1 on the street (height 0). Matches height_at: a ramp wins over
## a platform, the highest platform over a lower one.
func area_index_at(point: Vector2) -> int:
	for i in ramps.size():
		if _contains(ramps[i].rect, point):
			return platforms.size() + i
	var best := -1
	var best_h := 0.0
	for i in platforms.size():
		var p: Dictionary = platforms[i]
		if _contains(p.rect, point) and p.height > best_h:
			best = i
			best_h = p.height
	return best


## The rectangle of area index (see area_index_at).
func area_rect(index: int) -> Rect2:
	if index < platforms.size():
		return platforms[index].rect
	return ramps[index - platforms.size()].rect


## The outward normal of the side of area index's rectangle that a move from a
## (outside it) to b (inside it) enters through (task T-184). At a corner, the
## side crossed last (the one actually entered through).
func side_normal(index: int, a: Vector2, b: Vector2) -> Vector2:
	var rect := area_rect(index)
	var best := Vector2.ZERO
	var best_t := -INF
	var d := b - a
	var candidates := []
	if a.x < rect.position.x:
		candidates.append([Vector2.LEFT, rect.position.x, true])
	if a.x > rect.end.x:
		candidates.append([Vector2.RIGHT, rect.end.x, true])
	if a.y < rect.position.y:
		candidates.append([Vector2.UP, rect.position.y, false])
	if a.y > rect.end.y:
		candidates.append([Vector2.DOWN, rect.end.y, false])
	for c in candidates:
		var along: float = d.x if c[2] else d.y
		var start: float = a.x if c[2] else a.y
		var t := 0.0 if absf(along) < 1e-12 else (float(c[1]) - start) / along
		if t > best_t:
			best_t = t
			best = c[0]
	if best == Vector2.ZERO:
		# a is not outside (should not happen): push straight back along the move.
		best = -d.normalized() if d != Vector2.ZERO else Vector2.UP
	return best


## Moving from a to b: {"drop": bool, "height": float, "up": bool}.
## drop is true when the move crosses a platform edge that is not a ramp; height is the
## size of that step (the platform's height) and up is true when the step is a climb.
## Walking along a ramp is never a drop: its height changes gradually.
func edge_between(a: Vector2, b: Vector2) -> Dictionary:
	var length := a.distance_to(b)
	var n := maxi(1, ceili(length / SAMPLE_STEP))
	var prev := a
	for i in range(1, n + 1):
		var cur := a.lerp(b, float(i) / float(n))
		if not is_ramp(prev) and not is_ramp(cur):
			var hp := height_at(prev)
			var hc := height_at(cur)
			if not is_equal_approx(hp, hc):
				return {"drop": true, "height": absf(hc - hp), "up": hc > hp}
		prev = cur
	return {"drop": false, "height": 0.0, "up": false}
