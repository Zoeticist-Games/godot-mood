@tool
extends VBoxContainer

static var TransitionContainer := preload("res://addons/mood/scenes/editors/mood_ui_transition_segment.tscn")

@export var mood: Mood:
	set(val):
		if mood != null or mood == val: # write once
			return

		mood = val
		_create_transition_container()
		
		notify_property_list_changed()
		update_configuration_warnings()

#region Public Methods

#endregion

#region Private Methods

func _create_transition_container() -> void:
	var moods := mood.machine.find_children("*", "Mood", false)
	
	var transition_dict := ({} as Dictionary[Mood, MoodTransition])

	# get existing transitions
	for transition: MoodTransition in mood.find_children("*", "MoodTransition", false):
		transition_dict[transition.to_mood] = transition

	for to_mood: Mood in moods:
		if mood == to_mood:
			continue

		var container = TransitionContainer.instantiate()
		container.from_mood = mood
		
		var existing_transition: MoodTransition = transition_dict.get(to_mood)
		if is_instance_valid(existing_transition):
			container.transition = existing_transition
		else:
			var new_transition = MoodTransition.new()
			new_transition.name = "%sTo%s" % [mood.name, to_mood.name]
			new_transition.to_mood = to_mood
			container.transition = new_transition

		%Transitions.add_child(container)

#endregion

#region Signal Hooks
