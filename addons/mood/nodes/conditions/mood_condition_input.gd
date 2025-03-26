@tool
@icon("res://addons/mood/icons/mood_dpad.png")
class_name MoodConditionInput extends MoodCondition

## A condition that encapsulates validation of input state based on [InputMap] actions.[br]
## The most typical use case is to map a particular action (e.g. [code]ui_up[/code]) to
## a particular state (e.g. [code]MoveUp[/code]).[br][br]
## A very simple pseudo-structure Example:
## [codeblock]
## * MoodMachine -- configured with evaluate_moods_directly: true
##   * Mood: MoveUp
##     * MoodConditionInput:
##       -- actions: [ui_up]
##     * MoodScript: SetMoveDirection
##       -- direction: Up
##     * MoodScript: UpdatePosition
##   * repeat for Down, Left, and Right
## [/codeblock][br]
## [br]
## A more complex use-case might be triggering a specific state as a side-effect
## of another state while the button is held down and other conditions are met,
## such as a sprinting modifier while moving, with a post-release delay.[br]
## Example:[br]
## [codeblock]
## * MoodMachine: Movement -- configured with evaluate_moods_directly: false
##   * Mood: Standing
##     * MoodTransition: Sprinting
##       -- and_all_conditions: true
##       * MoodConditionIput:
##         -- actions: [ui_up, ui_down, ui_left, ui_right]
##       * MoodConditionIput:
##         -- actions: [sprinting]
##        * MoodConditionProperty:
##          -- property: target.energy
##          -- operator: GT
##          -- criteria: 0
##     * MoodTransition: Moving
##       -- actions: [ui_up, ui_down, ui_left, ui_right]
##   * Mood: Moving
##     * MoodTransition: Sprinting
##       -- and_all_conditions: true
##       * MoodConditionInput:
##         -- actions: [sprint]
##         -- rule_become_invalid_when: TIMEOUT_OR_RELEASE
##         -- rule_timeout_sec: 0.25 # adds a buffer after press+release to still move to sprint
##         -- rule_timeout_refresh_on_echo: true
##       * MoodCondition
##     * MoodScript: UpdatePosition
##   * Mood: Sprinting
##     * MoodTransition: Standing
##       * MoodConditionInput:
##         -- actions: [ui_up, ui_down, ui_left, ui_right]
##         -- invert_validity: true # move back to standing if we're not doing anything
##     * MoodTransition: Moving
##       -- and_all_conditions: false # any of these removes us from sprinting
##       * MoodConditionInput:
##         -- actions: [sprinting]
##         -- invert_validity: True
##       * MoodConditionProperty:
##         -- property: target.energy
##         -- operator: LTEQ
##         -- criteria: 0
##       * MoodConditionTimeout:
##         * time_sec: 0.5 #
##    * MoodScript: DrainStamina
##    * MoodScript: FlagSprinting
##    * MoodScript: UpdatePosition
## [/codeblock]

#region Constants

## The possible mechanisms by which this condition can become invalid.[br]
## * RELEASE -- when the actions are released or the mood is changed.[br]
## * MOOD_CHANGE -- when the mood is changed.[br]
## * TIMEOUT -- after a preset time or when the mood is changed.[br]
## * TIMEOUT_OR_RELEASE -- after a preset time, or when the actions are released,
##   or when the mood is changed.
enum InvalidTrigger {
	RELEASE,
	MOOD_CHANGE,
	TIMEOUT,
	TIMEOUT_OR_RELEASE
}

const Editor := preload("res://addons/mood/scenes/editors/components/mood_ui_condition.tscn")
const SubEditor := preload("res://addons/mood/scenes/editors/mood_ui_condition_input.tscn")

#endregion

#region Public Variables

## A list of InputMap actions that this state will be listening for to
## handle state changes.
@export var actions: Array[StringName] = []

## If true, then this condition will be considered valid until the actions
## are pressed, as per all the below rules.
@export var invert_validity := false

@export_group("Trigger Conditions", "trigger_")

## By default, inputs are processed and handled generically and globally,
## meaning that if you press [code]ui_accept[/code] then [b]all[/b]
## [code]MoodConditionInput[/code] nodes watching that action will flag it as
## being pressed. If this is set to [code]true[/code], though, it will only
## process the input if the parent [member MoodChild.mood] is the
## [member MoodMachine.current_mood].
@export var trigger_consider_only_if_current := false:
	set(val):
		trigger_consider_only_if_current = val
		property_list_changed.emit() # allow_echo_to_trigger hide/show

## Generally, an action will be flagged as pressed when the initial press occurs.
## However, if [member trigger_consider_only_if_current] is set, then a pressed button
## may [i]not[/i] trigger that tracking. This flag allows echo presses to trigger
## the pressed flag in that case.
@export var trigger_echo_counts_as_press := false

## If true, this condition is valid only when ALL actions are pressed/echoed,
## instead of ANY actions in the list.
@export var trigger_require_all_actions := false

@export_group("Rule Clearance", "clear_")

