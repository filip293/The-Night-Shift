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
	
	# Enable BBCode and meta interactions
	TextBox.bbcode_enabled = true
	TextBox.meta_underlined = false
	
	# Prevent links from turning browser blue — match your label's default color
	if TextBox.has_theme_color("default_color"):
		TextBox.add_theme_color_override("link_color", TextBox.get_theme_color("default_color"))
	
	# Connect RichTextLabel signals for mouse hover, link clicks, and box clicks
	if not TextBox.meta_hover_started.is_connected(_on_meta_hover_started):
		TextBox.meta_hover_started.connect(_on_meta_hover_started)
	if not TextBox.meta_clicked.is_connected(_on_meta_clicked):
		TextBox.meta_clicked.connect(_on_meta_clicked)
	if not TextBox.gui_input.is_connected(_on_text_box_gui_input):
		TextBox.gui_input.connect(_on_text_box_gui_input)

	# Ensure the mouse cursor is visible during intro choices
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# If nav_sound isn't assigned in Inspector, grab whatever was on AudioPlayer
	if not nav_sound and AudioPlayer and AudioPlayer.stream:
		nav_sound = AudioPlayer.stream

func _unhandled_input(event: InputEvent) -> void:
	if current_mode == Mode.INACTIVE:
		return

	# =========================================================================
	# MOUSE CLICK FALLBACK (Clicking anywhere on screen)
	# =========================================================================
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mode == Mode.CHOICES:
			_confirm_choice()
			get_viewport().set_input_as_handled()
			return
		elif current_mode == Mode.DIALOGUE:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
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
			_confirm_choice()
			get_viewport().set_input_as_handled()

	# =========================================================================
	# 2. DIALOGUE MODE (Advancing speech with Enter / Space)
	# =========================================================================
	elif current_mode == Mode.DIALOGUE:
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact"):
			_advance_dialogue()
			get_viewport().set_input_as_handled()

# --- MOUSE SIGNAL HANDLERS ---

func _on_meta_hover_started(meta: Variant) -> void:
	if current_mode != Mode.CHOICES:
		return
	var idx = int(meta)
	# Only update if the user hovered over a different option
	if idx != current_selection and idx >= 0 and idx < options.size():
		current_selection = idx
		_play_sound(nav_sound)
		_update_choice_display()

func _on_meta_clicked(meta: Variant) -> void:
	if current_mode != Mode.CHOICES:
		return
	var idx = int(meta)
	if idx >= 0 and idx < options.size():
		current_selection = idx
		_confirm_choice()

func _on_text_box_gui_input(event: InputEvent) -> void:
	if current_mode == Mode.INACTIVE:
		return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mode == Mode.CHOICES:
			_confirm_choice()
			TextBox.accept_event()
		elif current_mode == Mode.DIALOGUE:
			_advance_dialogue()
			TextBox.accept_event()

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
	_play_sound(select_sound)
	dialogue_advanced.emit()

## Displays interactive player choices
func show_choices(title: String, new_options: Array) -> void:
	prompt_title = title
	options = new_options
	current_selection = 0
	current_mode = Mode.CHOICES
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
		var prefix = "> " if i == current_selection else "  "
		# Wrap option in URL tag with slight padding for a comfortable click hit-box
		output += "[url=" + str(i) + "]" + prefix + str(options[i]) + "[/url]\n"
	TextBox.text = output

func _play_sound(stream_to_play: AudioStream) -> void:
	if AudioPlayer and stream_to_play:
		AudioPlayer.stop()
		AudioPlayer.stream = stream_to_play
		AudioPlayer.play()
