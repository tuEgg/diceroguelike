varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
    vec4 tex = texture2D(gm_BaseTexture, v_vTexcoord);
    gl_FragColor = vec4(v_vColour.rgb, tex.a * v_vColour.a);
}