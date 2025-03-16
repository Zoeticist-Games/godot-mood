@icon("res://addons/mood/icons/script.svg")

extends MoodScript

@export var stamina_per_sec := 10.0
@export var drain := true

# Fill this out for what code you want to run during idle processing when the
# mood machine (AKA finite state machine) is in this current mood (AKA state).
func _process(delta: float) -> void:
	if ("current_stamina" not in target) or ("max_stamina" not in target):
		return

	var updated: float
	if drain:
		updated = target.current_stamina - (stamina_per_sec * delta)
	else:
		updated = target.current_stamina + (stamina_per_sec * delta)

	target.current_stamina = clamp(updated, 0, target.max_stamina)
