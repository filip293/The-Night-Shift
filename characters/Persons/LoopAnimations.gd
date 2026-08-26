extends Node3D

@onready var dialogue_ui: Node = $"../../../InGame/CanvasLayer2/Control"
@onready var head_look_script_B: Node3D = $Armature
@onready var head_look_script_C: Node3D = $"../../../Path3D2/PathFollow3D/PoliceWoman/Armature_001"
@onready var door_node: Node = $"../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Door_03"

func _ready() -> void:
	while not Globals.get("in_game"):
		await get_tree().process_frame
		
	startOldWoman()

# Ensures door only toggles if it's currently closed
func _open_door_if_closed() -> void:
	if is_instance_valid(door_node):
		# Check your door's open tracking variable (e.g. is_open, isOpen, or opened)
		var is_door_open: bool = door_node.get("is_open") if "is_open" in door_node else false
		if not is_door_open:
			door_node._toggle_door(false)

func startOldWoman() -> void:
	$"../../AnimationPlayer".play("Walk")
	$AnimationPlayer.play("Walking")
	await Globals.calltime(48.4)
	
	_open_door_if_closed()
	
	await Globals.calltime(5.3)
	$AnimationPlayer.play("Idle")
	await Globals.calltime(11.3)
	$AnimationPlayer.play("Walking")
	await Globals.calltime(17)
	$AnimationPlayer.play("Idle")
	$"../../AnimationPlayer".pause()
	
	if head_look_script_B:
		head_look_script_B.set_tracking(true)
	
	Globals.can_talk_babushka = true
	
	await dialogue_ui.dialogue_finished
	if head_look_script_B:
		head_look_script_B.set_tracking(false)
	Globals.can_talk_babushka = false
	$"../../AnimationPlayer".play()
	$AnimationPlayer.play("Walking")
	await Globals.calltime(0.5)
	
	_open_door_if_closed()
	
	startPoliceWoman()

func startPoliceWoman() -> void:
	$"../../../Path3D2/AnimationPlayer".play("Walking")
	$"../../../Path3D2/PathFollow3D/PoliceWoman/AnimationPlayer".play("Walking")
	await Globals.calltime(15.6532)
	
	_open_door_if_closed()
	
	await Globals.calltime(1.911)
	$"../../../Path3D2/PathFollow3D/PoliceWoman/AnimationPlayer".play("Idle")
	await Globals.calltime(11.5358)
	$"../../../Path3D2/PathFollow3D/PoliceWoman/AnimationPlayer".play("Walking")
	await Globals.calltime(8)
	$"../../../Path3D2/PathFollow3D/PoliceWoman/AnimationPlayer".play("Idle")
	$"../../../Path3D2/AnimationPlayer".pause()
	
	if head_look_script_C:
		head_look_script_C.set_tracking(true)
	
	Globals.can_talk_policewoman = true
	
	await dialogue_ui.dialogue_finished
	
	if head_look_script_C:
		head_look_script_C.set_tracking(false)
	Globals.can_talk_policewoman = false
	$"../../../Path3D2/AnimationPlayer".play()
	$"../../../Path3D2/PathFollow3D/PoliceWoman/AnimationPlayer".play("Walking")
	await Globals.calltime(0.5)
	
	_open_door_if_closed()
