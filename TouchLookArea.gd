extends Control

@export var player: CharacterBody3D
@export var touch_sensitivity: float = 0.003
@export var max_tap_time: float = 0.2
@export var max_tap_distance: float = 15.0

var touch_index: int = -1
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
var is_dragging: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_index == -1:
				touch_index = event.index
				touch_start_pos = event.position
				touch_start_time = Time.get_ticks_msec() / 1000.0
				is_dragging = false
		else:
			if event.index == touch_index:
				var press_duration = (Time.get_ticks_msec() / 1000.0) - touch_start_time
				var dist = event.position.distance_to(touch_start_pos)
				
				if press_duration <= max_tap_time and dist <= max_tap_distance:
					_trigger_interact()
				
				touch_index = -1
				is_dragging = false

	elif event is InputEventScreenDrag and event.index == touch_index:
		var dist = event.position.distance_to(touch_start_pos)
		if dist > max_tap_distance:
			is_dragging = true
			
		if is_dragging and is_instance_valid(player):
			var look_delta = event.relative * touch_sensitivity
			if player.has_method("apply_look"):
				player.apply_look(look_delta)

func _trigger_interact() -> void:
	Input.action_press("Interact")
	await get_tree().process_frame
	Input.action_release("Interact")
