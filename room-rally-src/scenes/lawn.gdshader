shader_type spatial;

// Mowed lawn in world space: wide light/dark stripes with a little noise.
uniform vec3 grass_a : source_color = vec3(0.45, 0.72, 0.33);
uniform vec3 grass_b : source_color = vec3(0.39, 0.65, 0.29);
uniform float stripe_width = 6.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float s = step(0.5, fract(world_pos.x / (stripe_width * 2.0)));
	vec3 c = mix(grass_a, grass_b, s);
	float n = noise(world_pos.xz * 0.35) * 0.6 + noise(world_pos.xz * 1.7) * 0.4;
	c *= 0.9 + 0.18 * n;
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
