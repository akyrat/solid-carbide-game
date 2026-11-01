extends RefCounted
## How big a shadow is for an object at a height above the surface under it
## (task T-454; Visual style, Decisions, "Shadows shrink with height"). The one
## shared size curve: the car in the air (car_shadow.gd), a falling gift pack
## (gift_drops.gd, through car_shadow.gd), a falling minion or kaiju
## (minion_sprite.gd, kaiju_sprite.gd) and a thrown Molotov bottle
## (molotovs.gd) all ask it, so every shadow shrinks and grows the same way.
##
## The shadow lies on whatever surface is under the object (the street, or a
## rooftop's or ramp's top): the height that counts is the height above that
## surface (height_above), not above the street.
##
## The curve (a proposal for the playtest): full size at the surface, then
## 1 / (1 + h / HALF_SIZE_HEIGHT_UNITS), like a light from above, so it
## shrinks fastest just off the ground (small hops show) and slowly high up,
## and never below MIN_SCALE so a high object still marks its spot. It is never
## larger than the object's own size.

## Height above the surface (units) where the shadow is half its full size (proposal).
const HALF_SIZE_HEIGHT_UNITS := 4.0
## The smallest a shadow gets, as a fraction of its full size (proposal).
const MIN_SCALE := 0.35


## The shadow's size as a fraction of its full size, for an object
## `height_units` above the surface under it: 1 at the surface (and below),
## smaller as it rises, never under MIN_SCALE.
static func scale_for_height(height_units: float) -> float:
	if not (height_units > 0.0):  # also NAN
		return 1.0
	return clampf(1.0 / (1.0 + height_units / HALF_SIZE_HEIGHT_UNITS), MIN_SCALE, 1.0)


## The shadow's size for an object whose own size (its sprite's, on the
## surface) is `full_size`, at `height_units` above the surface. Any unit.
static func size_for_height(full_size: float, height_units: float) -> float:
	return full_size * scale_for_height(height_units)


## The object's height above the surface under it (units), never below 0.
static func height_above(object_height: float, surface_height: float) -> float:
	return maxf(object_height - surface_height, 0.0)


## The ground diameter (units) of a circle drawn through the isometric view
## (2:1) that is `width_px` drawn pixels wide: a circle of diameter d units is
## d x 16 x sqrt(2) pixels wide on screen.
static func diameter_for_screen_width(width_px: float, px_per_unit: float = 16.0) -> float:
	return width_px / (px_per_unit * sqrt(2.0))
