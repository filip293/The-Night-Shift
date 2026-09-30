extends RayCast3D

@export_group("UI Elements")
@export var label: Label
@export var crosshair: CanvasItem

@onready var task_mgr: Node = $"../../../../InGame/TaskManager"
@onready var dialogue_ui: Node = $"../../../../InGame/CanvasLayer2/Control"

enum ObjectType { GENERIC, DOOR, PUDDLE }

var label_tween: Tween
var crosshair_tween: Tween
var current_displayed_text: String = ""
var active_puddle: Node3D = null
var is_crosshair_visible: bool = false

func _ready() -> void:
	enabled = true
	$"../../../../Flashlight/Flashlight".play("Flicker")
	
	# Fallback if crosshair isn't assigned via the Inspector
	if not crosshair and has_node("../../../../InGame/CanvasLayer/CanvasLayer2/Crosshair"):
		crosshair = get_node("../../../../InGame/CanvasLayer/CanvasLayer2/Crosshair") as CanvasItem

	if label:
		label.text = ""
		label.modulate.a = 0.0

	if crosshair:
		crosshair.modulate.a = 0.25

func _physics_process(delta: float) -> void:
	# Block all world interactions while a dialogue is actively open
	if Globals.get("is_in_dialogue"):
		if is_instance_valid(active_puddle):
			active_puddle.cancel_mopping()
			active_puddle = null
		_animate_label("")
		_animate_crosshair(false)
		return

	var target_text = ""

	# 1. Active cleaning tick (Latched state: cleans continuously without needing to hold)
	if is_instance_valid(active_puddle):
		var collider = get_collider()
		# Cancel if player stops looking at the active puddle/dirt or if it gets deleted
		if collider != active_puddle or not active_puddle.is_being_mopped:
			active_puddle.cancel_mopping()
			active_puddle = null
		else:
			target_text = "Cleaning..."
			active_puddle.mop_tick(delta)
			
			# Check again after tick in case it finished
			if not is_instance_valid(active_puddle) or not active_puddle.is_being_mopped:
				active_puddle = null
				target_text = ""
				
		_animate_label(target_text)
		_animate_crosshair(target_text != "")
		return

	# 2. Raycast checking
	if is_colliding():
		var collider = get_collider()
		
		if collider and collider.has_method("is_held_by_player") and collider.is_held_by_player():
			pass
		elif collider and collider.has_method("interact") and "object_type" in collider:
			var object_type = collider.object_type
			
			if not "task_idx" in Globals:
				Globals.task_idx = 1
			var current_task = Globals.task_idx

			# --- DOOR ---
			if object_type == ObjectType.DOOR:
				target_text = "[Tap] Close Door" if collider.is_open else "[Tap] Open Door"
				if Input.is_action_just_pressed("Interact"):
					collider.interact()
					
			# --- GENERIC ---
			elif object_type == ObjectType.GENERIC:
				var object_name = collider.whoami() if collider.has_method("whoami") else "Object"
				var broom_held = $"../../../Bwoom2".visible
				var mop_held = $"../../../Bwooom".visible

				# --- NPC INTERACTIONS ---
				if object_name == "PoliceWoman":
					if Globals.get("can_talk_policewoman"):
						target_text = "[Tap] Talk to Police Officer"
						if Input.is_action_just_pressed("Interact") and not Globals.get("is_in_dialogue"):
							Globals.set("is_in_dialogue", true)
							dialogue_ui._start_policewoman_dialogue(collider)
					else:
						target_text = "She looks busy right now..."

				elif object_name == "Babushka" or object_name == "OldWoman":
					if Globals.get("can_talk_babushka"):
						target_text = "[Tap] Talk to Babushka"
						if Input.is_action_just_pressed("Interact") and not Globals.get("is_in_dialogue"):
							Globals.set("is_in_dialogue", true)
							dialogue_ui._start_babushka_dialogue(collider)
					else:
						target_text = "She looks busy right now..."

				# TASK 1: Broom
				elif object_name == "Broom" and current_task == 1:
					if broom_held:
						var dirt_left = get_tree().get_nodes_in_group("dirt").size()
						if dirt_left == 0:
							target_text = "[Tap] Return Broom"
							if Input.is_action_just_pressed("Interact"):
								$"../../../../Bwoom2".visible = true
								$"../../../Bwoom2".visible = false
								
								if task_mgr and task_mgr.has_method("next_task"):
									task_mgr.next_task()
								else:
									Globals.task_idx += 1
								
								collider.set_collision_layer_value(9, false)
						else:
							target_text = "Sweep all dirt first! (%d left)" % dirt_left
					else:
						target_text = "[Tap] Take Broom"
						if Input.is_action_just_pressed("Interact"):
							$"../../../../Bwoom2".visible = false
							$"../../../../Bwoom2/TakeBroom".play()
							$"../../../Bwoom2".visible = true

				# TASK 2: Take out the trash
				elif current_task == 2:
					var has_trash = Globals.get("has_trash_bag")
					if object_name == "Trash bag":
						if has_trash:
							target_text = "Already carrying trash bag"
						else:
							target_text = "[Tap] Take trash bag"
							if Input.is_action_just_pressed("Interact"):
								$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/StaticBody3D/PickUpGarbage".play()
								$"../../../Trash_002_Trash_0".visible = true
								Globals.set("has_trash_bag", true)
								collider.interact()
					elif object_name == "Trash can":
						if has_trash:
							target_text = "[Tap] Dispose trash"
							if Input.is_action_just_pressed("Interact"):
								Globals.set("has_trash_bag", false)
								$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Dumpster/Dumpster_Trash_1/ThrowGarbage".play()
								$"../../../Trash_002_Trash_0".visible = false
								collider.interact()
								collider.set_collision_layer_value(9, false)
								
								if task_mgr and task_mgr.has_method("next_task"):
									task_mgr.next_task()
								else:
									Globals.task_idx += 1
						else:
							target_text = "I need to take the trash bag first."

				# TASK 3: Mop
				elif object_name == "Mop" and current_task == 3:
					if mop_held:
						var puddles_left = get_tree().get_nodes_in_group("puddles").size()
						if puddles_left == 0:
							target_text = "[Tap] Return Mop"
							if Input.is_action_just_pressed("Interact"):
								$"../../../../BucketAndMop/StaticBody3D".visible = true
								$"../../../Bwooom".visible = false
								
								if task_mgr and task_mgr.has_method("next_task"):
									task_mgr.next_task()
								else:
									Globals.task_idx += 1
								
								collider.set_collision_layer_value(9, false)
						else:
							target_text = "Clean remaining puddles first! (%d left)" % puddles_left
					else:
						target_text = "[Tap] Take Mop"
						if Input.is_action_just_pressed("Interact"):
							$"../../../../BucketAndMop/StaticBody3D".visible = false
							$"../../../../BucketAndMop/StaticBody3D/TakeBroom".play()
							$"../../../Bwooom".visible = true
							collider.interact()

				# TASK 4 OBJECTS: Crate, Cans, Restock
				elif current_task == 4:
					var has_crate = Globals.get("has_crate")
					var crate_delivered = Globals.get("crate_delivered")
					var has_cans = Globals.get("has_cans")
					var cans_restocked = Globals.get("cans_restocked")

					if object_name == "Take crate":
						if crate_delivered:
							target_text = "Crate already delivered"
						elif has_crate:
							target_text = "Already carrying crate"
						else:
							target_text = "[Tap] Take crate"
							if Input.is_action_just_pressed("Interact"):
								Globals.set("has_crate", true)
								$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Door"._toggle_door(true)
								Globals.jumpscare_impending = true
								collider.interact()

					elif object_name == "Take cans":
						if not crate_delivered:
							if has_crate:
								target_text = "[Tap] Place crate"
								if Input.is_action_just_pressed("Interact"):
									Globals.set("has_crate", false)
									Globals.set("crate_delivered", true)
									collider.interact()
							else:
								target_text = "I need to bring the crate here first."
						else:
							if cans_restocked:
								target_text = "Empty crate"
								collider.set_collision_layer_value(9, false)
							elif has_cans:
								target_text = "Already carrying cans"
							else:
								target_text = "[Tap] Take cans"
								if Input.is_action_just_pressed("Interact"):
									Globals.set("has_cans", true)
									collider.interact()

					elif object_name == "Restock cans":
						if cans_restocked:
							target_text = "Shelf is stocked"
							collider.set_collision_layer_value(9, false)
						elif has_cans:
							target_text = "[Tap] Restock cans"
							if Input.is_action_just_pressed("Interact"):
								Globals.set("has_cans", false)
								Globals.set("cans_restocked", true)
								collider.interact()
								collider.set_collision_layer_value(9, false)
								
								if task_mgr and task_mgr.has_method("next_task"):
									task_mgr.next_task()
								else:
									Globals.task_idx += 1
						else:
							target_text = "I need to get cans first."
					
				if object_name == "Car1":
					target_text = "[Tap] Fuel car"
					if Input.is_action_just_pressed("Interact"):
						$"../../../../Map/FirstCar/PathFollow3D/suv".set_collision_layer_value(9, false)
						$"../../../../Map/FirstCar/PathFollow3D/suv/BeepBeep".volume_db = -100
						$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Fuel_pump_01/Fuel_pump_01_Fuel_pump_0/Pump1".play()
						Globals.stationcar = true
						await $"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Fuel_pump_01/Fuel_pump_01_Fuel_pump_0/Pump1".finished
						await Globals.calltime(2.0)
						$"../../../../Map/FirstCar/Animations".play("EXIT")
						await Globals.calltime(5.0)
						Globals.stationcar = false
					
				if object_name == "Car2":
					target_text = "[Tap] Fuel car"
					if Input.is_action_just_pressed("Interact"):
						$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Fuel_pump_03/Fuel_pump_03_Fuel_pump_0/Pump2".play()
						Globals.stationcar = true
						await $"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Fuel_pump_03/Fuel_pump_03_Fuel_pump_0/Pump2".finished
						await Globals.calltime(2.0)
						$"../../../../Map/SecondCar/Animations".play("EXIT")
						await Globals.calltime(5.0)
						Globals.stationcar = false
				
				if object_name == "LockedDoor":
					target_text = "Door is locked."
					if Input.is_action_just_pressed("Interact"):
						$"../../../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Door_02/LockedDoor".play()
				
				if object_name == "Radio":
					if Globals.radio_playing:
						target_text = "[Tap] Turn off radio"
						if Input.is_action_just_pressed("Interact"):
							$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Radio/Radio_01_Radio_0/Click.play()
							$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Radio/Radio_01_Radio_0/AudioStreamPlayer3D.stop()
							Globals.radio_playing = false
					else:
						target_text = "[Tap] Turn on radio"
						if Input.is_action_just_pressed("Interact"):
							$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Radio/Radio_01_Radio_0/Click.play()
							$/root/Node3D/Map/Sketchfab_model/Gas_station_fbx/RootNode/Radio/Radio_01_Radio_0/AudioStreamPlayer3D.play()
							Globals.radio_playing = true
								
			# --- PUDDLES & DIRT ---
			elif object_type == ObjectType.PUDDLE:
				var broom_held = $"../../../Bwoom2".visible
				var mop_held = $"../../../Bwooom".visible
				var p_type = collider.puddle_type if "puddle_type" in collider else 0

				if current_task == 1 and p_type == 0:
					if broom_held:
						target_text = "[Tap] Sweep dirt"
						if Input.is_action_just_pressed("Interact"):
							active_puddle = collider
							collider.start_mopping()
					else:
						target_text = "I need a broom first."

				elif current_task == 3 and p_type == 1:
					if mop_held:
						target_text = "[Tap] Mop Puddle"
						if Input.is_action_just_pressed("Interact"):
							active_puddle = collider
							collider.start_mopping()
					else:
						target_text = "I need a mop first."

	_animate_label(target_text)
	_animate_crosshair(target_text != "")

func _animate_label(new_text: String) -> void:
	if current_displayed_text == new_text:
		return

	current_displayed_text = new_text

	if label_tween and label_tween.is_valid():
		label_tween.kill()

	label_tween = create_tween()

	if new_text == "":
		label_tween.tween_property(label, "modulate:a", 0.0, 0.2)
		label_tween.tween_callback(func(): label.text = "")
	else:
		if label.modulate.a <= 0.05:
			label.text = new_text
			label_tween.tween_property(label, "modulate:a", 1.0, 0.3)
		else:
			label_tween.tween_property(label, "modulate:a", 0.0, 0.15)
			label_tween.tween_callback(func(): label.text = new_text)
			label_tween.tween_property(label, "modulate:a", 1.0, 0.25)

func _animate_crosshair(should_show: bool) -> void:
	if not crosshair or is_crosshair_visible == should_show:
		return

	is_crosshair_visible = should_show

	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()

	crosshair_tween = create_tween()
	var target_alpha = 1.0 if should_show else 0.25
	var duration = 0.2 if should_show else 0.15
	
	crosshair_tween.tween_property(crosshair, "modulate:a", target_alpha, duration)
