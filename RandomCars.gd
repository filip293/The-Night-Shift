extends Node3D

# Adjustable properties in the Inspector
@export var max_travel_distance: float = 120.0
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 6.0
@export var car_speed_min: float = 12.0
@export var car_speed_max: float = 18.0

# Prevents all cars from driving on the exact same center line
@export var max_lane_offset: float = 0.5 

# Toggles to easily correct direction in the Inspector if meshes are oriented differently
@export var invert_forward: bool = false
@export var invert_wheel_spin: bool = false

var cars: Array[Node3D] = []
var available_cars: Array[Node3D] = []

# List of active car data dictionaries
var active_cars: Array[Dictionary] = []
var spawn_timer: float = 0.0

func _ready() -> void:
	# Gathers all Car children (Car1, Car2, Car3, etc.)
	for child in get_children():
		if child is Node3D and child.name.begins_with("Car"):
			cars.append(child)
			child.visible = false # Keep hidden until spawned
			available_cars.append(child)
			
			# Ensure the driving sound is stopped on start
			var drive_sound = child.get_node_or_null("DriveSound")
			if drive_sound and drive_sound is AudioStreamPlayer3D:
				drive_sound.stop()
	
	reset_spawn_timer()

func _process(delta: float) -> void:
	# Reference your globals autoload directly
	var is_station_car_active: bool = Globals.stationcar

	# 1. Handle Spawning (only if the gas station event is NOT active)
	if is_station_car_active == false:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_random_car()
			reset_spawn_timer()
	
	# 2. Update Active Cars
	var finished_cars: Array[Dictionary] = []
	
	for car_data in active_cars:
		var car: Node3D = car_data["node"]
		var drive_sound = car.get_node_or_null("DriveSound") as AudioStreamPlayer3D
		
		# Cars always accelerate to their original target speed and finish passing, 
		# even if the station car event becomes active.
		var target_speed: float = car_data["target_speed"]
		car_data["current_speed"] = lerp(car_data["current_speed"], target_speed, delta * 3.5)
		
		var speed: float = car_data["current_speed"]
		
		if speed > 0.01:
			# Advance distance traveled
			car_data["distance"] += speed * delta
			
			var start_trans: Transform3D = car_data["start_transform"]
			
			# Forward movement vector
			var forward: Vector3 = start_trans.basis.z.normalized()
			if invert_forward:
				forward = -forward
			
			# Create a gentle sway (sinusoidal lateral drift) to look like human steering
			var time_sec: float = Time.get_ticks_msec() / 1000.0
			var sway_freq: float = 1.2
			var sway_amp: float = 0.15 # Max side-to-side drift offset in meters
			var sway: float = sin(time_sec * sway_freq + car_data["sway_seed"]) * sway_amp
			
			# Combine base lane offset and the active steering sway
			var lateral_offset: float = car_data["lane_offset"] + sway
			var right_vec: Vector3 = start_trans.basis.x.normalized()
			
			# Apply the new translation
			var target_pos: Vector3 = start_trans.origin + (forward * car_data["distance"]) + (right_vec * lateral_offset)
			car.global_position = target_pos
			
			# Turn/steer the car slightly in the direction of the lateral sway
			var steer_angle: float = cos(time_sec * sway_freq + car_data["sway_seed"]) * 0.02
			car.global_transform.basis = start_trans.basis.rotated(Vector3.UP, steer_angle)
			
			# Spin the wheels locally based on movement speed
			var spin_angle: float = (speed / 0.35) * delta
			if invert_wheel_spin:
				spin_angle = -spin_angle
				
			rotate_car_wheels(car, spin_angle)
			
			# Handle Engine Driving Audio
			if drive_sound:
				if not drive_sound.playing:
					drive_sound.play()
				
				# Dynamically adjust pitch based on acceleration for a more realistic engine hum
				var speed_ratio: float = speed / car_data["target_speed"]
				drive_sound.pitch_scale = lerp(0.7, 1.3, speed_ratio)
		else:
			if drive_sound and drive_sound.playing:
				drive_sound.stop()
		
		# Recycle the car if it has driven past the travel distance limit
		if car_data["distance"] >= max_travel_distance:
			finished_cars.append(car_data)
	
	# Clean up and return cars to pool
	for car_data in finished_cars:
		recycle_car(car_data)

func spawn_random_car() -> void:
	if available_cars.is_empty():
		return # No cars left in pool to send
	
	# Choose a random available car
	var idx: int = randi() % available_cars.size()
	var car: Node3D = available_cars[idx]
	available_cars.remove_at(idx)
	
	# Configure its starting properties
	var start_transform: Transform3D = car.global_transform
	var target_speed: float = randf_range(car_speed_min, car_speed_max)
	var lane_offset: float = randf_range(-max_lane_offset, max_lane_offset)
	var sway_seed: float = randf() * 100.0
	
	var car_data: Dictionary = {
		"node": car,
		"start_transform": start_transform,
		"target_speed": target_speed,
		"current_speed": 0.0, # Car starts from 0 and accelerates smoothly
		"distance": 0.0,
		"lane_offset": lane_offset,
		"sway_seed": sway_seed
	}
	
	active_cars.append(car_data)
	car.visible = true

func recycle_car(car_data: Dictionary) -> void:
	var car: Node3D = car_data["node"]
	car.visible = false
	
	# Ensure the sound stops immediately when the car is recycled
	var drive_sound = car.get_node_or_null("DriveSound")
	if drive_sound and drive_sound is AudioStreamPlayer3D and drive_sound.playing:
		drive_sound.stop()
		
	active_cars.erase(car_data)
	available_cars.append(car)
	# Reset local/global position back to its starting coordinate
	car.global_transform = car_data["start_transform"]

func reset_spawn_timer() -> void:
	spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

# Recursively scans the node and any nested sub-nodes for anything named "wheel"
func rotate_car_wheels(node: Node, angle: float) -> void:
	for child in node.get_children():
		if "wheel" in child.name.to_lower() and child is Node3D:
			# Rotates the wheel on its local X axis
			child.rotate_x(angle)
		
		# Recursively search deeper child branches (e.g. under the Steering group)
		if child.get_child_count() > 0:
			rotate_car_wheels(child, angle)
