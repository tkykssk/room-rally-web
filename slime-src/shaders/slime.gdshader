shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

// Pigment blobs simulated in slime.gd (unit body space).
// blob_pos.xyz = position, blob_col.xyz = log(color), blob_col.w = mass
const int MAX_BLOBS = 24;
uniform vec4 blob_pos[24];
uniform vec4 blob_col[24];
uniform int blob_count = 0;
uniform float sigma = 0.4;

// Body deformation driven from slime.gd
uniform vec3 wobble = vec3(0.0);
uniform float squash = 0.0;
uniform vec4 bulge = vec4(0.0, 0.0, 1.0, 0.0);
uniform float flat_y = -0.55;

varying vec3 body_pos;

void vertex() {
	vec3 p = VERTEX;
	body_pos = p;

	// idle jiggle
	p += NORMAL * (sin(TIME * 3.1 + p.x * 5.0 + p.z * 3.0) * 0.015 + sin(TIME * 2.3 + p.y * 6.0) * 0.012);

	// bump where something was just swallowed
	float bd = max(dot(normalize(VERTEX), bulge.xyz), 0.0);
	p += NORMAL * bulge.w * pow(bd, 6.0);

	// flat contact patch at the bottom
	if (p.y < flat_y) {
		p.y = flat_y + (p.y - flat_y) * 0.25;
	}
	float bottom = flat_y - (1.0 + flat_y) * 0.25;

	// squash & stretch around the bottom
	float h = p.y - bottom;
	p.y = bottom + h * (1.0 - squash);
	p.xz *= 1.0 + squash * 0.5;

	// jelly shear: the top lags behind the bottom
	float k = clamp(h / (1.0 - bottom), 0.0, 1.0);
	p.xz += wobble.xz * k * k;

	VERTEX = p;
}

void fragment() {
	// Sample the pigment field on the surface and at two depths inside,
	// mixing in log space (subtractive, paint-like: yellow + blue -> green).
	vec3 acc = vec3(0.0);
	float ws = 0.0;
	float inv_s2 = 1.0 / (sigma * sigma);
	for (int k = 0; k < 3; k++) {
		vec3 x = body_pos * (1.0 - float(k) * 0.3);
		for (int i = 0; i < MAX_BLOBS; i++) {
			if (i >= blob_count) {
				break;
			}
			vec3 d = x - blob_pos[i].xyz;
			float w = blob_col[i].w * exp(-dot(d, d) * inv_s2);
			acc += w * blob_col[i].xyz;
			ws += w;
		}
	}
	vec3 col = exp(acc / max(ws, 1e-20));

	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = col * 0.9;
	ALPHA = mix(0.72, 0.96, fres);
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
	RIM = 0.5;
	RIM_TINT = 0.3;
	EMISSION = col * (0.12 + 0.25 * fres);
}
