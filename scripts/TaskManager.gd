extends Node

const TASKS: Array[String] = [
	"NO TASK ASSIGNED",
	"Sweep the aisles",
	"Take out the trash",
	"Clean the restroom",
	"Restock the cans"
]

@onready var broom_held_node: Node = $"../../Player/Bwoom2"
@onready var mop_held_node: Node = $"../../Player/Bwooom"
@onready var budget_label: RichTextLabel = $"../CanvasLayer/CanvasLayer2/Budget"

func _ready() -> void:
	if not "task_idx" in Globals:
		Globals.task_idx = 1
		
	if Globals.has_signal("TASKCHANGED"):
		Globals.TASKCHANGED.connect(_on_task_changed)
		
	_update_task_ui()

func _process(_delta: float) -> void:
	_update_task_highlights()
	_update_budget_ui()

func next_task() -> void:
	if Globals.task_idx < TASKS.size() - 1:
		Globals.task_idx += 1
		_update_task_ui()

func _on_task_changed() -> void:
	_update_task_ui()

func _update_task_ui() -> void:
	if Globals.task_idx == 4 and Globals.task_given:
		var crate = get_node_or_null("../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Crate2")
		if crate:
			crate.visible = true
			var col = crate.get_node_or_null("CollisionShape3D")
			if col: col.disabled = false

func _update_budget_ui() -> void:
	if budget_label:
		budget_label.bbcode_enabled = true
		budget_label.text = "[font_size=32]$%d/[b]$500[/b][/font_size]" % Globals.earned_money

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
	if task == 1 and Globals.task_given:
		var broom_held = broom_held_node and broom_held_node.visible
		var dirt_left = get_tree().get_nodes_in_group("dirt").size()
		
		if not broom_held:
			_glow_by_name("Broom")
		elif dirt_left > 0:
			for dirt in get_tree().get_nodes_in_group("dirt"):
				_set_task_target(dirt, true)
		else:
			_glow_by_name("Broom")

	# TASK 2: Take out the trash
	elif task == 2 and Globals.task_given:
		var has_trash = Globals.get("has_trash_bag")
		if not has_trash:
			_glow_by_name("Trash bag")
		else:
			_glow_by_name("Trash can")

	# TASK 3: Mop & Puddles
	elif task == 3 and Globals.task_given:
		var mop_held = mop_held_node and mop_held_node.visible
		
		if not mop_held:
			_glow_by_name("Mop")

	# TASK 4: Crate, Cans, Shelf
	elif task == 4 and Globals.task_given:
		var has_crate = Globals.get("has_crate")
		var crate_delivered = Globals.get("crate_delivered")

		if not crate_delivered:
			if not has_crate:
				_glow_by_name("Take crate")
			_glow_by_name("Take cans")

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
