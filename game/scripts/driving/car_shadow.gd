extends Node2D
## The car's shadow in the elevation test scene (task T-185, round since T-192;
## Drifting, Decisions, "Elevation"): a dark, script-drawn filled circle on the
## ground right under the centre of the car's map position (the platform's top
## or the ramp when over them, the street otherwise), while the car's drawing
## lifts with its height.
##
## A circle on the ground is drawn through the view's transform, so on screen
## it is an ellipse twice as wide as it is tall (2:1 in the isometric view).
## It does not turn with the car. Pixel style: one opaque colour, no
## semi-transparent pixels (no antialiasing), never Redgull red. Its size does
## not change with height (a proposal).

const PX_PER_UNIT := 16.0
## Diameter of the circle on the ground, units: about the car's width (proposal).
const DIAMETER_UNITS := 1.0
## Points of the polygon that draws the circle.
const SEGMENTS := 32
## Opaque, darker than the street and the platform (proposal).
const COLOR := Color(0.02, 0.02, 0.05, 1.0)

## Flat world pixels -> drawn pixels (the scene's view transform, origin 0).
var view_basis := Transform2D.IDENTITY
## The height of the ground the shadow lies on, units.
var surface_height := 0.0


## Puts the shadow under a car at flat position map_units (units), on ground of
## height ground_height (units).
func place(map_units: Vector2, ground_height: float) -> void:
	position = view_basis * (map_units * PX_PER_UNIT) + Vector2(0.0, -ground_height * PX_PER_UNIT)
	surface_height = ground_height


## The shadow's outline in local drawn pixels (relative to position): the
## ground circle through the view's transform.
func outline() -> PackedVector2Array:
	var radius := DIAMETER_UNITS * PX_PER_UNIT / 2.0
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var a := TAU * float(i) / float(SEGMENTS)
		pts.append(view_basis.basis_xform(Vector2(cos(a), sin(a)) * radius))
	return pts


func _draw() -> void:
	draw_colored_polygon(outline(), COLOR)
