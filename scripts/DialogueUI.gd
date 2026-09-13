extends Control

signal babushka_dialogue_finished
signal policewoman_dialogue_finished

@export var dialogue_label: Label
@export var speaker_label: Label
@export var text_speed = 0.04

var dialogue_queue: Array[Dictionary] = []
var current_line_index: int = 0
var typewriter_tween: Tween

func _ready() -> void:
	hide()

func start_dialogue(lines: Array[Dictionary], _speaker: Node = null) -> void:
	dialogue_queue = lines
	current_line_index = 0
	show()
	_show_next_line()

func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_accept"):
		return

	get_viewport().set_input_as_handled()

	if typewriter_tween and typewriter_tween.is_running():
		typewriter_tween.kill()
		dialogue_label.visible_characters = -1
		return

	current_line_index += 1
	if current_line_index < dialogue_queue.size():
		_show_next_line()
	else:
		_end_dialogue()

func _show_next_line() -> void:
	var line_data = dialogue_queue[current_line_index]
	speaker_label.text = line_data.get("speaker", "")
	dialogue_label.text = line_data.get("text", "")
	dialogue_label.visible_characters = 0

	var duration = dialogue_label.text.length() * text_speed
	
	if typewriter_tween:
		typewriter_tween.kill()

	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_label, "visible_characters", dialogue_label.text.length(), duration)

func _end_dialogue() -> void:
	hide()
	if Globals.can_talk_babushka:
		babushka_dialogue_finished.emit()
	elif Globals.can_talk_policewoman:
		policewoman_dialogue_finished.emit()
	
	
func _start_policewoman_dialogue(npc_node: Node3D = null) -> void:
	if self.has_method("start_dialogue"):
		var dialogue: Array[Dictionary] = [
			{"speaker": "Officer", "text": "God, it's pouring. You can barely see ten feet past the pumps out there."},
			{"speaker": "You", "text": "Yeah... wipers on my car barely made it here."},
			{"speaker": "Officer", "text": "Keep the doors locked tight once three o'clock hits. Bad weather brings out the weird ones."}
		]
		start_dialogue(dialogue, npc_node)

func _start_babushka_dialogue(npc_node: Node3D = null) -> void:
	if self.has_method("start_dialogue"):
		var dialogue: Array[Dictionary] = [
			{"speaker": "Old Woman", "text": "They always send the quiet ones on the graveyard shift."},
			{"speaker": "You", "text": "I didn't really have a choice tonight, ma'am."},
			{"speaker": "Old Woman", "text": "...Check the latches on the stockroom. The wind out here opens things that ought to stay shut."}
		]
		start_dialogue(dialogue, npc_node)
