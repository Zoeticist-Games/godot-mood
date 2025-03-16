@tool
@icon("res://addons/mood/icons/mood.png")
class_name Mood extends MoodMachineChild

## A [Mood] is a representation of a State in a [MoodMachine], which is a Finite
## State Machine.[br]
##[br]
## When a [Mood] becomes the [member MoodMachine.current_mood], all of its child
## scripts will run _process/_physics_process/_input/_unhandled_input; this allows
## a mood to act as a sort of componentized functionality toggler, where you can
## easily identify "what is happening" in the system based on what the current
## mood of a machine is.[br]
##[br]
## All children of a [Mood] should inherit [MoodChild] to guarantee referential integrity.

#region Constants

const TransitionEditor = preload("res://addons/mood/scenes/editors/mood_ui_transitions_container.tscn")

# because the plugin "Mood" is also the node "Mood", we can put a bunch of constants here
# to use as namespacing. it clutters up the responsibility of the node a bit; just go with it.

#const Recursion := preload("res://addons/mood/autoloads/recursion.gd")

## A namespace for references to UI Editors for when the plugin is enabled.
class Editors: # for namespacing purposes
	static var registered_editors := {} as Dictionary[String, PackedScene]

	static func has_editor_by_path(path: String) -> bool:
		var obj: Object = load(path).new()
		return has_editor(obj)

	static func get_editor_by_path(path: String) -> CanvasItem:
		var obj: Node = load(path).new() as Node
		return get_editor(obj)

	static func has_editor(object: Object) -> bool:
		if object.has_method("get_editor"):
			return true
		
		var script: Script = object.get_script()
		if not script:
			return false

		var klass: String = script.get_global_name() as String

		return klass in registered_editors

	static func get_editor(object: Node) -> CanvasItem:
		if object.has_method("get_editor"):
			return object.call("get_editor")

		var script: Script = object.get_script()
		if not script:
			return null

		var klass: String = script.get_global_name() as String

		if klass in registered_editors:
			var editor: CanvasItem = registered_editors[klass].instantiate()

			if "condition" in editor:
				if object is MoodCondition:
					editor.condition = object
				elif "condition" in object:
					editor.condition = object.condition

			if "mood" in editor:
				if object is Mood:
					editor.mood = object
				elif "mood" in object:
					editor.mood = object.mood

			if "machine" in editor:
				if object is MoodMachine:
					editor.machine = object
				elif "machine" in object:
					editor.machine = object.machine

			return editor

		return null
		

	static func register_type(type_name: String, scene: PackedScene) -> void:
		registered_editors[type_name] = scene

#endregion

#region Signals

## Emitted [b]after[/b] this mood becomes the [member MoodMachine.current_mood].
## [param previous_mood]: the [member MoodMachine.current_mood] before this one.
signal mood_entered(previous_mood: Mood)

## Emitted when [member MoodMachine.current_mood] is changed, [b]before[/b].
## [param next_mood]: the [member MoodMachine.current_mood] that will become the current [Mood].
signal mood_exited(next_mood: Mood)

#endregion

#region Public Variables

## When [member MoodMachineChild.machine] has [member MoodMachine.evaluate_moods_directly]
## set to [code]true[/code], the root_condition represents the ingress to evaluating the
## validity of a Mood, and must be set.
@export var root_condition: MoodCondition

#endregion

#region Overrides

## When a Mood enters the tree, if the parent is a Machine and has no
## initial mood, we set the mood here.
##
## We also [method disable] the [Mood] on entry so that no functions
## run for itself or its children. It will be re-enabled when it becomes
## the current mood.
func _enter_tree() -> void:
	# note that calling `machine` here will dynamically find it.
	if is_instance_valid(machine) and machine.initial_mood == null:
		machine.initial_mood = self

	# by default we want to be disabled, so that the FSM can handle enabling.
	disable()

### The following basic rules are eligible for warnings on a MoodMachine:[br]
## [br]
## 1. If the [member MoodMachineChild.machine]'s [member MoodMachine.evaluate_moods_directly] is true,
## and [member MoodMachine.process_mood_on] is not [enum MoodMachine.ProcessMoodOn].MANUAL,
## this [Mood] must have [member root_condition] set.[br]
## 2. If the [member MoodMachineChild.machine]'s [member MoodMachine.evaluate_moods_directly] is false,
## and [member MoodMachine.process_mood_on] is not [enum MoodMachine.ProcessMoodOn].MANUAL,
## this [Mood] must have at least one immediate [MoodTransition] child.[br]
## 2. If the [member MoodMachineChild.machine]'s [member MoodMachine.evaluate_moods_directly] is false,
## and [member MoodMachine.process_mood_on] is not [enum MoodMachine.ProcessMoodOn].MANUAL,
## there should not be multiple immediate [MoodTransition] children with the same target.
func _get_configuration_warnings() -> PackedStringArray:
	var errors := []

	if not is_instance_valid(machine) or machine.process_mood_on == MoodMachine.ProcessMoodOn.MANUAL:
		return errors

	if machine.evaluate_moods_directly == true:
		if root_condition == null:
			errors.append("This mood's Machine is evaluating the state of Moods directly, but this mood does not have a root_condition.")
	else:
		var transition_targets := {} as Dictionary[Mood, bool]
		var has_transition := false

		for transition: MoodTransition in (find_children("*", "MoodTransition", false) as Array[MoodTransition]):
			has_transition = true # assign before bailing
			if not is_instance_valid(transition.to_mood):
				continue

			var transition_to := transition.to_mood
			if transition_targets.get(transition_to, false):
				errors.append("%s has multiple Transitions to it, behavior may be unexpected." % transition_to)
			else:
				transition_targets[transition_to] = true
		
		if transition_targets.size() == 0:
			errors.append("You should have at least one MoodTransition child, or you cannot transition out of this Mood.")

	return errors

#endregion

#region Public Methods

## Used by the Plugin to show the editor; there are two kinds dependent on the machine.
func get_editor() -> CanvasItem:
	var editor: CanvasItem

	if is_instance_valid(machine) and machine.evaluate_moods_directly:
		if is_instance_valid(root_condition):
			editor = Mood.Editors.get_editor(root_condition)
	else:
		editor = TransitionEditor.instantiate()
		editor.mood = self

	return editor


## Used by the Plugin to hide certain properties.
func should_skip_property(field: String) -> bool:
	if field == "root_condition":
		if is_instance_valid(machine) and not machine.evaluate_moods_directly:
			return true
			
	return false

## Whether or not this node is the [member MoodMachine.current_mood]
## of its [member MoodMachineChild.machine].
func is_current_mood() -> bool:
	return machine.current_mood == self

## Turn on processing for oneself and one's children. "Processing" refers to:[br]
## [br]
## * _process[br]
## * _physics_process[br]
## * _input[br]
## * _unhandled_input[br]
func enable() -> void:
	Recursion.recurse(self, "set_process", true)
	Recursion.recurse(self, "set_physics_process", true)
	Recursion.recurse(self, "set_process_input", true)
	Recursion.recurse(self, "set_process_unhandled_input", true)

## Turn off processing for oneself and one's children. "Processing" refers to:[br]
## [br]
## * _process[br]
## * _physics_process[br]
## * _input[br]
## * _unhandled_input[br]
func disable() -> void:
	Recursion.recurse(self, "set_process", false)
	Recursion.recurse(self, "set_physics_process", false)
	Recursion.recurse(self, "set_process_input", false)
	Recursion.recurse(self, "set_process_unhandled_input", false)

#endregion

#region Signal Hooks
