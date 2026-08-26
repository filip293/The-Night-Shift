extends Node3D

@export var play_intro: bool = true
@onready var TitleScreen: Node = $"../TitleScreen"
@onready var Prologue: Node2D = $"Prologue"
@onready var IntroCamera: Camera3D = $Camera3D
@onready var IntroSpotLight: SpotLight3D = $SpotLight3D
@onready var MotoV3i: Node3D = $"moto-v3i"
@onready var GUI: Node2D = $GUI
@onready var VoiceAudioPlayer: AudioStreamPlayer3D = $"moto-v3i/Voice"
@onready var Player: CharacterBody3D = $"../Player"
@onready var Map: Node3D = $"../Map"

# Preload your boss voicelines here (or leave null if not recorded yet)
var voice_boss_1: AudioStream = preload("res://introAssets/boss_voicelines/voiceline1_degraded_5800Hz.wav")
var voice_boss_2a: AudioStream = preload("res://introAssets/boss_voicelines/voiceline2a_degraded_5800Hz.wav")
var voice_boss_2b: AudioStream = preload("res://introAssets/boss_voicelines/voiceline2b_degraded_5800Hz.wav")
var voice_boss_3: AudioStream = preload("res://introAssets/boss_voicelines/voiceline3_degraded_5800Hz.wav")
var voice_boss_4a: AudioStream = preload("res://introAssets/boss_voicelines/voiceline4a_degraded_5800Hz.wav")
var voice_boss_4b: AudioStream = preload("res://introAssets/boss_voicelines/voiceline4b_degraded_5800Hz.wav")
var voice_boss_5a: AudioStream = preload("res://introAssets/boss_voicelines/voiceline5a_degraded_5800Hz.wav")
var voice_boss_5b: AudioStream = preload("res://introAssets/boss_voicelines/voiceline5b_degraded_5800Hz.wav")
var voice_boss_final1: AudioStream = preload("res://introAssets/boss_voicelines/voicelinefinal1_degraded_5800Hz.wav")
var voice_boss_final2: AudioStream = preload("res://introAssets/boss_voicelines/voicelinefinal2_degraded_5800Hz.wav")

var choice
var index: int

var light_tween: Tween

func _ready() -> void:
	Player.process_mode = Node.PROCESS_MODE_DISABLED
	Map.process_mode = Node.PROCESS_MODE_DISABLED
	IntroCamera.make_current()
	
	await Globals.calltime(3.0)
		
	if play_intro:
		await Prologue.play()
		
		# 1. Ringing Sequence
		await Globals.calltime(5.0)
		MotoV3i.start_calling()
		await Globals.calltime(3.0)
		turn_on_light()
		await Globals.calltime(3.0)
		
		# 2. Answering the phone prompt
		GUI.show_choices("Pick the phone up?", ["Yes", "No"])
		var initial_choice = await GUI.choice_made
		
		if initial_choice[0] == 1: # Chose "No"
			GUI.show_choices("You're gonna get fired.", ["Fine..."])
			await GUI.choice_made

		# 3. Answer Call $\rightarrow$ Stop Ringing $\rightarrow$ Snap Open Phone
		MotoV3i.stop_calling()
		await MotoV3i.snap_open().finished
		await Globals.calltime(0.3)

		# =========================================================================
		# INTERACTIVE DIALOGUE
		# =========================================================================
		
		# --- BEAT 1: Boss asks if you're awake ---
		_boss_speak("Look who finally decided to pick up. Don't tell me you were actually asleep.", voice_boss_1)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)

		# --- BEAT 1 (Player Response): ---
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["It's my night off.", "I was doing something."])
		choice = await GUI.choice_made
		
		# --- BEAT 2: Boss explains the shift ---
		index = choice[0]
		if index == 0:
			_boss_speak("Well congratulations, your night off is cancelled.", voice_boss_2a)
		elif index == 1:
			_boss_speak("Doesn't matter. I need you at the gas station.", voice_boss_2b)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)

		_boss_speak("Kyle had some kind of nervous breakdown twenty minutes into his shift, he threw his name tag in the slushie machine, and bolted out the back.", voice_boss_3)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)
		
		# --- BEAT 3 (Player Response): ---
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["Not my problem.", "Why did he run out?"])
		choice = await GUI.choice_made
		
		# --- BEAT 4: Boss final demand ---
		index = choice[0]
		if index == 0:
			_boss_speak("Listen. I don't pay Kyle to run off whenever he wants to, and I certainly don't pay you to be a smug prick.", voice_boss_4a)
		elif index == 1:
			_boss_speak("Apparently he heard a noise in the vents. It was probably a racoon or the HVAC rattling.", voice_boss_4b)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)
		
		MotoV3i.set_talking(false)
		GUI.show_choices("You:", ["Will I get paid overtime for this?", "Can I just not show up?"])
		choice = await GUI.choice_made
		
		index = choice[0]
		if index == 0:
			_boss_speak("You wish. You'll get minimum wage and store credit.", voice_boss_5a)
		elif index == 1:
			_boss_speak("Then you're fired. Not yet though.", voice_boss_5b)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)
		
		_boss_speak("Sweep the aisles, throw away the garbage and clean the bathrooms. We also have a delivery coming tonight as well.", voice_boss_final1)
		await VoiceAudioPlayer.finished
		await Globals.calltime(0.7)
		
		_boss_speak("Get to the store. NOW.", voice_boss_final2)
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
		
		await turn_off_light()

		await Globals.calltime(3.0)
		# DO SOMETHING HERE?
	
	if TitleScreen:
		TitleScreen.start()
		GUI.visible = false
		visible = false

func _boss_speak(text: String, voice_clip: AudioStream) -> void:
	GUI.show_dialogue("Boss", text)
	
	if VoiceAudioPlayer and voice_clip:
		VoiceAudioPlayer.stream = voice_clip
		VoiceAudioPlayer.play()
		
	MotoV3i.set_talking(true)

func turn_on_light() -> void:
	light_tween = create_tween()
	light_tween.tween_property(IntroSpotLight, "light_energy", 1.1, 3.0)
	await light_tween.finished
	
func turn_off_light() -> void:
	light_tween = create_tween()
	light_tween.tween_property(IntroSpotLight, "light_energy", 0.0, 1.0)
	await light_tween.finished
