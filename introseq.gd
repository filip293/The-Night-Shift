extends Node2D

@onready var Subtitles: RichTextLabel = $Control/RichTextLabel
@onready var ASP: AudioStreamPlayer = $ASP

signal finishedIntro
signal option_selected(option_idx: int) # Custom signal to handle choices

const BOSS_VOICELINES: Array[AudioStream] = [
	preload("res://Sounds/voiceline/v1.mp3"),
	preload("res://Sounds/voiceline/v2.mp3"),
	preload("res://Sounds/voiceline/v3.mp3"),
	preload("res://Sounds/voiceline/v4.mp3")
]

const SOUNDS: Array[AudioStream] = [
	preload("res://Sounds/ringtone.mp3"),
	preload("res://Sounds/call ended.mp3")
]

var is_ringing: bool = false

func _ready() -> void:
	$Control.visible = false
	$Control/HBoxContainer.visible = false
	Subtitles.bbcode_enabled = true
	
	# Connect our custom signal to button presses
	$Control/HBoxContainer/Button.pressed.connect(func(): option_selected.emit(1))
	$Control/HBoxContainer/Button2.pressed.connect(func(): option_selected.emit(2))
	
	# Connect the ASP finished signal to loop the ringtone automatically
	$ASP.finished.connect(_on_asp_finished)

func _on_asp_finished() -> void:
	# Automatically replay the ringtone if it finishes and the player hasn't picked up yet
	if is_ringing:
		$ASP.play()

func start() -> void:
	var decline_count = 0
	var call_answered = false
	var is_first_ring = true # Flag to track the first time the phone rings
	
	$Control.visible = true
	clear_subtitles()
	
	# Loop the ringing phase until the player answers
	while not call_answered:
		# Set up the buttons for the call choice
		$Control/HBoxContainer/Button.text = "Answer"
		$Control/HBoxContainer/Button2.text = "Decline"
		
		# Animate button fade-in ONLY the first time the call is received
		if is_first_ring:
			$Control/HBoxContainer.modulate.a = 0.0
			$Control/HBoxContainer.visible = true
			
			var tween = create_tween()
			tween.tween_property($Control/HBoxContainer, "modulate:a", 1.0, 0.6)
			is_first_ring = false
		else:
			$Control/HBoxContainer.modulate.a = 1.0
			$Control/HBoxContainer.visible = true
		
		# Start the ringtone loop
		$ASP.stream = SOUNDS[0]
		is_ringing = true
		$ASP.play()
		
		# Wait for the player to press either Answer (1) or Decline (2)
		var choice = await option_selected
		
		# Stop the ringing process immediately
		$Control/HBoxContainer.visible = false
		is_ringing = false
		$ASP.stop()
		
		if choice == 1:
			call_answered = true
		elif choice == 2:
			decline_count += 1
			
			# Second decline: Play disconnect sound for 1/4 duration, stop, wait, and close game
			if decline_count >= 2:
				$ASP.stream = SOUNDS[1]
				$ASP.play()
				await get_tree().create_timer($ASP.stream.get_length() / 4.0).timeout
				$ASP.stop()
				
				await get_tree().create_timer(2.0).timeout # Delay before closing
				get_tree().quit()
				return # Terminate the sequence
			
			# First decline: Play disconnect sound for 1/4 duration, stop, and wait in silence before ringing again
			$ASP.stream = SOUNDS[1]
			$ASP.play()
			await get_tree().create_timer($ASP.stream.get_length() / 4.0).timeout
			$ASP.stop() # Stops call-ended audio early
			
			await get_tree().create_timer(3.5).timeout # Pause in absolute silence

	# =========================================================================
	# DIALOGUE CONFIGURATION
	# =========================================================================
	# Parameters: (voiceline_idx, boss_text, require_response, opt1_text, opt2_text, show_options_delay)
	
	# Voiceline 0 (No response required)
	await play_voiceline_and_respond(0, "Did i wake you up?", false)
	await get_tree().create_timer(1.0).timeout
	
	# Voiceline 1 (Waits until he is completely finished talking before showing options)
	await play_voiceline_and_respond(
		1, 
		"The kid that was supposed to work tonight bailed on me", 
		true, 
		"Who bailed?", 
		"That sucks..."
	)
	await get_tree().create_timer(1.0).timeout
	
	# Voiceline 2 (Waits until he is completely finished talking before showing options)
	await play_voiceline_and_respond(
		2, 
		"I need you to get up and cover for him, youll be working the night shift", 
		true, 
		"On my way", 
		"Do I have to?"
	)
	await get_tree().create_timer(1.0).timeout
	
	# Voiceline 3 (Waits until he is completely finished talking before showing options)
	await play_voiceline_and_respond(
		3, 
		"I couldnt care less what youre up to, get to the store... NOW", 
		true, 
		"Fine", 
		"Ugh, okay"
	)
	
	# End Call Sound
	$ASP.stream = SOUNDS[1]
	$ASP.play()
	await get_tree().create_timer(3.0).timeout # Customize this duration as needed
	$ASP.stop()
	
	$Control.visible = false
	finishedIntro.emit()

