@tool
@icon("res://addons/mood/icons/mood_signal.png")
class_name MoodConditionSignal extends MoodCondition

## A condition which becomes valid when a signal from the
## [member signal_target] (defaulting to the machine target) is
## received.

#region Constants

## The PackedScene reference to the constant editor for this class.
const Editor := preload("res://addons/mood/scenes/editors/mood_ui_condition_signal.tscn")

#endregion

#region Public Variables

var _signal_target: Node
@export var signal_target: Node:
	get():
		if _signal_target == null:
			if is_instance_valid(target):
				signal_target = target
		return _signal_target
	set(value):
		if _signal_target == value:
			return
		
		if _signal_target:
			for trigger in signal_triggers:
				if !_signal_target.has_signal(trigger):
					continue

				if _signal_target.is_connected(trigger, _receive_signal):
					_signal_target.disconnect(trigger, _receive_signal)

		_signal_target = value
		_refresh_signals()

## A list of signals by name to associate with the
## signal target.
@export var signal_triggers: Array[String] = [] as Array[String]:
	set(value):
		if signal_triggers == value:
			return

		# clear triggers so we don't have hanging triggers
		if signal_target:
			for trigger in signal_triggers:
				if !_signal_target.has_signal(trigger):
					continue

				if signal_target.is_connected(trigger, _receive_signal):
					signal_target.disconnect(trigger, _receive_signal)

		signal_triggers = value
		_refresh_signals()

@export_group("Signal Flag Trigger Conditions", "trigger_")
## how many times one of the signals must be triggered before the flag is tripped.
@export var trigger_after_n_times := 1
## if set, when the flag would be set, delay the actual set until the
## timer ends.
@export var trigger_delay_timer: Timer

@export_group("Signal Flag Clearance", "clear_")
## If true, the received signal flag (when true) will be set to false
## once the transition occurs.
@export var clear_on_transition := true
## If set, the received signal flag (when true) will be set to false
## if the signal is received this many times, even if the machine
## has not yet transitioned to the condition's mood.
@export var clear_after_count := 0
## If set, start the timer when signal is received and clear
## when the timer is done.
@export var clear_after_signal_received_timer: Timer
## If set, start the timer when signal is received and clear
## when the timer is done.
@export var clear_after_signal_flag_set_timer: Timer

#endregion

#region Private Variables

var _received_signal := false
var _received_count := 0

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var res := []
	if _signal_target != null and len(signal_triggers) > 0:
		pass
	return res

func _property_can_revert(property: StringName) -> bool:
	return property == &"signal_target"

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"signal_target":
			if machine:
				return machine.target
			return null
		_:
			return null

func _exit_mood(_next_mood: Mood) -> void:
	if clear_on_transition:
		_received_signal = false

#endregion

#region Public Methods

## Used by the Plugin to skip fields which are represented in the [method get_editor] return.
func should_skip_property(field: String) -> bool:
	return field in ["signal_triggers"]


## Whether or not the condition is valid. Used for transitioning state.
func is_valid(cache: Dictionary = {}) -> bool:
	return _received_signal

#endregion

#region Private Methods

func _schedule_timer(timer: Timer) -> void:
	timer.start()
	await timer.timeout

## ensure that all configured signals are wired up correctly.
func _refresh_signals() -> void:
	if not is_instance_valid(signal_target):
		return

	for trigger in signal_triggers:
		if not signal_target.is_connected(trigger, _receive_signal):
			signal_target.connect(trigger, _receive_signal)

#endregion

#region Signal Hooks

func _receive_signal() -> void:
	_received_count += 1

	if clear_after_count > 0 and _received_count >= clear_after_count:
		_received_signal = false

	if _received_count >= trigger_after_n_times:
		if trigger_delay_timer:
			await _schedule_timer(trigger_delay_timer)

		_received_signal = true

		if clear_after_signal_flag_set_timer:
			await _schedule_timer(clear_after_signal_flag_set_timer)
			_received_signal = false

	if clear_after_signal_received_timer:
		await _schedule_timer(clear_after_signal_received_timer)
		_received_signal = false
