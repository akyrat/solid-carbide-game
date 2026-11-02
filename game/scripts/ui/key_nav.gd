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
