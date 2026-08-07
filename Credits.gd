extends Node2D

func ShowCredits() -> void:
	$Credits/ColorRect.visible = true
	$Credits/RichTextLabel.visible = true
	$Credits/Scroll.play("Scroll")
