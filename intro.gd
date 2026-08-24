extends Node3D

@export var play_intro: bool = true
@onready var TitleScreen: Node = $"../TitleScreen"
@onready var IntroCamera: Camera3D = $Camera3D
@onready var IntroSpotLight: SpotLight3D = $SpotLight3D
@onready var MotoV3i: Node3D = $"moto-v3i"
@onready var GUI: Node2D = $GUI
@onready var VoiceAudioPlayer: AudioStreamPlayer3D = $"moto-v3i/Voice"
@onready var Player: CharacterBody3D = $"../Player"
@onready var Map: Node3D = $"../Map"

# Preload your boss voicelines here (or leave null if not recorded yet)
var voice_boss_1: AudioStream = preload("res://Sounds/voiceline/v1.mp3")
var voice_boss_2: AudioStream = preload("res://Sounds/voiceline/v2.mp3")
var voice_boss_3: AudioStream = preload("res://Sounds/voiceline/v3.mp3")
var voice_boss_4: AudioStream = preload("res://Sounds/voiceline/v4.mp3")

func _ready() -> void:
	Player.process_mode = Node.PROCESS_MODE_DISABLED
	Map.process_mode = Node.PROCESS_MODE_DISABLED
	IntroCamera.make_current()
	
	await Globals.calltime(3.0)
		
	if play_intro:
		# 1. Ringing Sequence
		await Globals.calltime(1.5)
		MotoV3i.start_calling()
		await Globals.calltime(2.0)
		
		# 2. Answering the phone prompt
		GUI.show_choices("Pick the phone up?", ["Yes", "No"])
		var initial_choice = await GUI.choice_made
		
		if initial_choice[0] == 1: # Chose "No"
			GUI.show_choices("It's your boss.", ["Fine..."])
			await GUI.choice_made

		# 3. Answer Call $\rightarrow$ Stop Ringing $\rightarrow$ Snap Open Phone
		MotoV3i.stop_calling()
		await MotoV3i.snap_open().finished
		await Globals.calltime(0.3)

		# =========================================================================
		# INTERACTIVE DIALOGUE
		# =========================================================================
		
		# --- BEAT 1: Boss asks if you're awake ---
		_boss_speak("Did I wake you up?", voice_boss_1)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)

		# --- BEAT 1 (Player Response): ---
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["Yes, you did.", "No. I was doing something."])
		await GUI.choice_made

		# --- BEAT 2: Boss explains the shift ---
		_boss_speak("The kid that was supposed to work tonight bailed on me.", voice_boss_2)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)

		# --- BEAT 2 (Player Response): ---
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["And?", "Let me guess..."])
		await GUI.choice_made
		
		# --- BEAT 3: Boss final demand ---
		_boss_speak("I need you to get up and cover for him. You'll be working the night shift.", voice_boss_3)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)
		
		# --- BEAT 3 (Player Response): ---
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["I have other plans.", "I'm straight up jorking it."])
		await GUI.choice_made
		
		# --- BEAT 4: Boss final demand ---
		_boss_speak("I couldn't care less what you're up to, get to the store... NOW!", voice_boss_4)
		await VoiceAudioPlayer.finished

		# =========================================================================
		# END OF CALL
		# =========================================================================
		
		# 4. Stop talking wobble, hide GUI
		MotoV3i.set_talking(false)
		GUI.hide_text()
		await Globals.calltime(0.2)

		# 5. Snap Phone Shut (plays shut.mp3)
		await MotoV3i.snap_shut().finished
		await Globals.calltime(0.4)

		# 6. Cut spotlight and hide Intro
		if IntroSpotLight:
			IntroSpotLight.visible = false
		visible = false

		# 7. Start Title Screen Menu
		await Globals.calltime(1.0)
	
	if TitleScreen:
		TitleScreen.start()
		GUI.visible = false

func _boss_speak(text: String, voice_clip: AudioStream) -> void:
	GUI.show_dialogue("Boss", text)
	
	if VoiceAudioPlayer and voice_clip:
		VoiceAudioPlayer.stream = voice_clip
		VoiceAudioPlayer.play()
		
	MotoV3i.set_talking(true)
