@icon("res://addons/mood/icons/script.svg")

extends MoodScript

@export var target_shape: Shape2D = CircleShape2D.new()

var _original_shape: Shape2D

# Fill this out for what code you want to run when the machine enters this mood.
func _enter_mood(previous_mood: Mood) -> void:
	_original_shape = (target as CollisionShape2D).shape
	(target as CollisionShape2D).shape = target_shape

# Fill this out for what code you want to run when the machine exits this mood.
func _exit_mood(next_mood: Mood) -> void:
	(target as CollisionShape2D).shape = _original_shape

# Fill this out for what code you want to run during idle processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _process(delta: float) -> void:
	pass

# Fill this out for what code you want to run during physics processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _physics_process(delta: float) -> void:
	pass
