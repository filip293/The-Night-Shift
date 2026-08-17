extends StaticBody3D

@export var whoami_value: String = "Object"


enum ObjectType { GENERIC, DOOR, PUDDLE }
@export var object_type: ObjectType = ObjectType.GENERIC:
	set(value):
		object_type = value
		notify_property_list_changed()

enum PuddleType { DIRT_SWEEP, LIQUID_MOP }
@export var puddle_type: PuddleType = PuddleType.DIRT_SWEEP

# --- Door Settings ---
@export_group("Door Settings")
@export var open_rotation_y: float = 90.0
@export var closed_rotation_y: float = 0.0
@export var audio_player: AudioStreamPlayer3D
@export var open_sound: AudioStream
@export var close_sound: AudioStream
@export var close_sound_delay: float = 1.0

# --- Puddle Settings ---
@export_group("Puddle Settings")
@export var puddle_mesh: MeshInstance3D
@export var mop_animation_player: AnimationPlayer
@export var audio_player_mop: AudioStreamPlayer3D
@export var mopping_sound: AudioStream
@export var mop_duration: float = 1.5

var is_open: bool = false
var door_tween: Tween
var is_being_mopped: bool = false
var current_mop_progress: float = 0.0

# State tracking for task highlight
var is_task_target: bool = false

# Static yellow glow material generated once
static var task_glow_mat: ShaderMaterial

func _ready() -> void:
	_init_shaders()
	add_to_group("interactables")
	
	if object_type == ObjectType.PUDDLE:
		if puddle_type == PuddleType.DIRT_SWEEP:
			add_to_group("dirt")
		else:
			add_to_group("puddles")

func _init_shaders() -> void:
	if task_glow_mat == null:
		var glow_shader = Shader.new()
		glow_shader.code = """
		shader_type spatial;
		render_mode unshaded, depth_test_disabled;

		uniform vec4 color : source_color = vec4(1.0, 0.85, 0.2, 0.4);
		uniform float pulse_speed : hint_range(0.5, 10.0) = 3.0;

		void fragment() {
			float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
			ALBEDO = color.rgb;
			ALPHA = color.a * (0.3 + pulse * 0.7);
		}
		"""
		task_glow_mat = ShaderMaterial.new()
		task_glow_mat.shader = glow_shader

# Detects if this item is currently carried by the player
func is_held_by_player() -> bool:
	var curr: Node = self
	while curr:
		if "Player" in curr.name or "Camera" in curr.name:
			return true
		curr = curr.get_parent()
	return false

func get_all_meshes() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if puddle_mesh:
		meshes.append(puddle_mesh)
	else:
		for child in find_children("*", "MeshInstance3D", true, false):
			if child is MeshInstance3D:
				meshes.append(child)
	return meshes

# Kept empty for safety in case called elsewhere
func set_hovered(_hovered: bool) -> void:
	pass

# Set task target yellow glow (Disabled for Held Items and Invisible Items)
func set_task_target(active: bool) -> void:
	if is_held_by_player() or not is_visible_in_tree():
		is_task_target = false
		_update_overlay()
		return
	is_task_target = active
	_update_overlay()

func _update_overlay() -> void:
	var meshes = get_all_meshes()
	var target_mat: Material = null

	# Only apply yellow glow if item is active task target and NOT held/hidden
	if not is_held_by_player() and is_visible_in_tree() and is_task_target:
		target_mat = task_glow_mat

	for mesh in meshes:
		mesh.material_overlay = target_mat

func _validate_property(property: Dictionary) -> void:
	var door_properties = ["open_rotation_y", "closed_rotation_y", "audio_player", "open_sound", "close_sound", "close_sound_delay"]
	if property.name in door_properties and object_type != ObjectType.DOOR:
		property.usage = PROPERTY_USAGE_NO_EDITOR

	var puddle_properties = ["puddle_type", "puddle_mesh", "mop_animation_player", "audio_player_mop", "mopping_sound", "mop_duration"]
	if property.name in puddle_properties and object_type != ObjectType.PUDDLE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func interact() -> void:
	match object_type:
		ObjectType.DOOR:
			_toggle_door()
		ObjectType.GENERIC:
			_on_interact_generic()

