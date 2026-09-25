extends Control

signal babushka_dialogue_finished
signal policewoman_dialogue_finished

@export_group("UI Elements")
@export var dialogue_label: Label
@export var speaker_label: Label
@export var text_speed: float = 0.04

@export_group("Audio")
@export var typing_audio_player: AudioStreamPlayer
@export var typing_sound: AudioStream
@export var pitch_min: float = 0.95
@export var pitch_max: float = 1.05

@export_group("NPC Settings")
## Flip by 180 degrees so the NPC faces the player instead of facing away
@export var flip_npc_180: bool = true

@export_group("Camera Settings")
## Set your desired dialogue FOV here
@export var target_dialogue_fov: float = 50.0

var dialogue_queue: Array[Dictionary] = []
var current_line_index: int = 0
var typewriter_tween: Tween
var npc_turn_tween: Tween
var cam_zoom_tween: Tween

var is_dialogue_active: bool = false
var can_advance_dialogue: bool = false
var dialogue_start_time: float = 0.0
var last_sound_char_index: int = 0

# Cached NPC state for Path3D restoration
var active_npc: Node3D = null
var saved_npc_rot_y: float = 0.0
var has_saved_npc_rotation: bool = false

# Cached Player / Neck / Camera state
var active_camera: Camera3D = null
var active_neck: Node3D = null
var active_player: Node3D = null
var original_camera_fov: float = 75.0
var saved_player_rot_y: float = 0.0
var saved_neck_rot_x: float = 0.0
var is_camera_zoomed: bool = false

func _ready() -> void:
	hide()
	
	if not typing_audio_player:
		typing_audio_player = AudioStreamPlayer.new()
		typing_audio_player.name = "DialogueTypingAudio"
		add_child(typing_audio_player)
		
	if typing_sound and typing_audio_player:
		typing_audio_player.stream = typing_sound

func start_dialogue(lines: Array[Dictionary], speaker: Node = null) -> void:
	if is_dialogue_active:
		return

	is_dialogue_active = true
	dialogue_start_time = Time.get_ticks_msec() / 1000.0
	
	# Freeze player movement and mouse look
	Globals.playermoveallow = false
	Globals.playerlookallow = false
	Globals.set("is_in_dialogue", true)

	dialogue_queue = lines
	current_line_index = 0
	show()

	# Resolve NPC character root, save rotation for Path3D, and face player
	var npc_root = _resolve_npc_root(speaker) if speaker is Node3D else null
	if npc_root:
		active_npc = npc_root
		saved_npc_rot_y = npc_root.global_rotation.y
		has_saved_npc_rotation = true
		_turn_npc_to_player(npc_root)
		_zoom_camera_to_npc(npc_root)
	else:
		active_npc = null
		has_saved_npc_rotation = false

	_show_next_line()

	# Debounce so the interact key doesn't accidentally skip line 1
	can_advance_dialogue = false
	get_tree().create_timer(0.35).timeout.connect(func(): can_advance_dialogue = true)

func _input(event: InputEvent) -> void:
	if not is_dialogue_active or not visible:
		return

	# Ignore key-repeats from holding down a key
	if event.is_echo():
		return

	# ESC cancels incomplete dialogue without exiting game
	var is_cancel = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE)
	if is_cancel:
		get_viewport().set_input_as_handled()
		Input.action_release("ui_cancel")
		_cancel_dialogue()
		return

	if not can_advance_dialogue:
		return

	var is_advance = event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact")
	if not is_advance:
		return

	get_viewport().set_input_as_handled()

	# Fast-forward text if still typing
	if typewriter_tween and typewriter_tween.is_running():
		typewriter_tween.kill()
		dialogue_label.visible_characters = -1
		if typing_audio_player and typing_audio_player.is_playing():
			typing_audio_player.stop()
		return

	current_line_index += 1
	if current_line_index < dialogue_queue.size():
		_show_next_line()
	else:
		_end_dialogue(true)

func _show_next_line() -> void:
	var line_data = dialogue_queue[current_line_index]
	speaker_label.text = line_data.get("speaker", "")
	dialogue_label.text = line_data.get("text", "")
	dialogue_label.visible_characters = 0
	last_sound_char_index = 0

	var duration = dialogue_label.text.length() * text_speed

	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()

	typewriter_tween = create_tween()
	typewriter_tween.tween_method(_on_typewriter_step, 0, dialogue_label.text.length(), duration)

func _on_typewriter_step(val: float) -> void:
	var char_count = int(val)
	if char_count == dialogue_label.visible_characters:
		return

	dialogue_label.visible_characters = char_count

	if char_count > 0 and char_count <= dialogue_label.text.length():
		if char_count != last_sound_char_index:
			last_sound_char_index = char_count
			var c = dialogue_label.text[char_count - 1]
			if c != " " and c != "\n" and c != "\t":
				_play_typing_sound()

func _play_typing_sound() -> void:
	if typing_audio_player and typing_audio_player.stream:
		typing_audio_player.pitch_scale = randf_range(pitch_min, pitch_max)
		typing_audio_player.play()

