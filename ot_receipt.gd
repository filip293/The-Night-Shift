extends Node2D
class_name OTReceipt

var time = 0
signal clicked_r 
var pressed_r = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var new_task_alert: Label = $"../CanvasLayer/CanvasLayer/NewTaskAlert"

@export_group("References")
@export var sprite: Sprite2D

@export_group("Tear Frames")
@export var frame_21: Texture2D # Initial intact receipt frame
@export var frame_22: Texture2D # Partial tear frame
@export var frame_23: Texture2D # Fully torn frame

func _ready() -> void:
	sprite.texture = frame_21

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen"):
		pressed_r = true

func _animate_receipt() -> void:
	if not sprite:
		return
	
	animation_player.play("RESET")
	pressed_r = false
	if Globals.task_idx == 1:
		sprite.texture = frame_21
	elif Globals.task_idx == 2:
		sprite.texture = frame_22
	elif Globals.task_idx == 3:
		sprite.texture = frame_23
	print("Playing animation!")
	animation_player.play("slide_down_slice")
	await animation_player.animation_finished
	
	while !pressed_r:
		new_task_alert.visible = true
		await Globals.calltime(1.0)
		new_task_alert.visible = false
		await Globals.calltime(1.0)

func _on_globals_taskchanged() -> void:
	print("Caught it!")
	_animate_receipt()
