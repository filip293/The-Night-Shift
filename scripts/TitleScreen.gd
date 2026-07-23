extends Node2D

@onready var TitleCam := $"../Camera/TitleCamera"
@onready var TitleCamAnim := $"../Camera/AnimationPlayer"
@onready var Player := $"../Player"
@onready var Map := $"../Map"
@onready var PlayerCam := $"../Player/Neck/Camera"
@onready var BGM := $BackgroundMusic
@onready var Intro := $"../Intro"

func _ready() -> void:
	Player.process_mode = Node.PROCESS_MODE_DISABLED
	Map.process_mode = Node.PROCESS_MODE_DISABLED
	TitleCam.make_current()
	$CanvasLayer.visible = true
	TitleCamAnim.play("CamAnim/handheld_sway")
	$CanvasLayer/Animations.play("startup")
	BGM.autoplay = true
	await $CanvasLayer/Animations.animation_finished
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	$CanvasLayer/Animations.play("fadetitle")
	await $CanvasLayer/Animations.animation_finished
	$CanvasLayer.visible = false
	$CanvasLayer/Animations.play("fade")
	await $CanvasLayer/Animations.animation_finished
	BGM.stop() # I might make it very quiet while the boss is calling...
	BGM.autoplay = false
	await get_tree().create_timer(2.0).timeout
	#Intro.start()
	#await Intro.finishedIntro
	$"../InGame/CanvasLayer".visible = true
	PlayerCam.make_current()
	$CanvasLayer/Animations.play_backwards("fade")
	await $CanvasLayer/Animations.animation_finished
	$BlackScreen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Player.process_mode = Node.PROCESS_MODE_INHERIT
	Map.process_mode = Node.PROCESS_MODE_INHERIT
