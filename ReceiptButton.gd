extends TextureRect

@export var receipt_ui_path: NodePath
@export var hold_threshold: float = 0.15

@export_group("Buttons")
@export var button_1: Texture2D
@export var button_2: Texture2D 

@onready var hold_timer: Timer = $HoldTimer
var receipt_ui: CanvasLayer
var is_holding: bool = false
var touch_index: int = -1

var is_flashing: bool = false
var flash_time: float = 0.0

func _ready() -> void:
	# Hide by default until the first task arrives
	visible = false
	
	hold_timer.one_shot = true
	hold_timer.wait_time = hold_threshold
	if not hold_timer.timeout.is_connected(_on_hold_timeout):
		hold_timer.timeout.connect(_on_hold_timeout)
	
	if receipt_ui_path:
		receipt_ui = get_node_or_null(receipt_ui_path) as CanvasLayer

	if Globals.has_signal("TASKCHANGED"):
		if not Globals.TASKCHANGED.is_connected(_on_task_changed):
			Globals.TASKCHANGED.connect(_on_task_changed)

func _process(delta: float) -> void:
	# Flash icon if a new task arrives and hasn't been acknowledged
	if is_flashing and visible:
		flash_time += delta * 6.0 # Flash speed
		var alpha = (sin(flash_time) + 1.0) * 0.5 # Oscillates 0.0 -> 1.0
		modulate.a = lerp(0.3, 1.0, alpha)
	else:
		modulate.a = 1.0 # Solid once pressed

func _on_task_changed() -> void:
	# Reveal the button and start flashing when the first (or any new) task is given
	visible = true
	is_flashing = true
	flash_time = 0.0

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			_start_holding()
		elif not event.pressed and event.index == touch_index:
			_release_receipt()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_holding()
			else:
				_release_receipt()

func _start_holding() -> void:
	is_holding = true
	$".".texture = button_2
	is_flashing = false # Stop flashing when pressed (remains solid)
	hold_timer.start()

func _on_hold_timeout() -> void:
	if is_holding and receipt_ui:
		if receipt_ui.has_method("open_receipt"):
			receipt_ui.open_receipt()
		else:
			receipt_ui.visible = true

func _release_receipt() -> void:
	touch_index = -1
	$".".texture = button_1
	is_holding = false
	hold_timer.stop()
	
	if receipt_ui:
		if receipt_ui.has_method("close_receipt"):
			receipt_ui.close_receipt()
		else:
			receipt_ui.visible = false
