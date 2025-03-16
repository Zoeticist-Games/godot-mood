extends Area2D

@export var current_stamina: float = 100.0:
	set(val):
		if current_stamina == val:
			return

		if floor(val) != floor(current_stamina):
			stamina_changed.emit(val)

		current_stamina = val

		if current_stamina == 0:
			stamina_empty.emit()
		elif current_stamina == 100.0:
			stamina_full.emit()

@export var max_stamina := 100

@export var move_speed := 20
@export var sprint_speed := 50
@export_range(0, 60) var rage_time := 5.0

@export var sprint_machine: MoodMachine

signal stamina_changed(stamina: float)
signal stamina_full
signal stamina_empty
signal start_rage
signal end_rage

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_indent"): # tab key
		start_rage.emit()
		await get_tree().create_timer(rage_time).timeout
		end_rage.emit()
