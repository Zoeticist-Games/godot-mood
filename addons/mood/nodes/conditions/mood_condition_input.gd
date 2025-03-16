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

@export_group("Condition Rules", "rule")
## If true, this condition is valid only when ALL actions are pressed/echoed, instead
## of ANY actions in the list.
@export var rule_all_actions: bool = true
## This condition becomes valid whenever the initial press occurs. It may become
## invalid in several ways:
## * InvalidTrigger.MOOD_CHANGE -- the rule is valid only until the mood changes.
## * InvalidTrigger.TIMEOUT -- the rule is valid until a timeout occurs.
## * InvalidTrigger.RELEASE -- the rule becomes invalid as soon as the action
##   (or actions if rule_all_actions is true) is released.
## * InvalidTrigger.TIMEOUT_OR_RELEASE -- TIMEOUT + RELEASE.
@export var rule_become_invalid_when := InvalidTrigger.RELEASE
## If [param rule_become_invalid_when] is InvalidTrigger.TIMEOUT, how many seconds
## until the rule becomes invalid again
@export_range(0.0, 20.0, 0.25, "or_greater") var rule_timeout_sec := 0.25
## If true and [param rule_become_invalid_when] is InvalidTrigger.TIMEOUT, echoes
## of the action(s) will refresh the timeout.
@export var rule_timeout_refresh_on_echo := false
## If true and [param rule_becomes_invalid_when] is InvalidTrigger.RELEASE or TIMEOUT_OR_RELEASE,
## the validity will only be cleared once all actions are released, instead of
## when any action is released.
@export var rule_only_invalid_when_all_released := false
## If true, the timeout timer will be cleared when any/all actions are released,
## as per rule_only_invalid_when_all_released
@export var rule_reset_timer_on_release := true

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
	if invert_validity:
		_valid = true
	InputTracker.action_pressed.connect(_on_action_pressed)
	InputTracker.action_echoed.connect(_on_action_echoed)
	InputTracker.action_released.connect(_on_action_released)

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
func _exit_mood(_next_mood: Mood) -> void:
	_valid = false

#endregion

#region Signal Hooks

## When [signal InputTracker.action_pressed] is fired, we flag this condition as
## valid or invalid and set up any conditions needed to handle our invalidation
## trigger.
func _on_action_pressed(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	if action not in _pressed_actions:
		_pressed_actions.append(action)

	if !rule_all_actions or _pressed_actions.size() == actions.size():
		_valid = !invert_validity
		if rule_become_invalid_when in [InvalidTrigger.TIMEOUT, InvalidTrigger.TIMEOUT_OR_RELEASE]:
			if _timer == null or rule_timeout_refresh_on_echo:
				if _timer != null: # refreshing by killing
					_timer.timeout.disconnect(_on_timeout)
				_timer = get_tree().create_timer(rule_timeout_sec, false)
				_timer.timeout.connect(_on_timeout)

func _on_action_echoed(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	if _timer != null and rule_timeout_refresh_on_echo:
		_timer.timeout.disconnect(_on_timeout)
		_timer = get_tree().create_timer(rule_timeout_sec, false)

func _on_action_released(action: String, event: InputEvent) -> void:
	if action not in actions:
		return

	_pressed_actions.erase(action)

	if _timer != null and rule_reset_timer_on_release: # refreshing by killing
		_timer.timeout.disconnect(_on_timeout)
		_timer = null

	if rule_become_invalid_when in [InvalidTrigger.RELEASE, InvalidTrigger.TIMEOUT_OR_RELEASE]:
		if !rule_only_invalid_when_all_released or _pressed_actions.is_empty():
			_valid = invert_validity

func _on_timeout() -> void:
	_valid = invert_validity
	_timer = null
