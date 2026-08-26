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

var typewriter_tween: Tween
var dialogue_queue: Array[Dictionary] = []
var current_line_index: int = 0
var last_char_count: int = 0

func _ready() -> void:
	visible = false
	set_process_input(false)

func start_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_queue = lines
	current_line_index = 0
	Globals.is_in_dialogue = true
	visible = true
	set_process_input(true)
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
			# Otherwise, advance to next line
			current_line_index += 1
			if current_line_index < dialogue_queue.size():
				_show_next_line()
			else:
				_end_dialogue()

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
		
		# Use tween_method to smoothly update character count and play audio per new character
		typewriter_tween.tween_method(_update_visible_characters, 0, total_chars, duration)\
			.set_trans(Tween.TRANS_LINEAR)
			
func _update_visible_characters(char_count: int) -> void:
	if not dialogue_label:
		return
		
	dialogue_label.visible_characters = char_count
	
	# Only play audio when moving to a new character
	if char_count > last_char_count:
		var text_len = dialogue_label.text.length()
		if char_count <= text_len:
			var current_char = dialogue_label.text[char_count - 1]
			# Play sound only if it's not a space/whitespace
			if current_char.strip_edges() != "":
				_play_typewriter_sound()
				
		last_char_count = char_count

func _on_char_typed(_idx: int) -> void:
	if not dialogue_label:
		return
		
	var current_chars = dialogue_label.visible_characters
	
	# Only play audio if a new character was revealed (skips spaces)
	if current_chars > last_char_count:
		var current_char = dialogue_label.text[current_chars - 1] if current_chars <= dialogue_label.text.length() else ""
		
		if current_char.strip_edges() != "":
			_play_typewriter_sound()
			
	last_char_count = current_chars

func _play_typewriter_sound() -> void:
	if audio_player and typewriter_sound:
		# Randomize pitch scale to simulate hitting different keyboard keys
		audio_player.pitch_scale = randf_range(pitch_min, pitch_max)
		audio_player.stream = typewriter_sound
		audio_player.play()

func _end_dialogue() -> void:
	visible = false
	Globals.is_in_dialogue = false
	set_process_input(false)
	dialogue_finished.emit()
