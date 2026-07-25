extends Node

var mouse_sensitivity = 0.1
var playermoveallow = true
var playerlookallow = true
var stationcar = false
var task_idx = 0
var player_keys: Array[String] = []

func calltime(time: float) -> Signal:
	var timer := Timer.new()
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.wait_time = time
	timer.one_shot = true
	
	timer.timeout.connect(timer.queue_free)
	
	add_child(timer)
	timer.start()
	
	return timer.timeout
