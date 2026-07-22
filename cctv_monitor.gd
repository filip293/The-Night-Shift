extends MeshInstance3D

@export var cam1_viewport: SubViewport
@export var cam2_viewport: SubViewport
@export var cam3_viewport: SubViewport
@export var cam4_viewport: SubViewport

func _ready() -> void:
	# Wait one frame to ensure SubViewports are fully initialized
	await get_tree().process_frame

	# Get the ShaderMaterial assigned to Surface 0
	var mat = get_active_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("cam_top_left", cam1_viewport.get_texture())
		mat.set_shader_parameter("cam_top_right", cam2_viewport.get_texture())
		mat.set_shader_parameter("cam_bottom_left", cam3_viewport.get_texture())
		mat.set_shader_parameter("cam_bottom_right", cam4_viewport.get_texture())
