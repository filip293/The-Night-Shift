extends MeshInstance3D

@export var viewports: Array[SubViewport]

var timer: float = 0.0
var fps_interval: float = 1.0 / 3.0 # 3 FPS

func _process(delta: float) -> void:
	timer += delta
	if timer >= fps_interval:
		timer = fmod(timer, fps_interval)
		for vp in viewports:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
