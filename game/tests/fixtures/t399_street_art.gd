extends Control
## Screenshot fixture (task T-399): the final sidewalk, curb, car and crater art in the level creator,
## and the same level played as a run. Two roads cross; sidewalks are painted along them (curbs on
## straights, outer and inner corners); a small building and two boulders stand by the crossing; every
## parked and broken car at each of the four facings; the three craters next to the building and the
## boulders. T399_FOCUS picks the view: "curbs" (the crossing), "cars", "craters", or "run" (the level
## saved and played, the camera on the cars).
##   bash game/tools/screenshot.sh res://tests/fixtures/t399_street_art.tscn art-archive/T-399/screenshots/editor_cars.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const CARS := ["prop-parked-car-1", "prop-parked-car-2", "prop-parked-car-3", "prop-broken-car-1", "prop-broken-car-2"]

var editor: LevelCreatorEditor
var run: Node2D


func build_level() -> void:
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	editor.level_data["spawn"] = {"x": 1.0, "y": -30.0, "heading": 90}
	add_child(editor)
	editor.panel.pick("centre-line")
	editor.paint_road([Vector2(1, -40), Vector2(1, 40)])
	editor.paint_road([Vector2(-40, 1), Vector2(40, 1)])
	editor.panel.pick("sidewalk")
	for x in [-3, -1, 5, 7]:
		editor.paint_sidewalk([Vector2(x, -36), Vector2(x, 36)])
	for y in [-3, -1, 5, 7]:
		editor.paint_sidewalk([Vector2(-36, y), Vector2(36, y)])
	# The cars at each facing: parked at the curb of the road along y (south of the crossing) and on
	# the sidewalk east of it, one model to a row.
	var n := 0
	for id in CARS:
		for rot in ["north", "east", "south", "west"]:
			editor.panel.pick(id)
			for i in 4:
				if editor.pick_view == rot:
					break
				editor.rotate_pick()
			editor.place_asset(id, Vector2(12.1 + 5.0 * (n % 4), 12.1 + 5.0 * (n / 4)))
			n += 1
	# A small building north-west of the crossing, two boulders by the road, craters beside them.
	editor.panel.pick("building-small")
	editor.place_asset("building-small", Vector2(-10.0, -10.0))
	editor.panel.pick("boulder-a")
	editor.place_asset("boulder-a", Vector2(-12.1, 2.1))
	editor.place_asset("boulder-a", Vector2(14.1, 0.1))
	var craters := {"crater-1": Vector2(-8.9, 1.1), "crater-2": Vector2(10.1, 2.1), "crater-3": Vector2(1.1, -12.9)}
	for id in craters:
		editor.panel.pick(id)
		editor.place_asset(id, craters[id])


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_level()
	var focus := OS.get_environment("T399_FOCUS")
	if focus == "run":
		var path := "user://t399_street_level.json"
		LevelStore.save_level(path, editor.document.file_data("T-399 street"))
		remove_child(editor)
		editor.free()
		run = RunScene.instantiate()
		run.layout_path = path
		add_child(run)
		run.minions.enabled = false
		run.minions.clear()
		run.kaiju_boss.enabled = false
		run.car.use_keyboard = false
		run.camera_follow.dynamic = false
		run.set_zoom(16.0)
		var car = run.car
		car.model.set_position(Vector2(9.0, 20.0))
		car.model.rotation = -1.5708
		car.model.set_velocity(Vector2.ZERO)
		car._sync_from_model()
		run.sync_view()
		run.car_sprite.reset_physics_interpolation()
		run.camera.reset_physics_interpolation()
		return
	if focus == "cars":
		editor.panel.pick("prop-parked-car-1")
	else:
		editor.panel.pick("sidewalk")
	await get_tree().process_frame
	var centre := Vector2(-2, -2)
	var zoom := 3.0
	if focus == "cars":
		centre = Vector2(20, 22)
		zoom = 3.2
	elif focus == "craters":
		centre = Vector2(0, 0)
		zoom = 2.6
	editor.zoom_by(zoom, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre))
	editor._overlay.queue_redraw()


func _process(_delta: float) -> void:
	if run != null and run.state != null:
		run.state.health = run.state.max_health
