extends Node2D
## The car's shadow in the elevation test scene (task T-185; Drifting,
## Decisions, "Elevation"): a dark, script-drawn patch at the car's map
## position on the ground under it (the platform's top or the ramp when over
## them, the street otherwise), while the car's drawing lifts with its height.
##
## Pixel style: one opaque colour, no semi-transparent pixels, never Redgull
## red. It is the car's footprint (SIZE_UNITS, a little bigger than the drawn
## car's 1 by 3 units so it shows around it on the ground), turned with the
## car and drawn through the view's transform. Its size does not change with
## height (a proposal).

const PX_PER_UNIT := 16.0
## Length along the nose (x) and width across it (y) of the shadow, units (proposal).
const SIZE_UNITS := Vector2(3.2, 1.2)
## Opaque, darker than the street and the platform (proposal).
const COLOR := Color(0.02, 0.02, 0.05, 1.0)

## Flat world pixels -> drawn pixels (the scene's view transform, origin 0).
var view_basis := Transform2D.IDENTITY
## The car's heading, radians (nose along +x at 0, as car.rotation).
var heading := 0.0
## The height of the ground the shadow lies on, units.
var surface_height := 0.0


## Puts the shadow under a car at flat position map_units (units) with heading
## rot, on ground of height ground_height (units).
func place(map_units: Vector2, rot: float, ground_height: float) -> void:
	position = view_basis * (map_units * PX_PER_UNIT) + Vector2(0.0, -ground_height * PX_PER_UNIT)
	surface_height = ground_height
	if not is_equal_approx(rot, heading):
		heading = rot
		queue_redraw()


## The shadow's outline in local drawn pixels (relative to position).
func outline() -> PackedVector2Array:
	var half := SIZE_UNITS * PX_PER_UNIT / 2.0
	var pts := PackedVector2Array()
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var flat: Vector2 = (c * half).rotated(heading)
		pts.append(view_basis.basis_xform(flat))
	return pts


func _draw() -> void:
	draw_colored_polygon(outline(), COLOR)
