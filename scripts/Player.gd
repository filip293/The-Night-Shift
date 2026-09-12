extends CharacterBody3D

@export_group("Movement & Physics")
@export var walk_speed: float = 3.0
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0

@export_group("AAA Camera Juice")
@export var head_bob_frequency: float = 1.7
@export var head_bob_amplitude: float = 0.04
@export var camera_roll_amount: float = 1.2

@export_group("Audio & References")
@export var footstep_sounds: Array[AudioStream]

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera
@onready var footstep_player: AudioStreamPlayer3D = $Feet

const FOOTSTEP_INTERVAL: float = 0.6
const FOOT_OFFSET_X: float = 0.25
const MAX_PITCH_RAD: float = deg_to_rad(85.0)

var is_left_foot: bool = true
var footstep_timer: float = 0.0
var current_footstep_index: int = 0
var bob_timer: float = 0.0
var default_cam_pos: Vector3

var current_horizontal_speed: float = 0.0
var current_strafe_x: float = 0.0
	
func _ready() -> void:
	add_to_group("player")
	if camera:
		default_cam_pos = camera.position
	floor_snap_length = 0.3
	floor_stop_on_slope = true
	floor_constant_speed = true

func _physics_process(delta: float) -> void:
	# 1. Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Input Direction (Calculated from Neck basis, NOT CharacterBody3D)
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	current_strafe_x = input_dir.x
	var target_h_vel := Vector3.ZERO

	if Globals.playermoveallow and input_dir != Vector2.ZERO:
		# Use neck's Y-rotation so body doesn't need to rotate
		var forward := -neck.global_transform.basis.z
		var right := neck.global_transform.basis.x
		var direction := (forward * -input_dir.y + right * input_dir.x)
		direction.y = 0.0
		direction = direction.normalized()
		target_h_vel = direction * walk_speed

	# 3. Smooth Acceleration
	var current_h_vel := Vector3(velocity.x, 0.0, velocity.z)
	var rate := acceleration if target_h_vel != Vector3.ZERO else deceleration
	var weight := 1.0 - exp(-rate * delta)
	
	current_h_vel = current_h_vel.lerp(target_h_vel, weight)
	velocity.x = current_h_vel.x
	velocity.z = current_h_vel.z

	move_and_slide()

	current_horizontal_speed = current_h_vel.length()

	# 4. Footsteps
	if is_on_floor() and current_horizontal_speed > 0.5 and Globals.playermoveallow:
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			play_footstep_sound()
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0

## Visuals run in _process() at uncapped monitor framerate
func _process(delta: float) -> void:
	if not camera:
		return

	# Head Bobbing
	if is_on_floor() and current_horizontal_speed > 0.5 and Globals.playermoveallow:
		bob_timer += delta * current_horizontal_speed * head_bob_frequency
		var bob_y := sin(bob_timer) * head_bob_amplitude
		var bob_x := cos(bob_timer * 0.5) * (head_bob_amplitude * 0.5)
		camera.position = default_cam_pos + Vector3(bob_x, bob_y, 0.0)
	else:
		var weight := 1.0 - exp(-10.0 * delta)
		camera.position = camera.position.lerp(default_cam_pos, weight)

	# Camera Roll
	_apply_camera_roll(delta, current_strafe_x)

func _apply_camera_roll(delta: float, strafe_x: float) -> void:
	var target_roll := deg_to_rad(-strafe_x * camera_roll_amount)
	var weight := 1.0 - exp(-8.0 * delta)
	camera.rotation.z = lerp_angle(camera.rotation.z, target_roll, weight)

func play_footstep_sound() -> void:
	if footstep_sounds.is_empty():
		return
	if current_footstep_index >= footstep_sounds.size():
		current_footstep_index = 0
		footstep_sounds.shuffle()
	footstep_player.stream = footstep_sounds[current_footstep_index]
	footstep_player.position.x = -FOOT_OFFSET_X if is_left_foot else FOOT_OFFSET_X
	footstep_player.pitch_scale = randf_range(0.92, 1.08)
	footstep_player.play()
	current_footstep_index += 1
	is_left_foot = not is_left_foot

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			get_tree().quit()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotate ONLY Neck and Camera (Never touch CharacterBody3D here!)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.playerlookallow:
		var sens := deg_to_rad(Globals.mouse_sensitivity)
		neck.rotate_y(-event.relative.x * sens)
		camera.rotation.x = clampf(camera.rotation.x - (event.relative.y * sens), -MAX_PITCH_RAD, MAX_PITCH_RAD)
