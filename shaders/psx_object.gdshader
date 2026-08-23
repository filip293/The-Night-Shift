shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float jitter_precision : hint_range(1.0, 100.0, 1.0) = 32.0;

void vertex() {
	// Snap vertices to screen grid in clip space
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 grid_size = VIEWPORT_SIZE / (100.0 / jitter_precision);
	clip_pos.xy /= clip_pos.w;
	clip_pos.xy = floor(clip_pos.xy * grid_size) / grid_size;
	clip_pos.xy *= clip_pos.w;

	POSITION = clip_pos;
}

void fragment() {
	vec4 tex = texture(albedo_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
}