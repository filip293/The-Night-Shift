extends Area3D

@onready var audio_stream_player = $"../../../../../../../Player/Rain2"

const OUTDOOR_VOLUME: float = 0.0
const INDOOR_VOLUME: float = -20.0 

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_fade_volume(INDOOR_VOLUME)

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_fade_volume(OUTDOOR_VOLUME)

func _fade_volume(target_db: float) -> void:
	var tween = create_tween()
	tween.tween_property(audio_stream_player, "volume_db", target_db, 0.05)
