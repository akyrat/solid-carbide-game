extends Control
## Screenshot fixture (task T-441): the kaiju alert signs and banners as level creator pieces. A level is
## built through the editor (two skyscrapers, a height 3 rooftop and a low-rise; standing signs on the
## street, the rooftop and the low-rise; banners on both skyscrapers' south and east walls, in both
## designs, at different heights), saved to user://, and shown in the editor (`stage` "editor", with the
## alert banner picked so the side panel's strip shows its designs and hints, and its preview under the
## mouse) or in a run on that level (`stage` "run", the car parked in front).
## bash game/tools/screenshot.sh res://tests/fixtures/t441_alert_signs_demo.tscn art-archive/T-441/screenshots/editor.png 30
## bash game/tools/screenshot.sh res://tests/fixtures/t441_alert_signs_demo_run.tscn art-archive/T-441/screenshots/run.png 60

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")
const RunScene := preload("res://scenes/run/run.tscn")
const ISO := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)
const SKY_A := Vector2(0, -20)
const SKY_B := Vector2(30, -30)
const SKY_C := Vector2(-34, -24)
const ROOF := Vector2(-30, -4)
const LOWRISE := Vector2(-14, 10)
## Where the view looks (units).
const FOCUS := Vector2(-4, -22)
@export var stage := "editor"
@export var zoom := 0.6

var editor: LevelCreatorEditor
var run: Node2D
var _frames := 0


static func _wall(corner: Vector2, wall: String, up: float) -> Vector2:
	var g := corner + (Vector2(6, 12) if wall == "south" else Vector2(12, 6))
	return ISO.affine_inverse() * (ISO * (g * 16.0) - Vector2(0, up * 16.0)) / 16.0


static func _pick(e: LevelCreatorEditor, asset: String, view: String = "", mirror: bool = false, height: String = "") -> void:
	e.panel.pick(asset)
	for i in 4:
		if view == "" or e.pick_view == view:
			break
		e.rotate_pick()
	if mirror != e.pick_mirror:
		e.mirror_pick()
	for i in 6:
		if height == "" or str(e.panel.member.get("height", "")) == height:
			break
		e.height_pick()


## Builds the level in `e` (an editor in the tree).
static func build(e: LevelCreatorEditor) -> void:
	var d := e.document
	d.place("skyscraper-1", SKY_A + Vector2(1, 1))
	d.place("skyscraper-4", SKY_B + Vector2(1, 1))
	d.place("skyscraper-2", SKY_C + Vector2(1, 1))
	d.place("rooftop-3", ROOF + Vector2(1, 1), "", false, Vector2(12, 12))
	d.place("short-1", LOWRISE + Vector2(1, 1))
	e._rebuild_map()
	_pick(e, "alert-sign-head")
	e.place_asset("alert-sign-head", Vector2(6.5, 0.5))
	_pick(e, "alert-sign-body")
	e.place_asset("alert-sign-body", Vector2(22.5, 2.5))
	_pick(e, "alert-sign-body", "", true)
	e.place_asset("alert-sign-body", ROOF + Vector2(6.5, 6.5))
	_pick(e, "alert-sign-head", "", true)
	e.place_asset("alert-sign-head", LOWRISE + Vector2(6.5, 6.5))
	_pick(e, "alert-banner-head", "south", false, "3")
	e.place_asset("alert-banner-head", _wall(SKY_A, "south", 5.0))
	_pick(e, "alert-banner-body", "east", false, "9")
	e.place_asset("alert-banner-body", _wall(SKY_A, "east", 10.0))
	_pick(e, "alert-banner-body", "south", false, "6")
	e.place_asset("alert-banner-body", _wall(SKY_B, "south", 7.0))
	_pick(e, "alert-banner-head", "east", false, "12")
	e.place_asset("alert-banner-head", _wall(SKY_B, "east", 13.0))
	e.panel.pick("")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	editor.level_data["spawn"] = {"x": 10.0, "y": 8.0, "heading": 270}
	editor.levels_dir = RunPaths.file("t441_demo")
	add_child(editor)
	build(editor)
	var path := RunPaths.file("t441_demo/t441_alert_signs.json")
	LevelStore.save_level(path, editor.document.file_data("T-441 alert signs"))
	print("T-441 demo: saved to %s: %s" % [path, JSON.stringify(editor.document.data.alert_signs)])
	if stage == "editor":
		# The alert banner picked, the body design, its preview on skyscraper C's south wall.
		_pick(editor, "alert-banner-body", "south", false, "6")
		await get_tree().process_frame
		(editor.panel.get_node("Scroll") as ScrollContainer).ensure_control_visible(editor.panel.looks_strip)
		return
	remove_child(editor)
	editor.free()
	editor = null
	run = RunScene.instantiate()
	run.layout_path = path
	add_child(run)
	run.minions.enabled = false
	run.kaiju_boss.enabled = false
	run.car.use_keyboard = false


## T441_ZOOM and T441_FOCUS ("x,y" units) override the view, for closer shots.
func _view() -> Array:
	var z := float(OS.get_environment("T441_ZOOM")) if OS.get_environment("T441_ZOOM") != "" else zoom
	var f := FOCUS
	var env := OS.get_environment("T441_FOCUS")
	if env.contains(","):
		f = Vector2(float(env.get_slice(",", 0)), float(env.get_slice(",", 1)))
	return [z, f]


func _process(_delta: float) -> void:
	_frames += 1
	var v := _view()
	if editor != null and _frames >= 3:
		editor.zoom = v[0]
		editor.view_origin = editor.map_view.size / 2.0 - editor.ISO_TRANSFORM * ((v[1] as Vector2) * editor.PX_PER_UNIT) * float(v[0])
		editor._apply_view()
		editor.hover_units = _wall(SKY_C, "south", 7.0)
		editor.hover_cell = editor.document.cell_at(editor.hover_units)
		editor._overlay.queue_redraw()
	if run == null:
		return
	# T441_CAR ("x,y" units) parks the car elsewhere (behind skyscraper A: "6,-24", it fades with its banners).
	var at := Vector2(16, -2)
	var env := OS.get_environment("T441_CAR")
	if env.contains(","):
		at = Vector2(float(env.get_slice(",", 0)), float(env.get_slice(",", 1)))
	run.car.model.set_position(at)
	run.car.model.rotation = -PI / 2.0
	run.car.model.set_velocity(Vector2.ZERO)
	run.car.height_model.reset(at)
	run.car._sync_from_model()
	run.sync_view()
