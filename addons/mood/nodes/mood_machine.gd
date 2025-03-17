@tool
@icon("res://addons/mood/icons/mood_robot.png")
class_name MoodMachine extends Node

## The Finite State Machine for the Mood Plugin.[br]
##
## The MoodMachine should only have [Mood] nodes as its children. Depending
## on how you configure it, the MoodMachine will continually evaluate the
## [Mood] children's [MoodCondition] children to determine which is the
## current valid mood, then enable processing, physics processing, input, and
## unhandled input for all children.[br]
## [br]
## In this way, the "current mood" will be processed as normal by the engine,
## while all other children are, essentially, paused.

#region Constants

## used for evaluating the process mode for mood selection.
enum ProcessMoodOn {
	## Process mood selection in [method _process].
	IDLE,
	## Process mood selection in [method _physics_process].
	PHYSICS,
	## Do not automatically processe mood selection. Use this when you expect to
	## explicitly assign [member current_mood] in your own subsystem.
	MANUAL
}

## When [member evaluate_moods_directly] is [code]false[/code], This enum is
## used to determine how the [member current_mood] should transition, if any
## [MoodTransition] children of the [member current_mood] are valid.
enum TransitionSelectionStrategy {
	## Select the first valid [MoodTransition]'s [member MoodTransition.to_mood].
	FIRST_VALID,
	## Select the first valid [MoodTransition]'s [member MoodTransition.to_mood]
	## that [b]is also[/b] not the [member previous_mood].
	FIRST_VALID_NON_PREVIOUS,
}

## When [member evaluate_moods_directly] is [code]false[/code], this enum is used
## to determine how to handle when there are no valid [member Mood.root_condition]s
## to transition to.
enum TransitionFallbackStrategy {
	## don't change the mood.
	KEEP_CURRENT_MOOD,
	## Go back to the initial mood.
	FALLBACK_TO_INITIAL,
	## Go back to the previous mood.
	FALLBACK_TO_PREVIOUS,
	## re-evaluate previous->current transition. If it's valid, keep
	## the current mood. Otherwise, go back to the initial mood.
	VALID_CURRENT_ELSE_INITIAL,
	## re-evaluate previous->current transition. If it's valid, keep
	## the current mood. Otherwise, go back to the previous mood.
	VALID_CURRENT_ELSE_PREVIOUS,
	## call the [member mood_fallback_script]'s [code]_find_next_mood[/code] method.
	DEFER_TO_CALLABLE
}

## When [member evaluate_moods_directly] is [code]true[/code], This enum is
## used to determine how the [member current_mood] should transition, if any
## immediate [Mood] children's [member Mood.root_condition] are valid.
enum MoodSelectionStrategy {
	## Select the first [Mood] with a valid [member Mood.root_condition].
	FIRST_VALID,
	## Select the first [Mood] with a valid [member Mood.root_condition]
	## that [b]is also[/b] not the [member current_mood].
	FIRST_VALID_NEW,
	## Select the first [Mood] with a valid [member Mood.root_condition]
	## that [b]is also[/b] not the [member previous_mood].
	FIRST_VALID_NON_PREVIOUS,
	## Select the first [Mood] with a valid [member Mood.root_condition]
	## that [b]is also[/b] not the [member current_mood] or the [member previous_mood.
	FIRST_VALID_NEW_NON_PREVIOUS,
}

## When [member evaluate_moods_directly] is [code]true[/code], this enum is used
## to determine how to handle when there are no valid [member Mood.root_condition]s
## amongst immediate [Mood] children.
enum MoodFallbackStrategy {
	## don't change the mood.
	KEEP_CURRENT_MOOD,
	## Go back to the initial mood.
	FALLBACK_TO_INITIAL,
	## Go back to the previous mood.
	FALLBACK_TO_PREVIOUS,
	## call the [member mood_fallback_script]'s [code]_find_next_mood[/code] method.
	DEFER_TO_CALLABLE
}
#endregion

#region Public Variables

## The mood to select when the machine is started, before any conditions are
## evaluated. When the first [Mood] child enters the tree under this Node,
## it is automatically assigned as the initial mood.
@export var initial_mood: Mood = null:
	set(value):
		if initial_mood == value:
			return

		if previous_mood == null:
			previous_mood = initial_mood

		initial_mood = value
		update_configuration_warnings()

