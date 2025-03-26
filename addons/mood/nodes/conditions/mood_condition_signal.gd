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

## By default, when a signal is received, we treat this condition as valid.
## Setting this flag to [code]true[/code] inverts the relationship, so this
## condition is valid [i]until[/i] the signal is received.
@export var invert_validity := false

@export_group("Signal Flag Trigger Conditions", "trigger_")

## By default, inputs are processed and handled generically and globally,
## meaning that if you press [code]ui_accept[/code] then [b]all[/b]
## [code]MoodConditionInput[/code] nodes watching that action will flag it as
## being pressed. If this is set to [code]true[/code], though, it will only
## process the input if the parent [member MoodChild.mood] is the
## [member MoodMachine.current_mood].
@export var trigger_consider_only_if_current := false

## how many times one of the signals must be triggered before the flag is tripped.
@export var trigger_after_n_times := 1

## if set, when the flag would be set, delay the actual set until the
## timer ends.
@export var trigger_delay_timer: Timer

@export_group("Signal Flag Clearance", "clear_")

## If true, the received signal flag and count will be reset when this mood is
## exited.
@export var clear_on_mood_exit := true

## If true, the received signal flag and count will be reset when this mood is
## entered.
@export var clear_on_mood_enter := true

## If set to greater than [code]0[/code], the received signal flag and count
## will be reset after the signal is received this many times. This allows you
## to, for instance, provide "windows" based on trigger times, e.g. if [member trigger_after_n_times]
## is 5 and this is 10, then this condition is valid from the 5th time until the
## 10th time.
@export var clear_after_count := 0

## If set, start the timer when signal is received and clear when the timer is
## done.
@export var clear_after_signal_received_timer: Timer

## If set, start the timer when signal is received and clear when the timer is
## done.
@export var clear_after_signal_flag_set_timer: Timer

#endregion

#region Private Variables

var _valid := false
var _received_count := 0

#endregion

#region Overrides

func _ready() -> void:
	clear()

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

func _enter_mood(_previous_mood: Mood) -> void:
	if clear_on_mood_enter:
		clear()

func _exit_mood(_next_mood: Mood) -> void:
	if clear_on_mood_exit:
		clear()

#endregion

#region Public Methods

func clear() -> void:
	_valid = invert_validity
	_received_count = 0

## Used by the Plugin to skip fields which are represented in the [method get_editor] return.
func should_skip_property(field: String) -> bool:
	return field in ["signal_triggers"]

## Whether or not the condition is valid. Used for transitioning state.
func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

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
	if trigger_consider_only_if_current and not mood.is_current_mood():
		return

	_received_count += 1

	if clear_after_count > 0 and _received_count >= clear_after_count:
		clear()

	if _received_count >= trigger_after_n_times:
		if trigger_delay_timer:
			await _schedule_timer(trigger_delay_timer)

		# validity is set here!
		print(name, ": setting _valid to true")
		_valid = !invert_validity

		if clear_after_signal_flag_set_timer:
			await _schedule_timer(clear_after_signal_flag_set_timer)
			clear()

	if clear_after_signal_received_timer:
		await _schedule_timer(clear_after_signal_received_timer)
		clear()
