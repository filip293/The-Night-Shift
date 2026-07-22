extends Node

@onready var BaseTime = $/root/Node3D/BaseTime
signal timeend

var mouse_sensitivity = 0.1
var playermoveallow = true
var playerlookallow = true
var player_keys: Array[String] = []

func calltime(time) -> void:
	BaseTime.set_wait_time(time)
	BaseTime.start()
	await BaseTime.timeout
	timeend.emit()