## The main object the mood's component scripts will evaluated
## against. Because scripts cannot (currently) be evaluated in
## a dynamic context, the target is used as a reference for evaluating
@export var target: Node = null:
	set(value):
		if target == value:
			return

		target = value
		machine_target_changed.emit(target)
		update_configuration_warnings()

@export_category("Mood Selection Logic")

## Whether to evaluate changes to [member current_mood] automatically during
## [method _process] or [method _physics_process], or not at all.
@export var process_mood_on: ProcessMoodOn = ProcessMoodOn.IDLE:
	set(value):
		if process_mood_on == value:
			return

		process_mood_on = value

		set_process(value == ProcessMoodOn.IDLE)
		set_physics_process(value == ProcessMoodOn.PHYSICS)

## The Mood FSM system supports two mechanisms for automated [Mood] selection:[br]
## [br]
## 1. [b]Direct Evaluation[/b]: When this parameter is [code]true[/code], the
## MoodMachine runs the [member Mood.root_condition] for all immediate [Mood]
## children, use [member mood_selection_strategy] to determine the correct
## [Mood] amongst valid [Mood]s to transition to, and use [member mood_fallback_strategy]
## to handle when there are no valid [Mood]s.[br]
## 2. [b]Transition Evaluation[/b]: When this parameter is [code]false[/code],
## the MoodMachine will evaluate all immediate [MoodTransition] children of the
## [member current_mood], use [member transition_select_strategy] to determine
## the correct [Mood] amongst valid [Mood]s to transition to. There is no fallback
## handling.
@export var evaluate_moods_directly := false

## When [member evaluate_moods_directly] is [code]false[/code], this specifies the mechanism for
## transitioning between the [member current_mood] and a valid next [Mood].
@export var transition_selection_strategy: TransitionSelectionStrategy = TransitionSelectionStrategy.FIRST_VALID

## When [member evaluate_moods_directly] is [code]false[/code], what to do if there are
## no moods to transition to. See [enum TransitionFallbackStrategy]. 
@export var transition_fallback_strategy: TransitionFallbackStrategy = TransitionFallbackStrategy.KEEP_CURRENT_MOOD

## When [member evaluate_moods_directly] is true, this specifies the mechanism for
## identifying the correct
@export var mood_selection_strategy: MoodSelectionStrategy = MoodSelectionStrategy.FIRST_VALID

## See [enum MoodFallbackStrategy]. What strategy to use if no moods are considered valid.
@export var mood_fallback_strategy: MoodFallbackStrategy = MoodFallbackStrategy.KEEP_CURRENT_MOOD

## If the [member mood_fallback_strategy] is MoodFallbackStrategy.DEFER_TO_CALLABLE, this
## is required, and is the script that will be used.[br]
## The script must have this method signature:[br][br]
## 
## [code]_find_next_mood(machine: MoodMachine) -> Mood:[/code]
@export var mood_fallback_script: Script

## The current mood node reference.
var current_mood: Mood:
	get():
		if _current_mood == null:
			_current_mood = initial_mood

		return _current_mood

	## When we assign a new [Mood], either through automation or via direct assignment,
	##  the timeline of events is:[br]
	## 1. emit [signal mood_changing].[br]
	## 2. check to see if [member _block_change] has been set via [method keep_mood].
	## If it has, we reset [member _block_change] and do not update the current mood.[br]
	## 3. emit [Mood.mood_exited] on the [member previous_mood].[br]
	## 4. call [method Mood.disable] on the [member previous_mood].[br]
	## 5. assign the current mood to the new value.[br]
	## 6. emit [signal mood_changed].[br]
	## 7. emit [signal Mood.mood_entered] on the new current mood.[br]
	## 8. call [method Mood.enable] on the new current mood.
	set(value):
		# we must always have a mood.
		if value == null:
			return

		if _current_mood == value:
			return

		mood_changing.emit(_current_mood, value)

		if _block_change:
			_block_change = false
			return

		previous_mood = _current_mood

		if previous_mood:
			previous_mood.mood_exited.emit(current_mood)
			previous_mood.disable()

		_current_mood = value
		
		mood_changed.emit(previous_mood, _current_mood)

		value.mood_entered.emit(previous_mood)
		value.enable()

