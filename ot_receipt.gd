extends Node2D
class_name OTReceipt

var time := 0
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_group("References")
@export var sprite: Sprite2D

@export_group("Tear Frames")
@export var frame_21: Texture2D # Initial intact receipt frame
@export var frame_22: Texture2D # Partial tear frame
@export var frame_23: Texture2D # Fully torn frame

func _ready() -> void:
	sprite.texture = frame_21


func on_task_changed() -> void:
	if time != 0:
		_animate_receipt()
	time += 1

func _animate_receipt() -> void:
	if not sprite:
		return
		
	if Globals.task_idx == 1:
		sprite.texture = frame_21
	elif Globals.task_idx == 2:
		sprite.texture = frame_22
	elif Globals.task_idx == 3:
		sprite.texture = frame_23
		
	
	
	
