extends Node

@export var viewports: Array[SubViewport]
var current_index: int = 0
var timer: float = 0.0
var tick_rate: float = (1.0 / 3.0) / 4.0 

func _ready() -> void:
	for vp in viewports:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

func _process(delta: float) -> void:
	timer += delta
	if timer >= tick_rate:
		timer = 0.0
		
		# Update only ONE camera this tick
		viewports[current_index].render_target_update_mode = SubViewport.UPDATE_ONCE
		
		# Move to next camera
		current_index = (current_index + 1) % viewports.size()
