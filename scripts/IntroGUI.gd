extends Node2D

signal choice_made(index: int, text: String)
signal dialogue_advanced

@export_group("Sounds")
@export var nav_sound: AudioStream = preload("res://Sounds/blip.mp3")
@export var select_sound: AudioStream = null

@onready var TextBox: RichTextLabel = $CanvasLayer/InteractiveText
@onready var AudioPlayer: AudioStreamPlayer = $AudioStreamPlayer

enum Mode { INACTIVE, CHOICES, DIALOGUE }
var current_mode: Mode = Mode.INACTIVE

var current_selection: int = 0
var prompt_title: String = ""
var options: Array = []

func _ready() -> void:
	TextBox.text = ""
	TextBox.bbcode_enabled = true
	TextBox.meta_underlined = false
	
	if TextBox.has_theme_color("default_color"):
		TextBox.add_theme_color_override("link_color", TextBox.get_theme_color("default_color"))
	
	# Disconnect first to ensure clean single connections
	if TextBox.meta_hover_started.is_connected(_on_meta_hover_started):
		TextBox.meta_hover_started.disconnect(_on_meta_hover_started)
	if TextBox.meta_clicked.is_connected(_on_meta_clicked):
		TextBox.meta_clicked.disconnect(_on_meta_clicked)

	TextBox.meta_hover_started.connect(_on_meta_hover_started)
	TextBox.meta_clicked.connect(_on_meta_clicked)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if not nav_sound and AudioPlayer and AudioPlayer.stream:
		nav_sound = AudioPlayer.stream

func _input(event: InputEvent) -> void:
	if current_mode == Mode.INACTIVE:
		return

	if not event.is_pressed() or event.is_echo():
		return

	# =========================================================================
	# 1. DIALOGUE MODE (Tap/Click anywhere or press Enter/Space)
	# =========================================================================
	if current_mode == Mode.DIALOGUE:
		var is_press: bool = (event is InputEventScreenTouch) \
			or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventKey and ((event as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact")))

		if is_press:
			get_viewport().set_input_as_handled()
			_advance_dialogue()
			return

	# =========================================================================
	# 2. CHOICES MODE (Keyboard / Gamepad Navigation)
	# =========================================================================
	if current_mode == Mode.CHOICES and event is InputEventKey:
		var key = event as InputEventKey
		if key.keycode in [KEY_UP, KEY_W] or event.is_action_pressed("ui_up"):
			current_selection = (current_selection - 1 + options.size()) % options.size()
			_play_sound(nav_sound)
			_update_choice_display()
			get_viewport().set_input_as_handled()

		elif key.keycode in [KEY_DOWN, KEY_S] or event.is_action_pressed("ui_down"):
			current_selection = (current_selection + 1) % options.size()
			_play_sound(nav_sound)
			_update_choice_display()
			get_viewport().set_input_as_handled()

		elif key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact"):
			get_viewport().set_input_as_handled()
			_confirm_choice()

# --- BBCODE LINK CLICK HANDLERS ---

func _on_meta_hover_started(meta: Variant) -> void:
	if current_mode != Mode.CHOICES:
		return
	var idx = str(meta).to_int()
	if idx != current_selection and idx >= 0 and idx < options.size():
		current_selection = idx
		_play_sound(nav_sound)
		_update_choice_display()

func _on_meta_clicked(meta: Variant) -> void:
	if current_mode != Mode.CHOICES:
		return
	var idx = str(meta).to_int()
	if idx >= 0 and idx < options.size():
		current_selection = idx
		_confirm_choice()

# --- SELECTION & ADVANCEMENT LOGIC ---

func _confirm_choice() -> void:
	if current_mode != Mode.CHOICES:
		return
	current_mode = Mode.INACTIVE
	_play_sound(select_sound)
	var chosen_index = current_selection
	var chosen_text = str(options[chosen_index])
	hide_text()
	choice_made.emit(chosen_index, chosen_text)

func _advance_dialogue() -> void:
	if current_mode != Mode.DIALOGUE:
		return
	current_mode = Mode.INACTIVE
	_play_sound(select_sound)
	dialogue_advanced.emit()

## Displays interactive player choices
func show_choices(title: String, new_options: Array) -> void:
	prompt_title = title
	options = new_options
	current_selection = 0
	current_mode = Mode.CHOICES
	TextBox.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_choice_display()

## Displays a line spoken by the boss
func show_dialogue(speaker: String, text: String) -> void:
	current_mode = Mode.DIALOGUE
	TextBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TextBox.text = "[b]" + speaker + ":[/b]\n\"" + text + "\""

func hide_text() -> void:
	current_mode = Mode.INACTIVE
	TextBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	TextBox.text = ""

func _update_choice_display() -> void:
	var output: String = "[b]" + prompt_title + "[/b]\n\n"
	for i in range(options.size()):
		var prefix = "> " if i == current_selection else "  "
		# Clean standard ASCII spacing inside url tag
		output += "[url=" + str(i) + "]" + prefix + str(options[i]) + "[/url]\n\n"
	TextBox.text = output

func _play_sound(stream_to_play: AudioStream) -> void:
	if AudioPlayer and stream_to_play:
		AudioPlayer.stop()
		AudioPlayer.stream = stream_to_play
		AudioPlayer.play()
