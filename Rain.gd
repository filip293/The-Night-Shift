extends Area3D

@export var rain_audio: AudioStreamPlayer3D
@export var lightning_audio: AudioStreamPlayer3D

const OUTDOOR_VOLUME: float = 0.0
const INDOOR_VOLUME: float = -20.0 

var rain_tween: Tween
var lightning_tween: Tween

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_fade_volume(INDOOR_VOLUME)

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_fade_volume(OUTDOOR_VOLUME)

func _fade_volume(target_db: float) -> void:
	if rain_audio:
		if rain_tween and rain_tween.is_running():
			rain_tween.kill()
		rain_tween = create_tween()
		rain_tween.tween_property(rain_audio, "volume_db", target_db, 0.05)

	if lightning_audio:
		if lightning_tween and lightning_tween.is_running():
			lightning_tween.kill()
		lightning_tween = create_tween()
		lightning_tween.tween_property(lightning_audio, "volume_db", target_db, 0.05)
