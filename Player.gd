extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var footstep_player := $Feet

@export var footstep_sounds: Array[AudioStream]

const SPEED = 2.0
const FOOTSTEP_INTERVAL := 1.3 / SPEED
const FOOT_OFFSET_X := 0.3 

var is_left_foot := true
var footstep_timer := 0.0
var current_footstep_index := 0

var inmenu = true



func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$"../Map/Sketchfab_model/Gas_station_fbx/RootNode/Lamp_018/SpotLight3D/Flicker".play("Flicker")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		

			

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Globals.playermoveallow and direction.length() > 0.1:
		footstep_timer += delta
		if footstep_timer >= FOOTSTEP_INTERVAL:
			play_footstep_sound()
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0

	if direction and Globals.playermoveallow:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func play_footstep_sound():
	if footstep_sounds.is_empty():
		return

	if current_footstep_index >= footstep_sounds.size():
		current_footstep_index = 0
		footstep_sounds.shuffle()
		
	footstep_player.stream = footstep_sounds[current_footstep_index]

	if is_left_foot:
		footstep_player.position.x = -FOOT_OFFSET_X
	else:
		footstep_player.position.x = FOOT_OFFSET_X
	
	footstep_player.play()

	current_footstep_index += 1
	is_left_foot = !is_left_foot
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()

		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Globals.playerlookallow:
		self.rotate_y(deg_to_rad(event.relative.x * Globals.mouse_sensitivity * -1))
		
		var camera_rot = neck.rotation_degrees
		var rotation_to_apply_on_x_axis = (-event.relative.y * Globals.mouse_sensitivity);

		camera_rot.x = clamp(camera_rot.x + rotation_to_apply_on_x_axis, -90, 70)
		neck.rotation_degrees = camera_rot
