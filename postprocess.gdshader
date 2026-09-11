shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Modern PSX Polish Controls
uniform float grain_amount : hint_range(0.0, 0.1, 0.005) = 0.025;  // Subtle analog film grain
uniform float vignette_intensity : hint_range(0.0, 1.0, 0.05) = 0.35; // Darkens edges for claustrophobia
uniform float vignette_opacity : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float brightness_boost : hint_range(-0.2, 0.2, 0.01) = 0.02;

// Pseudo-random noise for film grain
float random(vec2 uv, float time) {
    return fract(sin(dot(uv + vec2(time * 0.1), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec3 col = texture(screen_texture, SCREEN_UV).rgb;

    // 1. Subtle Analog Film Grain (breathing noise, not static dots)
    float noise = (random(SCREEN_UV, TIME) - 0.5) * grain_amount;
    col += noise;

    // 2. Cinematic Vignette (darkens screen corners for horror mood)
    vec2 uv = SCREEN_UV * (1.0 - SCREEN_UV.yx);
    float vig = uv.x * uv.y * 15.0;
    vig = clamp(pow(vig, vignette_intensity), 0.0, 1.0);
    col = mix(col * vig, col, 1.0 - vignette_opacity);

    // 3. Subtle Brightness Lift
    col += brightness_boost;

    COLOR = vec4(col, 1.0);
}