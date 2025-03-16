@icon("res://addons/mood/icons/script.svg")
# meta-name: Mood Script
# meta-description: A generic script class for moods, which are just Finite States.
# meta-default: true
# meta-space-indent: 4
# meta-icon: "res://addons/mood/icons/script.svg"

extends MoodScript

# Fill this out for what code you want to run when the machine enters this mood.
func _enter_mood(previous_mood: Mood) -> void:
	pass

# Fill this out for what code you want to run when the machine exits this mood.
func _exit_mood(next_mood: Mood) -> void:
	pass

# Fill this out for what code you want to run during idle processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _process(delta: float) -> void:
	pass

# Fill this out for what code you want to run during physics processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _physics_process(delta: float) -> void:
	pass
