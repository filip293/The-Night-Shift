extends Node2D

signal part_advanced

@export_group("Monologue Parts")
@export var monologue_parts: Array[String] = [
	"SUNDAY NIGHT. 1:32 AM.",
	"This is my only night off this entire week.",
	"Long enough for me to catch my breath but I have to admit,\nworking at the Six-Twelve is hell on Earth.",
	"Dealing with people isn't as easy as I wanted it to be.\nEspecially with an asshole for a boss.",
	"I'm underpaid, overworked and I still stick around.\nI'll quit sooner or later.",
	"I'll take my chance to rest while I still can."
]

@export var char_speed: float = 0.08

@export_group("Audio")
@export var type_sound: AudioStream # Drag your typing click / blip sound here!
@export var TextBox: RichTextLabel
@export var AudioPlayer: AudioStreamPlayer

var is_active: bool = false
var is_typing: bool = false
var can_advance: bool = true

func _ready() -> void:
	if TextBox:
		TextBox.text = ""
	visible = false

## Call this from intro.gd: await Prologue.play()
func play() -> void:
	visible = true
	is_active = true
	_start_advance_debounce(0.3)

	# Play through each thought one by one
	for part in monologue_parts:
		await _type_part(part)
		await part_advanced

	# Finished all parts
	is_active = false
	visible = false
	if TextBox:
		TextBox.text = ""

func _start_advance_debounce(duration: float = 0.3) -> void:
	can_advance = false
	get_tree().create_timer(duration).timeout.connect(func():
		can_advance = true
	)

func _type_part(full_text: String) -> void:
	is_typing = true
	TextBox.text = ""
	
	# Type out the main sentence character by character
	for i in range(full_text.length()):
		if not is_typing:
			break # Player pressed or tapped to skip typing
			
		var c: String = full_text[i]
		TextBox.text += c
		
		# Play typing sound (skip spaces and newlines)
		if c != " " and c != "\n":
			_play_type_sound()
			
		# Natural punctuation pauses
		if c in [".", "!", "?"]:
			await get_tree().create_timer(char_speed * 6.0).timeout
		elif c in [",", ":", ";"]:
			await get_tree().create_timer(char_speed * 3.0).timeout
		else:
			await get_tree().create_timer(char_speed).timeout

	# 100% done typing -> Show full text and reveal prompt at bottom!
	is_typing = false
	TextBox.text = full_text + "\n\n[color=gray]PRESS TO CONTINUE[/color]"

func _input(event: InputEvent) -> void:
	if not is_active or not can_advance:
		return

	var is_confirm: bool = false

	# Screen touch support
	if event is InputEventScreenTouch and event.is_pressed():
		is_confirm = true
	# Mouse click support
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_confirm = true
	# Keyboard / Action button support
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key = event as InputEventKey
		if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE or event.is_action_pressed("ui_accept") or event.is_action_pressed("Interact"):
			is_confirm = true

	if is_confirm:
		_start_advance_debounce(0.3)
		if is_typing:
			is_typing = false
		else:
			part_advanced.emit()
			
		get_viewport().set_input_as_handled()

func _play_type_sound() -> void:
	if AudioPlayer and type_sound:
		AudioPlayer.stream = type_sound
		AudioPlayer.pitch_scale = randf_range(1.0, 1.05)
		AudioPlayer.play()

func _play_sound(stream_to_play: AudioStream) -> void:
	if AudioPlayer and stream_to_play:
		AudioPlayer.pitch_scale = 1.0
		AudioPlayer.stop()
		AudioPlayer.stream = stream_to_play
		AudioPlayer.play()
