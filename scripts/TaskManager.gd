extends Node

const TASKS: Array[String] = [
	"NO TASK ASSIGNED",
	"Sweep the aisles",
	"Clean the restroom",
	"Restock the cans"
]

func _ready() -> void:
	if not "task_idx" in Globals:
		Globals.task_idx = 1
	_update_task_ui()

func next_task() -> void:
	if Globals.task_idx < TASKS.size() - 1:
		Globals.task_idx += 1
		_update_task_ui()

func _update_task_ui() -> void:
	if Globals.task_idx == 3:
		$"../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Crate2".visible = true
		$"../../Map/Sketchfab_model/Gas_station_fbx/RootNode/Crate2/CollisionShape3D".disabled = false
