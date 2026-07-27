extends StaticBody3D

@export var whoami_value: String = "Object"

enum ObjectType { GENERIC, DOOR, PUDDLE }
@export var object_type: ObjectType = ObjectType.GENERIC:
	set(value):
		object_type = value
		notify_property_list_changed()

# --- Door Settings ---
@export_group("Door Settings")
@export var open_rotation_y: float = 90.0
@export var closed_rotation_y: float = 0.0
@export var audio_player: AudioStreamPlayer3D
@export var open_sound: AudioStream
@export var close_sound: AudioStream

# --- Puddle Settings ---
@export_group("Puddle Settings")
@export var puddle_mesh: MeshInstance3D
@export var mop_animation_player: AnimationPlayer
@export var mopping_sound: AudioStream
@export var mop_duration: float = 1.5

var is_open: bool = false
var door_tween: Tween
var is_being_mopped: bool = false
var current_mop_progress: float = 0.0  # Keeps track of progress even if paused

func _validate_property(property: Dictionary) -> void:
	# Handle Door settings visibility
	var door_properties = ["open_rotation_y", "closed_rotation_y", "audio_player", "open_sound", "close_sound"]
	if property.name in door_properties and object_type != ObjectType.DOOR:
		property.usage = PROPERTY_USAGE_NO_EDITOR

	# Handle Puddle settings visibility
	var puddle_properties = ["puddle_mesh", "mop_animation_player", "mopping_sound", "mop_duration"]
	if property.name in puddle_properties and object_type != ObjectType.PUDDLE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func interact() -> void:
	match object_type:
		ObjectType.DOOR:
			_toggle_door()
		ObjectType.GENERIC:
			_on_interact_generic()

func _toggle_door() -> void:
	if Engine.is_editor_hint() or (door_tween and door_tween.is_running()):
		return

	is_open = not is_open
	door_tween = create_tween()

	var target_y = open_rotation_y if is_open else closed_rotation_y
	var current_y = rotation_degrees.y
	var angle_difference = wrapf(target_y - current_y, -180.0, 180.0)
	var final_target_y = current_y + angle_difference

	if is_open:
		if audio_player and open_sound:
			audio_player.stream = open_sound
			audio_player.play()
		door_tween.tween_property(self, "rotation_degrees:y", final_target_y, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else: 
		if audio_player and close_sound:
			audio_player.stream = close_sound
			audio_player.play()
		door_tween.tween_property(self, "rotation_degrees:y", final_target_y, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

# Called once when the player first presses and holds E on the puddle
func start_mopping() -> void:
	if Engine.is_editor_hint() or is_being_mopped:
		return
		
	is_being_mopped = true
	
	# Lock player position and look angles
	if "playermoveallow" in Globals:
		Globals.playermoveallow = false
	if "playerlookallow" in Globals:
		Globals.playerlookallow = false

	# Play Mopping Sound
	if audio_player and mopping_sound:
		audio_player.stream = mopping_sound
		audio_player.play()

	# Play & loop the mopping animation programmatically
	if mop_animation_player and mop_animation_player.has_animation("Bwoom"):
		var anim = mop_animation_player.get_animation("Bwoom")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		mop_animation_player.play("Bwoom") 

	# Duplicate material to prevent fading other puddles simultaneously
	if puddle_mesh and puddle_mesh.get_active_material(0) and not puddle_mesh.material_override:
		var mat = puddle_mesh.get_active_material(0).duplicate()
		puddle_mesh.material_override = mat

# Called every frame while the player is successfully holding down E
func mop_tick(delta: float) -> void:
	if not is_being_mopped:
		return
		
	current_mop_progress += delta
	
	# Update opacity based on progress
	if puddle_mesh and puddle_mesh.material_override:
		var progress_pct = current_mop_progress / mop_duration
		puddle_mesh.material_override.albedo_color.a = clampf(1.0 - progress_pct, 0.0, 1.0)
		
	# Check for completion
	if current_mop_progress >= mop_duration:
		_finish_mopping()

# Called automatically when they release E before the puddle is fully cleaned
func cancel_mopping() -> void:
	if not is_being_mopped:
		return
		
	is_being_mopped = false
	
	# Unlock player
	if "playermoveallow" in Globals:
		Globals.playermoveallow = true
	if "playerlookallow" in Globals:
		Globals.playerlookallow = true

	# Stop sounds and animations
	if audio_player:
		audio_player.stop()
	if mop_animation_player:
		mop_animation_player.stop()

func _finish_mopping() -> void:
	is_being_mopped = false
	
	# Disable collision immediately
	var col_shape = get_node_or_null("CollisionShape3D")
	if col_shape:
		col_shape.set_deferred("disabled", true)

	# Unlock player
	if "playermoveallow" in Globals:
		Globals.playermoveallow = true
	if "playerlookallow" in Globals:
		Globals.playerlookallow = true

	# Stop sound & animations
	if audio_player:
		audio_player.stop()
	if mop_animation_player:
		mop_animation_player.stop()

	queue_free()

func _on_interact_generic() -> void:
	if not Engine.is_editor_hint():
		print("Interacted with generic object: ", whoami_value)
		
		if whoami_value == "Take crate":
			# Delete or hide the outside crate node
			queue_free()
			
		elif whoami_value == "Take cans":
			# This node gets interacted with twice. Let's look at the current global state:
			if Globals.get("crate_delivered") and not Globals.get("has_cans"):
				$"../../../Cans3".visible = true
				$"../../../Cans2".visible = true
			elif Globals.get("has_cans"):
				$"../../../Cans2".visible = false
			
		elif whoami_value == "Restock cans":
			$"../../../Cans2".visible = false
			$"../../../Cans".visible = true

func whoami() -> String:
	return whoami_value