func _toggle_door(other: bool = false) -> void:
	if Engine.is_editor_hint() or (door_tween and door_tween.is_running()):
		return
	
	if Globals.jumpscare_impending and self.whoami_value == "DoorSpecific":
		$/root/Node3D/Monster.visible = true
		$/root/Node3D/Player.walk_speed = 1.0
	
	if other and !is_open:
		_toggle_door()
	
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
		door_tween.tween_property(self, "rotation_degrees:y", final_target_y, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		door_tween.parallel().tween_callback(
			func():
				if audio_player and close_sound:
					audio_player.stream = close_sound
					audio_player.play()
		).set_delay(close_sound_delay)
	
	if Globals.jumpscare_impending:
		$/root/Node3D/Monster/AnimationPlayer.play("run")
		$/root/Node3D/Monster/AnimationPlayer.stop()
		$/root/Node3D/Monster/Idle.play("Idle")
		await Globals.calltime(5.0)
		$/root/Node3D/Monster/AnimationPlayer.play("RESET")
		$/root/Node3D/Monster/AnimationPlayer.play("run")
		await $/root/Node3D/Monster/AnimationPlayer.animation_finished
		$/root/Node3D/Monster/AnimationPlayer.play("fall_back")
		await $/root/Node3D/Monster/AnimationPlayer.animation_finished
		$/root/Node3D/Credits.ShowCredits()
		
func start_mopping() -> void:
	if Engine.is_editor_hint() or is_being_mopped:
		return

	is_being_mopped = true

	if "playermoveallow" in Globals: Globals.playermoveallow = false
	if "playerlookallow" in Globals: Globals.playerlookallow = false

	if audio_player_mop and mopping_sound:
		if not audio_player_mop.finished.is_connected(_on_mop_audio_finished):
			audio_player_mop.finished.connect(_on_mop_audio_finished)
		
		audio_player_mop.stream = mopping_sound
		audio_player_mop.play()

	if mop_animation_player and mop_animation_player.has_animation("Bwoom"):
		var anim = mop_animation_player.get_animation("Bwoom")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		mop_animation_player.play("Bwoom") 

	if puddle_mesh and puddle_mesh.get_active_material(0) and not puddle_mesh.material_override:
		var mat = puddle_mesh.get_active_material(0).duplicate()
		puddle_mesh.material_override = mat

func _on_mop_audio_finished() -> void:
	if is_being_mopped and audio_player_mop:
		audio_player_mop.play()

func mop_tick(delta: float) -> void:
	if not is_being_mopped: return

	current_mop_progress += delta

	if puddle_mesh and puddle_mesh.material_override:
		var progress_pct = current_mop_progress / mop_duration
		puddle_mesh.material_override.albedo_color.a = clampf(1.0 - progress_pct, 0.0, 1.0)
		
	if current_mop_progress >= mop_duration:
		_finish_mopping()

func cancel_mopping() -> void:
	if not is_being_mopped: return

	is_being_mopped = false

	if "playermoveallow" in Globals: Globals.playermoveallow = true
	if "playerlookallow" in Globals: Globals.playerlookallow = true

	if audio_player_mop: audio_player_mop.stop()
	if mop_animation_player: mop_animation_player.stop()

func _finish_mopping() -> void:
	is_being_mopped = false

	if puddle_type == PuddleType.DIRT_SWEEP:
		remove_from_group("dirt")
	else:
		remove_from_group("puddles")

	var col_shape = get_node_or_null("CollisionShape3D")
	if col_shape:
		col_shape.set_deferred("disabled", true)

	if "playermoveallow" in Globals: Globals.playermoveallow = true
	if "playerlookallow" in Globals: Globals.playerlookallow = true

	if audio_player_mop: audio_player_mop.stop()
	if mop_animation_player: mop_animation_player.stop()

	queue_free()

func _on_interact_generic() -> void:
	if not Engine.is_editor_hint():
		if whoami_value == "Take crate":
			queue_free()
			$/root/Node3D/Player/Crate.visible = true
		elif whoami_value == "Take cans":
			if Globals.get("crate_delivered") and not Globals.get("has_cans"):
				$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans3.visible = true
				$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans2.visible = true
				$/root/Node3D/Player/Crate.visible = false
			elif Globals.get("has_cans"):
				$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans2.visible = false
		elif whoami_value == "Restock cans":
			$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans2.visible = false
			$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans.visible = true
			$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Cans4.visible = false

func whoami() -> String:
	return whoami_value
