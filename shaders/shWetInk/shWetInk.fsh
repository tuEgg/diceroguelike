// The ink view's wet edge (Jared, 2026-11-22: not a border, the edge itself sloshing like liquid in a container): the
// ink edge of everything you can spend ink on swells out and back in a slow travelling wave, with a quicker ripple and
// a glint on top. Drawn over the view from oCombat.wet_surf, a mask (white where an ink thing is) that wet_ink_draw
// fills from the shapes wet_ink_rect / wet_ink_circle collected this frame. Only touches a thin band round each edge.
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
float m(vec2 uv) { return texture2D(gm_BaseTexture, uv).a; }
// 0 well outside a shape, 1 well inside, 0.5 on its edge: the mask blurred over u_reach
float field(vec2 uv) {
	float s = m(uv) * 2.0, w = 2.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7854 + 0.39;
		vec2 d = vec2(cos(a), sin(a)) * u_reach * u_texel;
		s += m(uv + d) + m(uv + d * 0.5) * 1.5;
		w += 2.5;
	}
	return s / w;
}

void main() {
	vec2 uv = v_vTexcoord;
	float f = field(uv);
	if (f <= 0.002 || f >= 0.998) { gl_FragColor = vec4(0.0); return; } // away from every edge
	vec2 px = uv / u_texel;
	float t = u_time;
	// the slosh: a slow swell running round the edges, a quicker ripple on it
	float swell = sin(px.x * 0.05 + px.y * 0.03 + t * 2.1) * 0.6 + sin(px.x * 0.11 - px.y * 0.07 - t * 3.3) * 0.25;
	float ripple = noise(px / 7.0 + vec2(t * 0.9, -t * 0.6)) - 0.5;
	float th = 0.5 - 0.38 * (swell * 0.7 + ripple * 0.6); // where the ink's edge is now: past the shape when the swell's up
	// a band of ink from that moving edge in to just inside the shape's own border
	float ink = smoothstep(th - 0.05, th + 0.05, f) * (1.0 - smoothstep(0.7, 0.8, f));
	if (ink <= 0.0) { gl_FragColor = vec4(0.0); return; }
	// a glint where the liquid's surface faces up and left
	float gx = field(uv + vec2(u_texel.x, 0.0)) - f;
	float gy = field(uv + vec2(0.0, u_texel.y)) - f;
	float lit = clamp(dot(normalize(vec2(gx, gy) + 1e-5), normalize(vec2(0.6, 0.8))), 0.0, 1.0);
	vec3 col = u_col + vec3(0.35, 0.38, 0.5) * pow(lit, 6.0) * (0.6 + 0.4 * sin(t * 1.3 + px.x * 0.02));
	gl_FragColor = vec4(col, ink * v_vColour.a);
}