func _cancel_dialogue() -> void:
	# Guard: Don't allow cancellation within 0.3s of opening
	if (Time.get_ticks_msec() / 1000.0) - dialogue_start_time < 0.3:
		return
		
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	if typing_audio_player and typing_audio_player.is_playing():
		typing_audio_player.stop()
	_end_dialogue(false)

func _end_dialogue(completed: bool = true) -> void:
	hide()
	is_dialogue_active = false
	current_line_index = 0
	_reset_dialogue_state(completed)

# --- NPC RESOLUTION, TURNING & RESTORATION ---

func _resolve_npc_root(node: Node3D) -> Node3D:
	if not is_instance_valid(node):
		return null

	var cur_name = node.name.to_lower()
	if "police" in cur_name or "babushka" in cur_name or "woman" in cur_name:
		return node

	var parent = node.get_parent()
	if parent is Node3D and parent != get_tree().current_scene:
		var p_name = parent.name.to_lower()
		if "police" in p_name or "babushka" in p_name or "woman" in p_name or "officer" in p_name:
			return parent

	var current: Node3D = node
	while current.get_parent() is Node3D:
		var p = current.get_parent() as Node3D
		if p == get_tree().current_scene:
			break
		var p_name = p.name.to_lower()
		if p_name in ["map", "world", "level", "environment", "npcs", "rootnode", "sketchfab_model", "path3d", "path3d2"]:
			break
		current = p
		if current.has_node("AnimationPlayer") or current.find_child("*Skeleton*", false, false):
			break

	return current

