extends StaticBody3D

@export var whoami_value: String = "Object"

enum ObjectType { GENERIC, DOOR }
@export var object_type: ObjectType = ObjectType.GENERIC

@export var open_rotation_y: float = 90.0
@export var closed_rotation_y: float = 0.0
@export var audio_player: AudioStreamPlayer3D
@export var open_sound: AudioStream
@export var close_sound: AudioStream

var is_open: bool = false
var door_tween: Tween

func _get_property_list():
	var properties = []
	if object_type == ObjectType.DOOR:
		properties.append({ "name": "open_rotation_y", "type": TYPE_FLOAT })
		properties.append({ "name": "closed_rotation_y", "type": TYPE_FLOAT })
		properties.append({ "name": "audio_player", "type": TYPE_NODE_PATH, "hint_string": "AudioStreamPlayer3D" })
		properties.append({ "name": "open_sound", "type": TYPE_OBJECT, "hint_string": "AudioStream" })
		properties.append({ "name": "close_sound", "type": TYPE_OBJECT, "hint_string": "AudioStream" })
	return properties

func interact() -> void:
	match object_type:
		ObjectType.DOOR:
			_toggle_door()
		ObjectType.GENERIC:
			_on_interact_generic()

func _toggle_door() -> void:
	if door_tween and door_tween.is_running():
		return

	is_open = not is_open
	
	door_tween = create_tween()

	if is_open:
		var open_duration = 1.5
		if audio_player and open_sound:
			audio_player.stream = open_sound
			audio_player.play()
			
		door_tween.tween_property(self, "rotation_degrees:y", open_rotation_y, open_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else: 
		var close_duration = 1.5
		if audio_player and close_sound:
			audio_player.stream = close_sound
			audio_player.play()
			
		door_tween.tween_property(self, "rotation_degrees:y", closed_rotation_y, close_duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _on_interact_generic() -> void:
	print("Interacted with generic object: ", whoami_value)

func whoami() -> String:
	return whoami_value
