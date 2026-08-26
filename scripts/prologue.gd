extends Node2D

signal part_advanced

@export_group("Monologue Parts")
@export var monologue_parts: Array[String] = [
	"Sunday night. 1:34 AM.",
	"My only night off this entire week.",
	"I had it all planned out: staring at the ceiling, drinking flat soda, and doing absolutely nothing.",
	"I hate the Six-Twelve. I hate the smell of expired roller-dogs... and most of all, I hate my boss.",
	"And right on cue..."
]

@export var char_speed: float = 0.035

@export_group("Audio")
@export var type_sound: AudioStream # Drag your typing click / blip sound here!
@export var select_sound: AudioStream = preload("res://Sounds/selection-made.mp3") if ResourceLoader.exists("res://Sounds/selection-made.mp3") else null

@export var TextBox: RichTextLabel
@export var AudioPlayer: AudioStreamPlayer

var is_active: bool = false
var is_typing: bool = false

func _ready() -> void:
	if TextBox:
		TextBox.text = ""
	visible = false

## Call this from intro.gd: await Prologue.play()
func play() -> void:
	visible = true
	is_active = true

	# Play through each thought one by one
	for part in monologue_parts:
		await _type_part(part)
		await part_advanced

	# Finished all parts
	is_active = false
	visible = false
	if TextBox:
		TextBox.text = ""

func _type_part(full_text: String) -> void:
	is_typing = true
	TextBox.text = ""
	
	# Type out the main sentence character by character
	for i in range(full_text.length()):
		if not is_typing:
			break # Player pressed Enter to skip typing
			
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

	# 100% done typing -> Show full text and reveal the prompt at the bottom!
	is_typing = false
	TextBox.text = full_text + "\n\n[color=gray]PRESS [ENTER] TO CONTINUE[/color]"

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	if not (event is InputEventKey and event.is_pressed() and not event.is_echo()):
		return

	var key = event as InputEventKey
	var is_confirm: bool = (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or 
						   key.keycode == KEY_SPACE or event.is_action_pressed("ui_accept") or 
						   event.is_action_pressed("Interact"))

	if is_confirm:
		if is_typing:
			# 1. Skip typing immediately and reveal the prompt
			is_typing = false
		else:
			# 2. Advance to the next part
			_play_sound(select_sound)
			part_advanced.emit()
			
		get_viewport().set_input_as_handled()

func _play_type_sound() -> void:
	if AudioPlayer and type_sound:
		AudioPlayer.stream = type_sound
		# Subtle pitch variation makes typing sound organic
		AudioPlayer.pitch_scale = randf_range(0.95, 1.05)
		AudioPlayer.play()

func _play_sound(stream_to_play: AudioStream) -> void:
	if AudioPlayer and stream_to_play:
		AudioPlayer.pitch_scale = 1.0
		AudioPlayer.stop()
		AudioPlayer.stream = stream_to_play
		AudioPlayer.play()
