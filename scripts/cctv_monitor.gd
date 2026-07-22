extends MeshInstance3D

@export var viewports: Array[SubViewport]

var next_tick_msec: int = 0
var interval_msec: int = 333
var is_snapping: bool = false
var tv_material: ShaderMaterial

func _ready() -> void:
	# 1. Retrieve the material and link textures programmatically
	tv_material = self.get_active_material(0) as ShaderMaterial
	if tv_material:
		tv_material.set_shader_parameter("cam_top_left", viewports[0].get_texture())
		tv_material.set_shader_parameter("cam_top_right", viewports[1].get_texture())
		tv_material.set_shader_parameter("cam_bottom_left", viewports[2].get_texture())
		tv_material.set_shader_parameter("cam_bottom_right", viewports[3].get_texture())
	
	# 2. Force an immediate render before freezing
	_snap_frame()
	
	next_tick_msec = Time.get_ticks_msec() + interval_msec

func _process(_delta: float) -> void:
	var current_time: int = Time.get_ticks_msec()
	
	if current_time >= next_tick_msec and not is_snapping:
		next_tick_msec = current_time + interval_msec
		_snap_frame()

func _snap_frame() -> void:
	is_snapping = true
	
	# Enable 3D pass and allow frame clear
	for vp in viewports:
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		vp.disable_3d = false
		
	# Wait two render cycles for the pipeline to push the frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	
	# Freeze buffer and disable 3D pass
	for vp in viewports:
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		vp.disable_3d = true
		
	is_snapping = false
