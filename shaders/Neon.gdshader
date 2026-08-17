shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D main_texture : source_color, hint_default_black;
uniform float glow_intensity : hint_range(1.0, 50.0) = 8.0;
uniform float saturation_boost : hint_range(1.0, 5.0) = 2.0; // Restores deep pink/blue hues
uniform float black_threshold : hint_range(0.0, 0.5) = 0.15;

void fragment() {
	vec4 col = texture(main_texture, UV);
	
	// Calculate pixel brightness
	float brightness = max(col.r, max(col.g, col.b));
	
	// Boost color saturation so high emission values don't blow out to white
	vec3 grayscale = vec3(dot(col.rgb, vec3(0.299, 0.587, 0.114)));
	vec3 vibrant_color = mix(grayscale, col.rgb, saturation_boost);
	
	// Apply boosted texture color directly to output
	ALBEDO = vibrant_color;
	EMISSION = vibrant_color * glow_intensity; // Color drives the WorldEnvironment bloom
	
	// Cut out black background
	if (brightness < black_threshold) {
		ALPHA = 0.0;
	} else {
		ALPHA = 1.0;
	}
}