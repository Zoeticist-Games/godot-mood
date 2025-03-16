@icon("res://addons/mood/icons/script.svg")

extends MoodScript

@export var modulate_target: Node

# Fill this out for what code you want to run when the machine enters this mood.
func _enter_mood(_previous_mood: Mood) -> void:
	target.modulate = Color("#ff3333ff")


# Fill this out for what code you want to run when the machine exits this mood.
func _exit_mood(_next_mood: Mood) -> void:
	target.modulate = Color("#ffffffff")
