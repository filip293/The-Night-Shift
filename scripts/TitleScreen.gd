extends Node2D

@onready var TitleCam := $"../Camera/TitleCamera"
@onready var TitleCamAnim := $"../Camera/AnimationPlayer"
@onready var Player := $"../Player"
@onready var Map := $"../Map"
@onready var PlayerCam := $"../Player/Neck/Camera"
@onready var BGM := $BackgroundMusic
@onready var Intro := $"../Intro"
@onready var TaskManager: Node = $"../InGame/TaskManager"

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
	$CanvasLayer/VBoxContainer/Start.disabled = true
	$CanvasLayer/VBoxContainer/Quit.disabled = true
	$CanvasLayer/Animations.play("fadetitle")
	await $CanvasLayer/Animations.animation_finished
	$CanvasLayer.visible = false
	$CanvasLayer/Animations.play("fade")
	await $CanvasLayer/Animations.animation_finished
	var tween := create_tween()
	tween.tween_property(BGM, "volume_db", -80.0, 3)
	tween.tween_callback(BGM.stop)
	BGM.autoplay = false
	await get_tree().create_timer(2.0).timeout
	Intro.start()
	await Intro.finishedIntro
	$"../InGame/CanvasLayer".visible = true
	PlayerCam.make_current()
	$"../Map/Sketchfab_model/Gas_station_fbx/RootNode/Radio/Radio_01_Radio_0/AudioStreamPlayer3D".play()
	$CanvasLayer/Animations.play_backwards("fade")
	await $CanvasLayer/Animations.animation_finished
	$BlackScreen.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Player.process_mode = Node.PROCESS_MODE_INHERIT
	Map.process_mode = Node.PROCESS_MODE_INHERIT
	Globals.task_idx = 0
	$"../InGame/CanvasLayer/RichTextLabel".visible = true
	$"../InGame/CanvasLayer/CanvasLayer2/Budget".visible = true
	Globals.in_game = true
	## ADD NPC INTERACTIONS BUT CALL FROM A DIFFERENT SCRIPT BEFORE STARTING
	await get_tree().create_timer(5.0).timeout
	TaskManager.next_task()