# Plays the voiceline with subtitles, and optionally opens response choices
func play_voiceline_and_respond(
	voiceline_idx: int, 
	boss_text: String, 
	require_response: bool = true, 
	opt1: String = "Option 1", 
	opt2: String = "Option 2",
	show_options_delay: float = -1.0
) -> void:
	
	# 1. Start the voice line audio and display the subtitle
	$ASP.stream = BOSS_VOICELINES[voiceline_idx]
	$ASP.play()
	display_subtitle(boss_text, true)
	
	# If no response is needed, simply wait for the audio to finish and exit
	if not require_response:
		await $ASP.finished
		clear_subtitles()
		return
	
	# 2. Determine when to display response options
	if show_options_delay >= 0.0:
		# Wait for the specified amount of seconds before showing options
		if show_options_delay > 0.0:
			await get_tree().create_timer(show_options_delay).timeout
		
		# Set custom button texts and show them while audio is still playing
		$Control/HBoxContainer/Button.text = opt1
		$Control/HBoxContainer/Button2.text = opt2
		$Control/HBoxContainer.modulate.a = 1.0
		$Control/HBoxContainer.visible = true
		
		# Wait for selection
		var choice = await option_selected
		$Control/HBoxContainer.visible = false
		
		# Stop the boss's audio immediately since the player responded
		$ASP.stop()
		
		# Display your selected option and wait 2 seconds
		var chosen_text = opt1 if choice == 1 else opt2
		display_subtitle(chosen_text, false)
		await get_tree().create_timer(2.0).timeout
		clear_subtitles()
		
	else:
		# Default (-1.0): Wait for the audio to finish playing entirely
		await $ASP.finished
		clear_subtitles()
		
		# Set custom button texts and show them
		$Control/HBoxContainer/Button.text = opt1
		$Control/HBoxContainer/Button2.text = opt2
		$Control/HBoxContainer.modulate.a = 1.0
		$Control/HBoxContainer.visible = true
		
		# Wait for selection
		var choice = await option_selected
		$Control/HBoxContainer.visible = false
		
		# Display your selected option and wait 2 seconds
		var chosen_text = opt1 if choice == 1 else opt2
		display_subtitle(chosen_text, false)
		await get_tree().create_timer(2.0).timeout
		clear_subtitles()

func display_subtitle(text: String, is_boss: bool) -> void:
	if is_boss:
		# Boss dialogue uses the default font
		Subtitles.text = "[center]%s[/center]" % text
	else:
		# Kid dialogue dynamically uses your custom Dialogue Font via its UID
		Subtitles.text = "[center][font=\"uid://chybldblxruc2\"]%s[/font][/center]" % text

func clear_subtitles() -> void:
	Subtitles.text = ""