func _turn_npc_to_player(npc: Node3D) -> void:
	if not is_instance_valid(npc):
		return

	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var look_target = Vector3(cam.global_position.x, npc.global_position.y, cam.global_position.z)
	if npc.global_position.distance_squared_to(look_target) < 0.01:
		return

	var start_rot_y = npc.global_rotation.y

	var original_transform = npc.global_transform
	npc.look_at(look_target, Vector3.UP)
	var target_rot_y = npc.global_rotation.y
	
	if flip_npc_180:
		target_rot_y += PI
		
	npc.global_transform = original_transform

	if npc_turn_tween and npc_turn_tween.is_valid():
		npc_turn_tween.kill()

	npc_turn_tween = create_tween()
	npc_turn_tween.tween_method(func(weight: float):
		if is_instance_valid(npc):
			npc.global_rotation.y = lerp_angle(start_rot_y, target_rot_y, weight)
	, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- CAMERA & PLAYER LOOK SYSTEM ---

func _resolve_player_hierarchy(cam: Camera3D) -> void:
	active_camera = cam
	active_neck = null
	active_player = null
	
	if not cam:
		return

	var p = cam.get_parent()
	if p is Node3D:
		active_neck = p
		var gp = p.get_parent()
		if gp is Node3D:
			active_player = gp

func _zoom_camera_to_npc(npc: Node3D) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	_resolve_player_hierarchy(cam)
	
	# Camera stays strictly level with Neck (no roll)
	cam.rotation = Vector3.ZERO

	original_camera_fov = cam.fov
	is_camera_zoomed = true

	var head_pos = _get_npc_head_pos(npc)

	if cam_zoom_tween and cam_zoom_tween.is_valid():
		cam_zoom_tween.kill()

	cam_zoom_tween = create_tween().set_parallel(true)
	
	# ONLY FOV IS TWEENED — NO POSITION SLIDING
	cam_zoom_tween.tween_property(cam, "fov", target_dialogue_fov, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Turn Player Yaw and Neck Pitch to face NPC
	if is_instance_valid(active_player) and is_instance_valid(active_neck):
		saved_player_rot_y = active_player.global_rotation.y
		saved_neck_rot_x = active_neck.rotation.x

		var diff = head_pos - active_player.global_position
		var target_player_yaw = atan2(-diff.x, -diff.z)
		var start_player_yaw = saved_player_rot_y

		var ground_dist = Vector2(head_pos.x - cam.global_position.x, head_pos.z - cam.global_position.z).length()
		var height_diff = head_pos.y - cam.global_position.y
		var target_neck_pitch = clamp(atan2(height_diff, ground_dist), deg_to_rad(-75.0), deg_to_rad(75.0))
		var start_neck_pitch = saved_neck_rot_x

		cam_zoom_tween.tween_method(func(weight: float):
			if is_instance_valid(active_player):
				active_player.global_rotation.y = lerp_angle(start_player_yaw, target_player_yaw, weight)
			if is_instance_valid(active_neck):
				active_neck.rotation.x = lerp_angle(start_neck_pitch, target_neck_pitch, weight)
				active_neck.rotation.y = 0.0
				active_neck.rotation.z = 0.0
			if is_instance_valid(active_camera):
				active_camera.rotation = Vector3.ZERO
		, 0.0, 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _reset_dialogue_state(completed: bool) -> void:
	var reset_duration: float = 0.4

	# 1. Return NPC back to pre-interaction Path3D rotation
	if has_saved_npc_rotation and is_instance_valid(active_npc):
		var current_rot = active_npc.global_rotation.y
		var target_rot = saved_npc_rot_y
		var npc_ref = active_npc

		if npc_turn_tween and npc_turn_tween.is_valid():
			npc_turn_tween.kill()

		npc_turn_tween = create_tween()
		npc_turn_tween.tween_method(func(weight: float):
			if is_instance_valid(npc_ref):
				npc_ref.global_rotation.y = lerp_angle(current_rot, target_rot, weight)
		, 0.0, 1.0, reset_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# 2. Return FOV and Player/Neck rotation (NO position change)
	if is_camera_zoomed and is_instance_valid(active_camera):
		var cam = active_camera

		if cam_zoom_tween and cam_zoom_tween.is_valid():
			cam_zoom_tween.kill()

		cam_zoom_tween = create_tween().set_parallel(true)
		cam_zoom_tween.tween_property(cam, "fov", original_camera_fov, reset_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		if is_instance_valid(active_player) and is_instance_valid(active_neck):
			var cur_p_yaw = active_player.global_rotation.y
			var cur_n_pitch = active_neck.rotation.x
			var target_p_yaw = saved_player_rot_y
			var target_n_pitch = saved_neck_rot_x

			cam_zoom_tween.tween_method(func(weight: float):
				if is_instance_valid(active_player):
					active_player.global_rotation.y = lerp_angle(cur_p_yaw, target_p_yaw, weight)
				if is_instance_valid(active_neck):
					active_neck.rotation.x = lerp_angle(cur_n_pitch, target_n_pitch, weight)
					active_neck.rotation.y = 0.0
					active_neck.rotation.z = 0.0
				if is_instance_valid(active_camera):
					active_camera.rotation = Vector3.ZERO
			, 0.0, 1.0, reset_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		cam_zoom_tween.chain().tween_callback(func():
			if is_instance_valid(active_camera):
				active_camera.rotation = Vector3.ZERO
				active_camera.fov = original_camera_fov
			_on_dialogue_fully_closed(completed)
		)
	else:
		_on_dialogue_fully_closed(completed)

func _on_dialogue_fully_closed(completed: bool) -> void:
	is_camera_zoomed = false
	has_saved_npc_rotation = false
	active_npc = null
	active_neck = null
	active_player = null

	# Unfreeze player movement and mouse look
	Globals.playermoveallow = true
	Globals.playerlookallow = true
	Globals.set("is_in_dialogue", false)

	if completed:
		if Globals.get("can_talk_babushka"):
			babushka_dialogue_finished.emit()
		elif Globals.get("can_talk_policewoman"):
			policewoman_dialogue_finished.emit()

func _get_npc_head_pos(npc: Node3D) -> Vector3:
	if not is_instance_valid(npc):
		return Vector3.ZERO

	var head_node = npc.find_child("*[Hh]ead*", true, false)
	if head_node and head_node is Node3D:
		return head_node.global_position

	var skeleton = npc.find_child("*[Ss]keleton*", true, false) as Skeleton3D
	if skeleton:
		for bone_name in ["Head", "head", "HEAD", "Neck"]:
			var bone_idx = skeleton.find_bone(bone_name)
			if bone_idx != -1:
				return skeleton.to_global(skeleton.get_bone_global_pose(bone_idx).origin)

	var col_shape = npc.find_child("*CollisionShape3D*", true, false) as CollisionShape3D
	if col_shape and col_shape.shape:
		if col_shape.shape is CapsuleShape3D:
			return col_shape.global_position + Vector3(0, col_shape.shape.height * 0.35, 0)
		elif col_shape.shape is BoxShape3D:
			return col_shape.global_position + Vector3(0, col_shape.shape.size.y * 0.35, 0)

	return npc.global_position + Vector3(0, 1.6, 0)

# --- DIALOGUE TRIGGERS ---

func _start_babushka_dialogue(npc_node: Node3D = null) -> void:
	if is_dialogue_active:
		return
	var dialogue: Array[Dictionary] = [
		{"speaker": "Old Woman", "text": "Oh, the rain is finally letting up a little.\nI thought I would take my walk while I still can."},
		{"speaker": "You", "text": "You come through here a lot this late, ma'am?"},
		{"speaker": "Old Woman", "text": "Most nights, dear. It gives me something to do.\nMy grandchildren don't come to visit as often as they used to,\nso I keep myself busy this way."}
	]
	start_dialogue(dialogue, npc_node)

func _start_policewoman_dialogue(npc_node: Node3D = null) -> void:
	if is_dialogue_active:
		return
	var dialogue: Array[Dictionary] = [
		{"speaker": "Officer", "text": "It's picked back up out there. Can barely\nsee past the pumps now."},
		{"speaker": "You", "text": "Yeah, my wipers could barely keep up on the drive in."},
		{"speaker": "Officer", "text": "Careful driving home later. Roads get slick\nthis time of night."}
	]
	start_dialogue(dialogue, npc_node)
