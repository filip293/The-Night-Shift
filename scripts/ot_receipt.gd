extends Node2D
class_name OTReceipt

signal clicked_r 
var pressed_r = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_group("References")
@export var sprite: Sprite2D

@export_group("Tear Frames")
@export var frame_21: Texture2D
@export var frame_22: Texture2D 
@export var frame_23: Texture2D 
@export var frame_24: Texture2D

func _ready() -> void:
	if sprite and frame_21:
		sprite.texture = frame_21
		
	if Globals.has_signal("TASKCHANGED"):
		if not Globals.TASKCHANGED.is_connected(_on_globals_taskchanged):
			Globals.TASKCHANGED.connect(_on_globals_taskchanged)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen"):
		pressed_r = true

func _animate_receipt() -> void:
	if not sprite or not animation_player:
		return
	
	animation_player.play("RESET")
	pressed_r = false
	
	match Globals.get("task_idx"):
		1:
			sprite.texture = frame_21
		2:
			sprite.texture = frame_22
			Globals.earned_money += 170
		3:
			sprite.texture = frame_23
			Globals.earned_money += 130
		4:
			sprite.texture = frame_24
			Globals.earned_money += 220

	animation_player.play("slide_down_slice")
	await animation_player.animation_finished

func _on_globals_taskchanged() -> void:
	Globals.task_given = false
	await Globals.calltime(2.0)
	_animate_receipt()
	await Globals.calltime(1.0)
	Globals.task_given = true
