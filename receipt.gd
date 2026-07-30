extends CanvasLayer

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var modulator := $CanvasModulate
@export var fade_duration: float

@export var sprite: Sprite2D
@export var task1: Texture2D
@export var task2: Texture2D
@export var task3: Texture2D
@export var hidden_color: Color
@export var visible_color: Color = Color.WHITE

var fade: Tween

func _ready() -> void:
	modulator.color = hidden_color
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen") and Globals.in_game:
		if Globals.task_idx == 1: 
			sprite.texture = task1
		elif Globals.task_idx == 2: 
			sprite.texture = task2
		elif Globals.task_idx == 3:
			sprite.texture = task3
		animate_to(visible_color)
	elif event.is_action_released("ReceiptOpen"):
		animate_to(hidden_color)

func animate_to(target_color: Color) -> void:
	if fade and fade.is_running():
		fade.kill()
	
	fade = create_tween()
	fade.set_trans(Tween.TRANS_EXPO)
	fade.set_ease(Tween.EASE_OUT)
	fade.tween_property(modulator, "color", target_color, fade_duration)
