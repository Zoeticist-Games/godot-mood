@tool
extends VBoxContainer

#region Constants

## A list of GDScript types which can be selected in the UI.
const VALID_TYPES := [
	TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_OBJECT, TYPE_NODE_PATH
]
const METHOD_SELECTOR_SCENE := preload("res://addons/mood/scenes/editors/popups/mood_ui_method_selector.tscn")

const COLOR_SELECTED := Color(0x55F3E3FF)
const COLOR_DESELECTED := Color(0x7F7F7FFF)

#endregion

#region Public Variables

@export var index_label: Label
@export var remove_button: Button
@export var go_to_node_button: Button

@export var _was_removed := false

@export var condition: MoodConditionProperty:
	set(val):
		if condition == val:
			return

		if condition:
			condition.renamed.disconnect(_update_label)
			condition.property_list_changed.disconnect(_update_property_editor)

		condition = val
		index_label.text = condition.name
		condition.renamed.connect(_update_label)
		condition.property_list_changed.connect(_update_property_editor)

		if condition.property_target:
			_refresh_property_cache()

		#Returns this object's methods and their signatures as an Array of dictionaries. Each Dictionary contains the following entries:
#- name is the name of the method, as a String;
#- args is an Array of dictionaries representing the arguments;
#- default_args is the default arguments as an Array of variants;
#- flags is a combination of MethodFlags;
#- id is the method's internal identifier int;
#- return is the returned value, as a Dictionary;
#
#Note: The dictionaries of args and return are formatted identically to the results of get_property_list(), although not all entries are used.

		if is_node_ready():
			_update_property_editor()
		elif not ready.is_connected(_update_property_editor):
			ready.connect(_update_property_editor)

@onready var current_editor: Control = %PlaceholderEdit
@onready var editors: Array[Node] = %PropEditContainer.get_children()
@onready var enum_edit: OptionButton = %EnumEdit

#endregion

#region Private Variables

var _properties_by_name: Dictionary = {}
var _methods_by_name: Dictionary = {}
var _method_selector: AcceptDialog
var _valid_node_types := [] as Array[StringName]

#endregion


#region Private Functions

func _refresh_property_cache() -> void:
	_properties_by_name = {}
	var prop_list := condition.property_target.get_property_list()
	for prop in prop_list:
		_properties_by_name[prop["name"]] = prop

	_methods_by_name = {}
	var meth_list = condition.property_target.get_method_list()
	for meth in meth_list:
		if meth["return"]["type"] in VALID_TYPES and (len(meth["args"]) - len(meth["default_args"]) == 0):
			_methods_by_name[meth["name"]] = meth

func _on_method_selected(method: String) -> void:
	condition.property = method
	condition.is_callable = method != ""
	_update_property_editor()

## and we use the property to figure stuff out.
func _on_prop_selected(property_path: NodePath) -> void:
	condition.is_callable = false
	if property_path.is_empty():
		condition.property = ""
	else:
		var clean_name = property_path.get_subname(0) # ":property" -> "property"
		condition.property = clean_name
	_update_property_editor()

func _update_label() -> void:
	index_label.text = condition.name

func _update_property_editor() -> void:
	if condition.property == "":
		%PropertySelectorButton.text = "Choose Property"
		%MethodSelectorButton.text = "Choose Method"
		%SelectedProperty.text = "Select A Property..."
		%SelectedProperty.add_theme_color_override("font_color", COLOR_DESELECTED)
	else:
		if condition.is_callable:
			%PropertySelectorButton.text = "Change To Property"
			%MethodSelectorButton.text = "Change Method"
			%SelectedProperty.text = condition.property + "()"
		else:
			%PropertySelectorButton.text = "Change Property"
			%MethodSelectorButton.text = "Change To Method"
			%SelectedProperty.text = condition.property

		%SelectedProperty.add_theme_color_override("font_color", COLOR_SELECTED)

	%Condition.select(condition.comparator as int)

	if current_editor:
		current_editor.hide()

	var prop: Dictionary = {}
	if condition.is_callable:
		prop = _methods_by_name.get(condition.property, {}).get("return", {})
	else:
		prop = _properties_by_name.get(condition.property, {})

	match prop.get("type", null):
		TYPE_OBJECT:
			_valid_node_types = [prop["class_name"]]
			current_editor = %NodeEdit
			_on_node_edit_confirmed(condition.criteria)
		TYPE_NODE_PATH:
			_valid_node_types = prop["hint_string"].split(",")
			current_editor = %NodeEdit
			_on_node_edit_confirmed(condition.criteria)
		TYPE_BOOL:
			current_editor = %BoolEdit
			current_editor.button_pressed = !!condition.criteria
		TYPE_FLOAT, TYPE_INT:
			current_editor = %NumberEdit
			if condition.criteria:
				current_editor.text = "%s" % condition.criteria
			else:
				condition.criteria = 0
				current_editor.text = "0"
		TYPE_STRING, TYPE_STRING_NAME:
			match prop["hint"]:
				PROPERTY_HINT_ENUM, PROPERTY_HINT_ENUM_SUGGESTION:
					enum_edit.clear()
					var idx := 0
					var selected := -1
					# @TODO handle special value assignments
					for enum_val in prop["hint_string"].split(","):
						enum_edit.add_item(enum_val, idx)
						if condition.criteria == enum_val:
							selected = idx
						idx += 1

					current_editor = enum_edit
					enum_edit.select(selected)
				_:
					current_editor = %StringEdit
					if condition.criteria:
						current_editor.text = condition.criteria
					else:
						current_editor.text = ""
		_:
			current_editor = %PlaceholderEdit

	if current_editor:
		current_editor.show()

