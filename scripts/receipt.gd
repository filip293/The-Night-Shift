extends CanvasLayer

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var modulator := $CanvasModulate
@onready var DialogueMana := $"../CanvasLayer2/Control"
@export var fade_duration: float = 0.3
@export var slide_duration: float = 0.3

@export_group("HUD Controls to Hide")
@export var movement_joystick: Control

@export_group("Receipt Visuals")
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
	_find_touch_controls()

func _find_touch_controls() -> void:
	if not movement_joystick:
		movement_joystick = get_tree().root.find_child("MovementJoystick", true, false) as Control

func _set_hud_controls_visible(visible_state: bool) -> void:
	if is_instance_valid(movement_joystick):
		movement_joystick.visible = visible_state

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ReceiptOpen"):
		open_receipt()
	elif event.is_action_released("ReceiptOpen"):
		close_receipt()

func open_receipt() -> void:
	if Globals.in_game and Globals.task_given and not DialogueMana.in_dialogue:
		# Hide touch UI while reading the receipt
		_set_hud_controls_visible(false)

		match Globals.get("task_idx"):
			1: 
				sprite.texture = task1
				task_desc.text = "Pick up the broom from\nthe staff room and sweep\nthe dirt off the\ngas station floor."
			2: 
				sprite.texture = task2
				task_desc.text = "There's trash out front,\ntake it and throw it in the\ndumpster out back."
			3: 
				sprite.texture = task3
				task_desc.text = "The restrooms behind\nthe gas station need a\ngood cleaning.\nGo do your job."
			4:
				sprite.texture = task4
				task_desc.text = "Delivery's here.\nLeave it in the back\nand restock the shelves."

		animate_to_color(visible_color)
		animate_to_position(visible_position)
		if $AudioStreamPlayer and not $AudioStreamPlayer.playing:
			$AudioStreamPlayer.play()

func close_receipt() -> void:
	# Restore touch UI visibility
	_set_hud_controls_visible(true)
	
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
