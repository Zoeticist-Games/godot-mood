@tool

## A generic class for handling all of the children of a finite state machine
## so that target state and process type/state changes are propagated down to
## any leaves, making it easy for us to avoid having to fetch values dynamically
## inside of looping (e.g. process) calls.
class_name MoodMachineChild extends Node

#region Public Variables

## The parent machine. This is lazily evaluated and cached in [member _machine].
## When it is assigned, it automatically integrates with the machine's
## [signal MoodMachine.machine_target_changed] signal to ensure consistency in
## [member MoodMachine.target] assignment relative to its children.
var machine: MoodMachine:
	get():
		if _machine == null:
			machine = Recursion.find_parent_recursively(self, MoodMachine)
		return _machine
	set(val):
		if _machine == val:
			return

		if _machine:
			if _machine.machine_target_changed.is_connected(_on_machine_target_changed):
				_machine.machine_target_changed.disconnect(_on_machine_target_changed)

		_machine = val

		if _machine:
			_machine.machine_target_changed.connect(_on_machine_target_changed)
			_target = _machine.target
		else:
			_target = null
		notify_property_list_changed()

## The referent for this script's operation, inherited from the parent Machine.
## see: [method MoodMachine.target]
var target: Node:
	get():
		if _target == null and is_instance_valid(machine):
			_target = machine.target
			notify_property_list_changed()
		return _target
	set(val):
		if _target == val:
			return
		_target = val
		notify_property_list_changed()

#endregion

#region Private Variables

# A cache of the parent machine.
var _machine: MoodMachine = null

# A cache of the target.
var _target: Node = null

#endregion

#region Private Methods

## [b]<OVERRIDABLE>[/b][br][br]
## Called by a [MoodMachine] once it is ready. Use it when a state needs to
## interact with one or more of its sibling states.
func _mood_machine_ready() -> void:
	pass

#endregion

#region Signal Hooks

func _on_machine_target_changed(new_target: Node) -> void:
	target = new_target