## The previous mood as a node reference.
var previous_mood: Mood = null

#endregion

#region Private Variables

## A cache of [member current_mood].
var _current_mood: Mood = null
## A flag, set via [method keep_mood], which can be used to interrupt an attempted change.[br]
## This feature will typically be triggered by handling [signal mood_changing].
var _block_change: bool = false
## A cache of [member target].
var _target: Node

#endregion

#region Signals

## signaled when the [member target] is changed, to ensure that changes to that
## value automatically propagate down to all [MoodMachineChild] children.
signal machine_target_changed(target: Node)

## signaled when the mood changes, before the values are assigned.
signal mood_changing(current_mood: Mood, next_mood: Mood)

## signaled when the mood has changed, after the new value has been assigned.
signal mood_changed(previous_mood: Mood, current_mood: Mood)

#endregion

#region Overrides

## When the machine is ready, it will call [code]_mood_machine_ready[/code]
## on all children which define that method. Note that this occurs regardless of
## the [member current_mood].
func _ready() -> void:
	if target == null:
		target = get_parent()

	for node: Node in get_children():
		if node is Mood:
			if (node as Mood) == current_mood:
				(node as Mood).enable()
			else:
				(node as Mood).disable()

	Mood.Recursion.recurse(self, "_mood_machine_ready")

## [member initial_mood] and [member target] are revertable as they have well-defined
## defaults: the first immediate [Mood] child for the former, and the parent of
## the MoodMachine for the latter.
func _property_can_revert(property: StringName) -> bool:
	return property == &"initial_mood" || property == &"target"

## [member initial_mood] and [member target] are revertable as they have well-defined
## defaults: the first immediate [Mood] child for the former, and the parent of
## the [MoodMachine] for the latter.
func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"initial_mood":
			var children := get_children()
			var idx = children.find_custom(func(node): return node is Mood)
			if idx != -1:
				return children[idx]
			return null
		&"target":
			return get_parent()
		_:
			return null

## The following basic rules are eligible for warnings on a MoodMachine:[br]
## [br]
## 1. There must be at least one [Mood], which gets assigned to [member initial_mood].[br]
func _get_configuration_warnings() -> PackedStringArray:
	var transition_targets := {} as Dictionary[String, bool]
	var errors := [] as PackedStringArray

	if initial_mood == null:
		errors.append("You must have at least one Mood child to assign as initial mood.")

	return errors

## If [member process_mood_on] is [enum ProcessMoodOn.IDLE]
func _process(_delta) -> void:
	if process_mood_on != ProcessMoodOn.IDLE:
		return

	_calc_next_mood()

func _physics_process(_delta) -> void:
	if process_mood_on != ProcessMoodOn.PHYSICS:
		return

	_calc_next_mood()

#endregion

#region Public Methods

## Used by the Plugin to hide certain properties.
func should_skip_property(field: String) -> bool:
	match field:
		"transition_selection_strategy", "transition_fallback_strategy":
			return evaluate_moods_directly
		"mood_selection_strategy", "mood_fallback_strategy":
			return !evaluate_moods_directly
		"mood_fallback_script":
			if evaluate_moods_directly:
				return mood_fallback_strategy == MoodFallbackStrategy.DEFER_TO_CALLABLE
			else:
				return transition_fallback_strategy == TransitionFallbackStrategy.DEFER_TO_CALLABLE
		_:
			return false

## Return the current mood as a name.
func mood() -> String:
	return current_mood.name

## If an underlying script wants to stop a transition, it can call
## this method in response to the mood_changed signal.
func keep_mood() -> void:
	_block_change = true

## Change the current mood manually.
## @param mood [String, Mood] the mood to change to.
## @return [Error] OK if the node was found, 
func change_mood(mood: Variant) -> void:
	var target_mood: Mood

	if mood is Mood:
		target_mood = mood
	elif mood is String:
		target_mood = find_child(mood, false)

	if target_mood:
		current_mood = target_mood
	else:
		push_error("Attempted to go to mood %s but it is not a child mood of %s" % [mood, name])

#endregion

#region Private Methods

func _calc_next_mood() -> void:
	if Engine.is_editor_hint():
		return

	var next_mood: Mood
	if evaluate_moods_directly:
		next_mood = _find_next_valid_mood()
	else:
		next_mood = _find_mood_to_transition()

	if next_mood and next_mood != current_mood:
		change_mood(next_mood)

