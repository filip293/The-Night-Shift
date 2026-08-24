shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx;

// --- Colors & Brightness ---
uniform vec4 asphalt_color : source_color = vec4(0.42, 0.44, 0.50, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.25, 0.28, 0.35, 1.0);

// SAFETY FLOOR: Guarantees the asphalt will NEVER go pitch black even in shadows
uniform float min_ambient_brightness : hint_range(0.0, 0.5, 0.01) = 0.12;

// --- Textures ---
uniform sampler2D texture_albedo : source_color, hint_default_white, filter_nearest, repeat_enable;
uniform sampler2D texture_normal : hint_normal, filter_nearest, repeat_enable;
uniform sampler2D puddle_noise : hint_default_white, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(6.0, 6.0);

// --- Puddle Controls ---
uniform float puddle_amount : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float puddle_softness : hint_range(0.01, 0.5, 0.01) = 0.08;

// --- Raindrop Ripples ---
uniform bool enable_rain_ripples = true;
uniform float ripple_speed : hint_range(0.5, 10.0, 0.1) = 2.5;
uniform float ripple_density : hint_range(5.0, 100.0, 1.0) = 35.0;
uniform float ripple_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

// Clean, lightweight procedural ripple function
vec2 get_ripples(vec2 uv, float time) {
    vec2 p = uv * ripple_density;
    vec2 id = floor(p);
    vec2 gv = fract(p) - 0.5;
    
    // Pseudo-random phase per ripple drop
    float noise = fract(sin(dot(id, vec2(127.1, 311.7))) * 43758.5453);
    float t = fract(time * ripple_speed * 0.2 + noise);
    
    float dist = length(gv);
    float ring = sin((dist - t * 0.8) * 32.0);
    float fade = smoothstep(0.5, 0.0, dist) * (1.0 - t);
    
    return normalize(gv + 0.001) * ring * fade * ripple_strength;
}

void fragment() {
    vec2 scaled_uv = UV * uv_scale;

    // 1. Sample Textures safely (hint_default_white guarantees no pure black)
    vec4 tex_albedo = texture(texture_albedo, scaled_uv);
    
    // 2. Calculate Puddle Mask from noise
    float noise_val = texture(puddle_noise, scaled_uv * 0.2).r;
    float puddle_mask = smoothstep(1.0 - puddle_amount - puddle_softness, 1.0 - puddle_amount + puddle_softness, noise_val);

    // 3. Color Math
    vec3 dry_base = tex_albedo.rgb * asphalt_color.rgb;
    vec3 wet_base = mix(dry_base * 0.85, puddle_color.rgb, 0.4);
    vec3 final_albedo = mix(dry_base, wet_base, puddle_mask);

    // Apply the safety ambient floor
    final_albedo = max(final_albedo, vec3(min_ambient_brightness) * asphalt_color.rgb);

    ALBEDO = final_albedo;

    // 4. Roughness & Specular (Puddles become mirror-smooth to catch light)
    ROUGHNESS = mix(0.85, 0.06, puddle_mask);
    SPECULAR = mix(0.1, 0.9, puddle_mask);

    // 5. Raindrop Ripples on Puddle Surfaces
    if (enable_rain_ripples && puddle_mask > 0.05) {
        vec2 ripple = get_ripples(scaled_uv, TIME) * puddle_mask;
        NORMAL = normalize(NORMAL + vec3(ripple.x, 0.0, ripple.y));
    }
}