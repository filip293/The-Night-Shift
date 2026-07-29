extends CanvasLayer

@onready var modulator := $CanvasModulate
@export var fade_duration: float

@export var hidden_color: Color
@export var visible_color: Color = Color.WHITE

var fade: Tween

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen"):
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
