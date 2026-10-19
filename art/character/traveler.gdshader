shader_type spatial;
render_mode cull_disabled;
uniform vec4 ink : source_color = vec4(1.0);
void fragment() {
    ALBEDO = ink.rgb;
    ROUGHNESS = 0.95;
    // A little fill keeps the face readable under the station canopy.
    EMISSION = ink.rgb * 0.055;
    if (!FRONT_FACING) NORMAL = -NORMAL;
}
void light() {
    float ndl = dot(NORMAL, LIGHT);
    float band = mix(0.32, 0.76, smoothstep(-0.12, -0.04, ndl));
    band = mix(band, 1.0, smoothstep(0.48, 0.55, ndl));
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
