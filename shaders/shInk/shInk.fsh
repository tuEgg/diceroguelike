// The log's ink look (F118): the screen as it would be, redrawn as wobbly ink lines and hatching on parchment.
// Drawn over the whole screen by combat_insight_view_draw while the log is open. Where u_mask is clear (the holes the
// log cuts: intents, the action queue) the original colour shows through. A port of docs/mockups/ink-log-preview.html.
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 u_texel;       // 1 / the scene surface's size
uniform float u_time;       // seconds, for the boil (lines redrawn 4x a second)
uniform sampler2D u_mask;   // the log's overlay: alpha 0 where things keep their colour, u_mask_a elsewhere
uniform float u_mask_a;

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
vec3 tx(vec2 uv) { return texture2D(gm_BaseTexture, uv).rgb; }

void main() {
	vec2 px = u_texel;
	vec3 orig = tx(v_vTexcoord);

	// the hand: a slow wobble in where each line is drawn, re-scribbled a few times a second
	float boil = floor(u_time * 4.0);
	vec2 q = gl_FragCoord.xy / 14.0;
	vec2 wob = (vec2(noise(q + boil * 3.1), noise(q + 17.0 + boil * 5.7)) - 0.5) * 2.4 * px;
	vec2 uv = v_vTexcoord + wob;

	// edges: Sobel on brightness and on colour, so two colours of the same brightness still get a line
	vec2 o = px * 0.96;
	vec3 a = tx(uv + o * vec2(-1.0, -1.0)), b = tx(uv + o * vec2(0.0, -1.0)), c = tx(uv + o * vec2(1.0, -1.0));
	vec3 d = tx(uv + o * vec2(-1.0,  0.0)),                                    f = tx(uv + o * vec2(1.0,  0.0));
	vec3 g = tx(uv + o * vec2(-1.0,  1.0)), h = tx(uv + o * vec2(0.0,  1.0)), i = tx(uv + o * vec2(1.0,  1.0));
	vec3 gx = (c + 2.0 * f + i) - (a + 2.0 * d + g);
	vec3 gy = (g + 2.0 * h + i) - (a + 2.0 * b + c);
	float edge = max(length(vec2(lum(gx), lum(gy))), 0.6 * length(vec2(length(gx), length(gy))) / 1.7);
	float skip = 0.75 + 0.25 * noise(gl_FragCoord.xy / 3.0 + boil); // a nib skipping
	float ink = smoothstep(0.10, 0.32, edge) * skip;

	// shading as hatching: one direction in the mid-darks, crossed in the darks
	float L = lum(tx(uv));
	vec2 fc = gl_FragCoord.xy + wob / px * 2.0;
	float h1 = 1.0 - smoothstep(0.08, 0.22, abs(fract((fc.x + fc.y) / 7.0) - 0.5));
	float h2 = 1.0 - smoothstep(0.08, 0.22, abs(fract((fc.x - fc.y) / 7.0) - 0.5));
	float hatch = h1 * (1.0 - smoothstep(0.30, 0.48, L)) + h2 * (1.0 - smoothstep(0.14, 0.26, L));
	hatch *= 0.35 * 0.55 * (0.7 + 0.3 * noise(fc / 9.0));

	// the page: parchment with a little grain and darker edges, and a faint wash of the original colour
	float grain = 0.93 + 0.07 * noise(gl_FragCoord.xy / 2.5) * noise(gl_FragCoord.xy / 31.0);
	float vig = 1.0 - 0.25 * pow(length(v_vTexcoord - 0.5) * 1.3, 2.0);
	vec3 paper = vec3(0.91, 0.85, 0.71) * grain * vig;
	paper = mix(paper, paper * (0.55 + 0.6 * orig), 0.15);
	vec3 col = mix(paper, vec3(0.17, 0.11, 0.07), clamp(max(ink, hatch), 0.0, 1.0));

	// what the log leaves in colour (its holes)
	float keep = 1.0 - clamp(texture2D(u_mask, v_vTexcoord).a / max(u_mask_a, 0.01), 0.0, 1.0);
	gl_FragColor = vec4(mix(col, orig, keep), 1.0);
}
