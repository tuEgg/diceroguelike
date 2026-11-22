// The ink view's wet edge (Jared, 2026-11-22: the edge itself sloshing like liquid in a container, each button on its
// own): the ink edge of everything you can spend ink on swells out and back in a slow travelling wave, with a quicker
// ripple and a glint on top. Drawn over the view from oCombat.wet_surf, a mask that wet_ink_draw fills from the shapes
// collected this frame, each in red, green or blue in turn so neighbours (Reroll over Redraw) keep separate edges.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texel;     // 1 / the mask's size
uniform float u_time;     // seconds, kept small
uniform float u_reach;    // how far the edge moves, in pixels
uniform vec3 u_col;       // the ink (global.color_intel)

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec3 mm(vec2 uv) { return texture2D(gm_BaseTexture, uv).rgb; }
// per shape channel: 0 well outside, 1 well inside, 0.5 on the edge (the mask blurred over u_reach)
vec3 field(vec2 uv) {
	vec3 s = mm(uv) * 2.0;
	float w = 2.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7854 + 0.39;
		vec2 d = vec2(cos(a), sin(a)) * u_reach * u_texel;
		s += mm(uv + d) + mm(uv + d * 0.5) * 1.5;
		w += 2.5;
	}
	return s / w;
}
// the band of ink round each shape's moving edge
vec3 band(vec3 f, float th) { return smoothstep(vec3(th - 0.05), vec3(th + 0.05), f) * (1.0 - smoothstep(vec3(0.7), vec3(0.8), f)); }

void main() {
	vec2 uv = v_vTexcoord;
	vec3 f = field(uv);
	if (max(f.r, max(f.g, f.b)) <= 0.002) { gl_FragColor = vec4(0.0); return; } // away from every shape
	vec2 px = uv / u_texel;
	float t = u_time;
	// the slosh: a slow swell running round the edges, a quicker ripple on it
	float swell = sin(px.x * 0.05 + px.y * 0.03 + t * 2.1) * 0.6 + sin(px.x * 0.11 - px.y * 0.07 - t * 3.3) * 0.25;
	float ripple = noise(px / 7.0 + vec2(t * 0.9, -t * 0.6)) - 0.5;
	float th = 0.5 - 0.52 * (swell * 0.7 + ripple * 0.6); // where the ink's edge is now: past the shape when the swell's up
	vec3 ink = band(f, th);
	// inside one shape, its neighbours' edges don't reach in
	vec3 raw = mm(uv);
	ink *= 1.0 - step(0.5, vec3(max(raw.g, raw.b), max(raw.r, raw.b), max(raw.r, raw.g)));
	float k = max(ink.r, max(ink.g, ink.b));
	if (k <= 0.0) { gl_FragColor = vec4(0.0); return; }
	// a glint where the liquid's surface faces up and left (on the shape whose edge this is)
	vec3 sel = step(vec3(k), ink);
	float fc = dot(f, sel) / max(1.0, dot(sel, vec3(1.0)));
	float gx = dot(field(uv + vec2(u_texel.x, 0.0)), sel) / max(1.0, dot(sel, vec3(1.0))) - fc;
	float gy = dot(field(uv + vec2(0.0, u_texel.y)), sel) / max(1.0, dot(sel, vec3(1.0))) - fc;
	float lit = clamp(dot(normalize(vec2(gx, gy) + 1e-5), normalize(vec2(0.6, 0.8))), 0.0, 1.0);
	vec3 col = u_col + vec3(0.35, 0.38, 0.5) * pow(lit, 6.0) * (0.6 + 0.4 * sin(t * 1.3 + px.x * 0.02));
	gl_FragColor = vec4(col, k * v_vColour.a);
}
