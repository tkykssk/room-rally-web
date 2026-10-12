shader_type spatial;

// Procedural wooden planks in world space (no texture to download).
uniform vec3 wood_a : source_color = vec3(0.76, 0.53, 0.33);
uniform vec3 wood_b : source_color = vec3(0.62, 0.41, 0.25);
uniform float plank_width = 1.6;
uniform float plank_length = 10.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float row = floor(world_pos.z / plank_width);
	float offset = hash(vec2(row, 7.0)) * plank_length;
	float u = world_pos.x + offset;
	float col = floor(u / plank_length);
	float h = hash(vec2(row, col));
	vec3 c = mix(wood_a, wood_b, h);
	float grain = sin(u * 2.3 + sin(world_pos.z * 6.0 + h * 12.0) * 0.8) * 0.5 + 0.5;
	c *= 0.94 + 0.06 * grain;
	float fu = fract(u / plank_length) * plank_length;
	float fz = fract(world_pos.z / plank_width) * plank_width;
	float seam = smoothstep(0.0, 0.06, fu) * smoothstep(0.0, 0.06, plank_length - fu)
		* smoothstep(0.0, 0.05, fz) * smoothstep(0.0, 0.05, plank_width - fz);
	ALBEDO = c * mix(0.62, 1.0, seam);
	ROUGHNESS = 0.55;
}
