@tool
@icon("res://addons/mood/icons/mood_tree.png")
class_name MoodConditionGroup extends MoodCondition

## A [MoodCondition] used to group multiple conditions together.[br]
## The [member Mood.root_condition] must be a [MoodCondition].[br]
## [MoodTransition] is a special type of [MoodConditionGroup] used when
## [member MoodMachine.evaluate_moods_directly] is [code]false[/code].

#region Constants

const Editor: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_group.tscn")

#endregion

#region Public Variables

## If this is true, then the condition group evaluates to [code]true[/code] only if
## [b]all[/b] of the conditions evaluate to true (bitwise "AND"). Otherwise, the
## condition evaluates to true if [b]any[/b] of the conditions evaluate to true
## (bitwise "OR").
@export var and_all_conditions: bool = true

#endregion

#region Private Variables

## A cache of [MoodCondition] immediate children.
var _conditions := [] as Array[MoodCondition]

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var errors := []

	if get_conditions().is_empty():
		errors.append("You must have at least one child MoodCondition.")

	return errors

#endregion

#region Public Methods

## Used by the Plugin to skip fields.
func should_skip_property(field: String) -> bool:
	return field == "and_all_conditions"

## public getter for conditions.
func get_conditions() -> Array[MoodCondition]:
	if Engine.is_editor_hint(): # don't cache in-engine
		_conditions = []

	if _conditions.is_empty():
		for child: Node in get_children():
			if child is MoodCondition:
				_conditions.append(child as MoodCondition)

	return _conditions


## This condition is valid if:[br]
## [br]
## 1. [member and_all_conditions] is [code]true[/code] and [b]all[/b] of its immediate [MoodCondition]
## children are true; or[br]
## 2. [member and_all_conditions] is [code]false[/code] and [b]any one[/b] of its immediate [MoodCondition]
## children are true.
func is_valid(cache: Dictionary = {}) -> bool:
	if and_all_conditions:
		return get_conditions().all(func (cond): return cond.is_valid(cache))
	
	return get_conditions().any(func (cond): return cond.is_valid(cache))

#endregion
