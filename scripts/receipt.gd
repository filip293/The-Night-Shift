extends CanvasLayer

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var modulator := $CanvasModulate
@export var fade_duration: float
@export var slide_duration: float

@export var sprite: Sprite2D
@export var task_desc: Label
@export var task1: Texture2D
@export var task2: Texture2D
@export var task3: Texture2D
@export var task4: Texture2D
@export var hidden_color: Color
@export var visible_color: Color = Color.WHITE

@export var hidden_position: Vector2
@export var visible_position: Vector2

var fade: Tween
var setting: Tween

func _ready() -> void:
	modulator.color = hidden_color
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen") and Globals.in_game and Globals.task_given:
		if Globals.task_idx == 1: 
			sprite.texture = task1
			task_desc.text = """
			Pick up the broom from
			the staff room and sweep
			the dirt off the
			gas station floor.
			"""
		elif Globals.task_idx == 2: 
			sprite.texture = task2
			task_desc.text = """
			There's trash out front,
			take it and throw it in the
			dumpster out back.
			"""
		elif Globals.task_idx == 3: 
			sprite.texture = task3
			task_desc.text = """
			The restrooms behind
			the gas station need a
			good cleaning.
			Go do your job.
			"""
		elif Globals.task_idx == 4:
			sprite.texture = task4
			task_desc.text = """
			Delivery's here.
			Leave it in the back
			and restock the shelves.
			"""
		animate_to_color(visible_color)
		animate_to_position(visible_position)
		$AudioStreamPlayer.play()
	elif event.is_action_released("ReceiptOpen") or !Globals.task_given:
		animate_to_position(hidden_position)
		animate_to_color(hidden_color)

func animate_to_color(target_color: Color) -> void:
	if fade and fade.is_running():
		fade.kill()
	
	fade = create_tween()
	fade.set_trans(Tween.TRANS_EXPO)
	fade.set_ease(Tween.EASE_OUT)
	fade.tween_property(modulator, "color", target_color, fade_duration)

func animate_to_position(target_position: Vector2) -> void:
	if setting and setting.is_running():
		setting.kill()
	
	setting = create_tween()
	setting.set_trans(Tween.TRANS_EXPO)
	setting.set_ease(Tween.EASE_OUT)
	setting.tween_property(sprite, "position", target_position, slide_duration)
