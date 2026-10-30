extends RefCounted
## Task T-400: the level of the small jump ramp's screenshots and GIF, built through the level
## creator's editor as the board would (pick, turn with R, drag the width, click): four Ramp 0 to 2
## on the street climbing north, east, south and west; a 3 rooftop with four Ramp 3 to 5 on it; a 6
## rooftop with four Ramp 6 to 8 on it. Positions are units, the pieces' top-left corners.

## [asset, top-left corner, direction (ramps), dragged size (a ramp: its width on its axis)].
const STEPS := [
	["ramp-0-2", Vector2(-110, -2), "north", Vector2(10, 0)],
	["ramp-0-2", Vector2(-90, -6), "east", Vector2(0, 10)],
	["ramp-0-2", Vector2(-76, -2), "south", Vector2(10, 0)],
	["ramp-0-2", Vector2(-56, -6), "west", Vector2(0, 10)],
	["rooftop-3", Vector2(-40, -40), "", Vector2(48, 80)],     # x -40..8, y -40..40
	["ramp-3-5", Vector2(-32, 20), "north", Vector2(10, 0)],
	["ramp-3-5", Vector2(-10, 10), "east", Vector2(0, 10)],
	["ramp-3-5", Vector2(-32, -30), "south", Vector2(10, 0)],
	["ramp-3-5", Vector2(-4, -28), "west", Vector2(0, 10)],
	["rooftop-6", Vector2(30, -40), "", Vector2(48, 80)],     # x 30..78
	["ramp-6-8", Vector2(38, 20), "north", Vector2(10, 0)],
	["ramp-6-8", Vector2(60, 10), "east", Vector2(0, 10)],
	["ramp-6-8", Vector2(38, -30), "south", Vector2(10, 0)],
	["ramp-6-8", Vector2(66, -28), "west", Vector2(0, 10)],
]


## Places every piece of STEPS through `editor` (LevelCreatorEditor). Returns the placed pieces.
static func build(editor) -> Array:
	var out: Array = []
	for s in STEPS:
		editor.panel.pick(s[0])
		for i in 4:
			if s[2] == "" or editor.pick_view == s[2]:
				break
			editor.rotate_pick()
		var p = editor.place_asset(s[0], s[1] + Vector2(1, 1), s[3])
		if p.is_empty():
			push_warning("T-400 level: %s at %s not placed (%s)" % [s[0], s[1], editor.last_problem])
		out.append(p)
	return out
