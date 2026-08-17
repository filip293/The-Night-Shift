extends Node3D

var runonce: bool = false
var js: AudioStream = preload("res://Sounds/jumpscare.mp3")
var drone: AudioStream = preload("res://Sounds/drone.mp3")
func _on_jumpscare_trigger_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if Globals.task_idx == 2 and !runonce: 
			runonce = true
			$AnimationPlayer.play("run")
			$"../Player/JumpscareAndDrone".stream = js
			$"../Player/JumpscareAndDrone".play()
			await $"../Player/JumpscareAndDrone".finished
			$"../Player/JumpscareAndDrone".autoplay = true
			$"../Player/JumpscareAndDrone".stream = drone
			$"../Player/JumpscareAndDrone".play()
