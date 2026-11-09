shader_type canvas_item;
// The Polarized Steering Wheel's tier 2 shock wave (T-603 quick tuning; Drifting, Decisions:
// the wheel's shock is drawn in the arrows' cyan and magenta, Bricks' own wave unchanged).
// Put on the wheel's BricksWave node only (polarized_shock.gd). It recolours Bricks' wave
// drawing by brightness into four flat steps, so the pixel art stays hard-edged: the
// darkest pixels become the icon's near-black outline, then the dark shade, the colour,
// and a pale tint of it. The left half of the wave (screen x < the landing spot) is cyan,
// the right half magenta, like the arrows (cyan on the left of the travel, magenta on the
// right) and the wheel icon's hub. Alpha is kept.

uniform vec4 outline : source_color = vec4(0.0549, 0.0392, 0.0863, 1.0);
uniform vec4 left_dark : source_color = vec4(0.1176, 0.5490, 0.7059, 1.0);
uniform vec4 left_colour : source_color = vec4(0.1647, 0.8353, 0.9373, 1.0);
uniform vec4 right_dark : source_color = vec4(0.4314, 0.1333, 0.4078, 1.0);
uniform vec4 right_colour : source_color = vec4(0.8627, 0.2745, 0.7843, 1.0);
// Brightness steps: below the first, the outline; then dark, colour, pale.
uniform float step_outline = 0.22;
uniform float step_dark = 0.5;
uniform float step_pale = 0.8;
// How much white the palest step mixes in.
uniform float pale_mix = 0.55;

varying float side_x;

void vertex() {
	side_x = VERTEX.x;
}

void fragment() {
	vec4 c = COLOR;
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	bool left = side_x < 0.0;
	vec3 dark = left ? left_dark.rgb : right_dark.rgb;
	vec3 base = left ? left_colour.rgb : right_colour.rgb;
	vec3 rgb;
	if (lum < step_outline) {
		rgb = outline.rgb;
	} else if (lum < step_dark) {
		rgb = dark;
	} else if (lum < step_pale) {
		rgb = base;
	} else {
		rgb = mix(base, vec3(1.0), pale_mix);
	}
	COLOR = vec4(rgb, c.a);
}
