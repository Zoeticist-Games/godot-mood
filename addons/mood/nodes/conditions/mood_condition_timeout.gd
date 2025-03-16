@tool
@icon("res://addons/mood/icons/mood_hourglass.png")
class_name MoodConditionTimeout extends MoodCondition

## A condition which is valid based on a triggered timeout that begins when
## the parent mood is entered, so you can e.g. set up a condition that allows
## for transition to another node if an action is taken within N seconds of
## entry (if [member start_as_valid] is [code]true[/code]) or after N seconds
## (if [member start_as_valid] is [code]false[/code]).

#region Constants

const Editor := preload("res://addons/mood/scenes/editors/components/mood_ui_condition.tscn")
const SubEditor := preload("res://addons/mood/scenes/editors/mood_ui_condition_timeout.tscn")

## Controls how we treat validity relative to the timeout.
enum ValidationMode {
	## Become valid on mood entry, become invalid on mood exit or timeout.
	VALID_ON_ENTRY = 0,
	## Become valid on mood exit, become invalid on mood entry or timeout.
	VALID_ON_EXIT = 1,
	## Become valid on mood entry until timeout.
	VALID_ON_ENTRY_UNBOUND = 2,
	## Become valid on mood exit until timeout.
	VALID_ON_EXIT_UNBOUND = 3 
}

#region Public Variables

## How long between when this condition becomes valid and the timeout occurs. 
@export_range(0.0, 60.0, 1.0, "or_greater") var time_sec := 1.0
## Whether or not you want validity on mood entry or exit, and whether or not you want
## to invalidate on mood entry or exit (typically when [member MoodMachine.evaluate_nodes_directly]
## is [code]true[/code]) or only timeout (typically when false).
@export var validation_mode := ValidationMode.VALID_ON_ENTRY
## If this is set to [code]false[/code], then the condition is [i]always[/i] valid,
## [i]except[/i] for when the timeout is triggered on entry/exit as per [member validation_mode].
@export var trigger_sets_valid_to := true
## If using an UNBOUND validation mode, whether or not we want to reset the
## timer when re-triggering validity, or just leave it alone.
@export var reset_on_reentry := true

@export_group("Timer Settings")
## passthrough for [member SceneTree.create_timer] [param process_always].
@export var process_always := false
## passthrough for [member SceneTree.create_timer] [param process_in_physics].
@export var process_in_physics := false
## passthrough for [member SceneTree.create_timer] [param ignore_time_scale].
@export var ignore_time_scale := false

#endregion

#region Private Variables

var _timer: SceneTreeTimer
var _valid := false

#endregion

#region Overrides

## when we set up, _valid gets set up such that it can be triggered.
func _ready() -> void:
	_valid = !trigger_sets_valid_to

## Validity is reset when the parent mood is entered.
func _enter_mood(_previous_mood: Mood) -> void:
	match validation_mode:
		ValidationMode.VALID_ON_ENTRY, ValidationMode.VALID_ON_ENTRY_UNBOUND:
			_make_valid()
		ValidationMode.VALID_ON_EXIT:
			_on_timer_timeout()

## When we leave this mood, we are never valid.
func _exit_mood(_next_mood: Mood) -> void:
	match validation_mode:
		ValidationMode.VALID_ON_EXIT, ValidationMode.VALID_ON_EXIT_UNBOUND:
			_make_valid()
		ValidationMode.VALID_ON_ENTRY:
			_on_timer_timeout()

#endregion

#region Public Methods

func should_skip_property(field: String) -> bool:
	return field in ["time_sec", "validation_mode", "trigger_sets_valid_to", "reset_on_reentry"]

func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

#endregion

#region Private Methods

## Trigger the timer and set self as _valid.
func _make_valid() -> void:
	if is_instance_valid(_timer):
		if reset_on_reentry:
			_create_timer()
		else: # just to illustrate that if we have a timer but we're not re-entering, we just let it go.
			pass
	else:
		_create_timer()

func _create_timer() -> void:
	if is_instance_valid(_timer):
		_timer.timeout.disconnect(_on_timer_timeout)
		_timer = null
	_timer = get_tree().create_timer(time_sec, process_always, process_in_physics, ignore_time_scale)
	_timer.timeout.connect(_on_timer_timeout, CONNECT_ONE_SHOT)
	_valid = trigger_sets_valid_to

#endregion

#region Signal Hooks

## When we time out the timer we our never considered valid at that point.
func _on_timer_timeout() -> void:
	if is_instance_valid(_timer) and _timer.timeout.is_connected(_on_timer_timeout):
		_timer.timeout.disconnect(_on_timer_timeout)
	_timer = null
	_valid = !trigger_sets_valid_to
