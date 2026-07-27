extends RayCast3D

@export_group("UI Elements")
@export var label: Label

enum ObjectType { GENERIC, DOOR, PUDDLE }

var label_tween: Tween
var current_displayed_text: String = ""

# Track the puddle currently being mopped
var active_puddle: Node3D = null

func _ready() -> void:
	enabled = true
	if label:
		label.text = ""
		label.modulate.a = 0.0

func _physics_process(delta: float) -> void:
	var target_text = ""

	# If we are currently in the middle of mopping a puddle
	if is_instance_valid(active_puddle):
		if Input.is_action_pressed("Interact"):
			target_text = "Mopping..."
			active_puddle.mop_tick(delta)
			
			if not is_instance_valid(active_puddle):
				target_text = ""
		else:
			active_puddle.cancel_mopping()
			active_puddle = null
			
		_animate_label(target_text)
		return

	# Normal Raycast collision checking
	if is_colliding():
		var collider = get_collider()
		if collider and collider.has_method("interact") and "object_type" in collider:
			var object_type = collider.object_type
			
			if object_type == ObjectType.DOOR:
				target_text = "[E] Close Door" if collider.is_open else "[E] Open Door"
				if Input.is_action_just_pressed("Interact"):
					collider.interact()
					
			elif object_type == ObjectType.GENERIC:
				var object_name = collider.whoami() if collider.has_method("whoami") else "Object"
				
				# Ensure variables are initialized if not already declared in Globals
				if not "has_crate" in Globals: Globals.set("has_crate", false)
				if not "crate_delivered" in Globals: Globals.set("crate_delivered", false)
				if not "has_cans" in Globals: Globals.set("has_cans", false)
				if not "cans_restocked" in Globals: Globals.set("cans_restocked", false)
				
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
						target_text = "[E] Take crate"
						if Input.is_action_just_pressed("Interact"):
							Globals.set("has_crate", true)
							collider.interact()
							
				elif object_name == "Take cans":
					if not crate_delivered:
						if has_crate:
							target_text = "[E] Place crate"
							if Input.is_action_just_pressed("Interact"):
								Globals.set("has_crate", false)
								Globals.set("crate_delivered", true)
								collider.interact()
						else:
							target_text = "I need to bring the crate here first."
					else:
						# Crate is delivered, now handle taking cans
						if cans_restocked:
							target_text = "Empty crate"
						elif has_cans:
							target_text = "Already carrying cans"
						else:
							target_text = "[E] Take cans"
							if Input.is_action_just_pressed("Interact"):
								Globals.set("has_cans", true)
								collider.interact()
								
				elif object_name == "Restock cans":
					if cans_restocked:
						target_text = "Shelf is stocked"
					elif has_cans:
						target_text = "[E] Restock cans"
						if Input.is_action_just_pressed("Interact"):
							Globals.set("has_cans", false)
							Globals.set("cans_restocked", true)
							collider.interact()
					else:
						target_text = "I need to get cans first."
						
				elif object_name == "Mop":
					target_text = "[E] Use Mop"
					if Input.is_action_just_pressed("Interact"):
						$"../../../../BucketAndMop/StaticBody3D".visible = false
						$"../../../Bwooom".visible = true
						collider.interact()
				
				else:
					target_text = "[E] Use " + object_name
					if Input.is_action_just_pressed("Interact"):
						collider.interact()
					
			elif object_type == ObjectType.PUDDLE:
				var has_mop = $"../../../Bwooom".visible
				
				if has_mop:
					target_text = "[E] Mop Puddle"
					if Input.is_action_just_pressed("Interact"):
						active_puddle = collider
						collider.start_mopping()
				else:
					target_text = "I need a mop first."

	_animate_label(target_text)

func _animate_label(new_text: String):
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
