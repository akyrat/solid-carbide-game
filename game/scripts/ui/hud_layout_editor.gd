class_name HudLayoutEditor
extends Control
## The HUD layout editor (task T-453; HUD and menus, Decisions, "The player can move the HUD's
## pieces"), opened from the pause screen's "Edit HUD layout" button. It covers the screen over
## the paused run, draws a frame round each movable HUD piece and lets the player drag them with
## the mouse; a small bar in the middle of the screen holds the hint, "Reset layout" and "Done".
## It only collects the drags: the HUD places the pieces (Hud.move_piece, snapped and kept on
## screen by HudLayout) and the pause screen saves the layout once, on Done.
## Controls (proposals for the playtest): left mouse drags a piece; Escape or Done finishes.

## Done was pressed (or Escape): the pause screen saves the layout and shows its strip again.
signal done

## The frames round the pieces (proposals for the playtest): white, the dragged one filled a little.
const FRAME_COLOR := Color(1, 1, 1, 0.9)
const FRAME_HOVER_FILL := Color(1, 1, 1, 0.12)
const FRAME_DRAG_FILL := Color(1, 1, 1, 0.22)
const FRAME_WIDTH := 2.0

var hud: Hud
var bar: PanelContainer
var hint_label: Label
var reset_button: Button
var done_button: Button
## The piece being dragged ("" when none), the pointer's start and the piece's start (layout pixels).
var dragging := ""
var _drag_from := Vector2.ZERO
var _piece_from := Vector2.ZERO
var _hover := ""


## Builds the editor for `the_hud` with the texts (T-452's): hint, reset and done.
func setup(the_hud: Hud, hint: String, reset_text: String, done_text: String) -> void:
	hud = the_hud
	name = "HudLayoutEditor"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	bar = PanelContainer.new()
	bar.name = "EditorBar"
	bar.set_anchors_preset(Control.PRESET_CENTER)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = HudStyle.PAUSE_STRIP_COLOR
	style.set_content_margin_all(12.0)
	bar.add_theme_stylebox_override("panel", style)
	add_child(bar)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	bar.add_child(col)
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = hint
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HudStyle.apply(hint_label, "pause_text")
	col.add_child(hint_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	reset_button = Button.new()
	reset_button.name = "ResetLayoutButton"
	reset_button.text = reset_text
	HudStyle.style_button(reset_button, true)  # the shared button (T-446)
	reset_button.pressed.connect(reset)
	row.add_child(reset_button)
	done_button = Button.new()
	done_button.name = "DoneButton"
	done_button.text = done_text
	HudStyle.style_button(done_button, true)
	done_button.pressed.connect(finish)
	row.add_child(done_button)
	visible = false


func open() -> void:
	dragging = ""
	_hover = ""
	visible = true
	done_button.grab_focus()
	queue_redraw()


func is_open() -> bool:
	return visible


## Every piece back at its default place; saved with the rest on Done.
func reset() -> void:
	dragging = ""
	hud.reset_layout()
	queue_redraw()


func finish() -> void:
	dragging = ""
	visible = false
	done.emit()


## A piece's frame in this editor's (screen) pixels.
func screen_rect(id: String) -> Rect2:
	var r := hud.piece_rect(id)
	var t := hud.root.get_global_transform()
	return Rect2(t * r.position, r.size * hud.hud_scale())


## The movable piece under the screen point `at`, the topmost first ("" when none).
func piece_at(at: Vector2) -> String:
	var ids := HudLayout.PIECES.duplicate()
	ids.reverse()
	for id in ids:
		if screen_rect(id).has_point(at):
			return id
	return ""


## Starts dragging the piece under `at` (screen pixels); false when there is none.
func press(at: Vector2) -> bool:
	var id := piece_at(at)
	if id == "":
		return false
	dragging = id
	_drag_from = at
	_piece_from = hud.piece_rect(id).position
	queue_redraw()
	return true


## Moves the dragged piece with the pointer at `at` (screen pixels).
func drag_to(at: Vector2) -> void:
	if dragging == "":
		return
	hud.move_piece(dragging, _piece_from + (at - _drag_from) / hud.hud_scale())
	queue_redraw()


func release() -> void:
	dragging = ""
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if press(event.position):
				accept_event()
		elif dragging != "":
			release()
			accept_event()
	elif event is InputEventMouseMotion:
		if dragging != "":
			drag_to(event.position)
			accept_event()
		else:
			var h := piece_at(event.position)
			if h != _hover:
				_hover = h
				queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()  # follows a window resize or a HUD size change


func _draw() -> void:
	if hud == null:
		return
	for id in HudLayout.PIECES:
		var r := screen_rect(id)
		if id == dragging:
			draw_rect(r, FRAME_DRAG_FILL, true)
		elif id == _hover:
			draw_rect(r, FRAME_HOVER_FILL, true)
		draw_rect(r, FRAME_COLOR, false, FRAME_WIDTH)
