extends Node3D

func startOldWoman() -> void:
	$"../../AnimationPlayer".play("Walk")
	$AnimationPlayer.play("Walking")
	await Globals.calltime(48.84)
	$"../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Door_03"._toggle_door(false)
	await Globals.calltime(4.86)
	$AnimationPlayer.play("Idle")
	await Globals.calltime(11.3)
	$AnimationPlayer.play("Walking")
	await Globals.calltime(15)
	$AnimationPlayer.play("Idle")
