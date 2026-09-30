extends Node2D

func ShowCredits() -> void:
	$"../InGame/CanvasLayer/CanvasLayer2/Crosshair".visible = false
	$Credits/ColorRect.visible = true
	$Credits/RichTextLabel.visible = true
	$Credits/Scroll.play("Scroll")
	$"../Player/Rain2".stop()
	$"../Map".queue_free()
	$"../Player/Feet".queue_free()
	$"../Player/30".stop()
	$"../Player/JumpscareAndDrone".stop()
	Globals.task_given = false
	$"../RandomCars/Car1/DriveSound".stop()
	$"../RandomCars/Car2/DriveSound".stop()
	$"../RandomCars/Car3/DriveSound".stop()
	$"../RandomCars/Car4/DriveSound".stop()
	$"../RandomCars/Car5/DriveSound".stop()
	$"../RandomCars/Car6/DriveSound".stop()
	$"../MobileUI".visible = false
