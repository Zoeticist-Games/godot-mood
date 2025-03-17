@tool
extends EditorPlugin

#region Constants

const INSPECTOR_CONDITION_GROUP_SCRIPT = preload("res://addons/mood/sub_plugins/mood_condition_group_inspector_plugin.gd")

const CUSTOM_PROPERTIES: Dictionary = {
	"input_tracking_exact_match": {"category": "input", "type": TYPE_BOOL, "default": true},
	"input_echo_delay_sec": {"category": "input", "type": TYPE_FLOAT, "default": 0.00},
}

#const InputTracker := preload("res://addons/mood/autoloads/input_tracker.gd")

#endregion

#region Variables

var inspector_plugin_instance: EditorInspectorPlugin
var condition_inspector_instance: EditorInspectorPlugin
var input_tracker_singleton: Object

#endregion

#region Setup/Teardown

func _enable_plugin() -> void:
	for config_name in CUSTOM_PROPERTIES:
		var prop_def := CUSTOM_PROPERTIES[config_name] as Dictionary
		var prop_name := "mood/%s/%s" % [prop_def.get("category", "config"), config_name]

		if ProjectSettings.has_setting(prop_name):
			continue

		var property = {
			"name": prop_name,
			"type": prop_def["type"]
		}
		for extra_key in ["hint", "hint_string"]:
			if prop_def.has(extra_key):
				property[extra_key] = prop_def[extra_key]

		ProjectSettings.set_setting(prop_name, prop_def["default"])
		ProjectSettings.add_property_info(property)
		ProjectSettings.set_initial_value(prop_name, prop_def["default"])
		ProjectSettings.set_as_basic(prop_name, !prop_def.has("advanced"))

	add_autoload_singleton("InputTracker", "res://addons/mood/autoloads/input_tracker.gd")

func _disable_plugin() -> void:
	for config_name in CUSTOM_PROPERTIES:
		var def := CUSTOM_PROPERTIES.get(config_name) as Dictionary
		var prop_name := "mood/%s/%s" % [def.get("category", "config"), config_name]
		if ProjectSettings.has_setting(prop_name):
			ProjectSettings.clear(prop_name)

	remove_autoload_singleton("InputTracker")

func _enter_tree() -> void:
	_load_editors()
	condition_inspector_instance = INSPECTOR_CONDITION_GROUP_SCRIPT.new()
	add_inspector_plugin(condition_inspector_instance)

func _exit_tree() -> void:
	remove_inspector_plugin(condition_inspector_instance)

#endregion

#region Built-In Hooks

#endregion

#region Private Methods

func _load_editors() -> void:
	var class_paths := Mood.LocalClassFunctions.get_class_tree_for("MoodCondition").get_flat_data("path")
	for klass: String in class_paths:
		var script_path: String = class_paths[klass]
		var klass_ref := load(script_path)
		if "Editor" in klass_ref and klass not in Mood.Editors.registered_editors:
			Mood.Editors.register_type(klass, klass_ref.get("Editor"))

func _get_plugin_setting(key: String) -> Variant:
	if key not in CUSTOM_PROPERTIES:
		return null

	var setting := "mood/%s/%s" % [CUSTOM_PROPERTIES[key].get("category", "config"), key]
	return ProjectSettings.get_setting(setting)

#endregion
