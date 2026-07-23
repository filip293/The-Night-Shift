extends AudioStreamPlayer3D

@export var sun_light: DirectionalLight3D

const NORMAL_COLOR: Color = Color("791fa9")
const NORMAL_ENERGY: float = 0.05

const FLASH_COLOR: Color = Color("791fa9") 
const FLASH_ENERGY: float = 3.5

# Flash timing parameters
const STRIKE_2_AUDIO_TIME: float = 9.0
const LIGHT_SPEED_DELAY: float = 2.5

func _ready() -> void:
	_reset_light()
	_schedule_next_strike()

func trigger_lightning() -> void:
	play(0.0)
	
	_flash_sequence()
	
	var flash_delay: float = max(0.0, STRIKE_2_AUDIO_TIME - LIGHT_SPEED_DELAY)
	get_tree().create_timer(flash_delay).timeout.connect(_flash_sequence)
	
	_schedule_next_strike()

func _flash_sequence() -> void:
	if not sun_light:
		push_warning("Lightning script needs a DirectionalLight3D assigned!")
		return
		
	var tween = create_tween()
	
	sun_light.light_color = Color.WHITE
	
	tween.tween_property(sun_light, "light_energy", FLASH_ENERGY, 0.02)
	
	tween.tween_property(sun_light, "light_energy", FLASH_ENERGY * 0.2, 0.04)

	tween.tween_property(sun_light, "light_energy", FLASH_ENERGY * 0.7, 0.03)

	tween.tween_property(sun_light, "light_energy", 0.0, 0.15)
	
	tween.tween_callback(func():
		sun_light.light_color = NORMAL_COLOR
		sun_light.light_energy = NORMAL_ENERGY
	)

func _schedule_next_strike() -> void:
	var random_wait_time: float = randf_range(10.0, 30.0)
	get_tree().create_timer(random_wait_time).timeout.connect(trigger_lightning)

func _reset_light() -> void:
	if sun_light:
		sun_light.light_color = NORMAL_COLOR
		sun_light.light_energy = NORMAL_ENERGY