#endregion

#region Signal Hooks

## strips out non-numeric values for the number editor.
func _on_number_edit_text_changed(new_text: String) -> void:
	var re = RegEx.new()
	re.compile(r'[^0-9.-]')
	new_text = re.sub(new_text, "", true)
	%NumberEdit.text = new_text
	%NumberEdit.caret_column = len(new_text)
	
	if condition:
		if new_text.contains("."):
			condition.criteria = float(new_text)
		else:
			condition.criteria = int(new_text)

## User selects a property...
func _on_property_selector_button_pressed() -> void:
	EditorInterface.popup_property_selector(condition.property_target, _on_prop_selected, VALID_TYPES, condition.property)

func _on_method_selector_pressed() -> void:
	if _method_selector:
		_method_selector.queue_free()

	_method_selector = METHOD_SELECTOR_SCENE.instantiate()
	_method_selector.target_node = condition.property_target
	_method_selector.select_item_by_text(condition.property)
	_method_selector.on_method_selected.connect(_on_method_selected)
	_method_selector.popup_exclusive(EditorInterface.get_editor_main_screen())

func _on_condition_item_selected(index: int) -> void:
	if not condition:
		return
	
	condition.comparator = index

func _on_string_edit_text_changed(new_text: String) -> void:
	if condition:
		condition.criteria = new_text

func _on_enum_edit_item_selected(index: int) -> void:
	if condition:
		condition.criteria = enum_edit.get_item_text(index)

func _on_bool_edit_toggled(toggled_on: bool) -> void:
	if condition:
		condition.criteria = toggled_on

func _on_remove_condition_button_pressed() -> void:
	_was_removed = true
	condition.queue_free.call_deferred()
	queue_free.call_deferred()

func _on_node_edit_pressed() -> void:
	var selected: Node
	if condition.criteria and condition.node_path_root:
		selected = condition.node_path_root.get_node(condition.criteria) as Node
	else:
		selected = null
	EditorInterface.popup_node_selector(_on_node_edit_confirmed, _valid_node_types, selected)

func _on_node_edit_confirmed(node_path: NodePath) -> void:
	if node_path:
		var target_node := get_tree().edited_scene_root.get_node(node_path)
		if is_instance_valid(target_node):
			%SelectedNodeLabel.show()

			condition.criteria = node_path
			condition.is_node_path = true
			condition.node_path_root = get_tree().edited_scene_root

			var local_node_script = target_node.get_script()
			var icon_path
			if local_node_script:
				icon_path = LocalClassFunctions.get_icon_path(local_node_script.get_global_name())

			if icon_path:
				%SelectedNodeIcon.texture = load(icon_path) as Texture2D
			else:
				%SelectedNodeIcon.texture = EditorInterface.get_editor_theme().get_icon(target_node.get_class(), "EditorIcons")

			%SelectedNodeName.text = node_path
			
	else:
		condition.criteria = null
		condition.is_node_path = false
		condition.node_path_root = null
		%SelectedNodeLabel.hide()

func _on_go_to_node_button_pressed() -> void:
	if is_instance_valid(condition):
		EditorInterface.inspect_object(condition)
