@tool
@icon("res://addons/mood/icons/mood_checkbox.png")
class_name MoodConditionProperty extends MoodCondition

## A type of condition that evaluates whether a property or method value on a
## given target evaluates a given criteria. This node is the bread-and-butter of
## condition selection.[br]
##[br]
## This can basically be considered an evaluation that looks like:[br]
##[br]
##[codeblock]
## [property_target].[property] [operator] [criteria]
##[/codeblock]

#region Constants

## The PackedScene reference to the constant editor for this class.
const Editor := preload("res://addons/mood/scenes/editors/mood_ui_condition_property.tscn")

## The mechanism to compare the evaluated [member property] to the [member criteria].
enum Operator {
	## ==
	EQ = 0,
	## <
	LT = 1,
	## <=
	LTE = 2,
	## >
	GT = 3,
	## >=
	GTE = 4,
	## !=
	NOT = 5
}

#endregion

#region Public Variables

## The source of the property being evaluated. By default, this will be the same
## as the [member MoodMachineChild.target]
@export var property_target: Node:
	get():
		if _property_target == null:
			if is_instance_valid(target):
				_property_target = target

		return _property_target
	set(value):
		if _property_target == value:
			return

		_property_target = value
		notify_property_list_changed()

## The property or method on the [member property_target] whose value we will be
## evaluating.
@export var property := ""
## The mechanism for comapring the resolved [member property] to the [member criteria].
@export var comparator: Operator = Operator.EQ
## The value that we are comparing to the [member property] via the [member comparator].
## The criteria's type is limited.
@export var criteria: Variant = null
## If the type of the [member property] to compare against is a [Node], this flag
## should be set to true so that we can store only the node path and resolve it at runtime.
@export var is_node_path := false
## If the type of the [member property] to compare against is a [Node], since we store
## its value as a relative [NodePath] we need to know the root Node to path from.
@export var node_path_root: Node
## If this is true, the [member property] will be assumed to be a [Callable] which takes
## no parameters instead of a member. 
@export var is_callable := false

#endregion

#region Private Variables

## A cache of [member property_target].
var _property_target: Node

#endregion

#region Overrides

func _property_can_revert(property: StringName) -> bool:
	return property == &"property_target"

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"property_target":
			if is_instance_valid(target):
				return target
			return null
		_:
			return null

#endregion

#region Public Methods

## Used by the Plugin to skip fields which are represented in the [method get_editor] return.
func should_skip_property(field: String) -> bool:
	return field in ["property", "comparator", "criteria", "is_callable", "is_node_path", "node_path_root"]

## This condition is valid if the result of comparing the [member property_target]'s
## [member property] to the [member criteria] via the [member comparator] results in
## true.[br]
##[br]
## Example:[br]
## given the following configuration:[br]
## * [member property_target] is a [CharacterBody2D][br]
## * [member property] is [code]"is_on_floor"[/code][br]
## * [member is_callable] is [code]true[/code][br]
## * [member comparator] is [enum Operator.EQ][br]
## * [member criteria] is [code]true[/code][br]
##[br]
## then this node will be valid whenever the result of [method CharacterBody2D.is_on_floor] returns [code]true[/code].
func is_valid(cache: Dictionary = {}) -> bool:
	if property not in cache:
		if is_callable:
			if not property_target.has_method(property):
				push_error("Expected Node %s to respond to %s but it does not" % [property_target.name, property])
				return false
			cache[property] = property_target.call(property)
		else:
			if property not in property_target:
				push_error("Expected Property %s to be in Node %s but it was not" % [property, property_target.name])
				return false

			cache[property] = property_target.get(property)

	var input: Variant = cache[property]

	var resolved_criteria = criteria
	if is_node_path and node_path_root:
		resolved_criteria = node_path_root.get_node(criteria)

	match comparator:
		Operator.EQ:
			return input == resolved_criteria
		Operator.LT:
			return input < resolved_criteria
		Operator.LTE:
			return input <= resolved_criteria
		Operator.GT:
			return input > resolved_criteria
		Operator.GTE:
			return input >= resolved_criteria
		Operator.NOT:
			return input != resolved_criteria
	
	return false

#endregion

#region Signal Hooks
