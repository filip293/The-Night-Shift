extends Node3D

@export var max_travel_distance: float = 120.0
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0
@export var car_speed_min: float = 12.0
@export var car_speed_max: float = 18.0

@export var invert_forward: bool = false
@export var invert_wheel_spin: bool = false

var available_cars: Array[Node3D] = []
var active_cars: Array[Dictionary] = []
var spawn_timer: float = 0.0

func _ready() -> void:
	for child in get_children():
		if child is Node3D and child.name.begins_with("Car"):
			child.visible = false
			available_cars.append(child)
			
			var sound = child.get_node_or_null("DriveSound")
			if sound and sound is AudioStreamPlayer3D:
				sound.stop()
	
	spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

func _process(delta: float) -> void:
	if not Globals.stationcar:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_random_car()
			spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)
	
	for i in range(active_cars.size() - 1, -1, -1):
		var data = active_cars[i]
		var car: Node3D = data["node"]
		var sound = car.get_node_or_null("DriveSound") as AudioStreamPlayer3D
		
		data["current_speed"] = lerp(data["current_speed"], data["target_speed"], delta * 3.5)
		var speed: float = data["current_speed"]
		
		if speed > 0.01:
			data["distance"] += speed * delta
			var start_trans: Transform3D = data["start_transform"]
			
			var forward: Vector3 = start_trans.basis.z.normalized()
			if invert_forward:
				forward = -forward
			
			var time_sec: float = Time.get_ticks_msec() / 1000.0
			var sway: float = sin(time_sec * 1.2 + data["sway_seed"]) * 0.15
			var right_vec: Vector3 = start_trans.basis.x.normalized()
			
			car.global_position = start_trans.origin + (forward * data["distance"]) + (right_vec * sway)
			
			var steer_angle: float = cos(time_sec * 1.2 + data["sway_seed"]) * 0.02
			car.global_transform.basis = start_trans.basis.rotated(Vector3.UP, steer_angle)
			
			var spin_angle: float = (speed / 0.35) * delta
			rotate_car_wheels(car, -spin_angle if invert_wheel_spin else spin_angle)
			
			if sound:
				if not sound.playing:
					sound.play()
				sound.pitch_scale = lerp(0.7, 1.3, speed / data["target_speed"])
		elif sound and sound.playing:
			sound.stop()
		
		if data["distance"] >= max_travel_distance:
			recycle_car(data)

func spawn_random_car() -> void:
	if available_cars.is_empty():
		return
	
	var car = available_cars.pick_random()
	available_cars.erase(car)
	
	active_cars.append({
		"node": car,
		"start_transform": car.global_transform,
		"target_speed": randf_range(car_speed_min, car_speed_max),
		"current_speed": 0.0,
		"distance": 0.0,
		"sway_seed": randf() * 100.0
	})
	car.visible = true

func recycle_car(data: Dictionary) -> void:
	var car: Node3D = data["node"]
	car.visible = false
	
	var sound = car.get_node_or_null("DriveSound")
	if sound and sound is AudioStreamPlayer3D and sound.playing:
		sound.stop()
		
	car.global_transform = data["start_transform"]
	active_cars.erase(data)
	available_cars.append(car)

func rotate_car_wheels(node: Node, angle: float) -> void:
	for child in node.get_children():
		if "wheel" in child.name.to_lower() and child is Node3D:
			child.rotate_x(angle)
		if child.get_child_count() > 0:
			rotate_car_wheels(child, angle)
