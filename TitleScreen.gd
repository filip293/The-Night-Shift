extends Node2D

@onready var TitleCam := $"../TitleCamera"
@onready var Player := $"../Player"
@onready var Map := $"../Map"
@onready var PlayerCam := $"../Player/Neck/Camera"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	Player.process_mode = Node.PROCESS_MODE_DISABLED
	Map.process_mode = Node.PROCESS_MODE_DISABLED
	TitleCam.make_current()
	#PLAY ANIMATION HERE
	$CanvasLayer.visible = true
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	$CanvasLayer.visible = false
	#ADD TRANSITION HERE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	PlayerCam.make_current()
	Player.process_mode = Node.PROCESS_MODE_INHERIT
	Map.process_mode = Node.PROCESS_MODE_INHERIT
