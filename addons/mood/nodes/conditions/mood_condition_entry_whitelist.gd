@tool
@icon("res://addons/mood/icons/mood_frown.png")
class_name MoodConditionEntryWhitelist extends MoodCondition

## A [MoodCondition] which is considered valid if its parent [member MoodMachineChild.machine]'s
## [member MoodMachine.current_mood] is in this condition's whitelist. [br]
## [br]
## This condition should only be used when the [member MoodMachineChild.machine]'s
## [member MoodMachine.evaluate_moods_directly] is set to [code]true[/code]; when used
## as part of a [MoodTransition] tree, it makes no sense.

#region Public Variables

## When entering this mood, trigger _enter_mood on child scripts if the previous mood
## is in this list.
@export var allow_transition_from := [] as Array[Mood]

#endregion

#region Public Methods

## This condition is valid when the machine's current mood is in the [member allow_transition_from]
## whitelist.
func is_valid(cache: Dictionary = {}) -> bool:
	return machine.current_mood in allow_transition_from

#endregion
