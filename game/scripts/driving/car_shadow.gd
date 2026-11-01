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
## semi-transparent pixels (no antialiasing), never the heart's red.
##
## Its size changes with height (task T-454; Visual style, Decisions, "Shadows
## shrink with height"): full_diameter_units at the surface, smaller the higher
## the object is above the surface it lies on, through the shared curve
## (shadow_size.gd). The same node marks a falling gift pack's landing spot
## (gift_drops.gd), with the package's own size as its full size.

const ShadowSizeScript := preload("res://scripts/driving/shadow_size.gd")

const PX_PER_UNIT := 16.0
## Diameter of the circle on the ground, units: the car's width (its sprite is
## 1 unit wide, car_iso.json), the shadow's full size at the surface (proposal).
const DIAMETER_UNITS := 1.0
## Points of the polygon that draws the circle.
const SEGMENTS := 32
## Opaque, darker than the street and the platform (proposal).
const COLOR := Color(0.02, 0.02, 0.05, 1.0)

## Flat world pixels -> drawn pixels (the scene's view transform, origin 0).
var view_basis := Transform2D.IDENTITY
## The height of the ground the shadow lies on, units.
var surface_height := 0.0
## The shadow's full diameter at the surface, units (the object's own size).
var full_diameter_units := DIAMETER_UNITS
## How high the object is above the surface the shadow lies on, units (T-454).
var height_above := 0.0


## Puts the shadow under a car at flat position map_units (units), on ground of
## height ground_height (units). With object_height (units, the car's or the
## package's height) its size follows the object's height above that ground
## (T-454); without it the object is taken to be on the ground (full size).
func place(map_units: Vector2, ground_height: float, object_height: float = NAN) -> void:
	position = view_basis * (map_units * PX_PER_UNIT) + Vector2(0.0, -ground_height * PX_PER_UNIT)
	surface_height = ground_height
	set_height_above(0.0 if is_nan(object_height) else ShadowSizeScript.height_above(object_height, ground_height))


## Sets the object's height above the shadow's surface (units) and redraws.
func set_height_above(units: float) -> void:
	var h := maxf(units, 0.0)
	if h != height_above:
		height_above = h
		queue_redraw()


## The shadow's diameter now, units: full_diameter_units through the shared
## height curve (shadow_size.gd).
func diameter_units() -> float:
	return ShadowSizeScript.size_for_height(full_diameter_units, height_above)


## The shadow's outline in local drawn pixels (relative to position): the
## ground circle through the view's transform.
func outline() -> PackedVector2Array:
	var radius := diameter_units() * PX_PER_UNIT / 2.0
	var pts := PackedVector2Array()
	for i in SEGMENTS:
		var a := TAU * float(i) / float(SEGMENTS)
		pts.append(view_basis.basis_xform(Vector2(cos(a), sin(a)) * radius))
	return pts


func _draw() -> void:
	if Perf.on: Perf.each_begin(&"draw.car_shadow")
	draw_colored_polygon(outline(), COLOR)
	if Perf.on: Perf.each_end(&"draw.car_shadow")
