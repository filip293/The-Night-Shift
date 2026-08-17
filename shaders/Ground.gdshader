shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Uniforms exposed to the Inspector
uniform vec4 base_color : source_color = vec4(0.15, 0.15, 0.15, 1.0);
uniform vec4 puddle_color : source_color = vec4(0.08, 0.08, 0.08, 1.0);

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D puddle_noise : hint_default_white, filter_linear_mipmap, repeat_enable;

// Realistic roughness boundaries
uniform float dry_roughness : hint_range(0.0, 1.0) = 0.75;
uniform float wet_roughness : hint_range(0.0, 1.0) = 0.28; // Higher base roughness keeps it looking like solid ground

// Puddle distribution controls
uniform float puddle_threshold : hint_range(0.0, 1.0) = 0.72;
uniform float puddle_softness : hint_range(0.001, 0.2) = 0.03;

// Subtle Raindrop Impact Settings
uniform float drop_speed : hint_range(0.1, 10.0) = 2.0;
uniform float drop_density : hint_range(1.0, 50.0) = 25.0;
uniform float ripple_intensity : hint_range(0.0, 1.0) = 0.08; // Significantly reduced default intensity

vec2 rand_vec2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

vec2 get_raindrop_normal(vec2 uv, float time) {
    vec2 p = uv * drop_density;
    vec2 cell = floor(p);
    vec2 sub = fract(p);
    vec2 ripple_normal = vec2(0.0);
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 cell_offset = vec2(float(x), float(y));
            vec2 random_point = rand_vec2(cell + cell_offset);
            
            float drop_time = fract(time * drop_speed * 0.15 + random_point.x);
            vec2 dist_vec = sub - (cell_offset + random_point);
            float dist = length(dist_vec);
            
            float ring_radius = drop_time * 0.7;
            float ring_width = 0.05;
            float wave = sin((dist - ring_radius) * 30.0);
            float fade = smoothstep(ring_width, 0.0, abs(dist - ring_radius)) * (1.0 - drop_time);
            
            if (dist < ring_radius + ring_width && dist > ring_radius - ring_width) {
                ripple_normal += normalize(dist_vec) * wave * fade;
            }
        }
    }
    return ripple_normal * ripple_intensity;
}

void fragment() {
    // 1. Sample base textures
    vec4 albedo_tex = texture(texture_albedo, UV);
    vec3 normal_tex = texture(texture_normal, UV).rgb * 2.0 - 1.0;
    
    // 2. Sample puddle noise map
    float noise_val = texture(puddle_noise, UV).r;
    float puddle_mask = smoothstep(puddle_threshold - puddle_softness, puddle_threshold + puddle_softness, noise_val);
    
    // 3. Subtle ripples across surface
    vec2 drop_ripple = get_raindrop_normal(UV, TIME);
    
    // Preserve base surface normal map and add subtle ripple offset on top
    vec3 surface_normal = normalize(normal_tex + vec3(drop_ripple, 0.0));
    vec3 flat_puddle_normal = normalize(vec3(0.0, 0.0, 1.0) + vec3(drop_ripple * 1.5, 0.0));
    
    vec3 final_normal = mix(surface_normal, flat_puddle_normal, puddle_mask);
    
    // 4. Subtle color darkening when wet (wet ground absorbs light)
    vec3 wet_albedo = albedo_tex.rgb * base_color.rgb * 0.65;
    vec3 final_albedo = mix(wet_albedo, puddle_color.rgb, puddle_mask * 0.2);
    
    ALBEDO = final_albedo;
    ROUGHNESS = mix(dry_roughness, wet_roughness, puddle_mask);
    NORMAL_MAP = final_normal * 0.5 + 0.5;
    SPECULAR = mix(0.15, 0.35, puddle_mask);
}

void light() {
    float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
    DIFFUSE_LIGHT += LIGHT_COLOR * ALBEDO * NdotL * ATTENUATION;

    if (!LIGHT_IS_DIRECTIONAL) {
        vec3 H = normalize(VIEW + LIGHT);
        float NdotH = clamp(dot(NORMAL, H), 0.0, 1.0);
        float spec = pow(NdotH, mix(64.0, 8.0, ROUGHNESS));
        SPECULAR_LIGHT += LIGHT_COLOR * spec * ATTENUATION * 0.4;
    }
}