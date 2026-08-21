shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// Color quantization (16.0 - 32.0 feels like PS1 15-bit color)
uniform float color_depth : hint_range(4.0, 64.0, 1.0) = 16.0;
uniform float dither_scale : hint_range(1.0, 4.0, 1.0) = 1.0;
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 0.5;

// Standard 4x4 Bayer Dithering Matrix
const mat4 bayer_matrix = mat4(
    vec4( 0.0, 12.0,  3.0, 15.0) / 16.0,
    vec4( 8.0,  4.0, 11.0,  7.0) / 16.0,
    vec4( 2.0, 14.0,  1.0, 13.0) / 16.0,
    vec4(10.0,  6.0,  9.0,  5.0) / 16.0
);

void fragment() {
    vec3 col = texture(screen_texture, SCREEN_UV).rgb;

    // Get pixel coordinate inside the 4x4 grid
    ivec2 dither_pos = ivec2(FRAGCOORD.xy / dither_scale) % 4;
    float dither_val = (bayer_matrix[dither_pos.x][dither_pos.y] - 0.5) * dither_strength;

    // Add dither offset before color crushing
    vec3 dithered_col = col + (dither_val / color_depth);

    // Quantize / Crush colors down to target bit depth
    COLOR.rgb = floor(dithered_col * color_depth) / color_depth;
    COLOR.a = 1.0;
}