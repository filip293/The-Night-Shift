shader_type spatial;
render_mode blend_mix, depth_draw_always;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.05);
uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float refraction_strength : hint_range(-0.1, 0.1) = 0.02;
uniform float fresnel_power : hint_range(0.1, 5.0) = 2.0;
uniform float edge_intensity : hint_range(0.0, 1.0) = 0.2;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Glass is a dielectric material; metallic must be 0.
    METALLIC = 0.0;
    ROUGHNESS = roughness;
    SPECULAR = 0.5;

    // Calculate screen UV distortion based on view-space normals
    vec2 ref_offset = NORMAL.xy * refraction_strength;
    vec3 bg_color = texture(screen_tex, SCREEN_UV - ref_offset).rgb;

    // Calculate Fresnel for realistic edge reflections
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);

    // Composite the final color
    vec3 base_color = mix(bg_color, albedo.rgb, albedo.a);
    ALBEDO = mix(base_color, vec3(1.0), fresnel * edge_intensity);
}