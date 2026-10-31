extends SceneTree
## Draws the enemies' navigation on a level as a PNG (task T-419): which cells
## the kaiju's grid (planned for its 2-unit body, off buildings and edges)
## keeps open next to the minions' grid, and the kaiju's paths from a few
## street spots to a car spot, beside the paths the minions' grid would give
## it (what the kaiju walked before T-419).
##
## Usage, from the repo root:
##   bash game/tools/draw_kaiju_nav.sh <out.png> [level json, res:// path] [car x] [car y] [x,y ...]
## With starts ("x,y") after the car, only the kaiju's paths from those (T-436).
## Defaults: res://data/levels/kaiju_city.json, the car on roof-1 at (-32, 36).
##
## Colours: street light grey, rooftops and ramps darker by height, buildings
## that stay walls near black, props brown; cells the kaiju's grid closes and
## the minions' keeps open are tinted orange; the kaiju's paths now cyan, the
## old (minions' grid) paths red; the car a white square.

const RunScene := preload("res://scenes/run/run.tscn")
const NavScript := preload("res://scripts/enemies/enemy_navigation.gd")
const KaijuScript := preload("res://scripts/enemies/kaiju.gd")
const PX := 4
## Street spots the paths start from (units).
const STARTS := [Vector2(11, 7), Vector2(-41, -5), Vector2(-47, 93), Vector2(27, 45), Vector2(-69, 15)]


func _initialize() -> void:
	_draw.call_deferred()


## Builds the run on the level (its map is made once it is in the tree), then draws.
func _draw() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: draw_kaiju_nav.gd -- <out.png> [level] [car x] [car y]")
		quit(2)
		return
	var out: String = args[0]
	var level: String = args[1] if args.size() > 1 else "res://data/levels/kaiju_city.json"
	var car := Vector2(-32, 36)
	if args.size() > 3:
		car = Vector2(float(args[2]), float(args[3]))
	if not FileAccess.file_exists(level):
		printerr("no level file: %s" % level)
		quit(2)
		return
	var run = RunScene.instantiate()
	run.layout_path = level
	root.add_child(run)
	await process_frame
	await process_frame
	if run.minions == null or run.map == null:
		printerr("the run did not build its map")
		quit(1)
		return
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	var map = run.map
	var gh = run.elevation.ground_height
	var kaiju_nav = NavScript.for_map(map, KaijuScript.RADIUS_UNITS, true)
	var minion_nav = NavScript.for_map(map)
	var rect: Rect2 = map.rect_of(map.layout.map.rect)
	var img := Image.create(int(rect.size.x) * PX, int(rect.size.y) * PX, false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var u := rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) / PX
			var h: float = gh.height_at(u)
			var c := Color(0.82, 0.82, 0.82).darkened(clampf(h / 10.0, 0.0, 0.6))
			img.set_pixel(x, y, c)
	for w in load("res://scripts/level/short_platforms.gd").wall_rects(map.layout):
		_fill(img, rect, w.rect, Color(0.12, 0.12, 0.14))
	for r in LevelProps.obstacles(map.layout).rects:
		_fill(img, rect, r, Color(0.55, 0.35, 0.2))
	# Cells the minions may use and the kaiju may not.
	for k in kaiju_nav.open.size():
		if kaiju_nav.open[k] == 0 and minion_nav.open[k] == 1:
			var c: Vector2 = kaiju_nav.cell_centre(k)
			_blend(img, rect, Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.55, 0.1, 0.35))
	# The kaiju's paths before (minions' grid) and now.
	# T-436: starts given after the car ("x,y" each): only the kaiju's paths from them, each
	# start marked yellow (to show where its plan leads from a spot, e.g. on a ramp's foot).
	var given: Array = []
	for a in args.slice(4):
		var xy: PackedStringArray = str(a).split(",")
		if xy.size() == 2:
			given.append(Vector2(float(xy[0]), float(xy[1])))
	if given.is_empty():
		for s in STARTS:
			_path(img, rect, minion_nav.find_path(s, car), s, Color(0.9, 0.15, 0.15))
			_path(img, rect, kaiju_nav.find_path(s, car), s, Color(0.0, 0.75, 0.9))
	for s in given:
		_path(img, rect, kaiju_nav.find_path(s, car), s, Color(0.0, 0.75, 0.9))
		_fill(img, rect, Rect2(s - Vector2(0.75, 0.75), Vector2(1.5, 1.5)), Color(1.0, 0.9, 0.0))
	_fill(img, rect, Rect2(car - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
	var abs_out := out if out.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join("..").path_join(out)
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var err := img.save_png(abs_out)
	print("saved %s (%d)" % [abs_out, err])
	run.queue_free()
	quit(0 if err == OK else 1)


func _to_px(rect: Rect2, u: Vector2) -> Vector2:
	return (u - rect.position) * PX


func _fill(img: Image, rect: Rect2, r: Rect2, c: Color) -> void:
	var a := _to_px(rect, r.position)
	var b := _to_px(rect, r.end)
	for y in range(maxi(0, int(a.y)), mini(img.get_height(), int(b.y))):
		for x in range(maxi(0, int(a.x)), mini(img.get_width(), int(b.x))):
			img.set_pixel(x, y, c)


func _blend(img: Image, rect: Rect2, r: Rect2, c: Color) -> void:
	var a := _to_px(rect, r.position)
	var b := _to_px(rect, r.end)
	for y in range(maxi(0, int(a.y)), mini(img.get_height(), int(b.y))):
		for x in range(maxi(0, int(a.x)), mini(img.get_width(), int(b.x))):
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))


func _path(img: Image, rect: Rect2, path: PackedVector2Array, start: Vector2, c: Color) -> void:
	var prev := start
	for p in path:
		_line(img, _to_px(rect, prev), _to_px(rect, p), c)
		_fill(img, rect, Rect2(p - Vector2(0.4, 0.4), Vector2(0.8, 0.8)), c)
		prev = p


func _line(img: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var n := maxi(1, int(a.distance_to(b)))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var x := int(p.x)
		var y := int(p.y)
		if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
			img.set_pixel(x, y, c)
