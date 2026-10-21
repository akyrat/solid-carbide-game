extends Control
## Screenshot fixture (task T-237): snapping in the level creator. A rooftop at 3 is placed, then a
## ramp 0 to 3 clicked two units short of the rooftop's south side and two units past its east end.
## - stage "placed": the ramp after the click, snapped onto the rooftop's south side, within it.
## - stage "preview": the ramp picked and the "mouse" at that spot: the preview shows where it goes.
## - stage "overlap": a second rooftop clicked across the first; not placed, the top bar shows the
##   overlap message.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_snapping_demo.tscn art-archive/T-237/screenshots/ramp_snapped.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

@export var stage := "placed"
## Where the view is centred (map units) and how far it is zoomed in.
@export var centre_units := Vector2(-30, -70)
@export var zoom_factor := 2.5

## The click: the clicked cell's corner is (-20, -64), the snapped ramp's (-22, -66).
const RAMP_CLICK := Vector2(-19.5, -63.5)

var editor: LevelCreatorEditor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	editor.panel.pick("rooftop-3")
	editor.place_asset("rooftop-3", Vector2(-95.5, -95.5))
	match stage:
		"placed":
			editor.panel.pick("ramp-0-3")
			editor.place_asset("ramp-0-3", RAMP_CLICK)
			editor.panel.pick("")
			editor.select_at(Vector2(-17, -60))
		"preview":
			editor.panel.pick("ramp-0-3")
		"overlap":
			editor.panel.pick("rooftop-3")
			editor.place_asset("rooftop-3", Vector2(-59.5, -79.5))
	await get_tree().process_frame
	editor.zoom_by(zoom_factor, editor.map_view.size / 2.0)
	editor.pan_by(editor.map_view.size / 2.0 - editor.units_to_screen(centre_units))
	if stage in ["preview", "overlap"]:
		editor.hover_cell = editor.document.cell_at(RAMP_CLICK if stage == "preview" else Vector2(-59.5, -79.5))
	editor._overlay.queue_redraw()
