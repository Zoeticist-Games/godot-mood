@tool
class_name MoodChild extends MoodMachineChild

## An abstract base class for any child which is intended to operate within the
## context of a parent [Mood], or which is intended to operate only when a
## parent [Mood] is the [member MoodMachine.current_mood].

#region Public Variables

## The [Mood] parent node. It is assigned as a variable to avoid having to
## re-fetch the parent Mood whenever it is relevant.[br]
## When being set, if the class inheriting this one has [code]_enter_mood[/code]
## or [code]_exit_mood[/code] methods defined, they will be automatically
## connected to the [signal Mood.mood_entered] or [signal Mood.mood_exited]
## signals respectively.
var mood: Mood:
	get():
		if _mood == null:
			self.mood = Mood.Recursion.find_parent_recursively(self, Mood)
		return _mood
	set(value):
		if _mood == value:
			return

		if _mood:
			if has_method("_enter_mood"):
				var em := Callable(self, "_enter_mood")
				if _mood.mood_entered.is_connected(em):
					_mood.mood_entered.disconnect(em)
			if has_method("_exit_mood"):
				var em := Callable(self, "_exit_mood")
				if _mood.mood_exited.is_connected(em):
					_mood.mood_exited.disconnect(em)
		
		_mood = value

		if has_method("_enter_mood"):
			var em := Callable(self, "_enter_mood")
			if not _mood.mood_entered.is_connected(em):
				_mood.mood_entered.connect(em)
		if has_method("_exit_mood"):
			var em := Callable(self, "_exit_mood")
			if not _mood.mood_exited.is_connected(em):
				_mood.mood_exited.connect(em)

		# assign our processing status to match the mood's.
		set_process(_mood.is_processing())
		set_physics_process(_mood.is_physics_processing())
		set_process_input(_mood.is_processing_input())
		set_process_unhandled_input(_mood.is_processing_unhandled_input())

		update_configuration_warnings()

#endregion

#region Private Variables

## A cache of the [Mood] parent.
var _mood: Mood = null

#endregion

#region Overrides

## When we initiate, we always want to guarantee that _enter_mood and _exit_mood
## are triggered by signal appropriately.
func _ready() -> void:
	if not is_instance_valid(mood):
		return

	if has_method("_enter_mood"):
		var em := Callable(self, "_enter_mood")
		if not mood.mood_entered.is_connected(em):
			mood.mood_entered.connect(em)

	if has_method("_exit_mood"):
		var em := Callable(self, "_exit_mood")
		if not mood.mood_exited.is_connected(em):
			mood.mood_exited.connect(em)


#endregion
