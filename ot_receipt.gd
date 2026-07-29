extends Node2D
class_name OTReceipt

@export_group("References")
@export var sprite: Sprite2D

@export_group("Tear Frames")
@export var frame_21: Texture2D # Initial intact receipt frame
@export var frame_22: Texture2D # Partial tear frame
@export var frame_23: Texture2D # Fully torn frame

@export_group("Animation Settings")
@export var print_offset: Vector2 = Vector2(150, -400) # Off-screen top-right relative to rest position
@export var print_duration: float = 0.5
@export var frame_delay: float = 0.08 # Speed of tear animation frames

@onready var rest_position: Vector2 = position

func _ready() -> void:
	# Hide off-screen on game launch
	position = rest_position + print_offset
	if sprite and frame_21:
		sprite.texture = frame_21

## Connect your task_changed signal to this function
func on_task_changed() -> void:
	_animate_receipt()

func _animate_receipt() -> void:
	if not sprite:
		return

	# Reset state before animating
	position = rest_position + print_offset
	sprite.texture = frame_21
	sprite.modulate.a = 1.0

	var tween: Tween = create_tween()

	# 1. Slide down into position (Printing)
	tween.tween_property(self, "position", rest_position, print_duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# 2. Tear-off sequence (Frame 21 -> Frame 22 -> Frame 23)
	if frame_22:
		tween.tween_callback(func(): sprite.texture = frame_22)
		tween.tween_interval(frame_delay)

	if frame_23:
		tween.tween_callback(func(): sprite.texture = frame_23)
		tween.tween_interval(frame_delay)

	# 3. Drop down & fade out after tear-off
	tween.tween_property(self, "position:y", rest_position.y + 120, 0.35)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
