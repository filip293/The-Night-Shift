extends RichTextLabel

@onready var label: RichTextLabel = $"."

var hour: int = 2
var minute: int = 0
var timer: float = 0.0

func _ready() -> void:
	_update()

func _process(delta: float) -> void:
	timer += delta
	if timer >= 10.0:
		timer -= 10.0
		minute += 1
		if minute >= 60:
			minute = 0
			hour = (hour + 1) % 24
		_update()

func _update() -> void:
	label.text = "%d:%02d AM" % [hour, minute]
