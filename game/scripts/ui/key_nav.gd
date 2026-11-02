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
static func handle_wasd(event: InputEvent, owner: Control) -> bool:
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
