shader_type spatial;
render_mode cull_disabled;

// Replaces a prop's materials while it is being absorbed: the surface is eaten
// away starting at the contact point, with a noisy front glowing in the slime colour.
uniform vec4 albedo : source_color = vec4(1.0);
uniform float roughness = 0.8;
uniform bool use_vertex_color = false;
uniform vec3 contact = vec3(0.0);
uniform float extent = 1.0;
uniform float progress = 0.0;
uniform vec3 edge_color : source_color = vec3(0.45, 0.95, 0.6);

varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = distance(world_pos, contact) / extent;
	float n = noise(world_pos * 6.0 / extent) * 0.6 + noise(world_pos * 14.0 / extent) * 0.4;
	float v = d + (n - 0.5) * 0.4;
	float front = progress * 1.4 - 0.15;
	if (v < front) {
		discard;
	}
	float edge = 1.0 - smoothstep(0.0, 0.1, v - front);
	edge *= step(0.001, progress);
	vec3 base = use_vertex_color ? albedo.rgb * COLOR.rgb : albedo.rgb;
	ALBEDO = mix(base, edge_color, edge * 0.85);
	EMISSION = edge_color * edge * 0.7;
	ROUGHNESS = roughness;
}
