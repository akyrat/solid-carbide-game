extends RefCounted
## Task T-251: the small multi-layer level of the screenshots, the GIF and the tests, built through
## the level creator's editor as the board would (pick, rotate to a direction, drag to a size):
## rooftops of three sizes (48 x 32 and 16 x 16 at height 3, 14 x 12 and 16 x 16 at 6), a 6 standing
## on a 3 and one on the street, and ramps climbing in all four directions (0 to 3 north, east and
## west, 3 to 6 south and east, 0 to 6 north). Positions are units, the pieces' top-left corners.

## [asset, top-left corner, direction (ramps), dragged size (a ramp: its width on its axis)].
const STEPS := [
	["rooftop-3", Vector2(-30, -16), "", Vector2(48, 32)],   # A 3: x -30..18, y -16..16
	["rooftop-6", Vector2(-4, -4), "", Vector2(14, 12)],     # a 6 on it: x -4..10, y -4..8
	["rooftop-3", Vector2(40, -8), "", Vector2(16, 16)],     # a small 3: x 40..56
	["rooftop-6", Vector2(-30, 40), "", Vector2(16, 16)],    # a 6 on the street: y 40..56
	["ramp-0-3", Vector2(-26, 16), "north", Vector2(10, 0)], # up the big 3's south side
	["ramp-0-3", Vector2(-42, 0), "east", Vector2(0, 10)],   # up its west side
	["ramp-0-3", Vector2(56, -6), "west", Vector2(0, 10)],   # up the small 3's east side
	["ramp-3-6", Vector2(0, -16), "south", Vector2(10, 0)],  # on the 3, up the 6's north side
	["ramp-3-6", Vector2(-16, -2), "east", Vector2(0, 8)],   # on the 3, up the 6's west side
	["ramp-0-6", Vector2(-28, 56), "north", Vector2(12, 0)], # up the street 6's south side
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
		out.append(editor.place_asset(s[0], s[1] + Vector2(1, 1), s[3]))
	editor.panel.pick("")
	return out
