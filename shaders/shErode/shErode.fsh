varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2  u_texel;   // 1 / surface size
uniform float u_radius;  // inset in pixels

const int MAX_R = 8;     // loop bounds must be constant; keep >= any radius you use

void main() {
    float a = texture2D(gm_BaseTexture, v_vTexcoord).a;
    float r2 = u_radius * u_radius;

    for (int x = -MAX_R; x <= MAX_R; x++) {
        for (int y = -MAX_R; y <= MAX_R; y++) {
            vec2 o = vec2(float(x), float(y));
            if (dot(o, o) > r2) continue;
            a = min(a, texture2D(gm_BaseTexture, v_vTexcoord + o * u_texel).a);
        }
    }

    gl_FragColor = vec4(1.0, 1.0, 1.0, a);
}