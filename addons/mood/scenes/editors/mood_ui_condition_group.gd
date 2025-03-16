@tool
extends VBoxContainer

#region Public Variables

@export var index_label: Label
@export var condition_type_option: OptionButton
@export var go_to_node_button: Button
@export var _was_removed := false

@export var remove_button: Button

@export var condition: MoodConditionGroup = null:
	set(val):
		if condition != null or condition == val: # write once
			return

		condition = val
		_connect_to_group()

#endregion

#region Private Variables

var _condition_children: Dictionary[String, Variant]

#endregion

#region Overrides

func _ready() -> void:
	if not is_instance_valid(condition_type_option):
		return

	_condition_children = LocalClassFunctions.get_class_tree_for("MoodCondition").get_flat_data("path")
	var i := 1
	for child_class in _condition_children:
		if child_class == "MoodCondition" or child_class == "MoodTransition":
			continue

		condition_type_option.add_item(child_class, i)
		condition_type_option.set_item_metadata(i, _condition_children[child_class])
		i += 1

#region Public Methods

func add_condition(condition: MoodCondition) -> Node:
	var cond_scene = Mood.Editors.get_editor(condition)
	if cond_scene:
		cond_scene.condition = condition
		%Conditions.add_child(cond_scene)

	return cond_scene

#endregion

#region Private Methods

func _create_condition(name_prefix: String, klass: Variant) -> void:
	var child_condition = klass.new()
	child_condition.name = "%s Condition %s" % [name_prefix, len(condition.get_conditions()) + 1]
	condition.add_child(child_condition)
	child_condition.owner = EditorInterface.get_edited_scene_root()
	add_condition(child_condition)
	condition.notify_property_list_changed()

func _connect_to_group() -> void:
	if condition == null:
		return

	index_label.text = condition.name
	%AndAllConditions.button_pressed = condition.and_all_conditions
	condition.renamed.connect(func(): index_label.text = condition.name)

	for cond: MoodCondition in condition.get_conditions():
		add_condition(cond)

#endregion

#region Signal Hooks

# @TODO - popup to pick condition type
func _on_add_condition_pressed() -> void:
	_create_condition("Property", MoodConditionProperty)

func _on_all_of_toggled(toggled_on: bool) -> void:
	condition.and_all_conditions = toggled_on

func _on_remove_group_pressed() -> void:
	_was_removed = true
	queue_free.call_deferred()

func _on_add_signal_condition_pressed() -> void:
	_create_condition("Signal", MoodConditionSignal)

func _on_add_group_condition_button_pressed() -> void:
	_create_condition("Group", MoodConditionGroup)

func _on_child_option_item_selected(index: int) -> void:
	if index == 0:
		return

	var selected_type := condition_type_option.get_item_text(index)
	var selected_script: String = condition_type_option.get_item_metadata(index)
	var new_condition_klass: Variant = load(selected_script)

	var re := RegEx.new()
	re.compile(r"(?<lc>[a-z])(?<uc>[A-Z])")
	selected_type = selected_type.replace("MoodCondition", "")
	selected_type = re.sub(selected_type, "$1 $2")

	_create_condition(selected_type, new_condition_klass)
	
	condition_type_option.select(0)

func _on_go_to_node_button_pressed() -> void:
	if is_instance_valid(condition):
		EditorInterface.inspect_object(condition)
