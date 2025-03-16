extends Control

@export var stamina_label: Label
@export var move_machine_label: Label
@export var sprint_machine_label: Label

func _on_move_machine_mood_changed(_previous_mood: Mood, current_mood: Mood) -> void:
	if is_instance_valid(move_machine_label):
		move_machine_label.text = current_mood.name


func _on_sprint_machine_mood_changed(_previous_mood: Mood, current_mood: Mood) -> void:
	if is_instance_valid(sprint_machine_label):
		sprint_machine_label.text = current_mood.name


func _on_player_stamina_changed(stamina: float) -> void:
	if is_instance_valid(stamina_label):
		stamina_label.text = "%0.2f" % stamina
