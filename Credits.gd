extends Node2D

func ShowCredits() -> void:
	$Credits/ColorRect.visible = true
	$Credits/RichTextLabel.visible = true
	$Credits/Scroll.play("Scroll")
	$"../Player/Rain2".stop()
	$"../Map".queue_free()
	$"../Player/Feet".queue_free()
	
