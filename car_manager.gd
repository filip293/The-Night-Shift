extends Node

@onready var FirstCar: AnimationPlayer = $"../FirstCar/Animations"
@onready var SecondCar: AnimationPlayer = $"../SecondCar/Animations"
@onready var FCBeep: AudioStreamPlayer3D = $"../FirstCar/PathFollow3D/suv/BeepBeep"
@onready var SCBeep: AudioStreamPlayer3D = $"../SecondCar/PathFollow3D/suv/BeepBeep"

signal car1_done

func _ready() -> void:
	await Globals.calltime(20.0)
	Globals.stationcar = true
	await Globals.calltime(10.0)
	go_car1()
	await Globals.calltime(5.0)
	Globals.stationcar = false
	await car1_done
	
func go_car1() -> void:
	FirstCar.play("ENTER")
	await Globals.calltime(30.0) #make it annoying by repeating it all the time?
	FCBeep.play()
