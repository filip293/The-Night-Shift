extends Node2D

@onready var Subtitles: RichTextLabel = $Control/RichTextLabel
@onready var ASP: AudioStreamPlayer = $ASP

signal finishedIntro
signal option_selected(option_idx: int)

const BOSS_VOICELINES: Array[AudioStream] = [
	preload("res://Sounds/voiceline/v1.mp3"),
	preload("res://Sounds/voiceline/v2.mp3"),
	preload("res://Sounds/voiceline/v3.mp3"),
	preload("res://Sounds/voiceline/v4.mp3")
]

const SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/ringtone.mp3"),
	preload("res://Sounds/call ended.mp3")
]

var is_ringing: bool = false

func _ready() -> void:
	$Control.visible = false
	Subtitles.bbcode_enabled = true
	$Control/HBoxContainer/Button.pressed.connect(func(): option_selected.emit(1))
	$Control/HBoxContainer/Button2.pressed.connect(func(): option_selected.emit(2))
	$ASP.finished.connect(func(): if is_ringing: $ASP.play())

func start() -> void:
	$Control.visible = true
	Subtitles.text = ""
	
	var declines = 0
	var is_first_ring = true
	
	while true:
		$Control/HBoxContainer/Button.text = "Answer"
		$Control/HBoxContainer/Button2.text = "Decline"
		$Control/HBoxContainer.visible = true
		
		if is_first_ring:
			$Control/HBoxContainer.modulate.a = 0.0
			create_tween().tween_property($Control/HBoxContainer, "modulate:a", 1.0, 0.6)
			is_first_ring = false
		else:
			$Control/HBoxContainer.modulate.a = 1.0
		
		$ASP.stream = SOUNDS[0]
		is_ringing = true
		$ASP.play()
		
		var choice = await option_selected
		is_ringing = false
		$ASP.stop()
		$Control/HBoxContainer.visible = false
		
		if choice == 1:
			break
			
		declines += 1
		$ASP.stream = SOUNDS[1]
		$ASP.play()
		await get_tree().create_timer($ASP.stream.get_length() / 4.0).timeout
		$ASP.stop()
		
		if declines >= 2:
			await get_tree().create_timer(2.0).timeout
			get_tree().quit()
			return
			
		await get_tree().create_timer(3.5).timeout

#MAIN DIALOGUE///////////////////////////////////////////////////////

	await boss_say(0, "Did i wake you up?")
	await get_tree().create_timer(1.0).timeout
	
	await boss_say(1, "The kid that was supposed to work tonight bailed on me")
	await player_choose("Who bailed?", "That sucks...")
	await get_tree().create_timer(1.0).timeout
	
	await boss_say(2, "I need you to get up and cover for him, youll be working the night shift")
	await player_choose("On my way", "Do I have to?")
	await get_tree().create_timer(1.0).timeout
	
	await boss_say(3, "I couldnt care less what youre up to, get to the store... NOW")
	await player_choose("Fine", "Ugh, okay")

#MAIN DIALOGUE///////////////////////////////////////////////////////

	$ASP.stream = SOUNDS[1]
	$ASP.play()
	await get_tree().create_timer(3.0).timeout
	$ASP.stop()
	
	$Control.visible = false
	finishedIntro.emit()

func boss_say(idx: int, text: String) -> void:
	Subtitles.text = "[center]%s[/center]" % text
	$ASP.stream = BOSS_VOICELINES[idx]
	$ASP.play()
	await $ASP.finished
	Subtitles.text = ""

func player_choose(opt1: String, opt2: String) -> void:
	$Control/HBoxContainer/Button.text = opt1
	$Control/HBoxContainer/Button2.text = opt2
	$Control/HBoxContainer.visible = true
	
	var choice = await option_selected
	$Control/HBoxContainer.visible = false
	
	var chosen_text = opt1 if choice == 1 else opt2
	Subtitles.text = "[center][font=\"uid://chybldblxruc2\"]%s[/font][/center]" % chosen_text
	await get_tree().create_timer(2.0).timeout
	Subtitles.text = ""
