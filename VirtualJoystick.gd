extends Control

@export var max_length: float = 100.0
@export var deadzone: float = 10.0

@onready var knob: Sprite2D = $Knob
@onready var base: Sprite2D = $Base

var touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	joystick_center = base.position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_update_joystick(event.position)
		elif event.index == touch_index:
			_reset_joystick()

	elif event is InputEventScreenDrag and event.index == touch_index:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2) -> void:
	var offset = pos - joystick_center
	if offset.length() > max_length:
		offset = offset.normalized() * max_length
	
	knob.position = joystick_center + offset
	
	var dir = offset / max_length
	if offset.length() < deadzone:
		dir = Vector2.ZERO

	# Updated action names matching your InputMap
	if dir.x < -0.3: Input.action_press("Left")
	else: Input.action_release("Left")

	if dir.x > 0.3: Input.action_press("Right")
	else: Input.action_release("Right")

	if dir.y < -0.3: Input.action_press("Forward")
	else: Input.action_release("Forward")

	if dir.y > 0.3: Input.action_press("Back")
	else: Input.action_release("Back")

func _reset_joystick() -> void:
	touch_index = -1
	knob.position = joystick_center
	Input.action_release("Left")
	Input.action_release("Right")
	Input.action_release("Forward")
	Input.action_release("Back")
