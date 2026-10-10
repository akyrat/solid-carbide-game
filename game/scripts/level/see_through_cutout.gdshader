shader_type canvas_item;
// Cut-out look for the see-through building demo (task T-020): inside a circle
// around the car the building's alpha drops to hole_alpha; the edge is hard
// (no blur), so it keeps the pixel look. hole_center is in the building node's
// local (screen) coordinates.
uniform vec2 hole_center = vec2(0.0);
uniform float hole_radius = 40.0;
uniform float hole_alpha = 1.0;
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	if (distance(local_pos, hole_center) < hole_radius) {
		COLOR.a *= hole_alpha;
	}
}
