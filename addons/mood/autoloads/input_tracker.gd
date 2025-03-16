@tool
extends Node

## An Autoload which turns input events for action into signals and provides
## some simple wrappers for identifying the current state of the defined
## input actions.

#region Constants

## WAITING: this action has not been pressed or released.
##   All actions start in this state.
##   JUST_RELEASED actions go back to thi state after "mood/input/discard_release_delay_sec"
## JUST_PRESSED: Set during initial press.
## ECHOED: An echo event was received on or after the "mood/input/input_echo_delay_sec"
##   setting.
## JUST_RELEASED: A pressed or echoed action received a release event..
enum InputActionState {
	WAITING,
	JUST_PRESSED,
	ECHOED,
	JUST_RELEASED
}

#endregion

#region Signals

## Signalled when an action is pressed for the first time.
## Whether this uses exact_match or not is dependent on "mood/input/input_tracking_exact_match".
signal action_pressed(action: String, action_event: InputEvent)
## Signalled when a pressed action is echoed for the first time, on or after
## "mood/input/input_echo_delay_sec".
## Whether this uses exact_match or not is dependent on "mood/input/input_tracking_exact_match".
signal action_echoed(action: String, action_event: InputEvent)
## Signalled when a pressed or echoed action is released for the first time.
## Whether this uses exact_match or not is dependent on "mood/input/input_tracking_exact_match".
signal action_released(action: String, action_event: InputEvent)

#endregion

#region Private Variables

## the hash of action information to extract.
var _action_tracking := {}

#endregion

#region Overrides

## When an unhandled input is received, we will iterate through all available
## actions in the InputMap and update their state based on the event, as Godot
## does not provide a facility to return the specific action(s) that constitute
## the event.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_type():
		return

	# don't handle input events inside of the editor, that's silly!
	if Engine.is_editor_hint():
		return

	var now := Time.get_unix_time_from_system()
	var use_exact: bool = bool(ProjectSettings.get_setting("mood/input/input_tracking_exact_match", false))

	for action: StringName in InputMap.get_actions():
		if action not in _action_tracking:
			_action_tracking[action] = {
				"state": InputActionState.WAITING,
				"strength": 0.0,
				"since": now
			}

		var delta_since_last_time = now - _action_tracking[action]["since"]

		if event.is_action_pressed(action, false, use_exact): # just pressed
			_action_tracking[action]["state"] = InputActionState.JUST_PRESSED
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = event.get_action_strength(action, use_exact)
			action_pressed.emit(action, event)
		elif event.is_action_pressed(action, true, use_exact) and delta_since_last_time >= float(ProjectSettings.get_setting("mood/input/input_echo_delay_sec", 0.0)): # echo
			_action_tracking[action]["state"] = InputActionState.ECHOED
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = event.get_action_strength(action, use_exact)

			action_echoed.emit(action, event)
		if event.is_action_released(action, use_exact):
			_action_tracking[action]["state"] = InputActionState.JUST_RELEASED
			_action_tracking[action]["time_between_actions"] = delta_since_last_time
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = 0.0

			action_released.emit(action, event)
		elif _action_tracking[action]["state"] == InputActionState.JUST_RELEASED and delta_since_last_time >= float(ProjectSettings.get_setting("mood/input/discard_release_delay_sec", 0.0)):
			_action_tracking[action]["state"] = InputActionState.WAITING
			_action_tracking[action]["time_between_actions"] = delta_since_last_time
			_action_tracking[action]["strength"] = 0.0
			_action_tracking[action]["since"] = now

#endregion