## If true, reset validity when entering the mood this condition belongs to.
@export var clear_on_mood_enter := false
## If true, reset validity when exiting the mood this condition belongs to.
@export var clear_on_mood_exit := false
## If true, reset validity when one or all actions are released. see
## [member clear_on_release_only_when_all_are_released] for more information.
@export var clear_on_action_release := true:
	set(val):
		clear_on_action_release = val
		property_list_changed.emit()
## If true, reset validity when timeout configuration applies.
@export var clear_on_timeout := false:
	set(val):
		clear_on_timeout = val
		property_list_changed.emit()
## If true, require no actions to be pressed to trigger action-release clearing.
## Otherwise, the release of any action will clear validity, [i]even if other
## actions are still pressed[/i].
@export var clear_on_release_only_when_all_are_released := true

@export_group("Timeout Clearance", "timeout_")
## If [member clear_on_timeout] is [code]true[/code], how many seconds
## until the rule clears.
@export_range(0.0, 20.0, 0.25, "or_greater") var timeout_timeout_seconds := 0.25
## If true, an action being echoed will reset the timeout timer.
@export var timeout_reset_on_action_echo := false
## If true, the timeout timer will be zeroed when an action is released, as per
## the [member clear_on_release_only_when_all_are_released] flag logic.
@export var timeout_clear_on_action_release := true

#endregion

#region Private Variables

var _valid := false
var _pressed_actions := []
var _timer: SceneTreeTimer

#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides

## Connect to the [InputTracker] action signals when ready.
func _ready() -> void:
	_valid = invert_validity

	if has_node(^"/root/InputTracker"): # singleton
		var it_autoload := get_node(^"/root/InputTracker")
		it_autoload.action_pressed.connect(_on_action_pressed)
		it_autoload.action_echoed.connect(_on_action_echoed)
		it_autoload.action_released.connect(_on_action_released)

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	if not has_node(^"/root/InputTracker"): # singleton
		return ["You must enable the Mood Plugin for this Condition to work. Please do so then reload."]
	return []

## Used by the Plugin to skip fields.
func should_skip_property(field: String) -> bool:
	if field == "actions":
		return true
	
	if field.begins_with("timeout_") and not clear_on_timeout:
		return true

	if field == "clear_on_release_only_when_all_are_released":
		return not (clear_on_action_release or (clear_on_timeout and timeout_clear_on_action_release))

	if field == "trigger_echo_counts_as_press" and not trigger_consider_only_if_current:
		return true
	
	return false

#endregion

#region Public Methods

## Return whether or not an input is valid. This must be
## overridden in a child class.
##
## @param cache [Dictionary] an optional cache used to avoid
##   recalculating values across many moods/conditions.
## @return Whether or not the input is valid.
func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

#endregion

#region Private Methods

## When we exit the mood this condition belongs to, we always set ourselves to
## invalid.
func _enter_mood(_next_mood: Mood) -> void:
	if clear_on_mood_enter:
		_valid = invert_validity

## When we exit the mood this condition belongs to, we always set ourselves to
## invalid.
func _exit_mood(_next_mood: Mood) -> void:
	if clear_on_mood_exit:
		_valid = invert_validity

#endregion

#region Signal Hooks

## When [signal InputTracker.action_pressed] is fired, we flag this condition as
## valid or invalid and set up any conditions needed to handle our invalidation
## trigger.
func _on_action_pressed(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	if trigger_consider_only_if_current and not mood.is_current_mood():
		return

	if action not in _pressed_actions:
		_pressed_actions.append(action)

	if !trigger_require_all_actions or _pressed_actions.size() == actions.size():
		_valid = !invert_validity

		if clear_on_timeout:
			if _timer == null or timeout_reset_on_action_echo:
				if _timer != null: # refreshing by killing
					_timer.timeout.disconnect(_on_timeout)
				_timer = get_tree().create_timer(timeout_timeout_seconds, false)
				_timer.timeout.connect(_on_timeout)

func _on_action_echoed(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	if trigger_consider_only_if_current:
		if not mood.is_current_mood():
			return

		if action not in _pressed_actions and trigger_echo_counts_as_press:
			_on_action_pressed(action, event) # treat this like initial press first.

	if action in _pressed_actions and _timer != null and timeout_reset_on_action_echo:
		_timer.timeout.disconnect(_on_timeout)
		_timer = get_tree().create_timer(timeout_timeout_seconds, false)

func _on_action_released(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	if action not in _pressed_actions:
		return

	if trigger_consider_only_if_current and not mood.is_current_mood():
		return

	_pressed_actions.erase(action)

	if clear_on_action_release:
		if (not clear_on_release_only_when_all_are_released) or _pressed_actions.is_empty():
			_valid = invert_validity

	if _timer != null and timeout_clear_on_action_release: # refreshing by killing
		if (not clear_on_release_only_when_all_are_released) or _pressed_actions.is_empty():
			_timer.timeout.disconnect(_on_timeout)
			_timer = null

func _on_timeout() -> void:
	_valid = invert_validity
