extends Resource
## The look of the neon underglow's zone (task T-274; Visual style, Decisions,
## "The neon underglow drawn in code"): every colour, width and speed in one
## place, so the board can retune it in the editor (scenes/weapons/
## neon_underglow_look.tres) without touching code. Used by underglow_glow.gd.
##
## All colours are opaque and from the underglow's purple and pink; never
## Redgull red. Widths are in flat world pixels measured from the damage circle's
## edge (positive outwards, negative inwards), seen through the isometric view.

## The switch back to the generated sprite (T-175, art/weapons/underglow.png).
@export var use_sprite := false

## The bright ring just inside the damage circle's edge, outermost line first.
@export var shimmer_colour := Color(1.0, 0.92, 1.0)
@export var ring_core_colour := Color(1.0, 0.62, 0.95)
@export var ring_mid_colour := Color(0.9, 0.22, 0.85)
## Width of the core line and of the mid line inside it, in px.
@export var ring_core_px := 2.0
@export var ring_mid_px := 2.0

## The halo outside the edge, stepped: a solid purple band, then a dithered one.
@export var halo_near_colour := Color(0.55, 0.18, 0.95)
@export var halo_far_colour := Color(0.3, 0.1, 0.6)
@export var halo_near_px := 3.0
@export var halo_far_px := 3.0

## The floor glow inside the ring: a half-dithered band then a sparse one.
@export var floor_near_colour := Color(0.42, 0.12, 0.7)
@export var floor_far_colour := Color(0.3, 0.1, 0.6)
@export var floor_near_px := 6.0
@export var floor_far_px := 9.0

## Animation. One cycle is `cycle_frames` frames at `frames_per_second`; it holds
## `pulse_cycles` pulses (the halo and floor glow breathe out and in, in steps
## of `pulse_extra_px`, two steps at most) and `shimmer_laps` trips of the
## bright arc round the ring.
@export var frames_per_second := 12.0
@export var cycle_frames := 24
@export var pulse_cycles := 2
@export var shimmer_laps := 1
@export var pulse_extra_px := 1.0
## Length of the shimmer arc, in radians of the flat circle.
@export var shimmer_arc := 1.0


## Every colour the zone draws with (tests check none is Redgull red).
func colours() -> Array:
	return [shimmer_colour, ring_core_colour, ring_mid_colour, halo_near_colour,
		halo_far_colour, floor_near_colour, floor_far_colour]
