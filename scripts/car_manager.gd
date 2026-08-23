extends Node

@onready var FirstCar: AnimationPlayer = $"../FirstCar/Animations"
@onready var SecondCar: AnimationPlayer = $"../SecondCar/Animations"
@onready var FCBeep: AudioStreamPlayer3D = $"../FirstCar/PathFollow3D/suv/BeepBeep"
@onready var SCBeep: AudioStreamPlayer3D = $"../SecondCar/PathFollow3D/suv/BeepBeep"

var first = true

func _process(delta: float) -> void:
	if Globals.in_game == true and first == true:
		first = false
		await Globals.calltime(50.0)
		Globals.stationcar = true
		await Globals.calltime(10.0)
		go_car1()
		await Globals.calltime(5.0)
		Globals.stationcar = false
		await Globals.calltime(120.0)
		Globals.stationcar = true
		await Globals.calltime(10.0)
		go_car2()
		await Globals.calltime(5.0)
		Globals.stationcar = false
	
func go_car1() -> void:
	FirstCar.play("ENTER")
	await Globals.calltime(40.0)
	FCBeep.play()

func go_car2() -> void:
	SecondCar.play("ENTER")
	await Globals.calltime(70.0)
	SCBeep.play()
