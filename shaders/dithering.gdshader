shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// FIXED RETRO RESOLUTION (Resolution-Agnostic Target Grid)
// 640x360 = Clean, highly compatible PSX/PS2 style (Best for OBS/Streaming)
// 480x270 = Chunkier, heavy retro style
// 320x240 = Extreme low-res 4:3
uniform vec2 virtual_resolution = vec2(640.0, 360.0);

// Color depth quantization (16.0 - 24.0 feels like authentic 15/16-bit color)
uniform float color_depth : hint_range(4.0, 64.0, 1.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0, 0.05) = 0.45;

// Standard 4x4 Bayer Dithering Matrix
const mat4 bayer_matrix = mat4(
    vec4( 0.0, 12.0,  3.0, 15.0) / 16.0,
    vec4( 8.0,  4.0, 11.0,  7.0) / 16.0,
    vec4( 2.0, 14.0,  1.0, 13.0) / 16.0,
    vec4(10.0,  6.0,  9.0,  5.0) / 16.0
);

void fragment() {
    // 1. Quantize UV coordinates to the VIRTUAL grid (Independent of monitor/window resolution)
    vec2 grid_uv = floor(SCREEN_UV * virtual_resolution) / virtual_resolution;

    // 2. Sample screen at the quantized pixel center
    vec3 col = texture(screen_texture, grid_uv).rgb;

    // 3. Calculate 4x4 Bayer pattern coordinates based on the VIRTUAL grid, NOT screen pixels!
    ivec2 dither_pos = ivec2(grid_uv * virtual_resolution) % 4;
    float dither_val = (bayer_matrix[dither_pos.x][dither_pos.y] - 0.5) * dither_strength;

    // 4. Apply dither offset and quantize colors
    vec3 dithered_col = col + (dither_val / color_depth);
    
    // Safety clamp to prevent pure black crushed holes
    dithered_col = max(dithered_col, vec3(0.03, 0.03, 0.05));

    COLOR.rgb = floor(dithered_col * color_depth) / color_depth;
    COLOR.a = 1.0;
}