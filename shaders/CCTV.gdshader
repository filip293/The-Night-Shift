shader_type spatial;
render_mode unshaded; // Prevents 3D scene lighting from washing out the TV screen

uniform sampler2D cam_top_left : hint_default_black;
uniform sampler2D cam_top_right : hint_default_black;
uniform sampler2D cam_bottom_left : hint_default_black;
uniform sampler2D cam_bottom_right : hint_default_black;

uniform float fps = 3.0;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.08;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    float time_step = floor(TIME * fps) / fps;

    // Remap 3D UVs into 2x2 quadrants
    vec2 quad_uv = fract(UV * 2.0);
    vec4 src_color;

    if (UV.x < 0.5 && UV.y < 0.5) {
        src_color = texture(cam_top_left, quad_uv);
    } else if (UV.x >= 0.5 && UV.y < 0.5) {
        src_color = texture(cam_top_right, quad_uv);
    } else if (UV.x < 0.5 && UV.y >= 0.5) {
        src_color = texture(cam_bottom_left, quad_uv);
    } else {
        src_color = texture(cam_bottom_right, quad_uv);
    }

    // Grayscale / Nightvision color conversion
    float lum = dot(src_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 final_color = vec3(lum) * vec3(0.85, 0.95, 0.85);

    // Static noise driven strictly by the 3 FPS time_step
    float noise = (random(quad_uv + vec2(time_step)) - 0.5) * noise_amount;

    ALBEDO = clamp(final_color + noise, 0.0, 1.0);
}