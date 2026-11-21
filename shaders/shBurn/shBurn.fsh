//
// shBurn: a page burning away (the draft's lost page, 2026-11-21). Whatever is drawn through it (a surface of the page)
// is eaten by a noisy flame front: ahead of the front the paper scorches brown, the front itself glows ember orange,
// behind it nothing is left. u_t runs from about -0.15 (untouched) to 1.0 (gone).
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_t;      // how far the burn has got
uniform float u_seed;   // a different pattern per page
uniform vec2 u_scale;   // noise cells across the texture (about 120 px each)

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32 + u_seed);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * noise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

void main() {
	vec4 base = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
	if (base.a <= 0.0) discard;
	float n = clamp((fbm(v_vTexcoord * u_scale) - 0.22) / 0.52, 0.0, 1.0); // fbm bunches round 0.47: spread it over 0-1 so the burn moves evenly
	float edge = n - u_t; // below 0: burnt away
	if (edge < 0.0) discard;
	vec3 col = base.rgb;
	// scorched ahead of the flame
	float scorch = 1.0 - smoothstep(0.0, 0.2, edge);
	col = mix(col, vec3(0.18, 0.10, 0.05), scorch * 0.85);
	// the glowing rim of the flame
	float rim = 1.0 - smoothstep(0.0, 0.06, edge);
	vec3 ember = mix(vec3(1.0, 0.85, 0.3), vec3(1.0, 0.35, 0.05), rim);
	col = mix(col, ember, rim);
	gl_FragColor = vec4(col, base.a);
}
