extends SceneTree
## The hint pieces' screenshots and test level (task T-576): builds a small level in the level creator with
## every hint both ways (painted on a road and as roadside signs, in several headings, the curved and
## circular arrows mirrored), saves it as `--level` (a file outside game/data/levels/), and saves:
## - creator_hints.png: the creator with the level and a picked sign's preview under the mouse, the side
##   panel scrolled to its Driver hints group;
## - creator_ground_preview.png: the same with a picked ground arrow's preview;
## - run_hints.png: a run on the level, the car on the road among the hints.
##
## Needs a real window (not --headless):
##   godot --path game --resolution 1280x720 -s res://tools/hint_shots.gd -- --out=C:/abs/dir --level=C:/abs/file.json

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

var _out := ""
var _level := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--level="):
			_level = arg.substr(8)
	if _out == "" or _level == "" or _level.replace("\\", "/").contains("data/levels"):
		printerr("hint_shots.gd: need --out=<folder> --level=<file.json> (never in game/data/levels/)")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	_go.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame
	await RenderingServer.frame_post_draw


func _shot(name: String) -> void:
	await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png(_out.path_join(name))
	print("wrote ", _out.path_join(name))


func _pick(e, icon: String, mode: String, heading: String, mirror: bool = false) -> void:
	e.panel.pick("hint-" + icon)
	e.set_hint_mode(mode)
	for i in 8:
		if e.pick_view == heading:
			break
		e.rotate_pick()
	if mirror != e.pick_mirror:
		e.mirror_pick()


func _centre(e, units: Vector2, zoom: float) -> void:
	e.zoom = zoom
	e.view_origin = e.map_view.size / 2.0 - zoom * (ISO * (units * 16.0))
	e._apply_view()


func _go() -> void:
	var e = EDITOR_SCENE.instantiate()
	e.open_new()
	e.level_data["spawn"] = {"x": -31.0, "y": 1.0, "heading": 0}
	root.add_child(e)
	await _frames(2)
	# A road along y 0..4 and one crossing it at x 16..20.
	e.paint_road([Vector2(-34, 1), Vector2(34, 1)])
	e.paint_road([Vector2(17, -20), Vector2(17, 20)])
	# On the road: gas, the straight arrow, the curved arrow (left), brake; the circular arrow at the crossing.
	_pick(e, "gas", "ground", "0")
	e.place_asset(e.panel.picked, Vector2(-23, 1))
	_pick(e, "arrow-straight", "ground", "0")
	e.place_asset(e.panel.picked, Vector2(-15, 1))
	_pick(e, "arrow-curved", "ground", "0", true)
	e.place_asset(e.panel.picked, Vector2(-7, 1))
	_pick(e, "brake", "ground", "0")
	e.place_asset(e.panel.picked, Vector2(9, 1))
	_pick(e, "arrow-circular", "ground", "90")
	e.place_asset(e.panel.picked, Vector2(17, 9))
	# Roadside signs, north of the road (y -2..0), facing the way the car drives, and one south of it.
	_pick(e, "gas", "sign", "0")
	e.place_asset(e.panel.picked, Vector2(-21, -1))
	_pick(e, "arrow-straight", "sign", "0")
	e.place_asset(e.panel.picked, Vector2(-13, -1))
	_pick(e, "arrow-curved", "sign", "0", true)
	e.place_asset(e.panel.picked, Vector2(-5, -1))
	_pick(e, "brake", "sign", "0")
	e.place_asset(e.panel.picked, Vector2(7, -1))
	_pick(e, "arrow-circular", "sign", "45", true)
	e.place_asset(e.panel.picked, Vector2(13, 5))
	e.name_field.text = "T-576 hint test"
	e.level_data["spawn"] = {"x": -21.0, "y": 3.0, "heading": 0}  # on the gas hint: the run starts the car over it
	var err := LevelStore.save_level(_level, e.document.file_data("T-576 hint test"))
	print("level ", _level, " ", err, " hints: ", e.level_data.get("hints", []).size())
	# The creator: a sign picked, its preview under the mouse.
	_centre(e, Vector2(-6, 0), 1.1)
	_pick(e, "arrow-curved", "sign", "270")
	e.hover_units = Vector2(1, -1)
	e.hover_cell = e.document.cell_at(e.hover_units)
	e._overlay.queue_redraw()
	# The side panel scrolled to its Driver hints group, the picked hint's strip under it.
	var scroll: ScrollContainer = e.panel.get_node("Scroll")
	await _frames(2)
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _shot("creator_hints.png")
	_pick(e, "arrow-straight", "ground", "315")
	e.hover_units = Vector2(1, 1)
	e.hover_cell = e.document.cell_at(e.hover_units)
	e._overlay.queue_redraw()
	await _shot("creator_ground_preview.png")
	e.queue_free()
	await _frames(2)
	# A run on the level, the car on the road heading east among the hints.
	var run = RunScene.instantiate()
	run.layout_path = _level
	root.add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false
	run.car.set_physics_process(false)
	await _frames(40)
	await _shot("run_hints.png")
	quit(0)
