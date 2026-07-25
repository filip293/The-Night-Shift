extends Node

@onready var task_name: Label = $"../CanvasLayer/TaskName"

const TASKS: Array[String] = [
	"NO TASK ASSIGNED",
	"Sweep the aisles",
	"Clean the restroom",
	"Restock the beer cooler"
]

func _ready() -> void:
	task_name.text = TASKS[Globals.task_idx]

func next_task() -> void:
	Globals.task_idx =+ 1
	task_name.text = TASKS[Globals.task_idx]
