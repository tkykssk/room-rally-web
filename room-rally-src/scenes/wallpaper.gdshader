shader_type spatial;

// Soft striped wallpaper, striped along the wall in world space.
uniform vec3 base_color : source_color = vec3(0.96, 0.90, 0.80);
uniform vec3 stripe_color : source_color = vec3(0.92, 0.82, 0.70);
uniform float stripe_width = 1.2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = fract((world_pos.x + world_pos.z) / (stripe_width * 2.0));
	float s = smoothstep(0.46, 0.5, t) * (1.0 - smoothstep(0.96, 1.0, t));
	ALBEDO = mix(base_color, stripe_color, s);
	ROUGHNESS = 0.9;
}
