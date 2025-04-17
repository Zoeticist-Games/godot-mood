@tool
@icon("res://addons/mood/icons/mood_hourglass.png")
class_name MoodConditionTimeout extends MoodCondition

## A condition which is valid based on a triggered timeout that begins when
## the parent mood is entered, so you can e.g. set up a condition that allows
## for transition to another node if an action is taken within N seconds of
## entry (if [member start_as_valid] is [code]true[/code]) or after N seconds
## (if [member start_as_valid] is [code]false[/code]).

#region Constants

#const Editor := preload("res://addons/mood/scenes/editors/components/mood_ui_condition.tscn")
#const SubEditor := preload("res://addons/mood/scenes/editors/mood_ui_condition_timeout.tscn")

#region Public Variables

## How long between when this condition becomes valid and the timeout occurs.
@export_range(0.0, 60.0, 1.0, "or_greater") var time_sec := 1.0

## By default, this rule is considered [b]invalid[/b] until the timer
## times out. Setting this flag inverts that, such that the condition begins
## as valid and the trigger sets it as invalid.
@export var invert_validity := false

## By default, if the [member clear_valid_on_mood_enter] flag is set,
## the timer will be removed when entering the mood, and if the
## [member clear_valid_on_mood_exit] flag is set, the timer will be removed
## when exiting the mood. If this flag is true, however, the timer
## will persist despite validity clearance.
@export var persist_timer := false

@export_group("On Mood Entry", "on_mood_entry_")
## If this is true, any persisted timers (due to lack of clearance
## or due to [member persist_timer] being [code]true[/code]) will be
## reset on mood entry.
@export var on_mood_entry_start_timer := true

## If true, reset validity when entering the mood this condition belongs to.
## if [member persist_timer] is [code]false[/code], [b]also[/b] remove the timer.
@export var on_mood_entry_clear_valid := true

## if [member start_timer_on_mood_entry] is [code]false[/code],
## [member persist_timer] is [code]true[/code], and
## [member clear_timer_on_mood_entry]  is false, you may want to still
## reset the timer if going out of and then back into the mood for this condition.
@export var on_mood_entry_reset_timer := false

@export_group("On Mood Exit", "on_mood_exit_")
## If this is true, any persisted timers (due to lack of clearance
## or due to [member persist_timer] being [code]true[/code]) will be
## reset on mood entry.
@export var on_mood_exit_start_timer := false

## If true, reset validity when entering the mood this condition belongs to.
## if [member persist_timer] is [code]false[/code], [b]also[/b] remove the timer.
@export var on_mood_exit_clear_valid := true

## if [member on_mood_exit_start_timer] is [code]false[/code],
## [member persist_timer] is [code]true[/code], and [member on_mood_exit_clear_valid]
## is [code]false[/code], you may want to still reset the timer if going out of and
## then back into the mood for this condition.
@export var on_mood_exit_reset_timer := false

@export_group("Timer Settings")
## passthrough for [member SceneTree.create_timer] [param process_always].
@export var process_always := false
## passthrough for [member SceneTree.create_timer] [param process_in_physics].
@export var process_in_physics := false
## passthrough for [member SceneTree.create_timer] [param ignore_time_scale].
@export var ignore_time_scale := false

## Get the [member SceneTreeTimer.time_left] as a reader.
var time_left: float:
	get():
		if not is_instance_valid(_timer):
			return 0.0

		return _timer.time_left

#endregion

#region Private Variables

var _timer: SceneTreeTimer
var _valid := false

#endregion

#region Overrides

## when we set up, _valid gets set up such that it can be triggered.
func _ready() -> void:
	super()

	_valid = invert_validity

## Validity is reset when the parent mood is entered.
func _enter_mood(_previous_mood: Mood) -> void:
	if on_mood_entry_clear_valid:
		_valid = invert_validity

	if is_instance_valid(_timer) and not persist_timer:
		_timer.timeout.disconnect(_on_timer_timeout)
		_timer = null

	if on_mood_entry_start_timer or (is_instance_valid(_timer) and on_mood_entry_reset_timer):
		start_timer()

func _exit_mood(_next_mood: Mood) -> void:
	if on_mood_exit_clear_valid:
		_valid = invert_validity
		if is_instance_valid(_timer) and not persist_timer:
			_timer.timeout.disconnect(_on_timer_timeout)
			_timer = null

	if on_mood_exit_start_timer or (is_instance_valid(_timer) and on_mood_exit_reset_timer):
		start_timer()

#endregion

#region Public Methods

func should_skip_property(field: String) -> bool:
	return false
	#return field in ["time_sec", "validation_mode", "trigger_sets_valid_to", "reset_on_reentry"]

func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

## Start the timer.
func start_timer() -> void:
	if is_instance_valid(_timer):
		_timer.timeout.disconnect(_on_timer_timeout)
		_timer = null
	_timer = get_tree().create_timer(time_sec, process_always, process_in_physics, ignore_time_scale)
	_timer.timeout.connect(_on_timer_timeout, CONNECT_ONE_SHOT)

#endregion

#region Private Methods

#endregion

#region Signal Hooks

## When we time out the timer we our never considered valid at that point.
func _on_timer_timeout() -> void:
	_valid = !invert_validity
	if is_instance_valid(_timer) and _timer.timeout.is_connected(_on_timer_timeout):
		_timer.timeout.disconnect(_on_timer_timeout)
	_timer = null
