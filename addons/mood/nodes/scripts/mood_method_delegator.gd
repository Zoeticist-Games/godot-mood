@tool
class_name MoodMethodDelegator extends MoodScript

## A generic Mood Component which allows delegation of behavior to methods in the
## [member MoodMachineChild.target]'s script. This allows you to break the
## componentization pattern of [MoodScript] in favor of writing methods in classes.[br]
## I don't know why you would want to do that, but you do you.

#region Public Variables

# For performance purposes we don't evaluate the validity of these calls, so don't
# do anything stupid, okay? :)

## If set, in  [method _process] call this method on the target, passing in delta.
@export var process_method: String:
	set(value):
		process_method = value
		update_configuration_warnings()
## If set, in  [method _physics_process] call this method on the target, passing in delta.
@export var physics_process_method: String:
	set(value):
		physics_process_method = value
		update_configuration_warnings()
## If set, in  [method _input] call this method on the target, passing in event.
@export var input_method: String:
	set(value):
		input_method = value
		update_configuration_warnings()
## If set, in  [method _unhandled_input] call this method on the target, passing in event.
@export var unhandled_input_method: String:
	set(value):
		unhandled_input_method = value
		update_configuration_warnings()

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var errors: PackedStringArray = []

	for meth in [process_method, physics_process_method, input_method, unhandled_input_method]:
		if meth != "" and not target.has_method(meth):
			errors.push_back("%s does not respond to %s" % [target.name, meth])
	
	return errors

func _process(delta: float) -> void:
	if process_method:
		target.call(process_method, delta)

func _physics_process(delta: float) -> void:
	if physics_process_method:
		target.call(physics_process_method, delta)

func _input(event: InputEvent) -> void:
	if input_method:
		target.call(input_method, event)

func _unhandled_input(event: InputEvent) -> void:
	if unhandled_input_method:
		target.call(unhandled_input_method, event)

#endregion
