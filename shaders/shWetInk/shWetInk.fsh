// The ink view's wet edge (Jared, 2026-11-22; docs/mockups/wet-ink-edge.html): ink bleeding out round everything you
// can spend ink on, darkest where it pools at the rim, lobed by the paper's fibres, running in a few drips, with a
// moving shine. Drawn over the view from oCombat.wet_surf, a half-size mask (white where an ink thing is) that
// wet_ink_draw fills from the shapes wet_ink_rect / wet_ink_circle collected this frame. Clear inside the shapes
// and away from them, so it can go on top.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texel;     // 1 / the mask's size
uniform float u_time;     // seconds, kept small
uniform float u_spread;   // how far it bleeds, in mask pixels
uniform float u_shine;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int k = 0; k < 4; k++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }
float m(vec2 uv) { return texture2D(gm_BaseTexture, uv).a; }
// how much ink is near: the mask blurred over a disc of u_spread (two rings of taps)
float field(vec2 uv) {
	float s = 0.0, w = 0.0;
	for (int i = 0; i < 12; i++) {
		float a = float(i) * 0.5236;
		vec2 d = vec2(cos(a), sin(a)) * u_spread * u_texel;
		s += m(uv + d * 0.5) * 0.95 + m(uv + d) * 0.6;
		w += 1.55;
	}
	return (s + m(uv) * 1.5) / (w + 1.5);
}

void main() {
	vec2 uv0 = v_vTexcoord;
	if (m(uv0) > 0.5) { gl_FragColor = vec4(0.0); return; } // the thing itself shows through
	vec2 px = uv0 / u_texel;
	// drips: here and there the ink runs down a little, swaying slowly
	float dn = noise(vec2(px.x / 5.5, 3.0));
	float drip = pow(dn, 4.0) * u_spread * (2.2 + 0.4 * sin(u_time * 0.6 + dn * 6.0));
	// nothing near (a quick look round first): clear
	float near = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7854;
		near += m(uv0 + vec2(cos(a), sin(a)) * u_spread * 1.3 * u_texel);
	}
	near += m(uv0 - vec2(0.0, drip * u_texel.y));
	near += m(uv0 - vec2(0.0, drip * 0.5 * u_texel.y));
	if (near <= 0.0) { gl_FragColor = vec4(0.0); return; }
	// the edge creeps: where we sample from wanders with slow noise
	vec2 drift = vec2(fbm(px / 19.0 + u_time * 0.12), fbm(px / 19.0 + 9.3 - u_time * 0.1)) - 0.5;
	vec2 uv = uv0 + drift * 2.5 * u_texel;
	float f = max(field(uv), field(uv - vec2(0.0, drip * u_texel.y)) * smoothstep(0.55, 0.8, dn));
	float grain = fbm(px / 4.5 + u_time * 0.04); // the paper soaking it up unevenly: lobes
	float th = 0.03 + 0.16 * grain * grain + 0.01 * sin(u_time * 1.7);
	float wet = smoothstep(th, th + 0.025, f);
	if (wet <= 0.0) { gl_FragColor = vec4(0.0); return; }
	// solid near the shape, darkest at the outer rim
	float rim = 1.0 - smoothstep(th + 0.01, th + 0.09, f);
	float a = wet * mix(0.72, 0.96, max(rim, smoothstep(0.35, 0.6, f)));
	vec3 col = vec3(0.05, 0.06, 0.13);
	// the shine: the wet surface as a dome, lit from the top left, sliding a little
	float fx = field(uv + vec2(u_texel.x * 1.5, 0.0)) - f;
	float fy = field(uv + vec2(0.0, u_texel.y * 1.5)) - f;
	vec3 n = normalize(vec3(-fx * 18.0, -fy * 18.0, 1.0));
	vec3 L = normalize(vec3(-0.5 + 0.3 * sin(u_time * 0.7), -0.7, 0.55));
	vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
	float nh = max(dot(n, H), 0.0);
	float spec = (pow(nh, 40.0) * 0.55 + pow(nh, 160.0) * 0.7) * wet * u_shine;
	col += vec3(0.62, 0.68, 0.9) * spec;
	gl_FragColor = vec4(col, clamp(a + spec * 0.5, 0.0, 1.0) * v_vColour.a);
}
