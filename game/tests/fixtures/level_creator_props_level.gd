extends RefCounted
## Task T-253: the level of the screenshots, built through the level creator's editor as the board
## would (pick a prop, rotate with R, click): every prop in its four rotations in two grids, one on
## the street (west) and one on a 3 high rooftop (east). Rows are the props in the catalogue's order,
## columns the rotations north, east, south, west. Positions are units.

const ROTATIONS := ["north", "east", "south", "west"]
const STREET_ORIGIN := Vector2(-62, -30)
const ROOF_ORIGIN := Vector2(4, -30)
const ROOFTOP_AT := Vector2(0, -38)
const ROOFTOP_SIZE := Vector2(40, 74)
const SPACING := Vector2(8, 8)


## Places the rooftop and every prop through `editor` (LevelCreatorEditor).
static func build(editor) -> void:
	editor.panel.pick("rooftop-3")
	editor.place_asset("rooftop-3", ROOFTOP_AT + Vector2(1, 1), ROOFTOP_SIZE)
	var ids: Array = []
	for e in LevelDocument.entries():
		if str(e.kind) == "prop":
			ids.append(str(e.id))
	for origin in [STREET_ORIGIN, ROOF_ORIGIN]:
		for r in ids.size():
			for c in ROTATIONS.size():
				editor.panel.pick(ids[r])
				for i in 4:
					if editor.pick_view == ROTATIONS[c]:
						break
					editor.rotate_pick()
				editor.place_asset(ids[r], origin + Vector2(c * SPACING.x, r * SPACING.y) + Vector2(1, 1))
	editor.panel.pick("")
