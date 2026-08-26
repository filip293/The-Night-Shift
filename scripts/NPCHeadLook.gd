extends Node3D

@export_group("Target & Node References")
@export var player_node: Node3D
@export var look_at_modifier: LookAtModifier3D

@export_group("Look Limits & Speeds")
@export var max_head_angle_deg: float = 40.0 # Angle before body starts rotating
@export var body_rotation_speed: float = 2.5 # Speed of body turn
@export var blend_speed: float = 3.0

@export_group("Model Axis Calibration")
@export var model_forward_offset_deg: float = 260.0 

var is_tracking_player: bool = false

func _ready() -> void:
	if not player_node and has_node("/root/Node3D/Player"):
		player_node = get_node("/root/Node3D/Player")

func _process(delta: float) -> void:
	if not is_tracking_player or not is_instance_valid(player_node):
		if look_at_modifier:
			look_at_modifier.influence = move_toward(look_at_modifier.influence, 0.0, delta * blend_speed)
		return

	# Enable head modifier influence smoothly
	if look_at_modifier:
		look_at_modifier.influence = move_toward(look_at_modifier.influence, 1.0, delta * blend_speed)

	# 1. Get flat direction vector toward player
	var global_pos = global_transform.origin
	var player_pos = player_node.global_transform.origin
	var dir = (player_pos - global_pos)
	dir.y = 0.0
	
	if dir.length_squared() < 0.001:
		return
	dir = dir.normalized()

	# 2. Calculate actual chest direction vector using your 260 degree offset
	var offset_rad = deg_to_rad(model_forward_offset_deg)
	var chest_forward = (-global_transform.basis.z).rotated(Vector3.UP, offset_rad)
	
	# 3. Calculate signed angle between chest and player (-180 to 180 degrees)
	var angle_diff_deg = rad_to_deg(chest_forward.signed_angle_to(dir, Vector3.UP))

	# 4. Body turning logic:
	# If player moves beyond max_head_angle_deg, rotate the body to keep the player within the head's comfort zone
	if abs(angle_diff_deg) > max_head_angle_deg:
		var target_y = atan2(-dir.x, -dir.z) - offset_rad
		rotation.y = lerp_angle(rotation.y, target_y, delta * body_rotation_speed)

func set_tracking(active: bool) -> void:
	is_tracking_player = active
