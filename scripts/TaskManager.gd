extends Node

const TASKS: Array[String] = [
	"NO TASK ASSIGNED",
	"Sweep the aisles",
	"Clean the restroom",
	"Restock the cans"
]

@onready var broom_held_node: Node = $"../../Player/Bwoom2"
@onready var mop_held_node: Node = $"../../Player/Bwooom"

func _ready() -> void:
	if not "task_idx" in Globals:
		Globals.task_idx = 1
		
	if Globals.has_signal("TASKCHANGED"):
		Globals.TASKCHANGED.connect(_on_task_changed)
		
	_update_task_ui()

func _process(_delta: float) -> void:
	_update_task_highlights()

func next_task() -> void:
	if Globals.task_idx < TASKS.size() - 1:
		Globals.task_idx += 1
		_update_task_ui()

func _on_task_changed() -> void:
	_update_task_ui()

func _update_task_ui() -> void:
	if Globals.task_idx == 3:
		var crate = get_node_or_null("../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Crate2")
		if crate:
			crate.visible = true
			var col = crate.get_node_or_null("CollisionShape3D")
			if col: col.disabled = false

func _update_task_highlights() -> void:
	var task = Globals.task_idx
	
	# Reset ALL object glows first
	for node in get_tree().get_nodes_in_group("interactables"):
		_set_task_target(node, false)
	for node in get_tree().get_nodes_in_group("dirt"):
		_set_task_target(node, false)
	for node in get_tree().get_nodes_in_group("puddles"):
		_set_task_target(node, false)

	# TASK 1: Broom & Dirt
	if task == 1:
		var broom_held = broom_held_node and broom_held_node.visible
		var dirt_left = get_tree().get_nodes_in_group("dirt").size()
		
		if not broom_held:
			_glow_by_name("Broom")
		elif dirt_left > 0:
			for dirt in get_tree().get_nodes_in_group("dirt"):
				_set_task_target(dirt, true)
		else:
			_glow_by_name("Broom")

	# TASK 2: Mop & Puddles
	elif task == 2:
		var mop_held = mop_held_node and mop_held_node.visible
		var puddles_left = get_tree().get_nodes_in_group("puddles").size()
		
		if not mop_held:
			_glow_by_name("Mop")
		elif puddles_left > 0:
			for puddle in get_tree().get_nodes_in_group("puddles"):
				_set_task_target(puddle, true)
		else:
			_glow_by_name("Mop")

	# TASK 3: Crate, Cans, Shelf
	elif task == 3:
		var has_crate = Globals.get("has_crate")
		var crate_delivered = Globals.get("crate_delivered")
		var has_cans = Globals.get("has_cans")
		var cans_restocked = Globals.get("cans_restocked")

		if not crate_delivered:
			# Glows Crate and 'Take cans' location together so player knows where to drop it off
			if not has_crate:
				_glow_by_name("Take crate")
			_glow_by_name("Take cans")
		#elif not cans_restocked:
			#if not has_cans:
				#_glow_by_name("Take cans")
			#else:
				#_glow_by_name("Restock cans")

# Case-insensitive and space-trimmed string matching
func _glow_by_name(target_whoami: String) -> void:
	var target_clean = target_whoami.strip_edges().to_lower()
	for node in get_tree().get_nodes_in_group("interactables"):
		if is_instance_valid(node) and node.has_method("whoami"):
			if node.whoami().strip_edges().to_lower() == target_clean:
				_set_task_target(node, true)

func _set_task_target(node: Node, state: bool) -> void:
	if is_instance_valid(node) and node.has_method("set_task_target"):
		node.set_task_target(state)
