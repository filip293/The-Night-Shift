extends Node2D



func _on_quit_pressed() -> void:
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
