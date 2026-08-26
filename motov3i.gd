extends Node3D

var open_sound: AudioStream = preload("res://Sounds/open.mp3")
var close_sound: AudioStream = preload("res://Sounds/shut.mp3")

@export_group("Nodes")
@export var audio_player: AudioStreamPlayer3D
@export var screen_light: OmniLight3D
@export var hinge: Node3D

@export_group("Talking Wobble (Adjustable)")
@export var wobble_enabled: bool = true
@export var wobble_speed: float = 5.0          # How fast it rocks
@export var wobble_angle: float = 2.5          # Subtle tilt in degrees (lowered from 6.0)
@export var wobble_height: float = 0.008       # Subtle vertical bounce

@export_group("Vibration Settings")
@export var vibrate_intensity: float = 0.006
@export var vibrate_rot_intensity: float = 1.0

@export_group("Timing & Light Pulse")
@export var ring_duration: float = 1.4
@export var pause_duration: float = 1.6
@export var flash_energy: float = 1.8

@export_group("Hinge Settings")
@export var open_angle_x: float = -155.0
@export var flip_speed: float = 0.18

var is_calling: bool = false
var is_pulse_active: bool = false
var is_talking: bool = false
var pulse_timer: float = 0.0
var talk_timer: float = 0.0

var base_pos: Vector3
var base_rot: Vector3
var base_hinge_rot_x: float = 0.0

func _ready() -> void:
	base_pos = position
	base_rot = rotation_degrees
	
	if not audio_player and has_node("AudioStreamPlayer3D"):
		audio_player = $AudioStreamPlayer3D
	if not screen_light and has_node("Hinge/OmniLight3D"):
		screen_light = $Hinge/OmniLight3D
	if not hinge and has_node("Hinge"):
		hinge = $Hinge

	if hinge:
		base_hinge_rot_x = hinge.rotation_degrees.x

	if screen_light:
		screen_light.light_energy = 0.0

func _process(delta: float) -> void:
	# 1. Ringing Vibration
	if is_calling:
		pulse_timer += delta
		if is_pulse_active:
			position.x = base_pos.x + randf_range(-vibrate_intensity, vibrate_intensity)
			position.z = base_pos.z + randf_range(-vibrate_intensity, vibrate_intensity)
			rotation_degrees.y = base_rot.y + randf_range(-vibrate_rot_intensity, vibrate_rot_intensity)
			if pulse_timer >= ring_duration:
				_end_pulse()
		else:
			if pulse_timer >= pause_duration:
				_start_pulse()

	# 2. Subtle Talking Wobble
	if is_talking and wobble_enabled:
		talk_timer += delta * wobble_speed
		rotation_degrees.z = base_rot.z + sin(talk_timer) * wobble_angle
		position.y = base_pos.y + abs(sin(talk_timer * 1.5)) * wobble_height
	elif not is_calling:
		# Return cleanly to resting pose
		rotation_degrees.z = lerp(rotation_degrees.z, base_rot.z, delta * 12.0)
		position.y = lerp(position.y, base_pos.y, delta * 12.0)

func start_calling() -> void:
	is_calling = true
	_start_pulse()

func stop_calling() -> void:
	is_calling = false
	is_pulse_active = false
	position = base_pos
	rotation_degrees = base_rot
	
	if audio_player and audio_player.playing:
		audio_player.stop()

func snap_open() -> Tween:
	if not hinge:
		return null
	
	if audio_player and open_sound:
		audio_player.volume_db = -20.0
		audio_player.stream = open_sound
		audio_player.play()
		
	if screen_light:
		create_tween().tween_property(screen_light, "light_energy", 1.2, 0.15)
		
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(hinge, "rotation_degrees:x", open_angle_x, flip_speed)
	return tween

func snap_shut() -> Tween:
	if not hinge:
		return null
		
	is_talking = false
	
	if audio_player and close_sound:
		audio_player.volume_db = -20.0
		audio_player.stream = close_sound
		audio_player.play()
		
	if screen_light:
		create_tween().tween_property(screen_light, "light_energy", 0.0, 0.08)
		
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(hinge, "rotation_degrees:x", base_hinge_rot_x, 0.08)
	return tween

func set_talking(talking: bool) -> void:
	is_talking = talking
	if not talking:
		talk_timer = 0.0

func _start_pulse() -> void:
	is_pulse_active = true
	pulse_timer = 0.0
	if audio_player and not audio_player.playing:
		audio_player.play()
	if screen_light:
		create_tween().tween_property(screen_light, "light_energy", flash_energy, 0.08)

func _end_pulse() -> void:
	is_pulse_active = false
	pulse_timer = 0.0
	position = base_pos
	rotation_degrees = base_rot
	if screen_light:
		create_tween().tween_property(screen_light, "light_energy", 0.0, 0.2)
