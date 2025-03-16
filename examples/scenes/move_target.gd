@icon("res://addons/mood/icons/script.svg")

extends MoodScript

@export var speed_const := "move_speed"

# Fill this out for what code you want to run during physics processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _physics_process(delta: float) -> void:
	target.position += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized() * target.get(speed_const) * delta
