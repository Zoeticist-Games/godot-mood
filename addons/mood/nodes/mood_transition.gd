@tool
@icon("res://addons/mood/icons/mood_arrow_right.png")
class_name MoodTransition extends MoodConditionGroup

## A class which represents the root of condition nodes to transition to a
## specific mood.

#region Public Variables

## The target [Mood] to transition to if all of this transition's conditions
## are true.
@export var to_mood: Mood:
	set(val):
		if to_mood == val:
			return
		
		to_mood = val
		notify_property_list_changed()
		update_configuration_warnings()

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var results := super()
	
	if !is_instance_of(get_parent(), Mood):
		results.append("The MoodTransition must be a child of a Mood.")

	if is_instance_valid(to_mood):
		if to_mood == get_parent():
			results.append("You cannot transition a mood to itself.")

		if to_mood.machine != (get_parent() as Mood).machine:
			results.append("The target mood must be in the same MoodMachine as this mood.")
	else:
		results.append("You must assign a 'To Mood' value.")
	
	return results

#endregion
