extends Control

signal dialogue_finished

@export_group("UI Elements")
@export var dialogue_label: Label
@export var speaker_label: Label

@export_group("Text & Audio Settings")
@export var text_speed: float = 0.04
@export var typewriter_sound: AudioStream
@export var audio_player: AudioStreamPlayer
@export var pitch_min: float = 0.85
@export var pitch_max: float = 1.15

# Distance check configuration
@export var max_dialogue_distance: float = 3.5

var typewriter_tween: Tween
var dialogue_queue: Array[Dictionary] = []
var current_line_index: int = 0
var last_char_count: int = 0

var active_speaker_node: Node3D = null
var player_node: Node3D = null

func _ready() -> void:
	visible = false
	set_process_input(false)
	set_process(false)

func _process(_delta: float) -> void:
	if not Globals.is_in_dialogue:
		return

	# Cache player reference
	if not is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("Player") if get_tree().has_group("Player") else $"../../../Player"

	# Locate speaker node matching current label
	if speaker_label and speaker_label.text != "":
		if not is_instance_valid(active_speaker_node) or active_speaker_node.name != speaker_label.text:
			active_speaker_node = get_tree().root.find_child(speaker_label.text, true, false) as Node3D

	# Distance check for walking away
	if is_instance_valid(player_node) and is_instance_valid(active_speaker_node):
		var dist = player_node.global_position.distance_to(active_speaker_node.global_position)
		if dist > max_dialogue_distance:
			# Interrupted dialogue: walk away without finishing
			_end_dialogue(false)

func start_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_queue = lines
	current_line_index = 0
	Globals.is_in_dialogue = true
	visible = true
	set_process_input(true)
	set_process(true)
	_show_next_line()

func _input(event: InputEvent) -> void:
	if not Globals.is_in_dialogue:
		return

	var is_next_pressed: bool = false
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		match event.keycode:
			KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				is_next_pressed = true

	if event.is_action_pressed("Interact") and not event.is_echo():
		is_next_pressed = true

	if is_next_pressed:
		get_viewport().set_input_as_handled()

		# If text is still typing, skip to full text immediately
		if typewriter_tween and typewriter_tween.is_running():
			typewriter_tween.kill()
			if dialogue_label:
				dialogue_label.visible_characters = -1
		else:
			# Advance line or finish dialogue completely
			current_line_index += 1
			if current_line_index < dialogue_queue.size():
				_show_next_line()
			else:
				_end_dialogue(true) # Completed whole dialogue

func _show_next_line() -> void:
	if dialogue_queue.is_empty() or current_line_index >= dialogue_queue.size():
		return

	var line_data = dialogue_queue[current_line_index]
	
	if speaker_label:
		speaker_label.text = line_data.get("speaker", "")
		
	var full_text = line_data.get("text", "")
	
	if dialogue_label:
		dialogue_label.text = full_text
		dialogue_label.visible_characters = 0
		last_char_count = 0
		
		var total_chars = full_text.length()
		var duration = total_chars * text_speed
		
		if typewriter_tween and typewriter_tween.is_valid():
			typewriter_tween.kill()
			
		typewriter_tween = create_tween()
		typewriter_tween.tween_method(_update_visible_characters, 0, total_chars, duration)\
			.set_trans(Tween.TRANS_LINEAR)
			
func _update_visible_characters(char_count: int) -> void:
	if not dialogue_label:
		return
		
	dialogue_label.visible_characters = char_count
	
	if char_count > last_char_count:
		var text_len = dialogue_label.text.length()
		if char_count <= text_len:
			var current_char = dialogue_label.text[char_count - 1]
			if current_char.strip_edges() != "":
				_play_typewriter_sound()
				
		last_char_count = char_count

func _play_typewriter_sound() -> void:
	if audio_player and typewriter_sound:
		audio_player.pitch_scale = randf_range(pitch_min, pitch_max)
		audio_player.stream = typewriter_sound
		audio_player.play()

func _end_dialogue(completed_fully: bool = false) -> void:
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()

	# If player completed full dialogue, mark as talked and resume movement
	if completed_fully and is_instance_valid(active_speaker_node):
		var speaker_name = active_speaker_node.name
		
		if speaker_name == "PoliceWoman" or speaker_name == "Police Officer":
			Globals.set("can_talk_policewoman", false)
			Globals.set("policewoman_done", true)
			
			# Trigger walk / animation method on PoliceWoman if available
			if active_speaker_node.has_method("start_walking"):
				active_speaker_node.start_walking()
			elif active_speaker_node.has_method("resume_path"):
				active_speaker_node.resume_path()
			elif active_speaker_node.has_node("AnimationPlayer"):
				active_speaker_node.get_node("AnimationPlayer").play("Walk")

		elif speaker_name == "Babushka" or speaker_name == "OldWoman":
			Globals.set("can_talk_babushka", false)
			Globals.set("babushka_done", true)

	visible = false
	Globals.is_in_dialogue = false
	set_process_input(false)
	set_process(false)
	active_speaker_node = null
	dialogue_finished.emit()
