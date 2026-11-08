class_name KeyNav
extends RefCounted
## Explicit keyboard neighbours for a column of buttons (T-492): up and down walk the list in order
## and wrap round, left and right stay on the same button, so Godot's automatic guesses never
## jump somewhere surprising. Enter or Space presses the focused button (Godot's own ui_accept).


## Chains `buttons` (top to bottom) with explicit neighbours. A single button is its own neighbour.
static func chain_column(buttons: Array) -> void:
	var n := buttons.size()
	for i in n:
		var b: Control = buttons[i]
		var up: Control = buttons[(i - 1 + n) % n]
		var down: Control = buttons[(i + 1) % n]
		b.focus_neighbor_top = b.get_path_to(up)
		b.focus_neighbor_bottom = b.get_path_to(down)
		b.focus_neighbor_left = b.get_path_to(b)
		b.focus_neighbor_right = b.get_path_to(b)
		b.focus_next = b.get_path_to(down)
		b.focus_previous = b.get_path_to(up)


## W, A, S and D work like the arrow keys (board, 2026-11-02): a fresh press (no key repeat) moves
## the selection to the focused button's explicit neighbour. Returns true when the key was used.
## Screens call it from `_unhandled_key_input`.
static func handle_wasd(event: InputEvent, owner: Node) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	var side := -1
	match key.keycode:
		KEY_W: side = SIDE_TOP
		KEY_S: side = SIDE_BOTTOM
		KEY_A: side = SIDE_LEFT
		KEY_D: side = SIDE_RIGHT
	if side < 0:
		return false
	var focused := owner.get_viewport().gui_get_focus_owner()
	if focused == null or not owner.is_ancestor_of(focused):
		return false
	var target := focused.find_valid_focus_neighbor(side)
	if target != null:
		target.grab_focus()
	owner.get_viewport().set_input_as_handled()
	return true


## T-573: no button looks selected when a screen opens. A screen calls this when it opens (and when
## it comes back from a sub-page) instead of `grab_focus()`: it drops any selection inside `owner`.
static func clear_selection(owner: Node) -> void:
	if owner == null or not owner.is_inside_tree():
		return
	var focused := owner.get_viewport().gui_get_focus_owner()
	if focused != null and owner.is_ancestor_of(focused):
		focused.release_focus()


## True when something inside `owner` is selected.
static func has_selection(owner: Node) -> bool:
	if not owner.is_inside_tree():
		return false
	var focused := owner.get_viewport().gui_get_focus_owner()
	return focused != null and owner.is_ancestor_of(focused)


static func _is_move_key(key: InputEventKey) -> bool:
	return key.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_W, KEY_A, KEY_S, KEY_D]


static func _is_accept_key(key: InputEventKey) -> bool:
	return key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]


## With nothing selected inside `owner`, the first fresh press of an arrow, Tab, W, A, S or D
## selects `start` and nothing else (the selection shows where it starts). Enter or Space does the
## same, except when `accept_presses` is true: then it presses `start` (a screen whose Enter
## already did something before T-573). Returns true when the key was used.
static func reveal_selection(event: InputEvent, owner: Node, start: Control, accept_presses := false) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or start == null:
		return false
	if not start.is_visible_in_tree() or start.focus_mode == Control.FOCUS_NONE:
		return false
	var accept := _is_accept_key(key)
	if not accept and not _is_move_key(key):
		return false
	if has_selection(owner):
		return false
	owner.get_viewport().set_input_as_handled()
	if accept and accept_presses and start is BaseButton and not (start as BaseButton).disabled:
		(start as BaseButton).pressed.emit()
	else:
		start.grab_focus()
	return true


## What a screen's `_unhandled_key_input` calls: the first key reveals the selection at `start`,
## later W, A, S, D move it like the arrow keys. Returns true when the key was used.
static func handle_keys(event: InputEvent, owner: Node, start: Control, accept_presses := false) -> bool:
	if reveal_selection(event, owner, start, accept_presses):
		return true
	return handle_wasd(event, owner)