func _find_next_valid_mood() -> Mood:
	match mood_selection_strategy:
		MoodSelectionStrategy.FIRST_VALID:
			for node: Node in get_children():
				if node is not Mood:
					continue
				var mood: Mood = node as Mood
				if not is_instance_valid(mood.root_condition):
					continue
				if mood.root_condition.is_valid():
					return mood
		MoodSelectionStrategy.FIRST_VALID_NEW:
			for node: Node in get_children():
				if node is not Mood:
					continue
				var mood: Mood = node as Mood
				if not is_instance_valid(mood.root_condition):
					continue
				if mood == current_mood:
					continue
				if mood.root_condition.is_valid():
					return mood
		MoodSelectionStrategy.FIRST_VALID_NON_PREVIOUS:
			for node: Node in get_children():
				if node is not Mood:
					continue
				var mood: Mood = node as Mood
				if not is_instance_valid(mood.root_condition):
					continue
				if mood == previous_mood:
					continue
				if mood.root_condition.is_valid():
					return mood
		MoodSelectionStrategy.FIRST_VALID_NEW_NON_PREVIOUS:
			for node: Node in get_children():
				if node is not Mood:
					continue
				var mood: Mood = node as Mood
				if not is_instance_valid(mood.root_condition):
					continue
				if mood == previous_mood or mood == current_mood:
					continue
				if mood.root_condition.is_valid():
					return mood
	
	match mood_fallback_strategy:
		MoodFallbackStrategy.KEEP_CURRENT_MOOD:
			return current_mood
		MoodFallbackStrategy.FALLBACK_TO_INITIAL:
			return initial_mood
		MoodFallbackStrategy.FALLBACK_TO_PREVIOUS:
			if is_instance_valid(previous_mood):
				return previous_mood
			return initial_mood
		MoodFallbackStrategy.DEFER_TO_CALLABLE:
			if mood_fallback_script and mood_fallback_script.can_instantiate():
				var instance = Object.new()
				instance.set_script(mood_fallback_script)
				return instance._find_next_mood(self)

	return current_mood

## get the
func _find_mood_to_transition() -> Mood:
	# cast find_children result to proper typing
	var transitions: Array[MoodTransition]	
	for node: Node in current_mood.find_children("*", "MoodTransition", false):
		if node is MoodTransition:
			transitions.append(node as MoodTransition)

	match transition_selection_strategy:
		TransitionSelectionStrategy.FIRST_VALID:
			for transition: MoodTransition in transitions:
				if transition.is_valid():
					return transition.to_mood

		TransitionSelectionStrategy.FIRST_VALID_NON_PREVIOUS:
			for transition: MoodTransition in transitions:
				if transition.to_mood == previous_mood:
					continue

				if transition.is_valid():
					return transition.to_mood

	match transition_fallback_strategy:
		TransitionFallbackStrategy.KEEP_CURRENT_MOOD:
			return current_mood
		TransitionFallbackStrategy.FALLBACK_TO_INITIAL:
			return initial_mood
		TransitionFallbackStrategy.FALLBACK_TO_PREVIOUS:
			return previous_mood
		TransitionFallbackStrategy.VALID_CURRENT_ELSE_INITIAL:
			if is_instance_valid(previous_mood) and previous_mood != current_mood:
				for node: Node in previous_mood.get_children():
					if node is not MoodTransition:
						continue
					var transition := node as MoodTransition
					if transition.is_valid():
						break
					else:
						return initial_mood
		TransitionFallbackStrategy.VALID_CURRENT_ELSE_PREVIOUS:
			if is_instance_valid(previous_mood) and previous_mood != current_mood:
				for node: Node in previous_mood.get_children():
					if node is not MoodTransition:
						continue
					var transition := node as MoodTransition
					if transition.is_valid():
						break
					else:
						return previous_mood
		TransitionFallbackStrategy.DEFER_TO_CALLABLE:
			if mood_fallback_script and mood_fallback_script.can_instantiate():
				var instance = Object.new()
				instance.set_script(mood_fallback_script)
				return instance._find_next_mood(self)

	return current_mood

#endregion

#region Signal Hooks
