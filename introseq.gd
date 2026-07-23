extends Node2D

@onready var Subtitles: RichTextLabel = $Control/RichTextLabel
@onready var ASP: AudioStreamPlayer = $ASP

signal finishedIntro

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

func _ready() -> void:
	$Control.visible = false
	
func start() -> void:
	$ASP.stream = SOUNDS[0] #RINGTONE
	$ASP.play()
	$Control.visible = true
	await get_tree().create_timer(10.0).timeout
	$ASP.stop()
	$ASP.stream = BOSS_VOICELINES[0]
	$ASP.play()
	await $ASP.finished
	await get_tree().create_timer(1.0).timeout
	$ASP.stream = BOSS_VOICELINES[1]
	$ASP.play()
	await $ASP.finished
	await get_tree().create_timer(1.0).timeout
	$ASP.stream = BOSS_VOICELINES[2]
	$ASP.play()
	await $ASP.finished
	await get_tree().create_timer(1.0).timeout
	$ASP.stream = BOSS_VOICELINES[3]
	$ASP.play()
	await $ASP.finished
	$ASP.stream = SOUNDS[1]
	$ASP.play()
	await get_tree().create_timer(2.0).timeout
	$ASP.stop()
	$Control.visible = false
	finishedIntro.emit()
