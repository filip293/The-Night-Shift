extends Node3D
#
#@export_group("Target & Node References")
#@export var player_node: Node3D
#@export var look_at_modifier: LookAtModifier3D
#
#@export_group("Look Limits & Speeds")
#@export var max_head_angle_deg: float = 40.0
#@export var body_rotation_speed: float = 2.5
#@export var blend_speed: float = 3.0
#
#@export_group("Model Axis Calibration")
### Adjust this only if the raw mesh is rotated inside the scene
#@export var model_forward_offset_deg: float = 0.0
#
#var is_tracking_player: bool = false
#var original_rotation_y: float = 0.0
#
#func _ready() -> void:
	#original_rotation_y = rotation.y
	#if not is_instance_valid(player_node):
		#player_node = get_tree().get_first_node_in_group("Player") if get_tree().has_group("Player") else get_node_or_null("/root/Node3D/Player")
#
#func _process(delta: float) -> void:
	#if not is_tracking_player or not is_instance_valid(player_node):
		## Blend head back to neutral
		#if look_at_modifier:
			#look_at_modifier.influence = move_toward(look_at_modifier.influence, 0.0, delta * blend_speed)
		#return
#
	## Blend head modifier influence up
	#if look_at_modifier:
		#look_at_modifier.influence = move_toward(look_at_modifier.influence, 1.0, delta * blend_speed)
#
	## 1. Flat vector toward player
	#var global_pos = global_position
	#var player_pos = player_node.global_position
	#var dir = player_pos - global_pos
	#dir.y = 0.0
	#
	#if dir.length_squared() < 0.001:
		#return
	#dir = dir.normalized()
#
	## 2. Forward vector with offset
	#var offset_rad = deg_to_rad(model_forward_offset_deg)
	#var chest_forward = (-global_transform.basis.z).rotated(Vector3.UP, offset_rad)
	#
	## 3. Angle difference
	#var angle_diff_deg = rad_to_deg(chest_forward.signed_angle_to(dir, Vector3.UP))
#
	## 4. Turn body if head angle exceeds limit
	#if abs(angle_diff_deg) > max_head_angle_deg:
		#var target_y = atan2(-dir.x, -dir.z) - offset_rad
		#rotation.y = lerp_angle(rotation.y, target_y, delta * body_rotation_speed)
#
#func set_tracking(active: bool) -> void:
	#is_tracking_player = active
	#if not active and look_at_modifier:
		#look_at_modifier.influence = 0.0
