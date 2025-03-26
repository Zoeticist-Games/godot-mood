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

var _rage_pre_exit := false
var _timer_started := false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_indent") and not _timer_started: # tab key
		start_rage.emit()
		_timer_started = true
		await get_tree().create_timer(rage_time).timeout
		_timer_started = false
		if _rage_pre_exit:
			_rage_pre_exit = false
		else:
			end_rage.emit()

func _on_raging_mood_exited(_next_mood: Mood) -> void:
	_timer_started = false
	_rage_pre_exit = true
