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
@export var frame_21: Texture2D
@export var frame_22: Texture2D 
@export var frame_23: Texture2D 
@export var frame_24: Texture2D

func _ready() -> void:
	sprite.texture = frame_21
	Globals.TASKCHANGED.connect(_on_globals_taskchanged)

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
		Globals.earned_money += 170
	elif Globals.task_idx == 3:
		sprite.texture = frame_23
		Globals.earned_money += 130
	elif Globals.task_idx == 4:
		sprite.texture = frame_24
		Globals.earned_money += 220
	print("Playing animation!")
	animation_player.play("slide_down_slice")
	await animation_player.animation_finished
	
	while !pressed_r:
		new_task_alert.visible = true
		await Globals.calltime(1.0)
		new_task_alert.visible = false
		await Globals.calltime(1.0)

func _on_globals_taskchanged() -> void:
	Globals.task_given = false
	await Globals.calltime(2.0)
	print("Caught it!")
	_animate_receipt()
	await Globals.calltime(1.0)
	Globals.task_given = true
