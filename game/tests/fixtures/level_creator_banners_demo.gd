extends Control
## Screenshot fixture (task T-265): the level creator with eight skyscrapers, the six towers with their banner
## off (the default) and two of them again with the banner on (key B), the last one still picked so the top bar
## shows Banner on / Banner off.
## bash game/tools/screenshot.sh res://tests/fixtures/level_creator_banners_demo.tscn art-archive/T-265/screenshots/banners.png 30

const EDITOR_SCENE := preload("res://scenes/level_creator/editor.tscn")

var editor: LevelCreatorEditor


## Places tower `n` (1 to 6, its first body) at `at` with the banner `on`.
func _place(n: int, at: Vector2, on: bool) -> void:
	editor.panel.pick("skyscraper")
	for i in 2 * (n - 1):
		editor.look_pick()
	editor.set_banner(on)
	editor.place_asset(editor.panel.picked, at)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = EDITOR_SCENE.instantiate()
	editor.open_new()
	add_child(editor)
	# Back row: the six towers, banners off.
	for n in range(1, 7):
		_place(n, Vector2(-76 + (n - 1) * 24, -40 + (n - 1) * 0), false)
	# Front row: two of them with the banner on.
	_place(2, Vector2(-40, 8), true)
	_place(5, Vector2(24, 8), true)
	await get_tree().process_frame
	editor.zoom_by(1.25, editor.map_view.size / 2.0)
	editor.pan_by(Vector2(0, 40))
	editor.hover_cell = editor.document.cell_at(Vector2(60, 8))
	editor._overlay.queue_redraw()
