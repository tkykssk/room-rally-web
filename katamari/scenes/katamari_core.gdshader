shader_type spatial;

// Striped ball so the roll is readable even before anything sticks to it.
uniform vec4 color_a : source_color = vec4(0.95, 0.35, 0.55, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform float stripes = 6.0;

varying vec3 obj_normal;

void vertex() {
	obj_normal = NORMAL;
}

void fragment() {
	vec3 n = normalize(obj_normal);
	float band = step(0.5, fract(atan(n.z, n.x) / TAU * stripes));
	float cap = step(0.85, abs(n.y));
	ALBEDO = mix(color_a.rgb, color_b.rgb, max(band, cap));
	ROUGHNESS = 0.6;
}
