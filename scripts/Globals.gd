extends Node

var mouse_sensitivity = 0.1
var playermoveallow = true
var playerlookallow = true
var stationcar = false
var task_idx: int = 0
var chk_task: int = 0

# --- Task 2: Trash ---
var has_trash_bag: bool = false
var trash_disposed: bool = false

# --- Task 4: Crate & Cans ---
var has_crate: bool = false
var crate_delivered: bool = false
var has_cans: bool = false
var cans_restocked: bool = false

var in_game: bool = false
var jumpscare_impending: bool = false
var player_keys: Array[String] = []
var earned_money: int = 0
var radio_playing: bool = true
var task_given: bool = false

var can_talk_policewoman: bool = false
var can_talk_babushka: bool = false
var is_in_dialogue: bool = false

signal TASKCHANGED

func _physics_process(delta: float) -> void:
	if chk_task != task_idx:
		TASKCHANGED.emit()
		print("Task changed!")
	chk_task = task_idx
	
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()
		
func calltime(time: float) -> Signal:
	var timer := Timer.new()
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = time
	timer.one_shot = true
	
	timer.timeout.connect(timer.queue_free)
	
	add_child(timer)
	timer.start()
	
	return timer.timeout
