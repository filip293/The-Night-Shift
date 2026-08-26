extends Node2D

signal choice_made(index: int, text: String)
signal dialogue_advanced

@export_group("Sounds")
@export var nav_sound: AudioStream = preload("res://Sounds/blip.mp3")
@export var select_sound: AudioStream = null # OBNOXIOUS, I REMOVED IT

@onready var TextBox: RichTextLabel = $CanvasLayer/InteractiveText
@onready var AudioPlayer: AudioStreamPlayer = $AudioStreamPlayer

enum Mode { INACTIVE, CHOICES, DIALOGUE }
var current_mode: Mode = Mode.INACTIVE

var current_selection: int = 0
var prompt_title: String = ""
var options: Array = []

func _ready() -> void:
	TextBox.text = ""
	
	# If nav_sound isn't assigned in Inspector, grab whatever was on AudioPlayer
	if not nav_sound and AudioPlayer and AudioPlayer.stream:
		nav_sound = AudioPlayer.stream

func _unhandled_input(event: InputEvent) -> void:
	if current_mode == Mode.INACTIVE:
		return

	# Only process single key presses (ignore held down key repeats)
	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return

	var key = event as InputEventKey

	# =========================================================================
	# 1. CHOICES MODE (Navigating menu with Up/Down + Selecting with Enter)
	# =========================================================================
	if current_mode == Mode.CHOICES:
		# MOVE UP: Arrow Up, W, or ui_up action
		if key.keycode == KEY_UP or key.keycode == KEY_W or event.is_action_pressed("ui_up"):
			current_selection = (current_selection - 1 + options.size()) % options.size()
			_play_sound(nav_sound)
			_update_choice_display()
			get_viewport().set_input_as_handled()

		# MOVE DOWN: Arrow Down, S, or ui_down action
		elif key.keycode == KEY_DOWN or key.keycode == KEY_S or event.is_action_pressed("ui_down"):
			current_selection = (current_selection + 1) % options.size()
			_play_sound(nav_sound)
			_update_choice_display()
			get_viewport().set_input_as_handled()

		# SELECT: Enter, Space, Numpad Enter, or ui_accept/Interact
		elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact"):
			current_mode = Mode.INACTIVE
			_play_sound(select_sound)
			var chosen_index = current_selection
			var chosen_text = str(options[chosen_index])
			hide_text()
			choice_made.emit(chosen_index, chosen_text)
			get_viewport().set_input_as_handled()

	# =========================================================================
	# 2. DIALOGUE MODE (Advancing speech with Enter)
	# =========================================================================
	elif current_mode == Mode.DIALOGUE:
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact"):
			_play_sound(select_sound)
			dialogue_advanced.emit()
			get_viewport().set_input_as_handled()

## Displays interactive player choices
func show_choices(title: String, new_options: Array) -> void:
	prompt_title = title
	options = new_options
	current_selection = 0
	current_mode = Mode.CHOICES
	_update_choice_display()

## Displays a line spoken by the boss
func show_dialogue(speaker: String, text: String) -> void:
	current_mode = Mode.DIALOGUE
	TextBox.text = "[b]" + speaker + ":[/b]\n\"" + text + "\""

func hide_text() -> void:
	current_mode = Mode.INACTIVE
	TextBox.text = ""

func _update_choice_display() -> void:
	var output: String = "[b]" + prompt_title + "[/b]\n\n"
	for i in range(options.size()):
		if i == current_selection:
			output += "> " + str(options[i]) + "\n"
		else:
			output += "  " + str(options[i]) + "\n"
	TextBox.text = output

func _play_sound(stream_to_play: AudioStream) -> void:
	if AudioPlayer and stream_to_play:
		AudioPlayer.stop()
		AudioPlayer.stream = stream_to_play
		AudioPlayer.play()
